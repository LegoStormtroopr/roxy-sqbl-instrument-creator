<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:exslt="http://exslt.org/common" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:sqbl="sqbl:1" xmlns:ddi="ddi:instance:3_1"
	xmlns:a="ddi:archive:3_1" xmlns:r="ddi:reusable:3_1" xmlns:xhtml="http://www.w3.org/1999/xhtml"
	xmlns:d="ddi:datacollection:3_1" xmlns:l="ddi:logicalproduct:3_1" xmlns:c="ddi:conceptualcomponent:3_1"
	xmlns:ds="ddi:dataset:3_1" xmlns:s="ddi:studyunit:3_1" xmlns:g="ddi:group:3_1"
	exclude-result-prefixes="exslt fn fo xsl" extension-element-prefixes="exslt">
	<xsl:output method="xml" />
	<xsl:variable name="moduleName" select="/sqbl:QuestionModule/@name" />
	<xsl:template match="/">
		<ddi:DDIInstance id="x0" version="0.0.1" agency="com.kidstrythisathome.ddirepo.legostormtroopr">
			<g:ResourcePackage id="DogSurvey_Test_Form_1">
				<g:Purpose id="x2">
					<r:Content />
				</g:Purpose>
				<g:DataCollection />
				<d:QuestionScheme id="{$moduleName}_QuestionScheme">
					<xsl:apply-templates select="//sqbl:Question" mode="makeQuestionScheme" />
				</d:QuestionScheme>
			</g:ResourcePackage>
		</ddi:DDIInstance>
	</xsl:template>
	<xsl:template match="*" mode="makeQuestionScheme" />
	<xsl:template match="sqbl:Question" mode="makeQuestionScheme">
		<d:QuestionItem id="{$moduleName}_{./@name}_Question">
			<xsl:apply-templates select="sqbl:TextComponent/sqbl:QuestionText" mode="makeQuestionScheme" />
			<xsl:apply-templates select="sqbl:TextComponent/sqbl:QuestionIntent" mode="makeQuestionScheme" />
			<xsl:apply-templates select="sqbl:ResponseType" mode="makeQuestionScheme" />
		</d:QuestionItem>
	</xsl:template>
	<xsl:template match="sqbl:QuestionText" mode="makeQuestionScheme">
		<d:QuestionText xml:lang="{../@xml:lang}">
			<d:LiteralText>
				<d:Text>
					<xsl:value-of select="." />
				</d:Text>
			</d:LiteralText>
		</d:QuestionText>
	</xsl:template>
	<xsl:template match="sqbl:QuestionIntent" mode="makeQuestionScheme">
		<d:QuestionIntent xml:lang="{../@xml:lang}">
			<xsl:value-of select="." />
		</d:QuestionIntent>
	</xsl:template>
	<xsl:template match="sqbl:ResponseType" mode="makeQuestionScheme">
		<xsl:choose>
			<xsl:when test="count(*) = 1">
				<xsl:apply-templates mode="makeQuestionScheme" />
			</xsl:when>
			<xsl:otherwise>
				<d:StructuredMixedResponseDomain>
					<xsl:apply-templates mode="makeQuestionScheme" />
				</d:StructuredMixedResponseDomain>
			</xsl:otherwise>
		</xsl:choose>

	</xsl:template>
	<xsl:template match="sqbl:ResponseType/*" mode="makeQuestionScheme">
		<d:TextDomain />
	</xsl:template>

	<xsl:template match="sqbl:ResponseType/sqbl:CodeList" mode="makeQuestionScheme">
		<d:CodeDomain>
			<r:CodeSchemeReference>
				<r:ID>x</r:ID>
			</r:CodeSchemeReference>
		</d:CodeDomain>
	</xsl:template>
	<xsl:template match="sqbl:ResponseType/sqbl:Number" mode="makeQuestionScheme">
		<d:NumericDomain type="Decimal" />
	</xsl:template>
	<xsl:template match="sqbl:ResponseType/sqbl:Text" mode="makeQuestionScheme">
		<d:TextDomain />
	</xsl:template>

</xsl:stylesheet>
