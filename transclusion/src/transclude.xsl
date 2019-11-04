<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0"
                xmlns:f="http://docbook.org/xslt/ns/extension"
                xmlns:mp="http://docbook.org/xslt/ns/mode/private"
                xmlns:db="http://docbook.org/ns/docbook"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:ta="http://docbook.org/ns/transclude"
                xmlns:xia="http://www.w3.org/2001/XInclude/local-attributes"
                exclude-result-prefixes="f mp xs ta xia">

<!-- Remove for production files, pretty print can harm mixed content -->
<xsl:output indent="yes"/>

<xsl:template match="/">
  <xsl:variable name="adjusted" select="f:adjust-ids(/)"/>
  <xsl:variable name="result" select="f:adjust-idrefs($adjusted)"/>
  <xsl:sequence select="f:transclude-cleanup($result)"/>
</xsl:template>

<!-- Separator for auto generated suffixes -->
<xsl:param name="psep" select="'---'"/>

<!-- Function and mode for changing IDs based on provided suffix -->
<xsl:function name="f:adjust-ids" as="node()+">
  <xsl:param name="doc" as="node()+"/>

  <xsl:apply-templates select="$doc" mode="mp:transclude"/>
</xsl:function>

<xsl:template match="node()" mode="mp:transclude">
  <xsl:param name="idfixup" select="'none'" tunnel="yes"/>
  <xsl:param name="suffix" tunnel="yes"/>
  <xsl:copy>
    <xsl:copy-of select="@* except @xml:id"/>
    <xsl:if test="@xml:id">
      <xsl:choose>
        <xsl:when test="($idfixup = 'none')">
          <xsl:copy-of select="@xml:id"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:attribute name="xml:id" select="concat(@xml:id, $suffix)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
    <xsl:apply-templates mode="mp:transclude"/>
  </xsl:copy>
</xsl:template>

<xsl:template match="node()[@ta:*]" mode="mp:transclude">
  <xsl:param name="idfixup" select="'none'" tunnel="yes"/>
  <xsl:param name="suffix" tunnel="yes"/>

  <xsl:variable name="new-idfixup" select="if (@ta:idfixup) then @ta:idfixup else $idfixup"/>
  <xsl:variable name="linkscope" select="if (@ta:linkscope) then @ta:linkscope else 'near'"/>
  <xsl:variable name="new-suffix">
    <xsl:choose>
      <xsl:when test="$new-idfixup = 'auto'">
        <xsl:sequence select="concat($psep, generate-id(.))"/>
      </xsl:when>
      <xsl:when test="$new-idfixup = 'suffix'">
        <xsl:sequence select="concat($suffix, @ta:suffix)"/>
      </xsl:when>
      <xsl:otherwise></xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:copy>
    <xsl:copy-of select="@* except @xml:id"/>
    <xsl:if test="@xml:id">
      <xsl:choose>
        <xsl:when test="($new-idfixup = 'none')">
          <xsl:copy-of select="@xml:id"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:attribute name="xml:id" select="concat(@xml:id, $new-suffix)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
    <xsl:attribute name="ta:suffix" select="$new-suffix"/>
    <xsl:apply-templates mode="mp:transclude">
      <xsl:with-param name="idfixup" select="$new-idfixup" tunnel="yes"/>
      <xsl:with-param name="suffix" select="$new-suffix" tunnel="yes"/>
    </xsl:apply-templates>
  </xsl:copy>  
</xsl:template>

<!-- Function and mode for adjusting references to IDs -->
<xsl:function name="f:adjust-idrefs" as="node()+">
  <xsl:param name="doc" as="node()+"/>

  <xsl:apply-templates select="$doc" mode="mp:adjust-idrefs"/>
</xsl:function>

<xsl:template match="node()|@*" mode="mp:adjust-idrefs">
  <xsl:copy>
    <xsl:apply-templates select="@* | node()" mode="mp:adjust-idrefs"/>
  </xsl:copy>
