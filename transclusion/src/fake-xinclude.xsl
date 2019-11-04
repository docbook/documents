<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0"
		xmlns:f="http://docbook.org/xslt/ns/extension"
		xmlns:mp="http://docbook.org/xslt/ns/mode/private"
		xmlns:db="http://docbook.org/ns/docbook"
		xmlns:xs="http://www.w3.org/2001/XMLSchema"
		xmlns:xi="http://www.w3.org/2001/XInclude"
		xmlns:xia="http://www.w3.org/2001/XInclude/local-attributes"
		exclude-result-prefixes="f mp xs db xi xia">

<xsl:template match="node()">
  <xsl:copy>
    <xsl:copy-of select="@*"/>
    <xsl:apply-templates/>
  </xsl:copy>
</xsl:template>

<xsl:template match="xi:include[not(@parse) or (@parse = 'xml')]">
  <xsl:variable name="doc" select="doc(resolve-uri(@href, base-uri(.)))"/>
  <xsl:variable name="node">
    <xsl:choose>
      <xsl:when test="@xpointer">
        <xsl:sequence select="$doc//*[@xml:id = current()/@xpointer]"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="$doc/node()"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  <xsl:apply-templates select="$node" mode="fix-outer-node">
    <xsl:with-param name="set-xml-id" select="not(empty(@set-xml-id))"/>
    <xsl:with-param name="id" select="@set-xml-id"/>
    <xsl:with-param name="attrs" select="@*[namespace-uri() != ''] except (@xml:* | @xia:*)"/>
    <xsl:with-param name="local-attrs" select="@xia:*"/>
    <xsl:with-param name="base-uri" select="(: resolve-uri( :) @href (:, base-uri(.)):)"/>
  </xsl:apply-templates>
</xsl:template>

<xsl:template match="node()[not(self::*)]" mode="fix-outer-node">
  <xsl:copy>
    <xsl:apply-templates/>
  </xsl:copy>
</xsl:template>

<xsl:template match="*" mode="fix-outer-node">
  <xsl:param name="set-xml-id"/>
  <xsl:param name="id"/>
  <xsl:param name="attrs"/>
  <xsl:param name="local-attrs"/>
  <xsl:param name="base-uri"/>
  <xsl:copy>
    <xsl:copy-of select="@* except @xml:id[$set-xml-id]"/>
    <xsl:copy-of select="$attrs"/>
    <xsl:for-each select="$local-attrs">
      <xsl:attribute name="{local-name(.)}" select="."/>
    </xsl:for-each>
    <xsl:if test="$set-xml-id and $id ne ''">
      <xsl:attribute name="xml:id" select="$id"/>
    </xsl:if>
    <xsl:attribute name="xml:base" select="$base-uri"/>
    <xsl:apply-templates/>
  </xsl:copy>
</xsl:template>

<xsl:template match="xi:include[@parse = 'text']">
  <xsl:copy-of select="unparsed-text(resolve-uri(@href, base-uri(.)))"/>
</xsl:template>

</xsl:stylesheet>