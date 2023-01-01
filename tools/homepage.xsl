<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:db="http://docbook.org/ns/docbook"
                xmlns:h="http://www.w3.org/1999/xhtml"
                xmlns:m="http://docbook.org/ns/docbook/modes"
                xmlns:v="http://docbook.org/ns/docbook/variables"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns="http://www.w3.org/1999/xhtml"
                exclude-result-prefixes="db h m v xs"
                version="3.0">

  <xsl:import href="https://cdn.docbook.org/release/xsltng/current/xslt/docbook.xsl"/>
<!--
  <xsl:import href="/Users/ndw/Projects/docbook/xslTNG/build/xslt/docbook.xsl"/>
-->

  <xsl:param name="css-links" select="'css/docbook.css css/docbook-screen.css css/transclude.css'"/>

  <xsl:param name="generate-toc" select="'self::db:book'"/>

  <xsl:variable name="v:user-title-properties" as="element()*">
    <title xpath="self::db:section"
           label="false"/>
  </xsl:variable>

  <!-- chunk cleanup; move article header elements into nav -->

  <xsl:template match="/" mode="m:chunk-cleanup">
    <xsl:param name="docbook" as="document-node()" tunnel="yes" required="yes"/>
    <xsl:variable name="clean">
      <xsl:next-match/>
    </xsl:variable>

    <xsl:document>
      <xsl:apply-templates select="$clean/*" mode="reorg-nav"/>
    </xsl:document>
  </xsl:template>

  <xsl:template match="h:nav[@class='top']" mode="reorg-nav">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="reorg-nav"/>
      <xsl:apply-templates select="//h:article/h:header/node()" mode="reorg-nav"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="h:article/h:header/h:h1" mode="reorg-nav">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="reorg-nav"/>
      <div class="center">
        <img src="https://docbook.org/graphics/banner.png" alt="Duck graphic"/>
        <xsl:apply-templates select="node()" mode="reorg-nav"/>
      </div>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="h:article/h:header" mode="reorg-nav">
    <!-- discard -->
  </xsl:template>

  <xsl:template match="element()" mode="reorg-nav">
    <xsl:copy>
      <xsl:apply-templates select="@*,node()" mode="reorg-nav"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="attribute()|text()|comment()|processing-instruction()"
                mode="reorg-nav">
    <xsl:copy/>
  </xsl:template>
</xsl:stylesheet>