</xsl:template>

<!-- FIXME: add support for @linkends, @zone, @arearefs -->
<!-- FIEMX: add support for xlink:href starting with # -->
<xsl:template match="@linkend | @endterm | @otherterm | @startref" mode="mp:adjust-idrefs">
  <xsl:variable name="idref" select="."/>

  <xsl:variable name="annotation" select="ancestor-or-self::*[@ta:linkscope][1]"/>
  <xsl:variable name="linkscope" select="($annotation/@ta:linkscope, 'near')[1]"/>
  <xsl:variable name="suffix" select="$annotation/@ta:suffix"/>

  <xsl:attribute name="{local-name(.)}">
    <xsl:choose>
      <xsl:when test="$linkscope = 'user'">
        <xsl:value-of select="$idref"/>
      </xsl:when>
      <xsl:when test="$linkscope = 'local'">
        <xsl:value-of select="concat($idref, $suffix)"/>
      </xsl:when>
      <xsl:when test="$linkscope = 'near'">
        <xsl:value-of select="f:nearest-matching-id($idref, ..)"/>
      </xsl:when>
      <xsl:when test="$linkscope = 'global'">
        <xsl:value-of select="f:nearest-matching-id($idref, root(.))"/>
      </xsl:when>
    </xsl:choose>
  </xsl:attribute>
</xsl:template>

<!-- Function searches nearest matching ID in a given context -->
<xsl:function name="f:nearest-matching-id" as="xs:string?">
  <xsl:param name="idref" as="xs:string"/>
  <xsl:param name="context" as="node()"/>

  <!-- FIXME: key() requires document-node() rooted subtree -->
  <!--  <xsl:variable name="targets" select="key('unprefixed-id', f:unprefixed-id($idref, $context), $context)"/> -->
  <xsl:variable name="targets" select="$context//*[@xml:id][f:unprefixed-id(@xml:id, .) eq f:unprefixed-id($idref, $context)]"/> 

  <xsl:choose>
    <xsl:when test="not($targets) and $context/..">
      <xsl:sequence select="f:nearest-matching-id($idref, $context/..)"/>
    </xsl:when>
    <xsl:when test="$targets">
      <xsl:sequence select="$targets[1]/string(@xml:id)"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:message>Error: no matching ID for reference "<xsl:value-of select="$idref"/>" was found.</xsl:message>
    </xsl:otherwise>
  </xsl:choose>
</xsl:function>

<!-- FIXME: type annotation should be without ?, find why it is called with empty sequence -->
<xsl:function name="f:unprefixed-id" as="xs:string?">
  <xsl:param name="id" as="xs:string?"/>
  <xsl:param name="context" as="node()"/>
  
  <xsl:variable name="suffix" select="$context/ancestor-or-self::*[@ta:suffix][1]/@ta:suffix"/>

  <xsl:sequence select="if ($suffix) then substring-before($id, $suffix) else $id"/>
</xsl:function>

<!--
<xsl:key name="unprefixed-id" match="*[@xml:id]" use="f:unprefixed-id(@xml:id, .)"/>
-->

<!-- Function and mode for removing transclusion attributes from the final output -->
<xsl:function name="f:transclude-cleanup" as="node()+">
  <xsl:param name="doc" as="node()+"/>
  
  <xsl:apply-templates select="$doc" mode="mp:transclude-cleanup"/>
</xsl:function>
  
<xsl:template match="node()" mode="mp:transclude-cleanup">
  <xsl:copy>
    <xsl:apply-templates mode="mp:transclude-cleanup"/>
  </xsl:copy>
</xsl:template>      

<xsl:template match="*" mode="mp:transclude-cleanup" priority="10">
  <xsl:element name="{name()}" namespace="{namespace-uri()}">
    <xsl:copy-of select="@* except @ta:*"/>
    <xsl:apply-templates mode="mp:transclude-cleanup"/>
  </xsl:element>
</xsl:template>      
  
</xsl:stylesheet>