<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:exslt="http://exslt.org/common" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:sqbl="sqbl:1" xmlns:qwac="qwac:reusable:1"
	xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:xf="http://www.w3.org/2002/xforms"
	xmlns:ev="http://www.w3.org/2001/xml-events" 
	xmlns:skip="http://legostormtoopr/skips" xmlns:cfg="rml:RamonaConfig_v1"
	exclude-result-prefixes="qwac exslt skip cfg" extension-element-prefixes="exslt">
	<!-- Import the XSLT for turning a responseML document into the skip patterns needed for conditional questions. -->
	<!-- xsl:import href="./DDI_to_ResponseML.xsl"/ -->
	<!-- xsl:import href="./configTransformations.xsl"/ -->

	<xsl:import href="SQBL_to_Skips.xsl" />

	<!-- We are outputing XHTML so the output method will be XML, not HTML -->
	<xsl:output method="xml" />

	<!-- Read in the configuration file. This contains information about how the XForm is to be created and displayed. Including CSS file locations and language information. -->
	<!--<xsl:variable name="config" select="document('./config.xml')/cfg:config"/>-->

	<!-- Based on the deployer Environment, determine the correct path to the theme specific configuration file -->
	<!--	<xsl:variable name="theme_file">
		<xsl:choose>
			<!-\- If we are deployed on an eXist-db install construct the correct path to the theme config -\->
			<xsl:when test="$config/cfg:environment = 'exist-db'">
				<xsl:copy-of select="concat('./themes/',$config/cfg:themeName,'/theme.xml')"/>
			</xsl:when>
			<!-\- If we don't know the deployed environment assume the theme is in the default distribution directory -\->
			<xsl:otherwise>
				<xsl:copy-of select="concat('./themes/',$config/cfg:themeName,'/theme.xml')"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>-->
	<!-- The concat below is a work around to pull the correct theme file. If you just try and use this:
			<xsl:variable name="theme" select="document($theme_file)/theme"/>
			It will fail, for some as of yet undetermined reason.
	-->
	<!--<xsl:variable name="theme" select="document(concat('',$theme_file,''))/cfg:theme"/>-->
	<!-- 
		Create the instrument for the XForms Model. This is represntation of the "true XML hierarchy" of the questionnaire (as opposed to the referential hiearchy of the DDI Document
		This is created as a global variable as it is needed in several different places for processing.
		The generated XML model of the questionnaire is needed for the data model of the final XForm, and exists as a ResponseML document.
	-->

	<xsl:variable name="skips">
		<xsl:call-template name="makeSkips">
			<xsl:with-param name="doc" select="//sqbl:ModuleLogic" />
		</xsl:call-template>
	</xsl:variable>

	<xsl:variable name="numbers">
		<xsl:for-each select="//sqbl:Question">
			<xsl:element name="question">
				<xsl:attribute name="name">
					<xsl:value-of select="@name" />
				</xsl:attribute>
				<xsl:value-of select="position()" />
			</xsl:element>
		</xsl:for-each>
	</xsl:variable>

	<!-- 
		==============================
		MAIN ENTRY POINT FOR TRANSFORM
		==============================
		
		This template matches for the base module and creates the boiler plate for the final XHTML+XForms Document.
		It creates sections to hold a side menu linking within the page to all the major sections (div.majorsections), and main section for the survey itself (div.survey)
		There is the assumption that whatever calls this process will construct a DDI document with only one instrument.
		This assumption is based on the fact that only one survey instrument would be displayed to a respondent at a time.
		Prints the instrument name and description, and processes the single, valid ControlConstruct contained within the DDI Instrument.
	-->
	<xsl:template match="/">
		<xsl:processing-instruction name="xml-stylesheet">href="xsltforms-beta2/xsltforms/xsltforms.xsl" type="text/xsl"</xsl:processing-instruction>
		<xsl:processing-instruction name="xsltforms-options">debug="no"</xsl:processing-instruction>
		<html xmlns="http://www.w3.org/1999/xhtml" xmlns:xhtml="http://www.w3.org/1999/xhtml">
			<head>
				<title>
					<xsl:apply-templates select="sqbl:QuestionModule/sqbl:TextComponent/sqbl:LongName" />
				</title>
				<!-- Link to the CSS for rendering the form - ->
				<xsl:apply-templates select="$theme/cfg:styles/*"/ -->
				 <xhtml:link rel="stylesheet"
                  type="text/css"
                  href=".//themes/koala/./Questionnaire.css"/>
				<!-- Xforms Data model and bindings, including the ResponseML data instance. -->
				<xf:model>
					<xf:instance id="{//sqbl:QuestionModule/@name}">
					<!-- xf:instance -->
						<!-- xsl:copy-of select="/sqbl:QuestionModule/sqbl:ModuleLogic" / -->
						<xsl:apply-templates select="/sqbl:QuestionModule/sqbl:ModuleLogic" mode="makeDataModel"/>
						<!-- xsl:call-template name="dataModelBuilder"/ -->
					</xf:instance>
					<xf:instance id="decisionTables">
						<DecisionTables>
							<xsl:apply-templates select="/sqbl:QuestionModule/sqbl:ModuleLogic//sqbl:ConditionalTree" mode="makeDTs" />
						</DecisionTables>
					</xf:instance>
					<xsl:apply-templates select="//sqbl:ModuleLogic//sqbl:ConditionalTree" mode="makeBindings"/>
					<xf:submission id="saveLocally" method="put" action="file://C:/temp/saved_survey.xml" />
					<!-- xf:submission id="saveRemotely" method="post"
						action="{$config/cfg:serverSubmitURI}"/ -->
					<xf:submission id="debugDTs" method="put" ref="instance('decisionTables')//"
						action="file://C:/temp/saved_survey.xml" />
				</xf:model>
			</head>
			<body>
				<div id="survey">
					<h1>
						<xsl:apply-templates select="sqbl:QuestionModule/sqbl:TextComponent/sqbl:LongName" />
					</h1>
					<xsl:apply-templates select="//sqbl:ModuleLogic" />
					<xf:submit submission="saveLocally">
						<xf:label>Save data locally</xf:label>
					</xf:submit>
					<xf:submit submission="saveRemotely">
						<xf:label>Submit</xf:label>
					</xf:submit>
					<xf:submit submission="debugDTs">
						<xf:label>Debug DTs</xf:label>
					</xf:submit>
				</div>
			</body>
		</html>
	</xsl:template>

	<xsl:template match="sqbl:ModuleLogic">
		<xsl:apply-templates select="*" />
	</xsl:template>

	<xsl:template match="sqbl:Statement">
		<xsl:element name="a">
			<xsl:attribute name="name">
				<xsl:value-of select="@name" />
			</xsl:attribute>
			<!-- xsl:value-of select="exslt:node-set($numbers)//question[@name=$qName]"></xsl:value-of -->
			<xsl:apply-templates select="./sqbl:TextComponent[@xml:lang='en']/sqbl:StatementText" />
		</xsl:element>
	</xsl:template>
	<!--
		Process IfThenElse Constructs and their child Then and Else elements.
		Both the Then and Else are wrapped in an XForms group. Then and Else get expressed as child XForms groups of this with bindings to allow or disallow response accordingly.
		Referenced ControlConstructs in the Then and Else blocks are then processed.
		At this point ElseIf constructs are ignored.
	-->
	<xsl:template match="sqbl:ConditionalTree">
		<xsl:apply-templates select="sqbl:Branch" />
	</xsl:template>
	<xsl:template match="sqbl:Branch">
		<xsl:element name="xf:group">
			<xsl:attribute name="bind">bind-<xsl:value-of select="@name" /></xsl:attribute>
			<xsl:apply-templates select="./sqbl:BranchLogic" />
		</xsl:element>
	</xsl:template>

	<xsl:template match="sqbl:Question">
		<p>
		<xsl:variable name="qName" select="@name" />
		<xsl:element name="xf:input">
			<xsl:attribute name="ref">instance('<xsl:value-of select="//sqbl:QuestionModule/@name"/>')//*[@name='<xsl:value-of select="@name" />']</xsl:attribute>
			<!-- xsl:attribute name="ref">//sqbl:Question[@name='<xsl:value-of select="@name" />']</xsl:attribute -->
			<xf:label>
				<xsl:element name="a">
					<xsl:attribute name="name">
						<xsl:value-of select="@name" />
					</xsl:attribute>
					<xsl:value-of select="exslt:node-set($numbers)//question[@name=$qName]" />. <xsl:apply-templates
						select="./sqbl:TextComponent[@xml:lang='en']/sqbl:QuestionText" />
				</xsl:element>
			</xf:label>
			<xsl:variable name="name" select="@name" />
			<xsl:if test="count(exslt:node-set($skips)/skip:skips2/*[@from=$name]) > 1">
				<ul>
					<xsl:for-each select="exslt:node-set($skips)/skip:skips2/*[@from=$name]">
						<li>
							<xsl:choose>
								<xsl:when test="@condition='otherwise'"> Otherwise </xsl:when>
								<xsl:otherwise> If <xsl:value-of select="skip:condition/@comparator" />
										'<xsl:value-of select="skip:condition" />' </xsl:otherwise>
							</xsl:choose> Go to <a href="#{@to}"><small><xsl:value-of select="@to" /></small></a>
						</li>
					</xsl:for-each>
				</ul>
			</xsl:if>
		</xsl:element>
		</p>
	</xsl:template>

	<xsl:template match="*" mode="makeDTs" />
	<xsl:template match="sqbl:ConditionalTree" mode="makeDTs">
		<sqbl:SequenceGuide name="{@name}">
			<!-- The name is never used on this element, its just a sanity check for coders debuging the generated XForms -->
			<xsl:for-each select="sqbl:SequenceGuide/sqbl:Condition">
				<sqbl:Condition name="{@resultBranch}" />
			</xsl:for-each>
		</sqbl:SequenceGuide>
	</xsl:template>

	<xsl:template match="*" mode="makeBindings" />
	<xsl:template match="sqbl:ConditionalTree" mode="makeBindings">
		<xsl:apply-templates select="sqbl:SequenceGuide/sqbl:Condition" mode="makeBindings" />
		<xsl:apply-templates select="sqbl:Branch" mode="makeBindings" />
	</xsl:template>

	<xsl:template match="sqbl:Condition" mode="makeBindings">
		<xsl:element name="xf:bind">
			<xsl:variable name="Bid">
				<xsl:value-of select="@resultBranch" />
			</xsl:variable>
			<xsl:attribute name="id">bind-SG-<xsl:value-of select="$Bid" />-<xsl:value-of select="position()" /></xsl:attribute>
			<xsl:attribute name="nodeset">instance('decisionTables')//*[@name='<xsl:value-of select="$Bid" />' and position()=<xsl:value-of select="position()" />]</xsl:attribute>
			<xsl:attribute name="calculate">
				<xsl:text>true()</xsl:text>
				<xsl:for-each select="sqbl:ValueOf">
					<xsl:variable name="cond">
						<xsl:if test="@is = 'equal_to'">
							<xsl:text>=</xsl:text>
						</xsl:if>
						<xsl:if test="@is = 'not_equal_to'">
							<xsl:text>!=</xsl:text>
						</xsl:if>
						<xsl:if test="@is = 'less_than'">
							<xsl:text>&lt;</xsl:text>
						</xsl:if>
						<xsl:if test="@is = 'less_than_eq'">
							<xsl:text>&lt;=</xsl:text>
						</xsl:if>
						<xsl:if test="@is = 'greater_than'">
							<xsl:text>&gt;</xsl:text>
						</xsl:if>
						<xsl:if test="@is = 'greater_than_eq'">
							<xsl:text>&gt;=</xsl:text>
						</xsl:if>
						<!-- We can fix the next two later -->
						<xsl:if test="@is = 'inclusive_of'">
							<xsl:text>=</xsl:text>
						</xsl:if>
						<xsl:if test="@is = 'match_for'">
							<xsl:text>=</xsl:text>
						</xsl:if>
					</xsl:variable>
					<xsl:text /> and instance('<xsl:value-of select="//sqbl:QuestionModule/@name" />')//.[@name='<xsl:value-of select="@question" />'] <xsl:value-of select="$cond"/> '<xsl:value-of select="." />'<xsl:text />
				</xsl:for-each>
			</xsl:attribute>
		</xsl:element>
	</xsl:template>

	<xsl:template match="sqbl:Branch" mode="makeBindings">
		<xsl:element name="xf:bind">
			<xsl:attribute name="id">bind-<xsl:value-of select="@name" /></xsl:attribute>
			<xsl:attribute name="nodeset">instance('<xsl:value-of select="//sqbl:QuestionModule/@name"/>')//[@name='<xsl:value-of select="@name" />']</xsl:attribute>
			<xsl:attribute name="relevant">instance('decisionTables')//[@name='<xsl:value-of select="@name" />'] = true()</xsl:attribute>
			<xsl:attribute name="readonly">not(instance('decisionTables')//[@name='<xsl:value-of select="@name" />'] = true())</xsl:attribute>
		</xsl:element>
	</xsl:template>

	<xsl:template match="@*|node()" mode="makeDataModel">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()" mode="makeDataModel"/>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="sqbl:Question" mode="makeDataModel">
		<sqbl:Question name="{@name}" />
	</xsl:template>
	

</xsl:stylesheet>
