<xsl:stylesheet
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xalan="http://xml.apache.org/xslt"
	version="2.0">
<xsl:output method="xml" indent="yes"/>

<xsl:param name="user_name" />
<xsl:param name="user_groups" />
<xsl:param name="default_user_group" />
<xsl:param name="contact" />

<xsl:template match="media-mogul-configuration">
<media-mogul-configuration>
<config>
	<segment-templates>
		<!-- EDIT THIS FILE WITH CAUTION! -->
		<!-- Errors processing this file will force all users to have the system default template, with no overrides. -->

		<!-- These templates will be available to all users. -->
		<!-- Template names must be alphanumeric with no punctuation except for the underscore character. -->
		<template name="default" display-name="Default" asset-type="all">
			<limits BODY="1" HEADLINE="1" BYLINE="1"/>
			<!-- HEADLINE, BYLINE(Author), and BODY are all mandatory. This decision is documented as CHP-212. -->
			<segment type="HEADLINE" mandatory="true" static="true"></segment>
			<segment type="BYLINE" mandatory="false"><content><xsl:value-of select="$contact"/></content></segment>
			<segment type="BODY" mandatory="true" static="true"></segment>
		</template>

		<xsl:if test="$user_name = 'Harker'">
			<template name="default" display-name="News International Template" asset-type="STORY">
				<limits BODY="1" HEADLINE="1" BYLINE="1"/>
				<segment type="HEADLINE" mandatory="true" static="true"></segment>
				<segment type="CAPTION" mandatory="false"><content></content></segment>
				<segment type="BYLINE" mandatory="false"><content><xsl:value-of select="$contact"/></content></segment>
				<segment type="BODY" mandatory="true" static="true"><content></content></segment>
			</template>
		</xsl:if>

		<xsl:if test="$default_user_group = 'Lobby'">
			<template name="default" display-name="OpenText TEST Template">
				<limits BODY="1" HEADLINE="1" CAPTION="1"/>
				<segment type="HEADLINE" mandatory="false" static="true"></segment>
				<segment type="CAPTION" mandatory="true"><content></content></segment>
				<segment type="BODY" mandatory="false" static="true"><content></content></segment>
			</template>
		</xsl:if>

		<!-- This section allows the template list to be extended (or overridden by duplicating a named template). -->
		<!-- Users may have more than one role, these are passed in in lower case in a comma separated list. -->
		<xsl:for-each select="tokenize($user_groups, ',')" >
			<xsl:choose>
				<xsl:when test=". = 'sports desk'">
					<!--
					<template name="default" display-name="Sports Desk Default">
						<limits BODY="1" HEADLINE="1" BYLINE="1"/>
						<segment type="HEADLINE" mandatory="true" static="true"></segment>
						<segment type="BYLINE" mandatory="false"><content><xsl:value-of select="$contact"/></content></segment>
						<segment type="BODY" mandatory="true" static="true"><content></content></segment>
					</template>
					<template name="default_with_caption" display-name="Sports Desk with Caption">
						<limits BODY="1" HEADLINE="1" BYLINE="1"/>
						<segment type="HEADLINE" mandatory="true" static="true"></segment>
						<segment type="CAPTION" mandatory="false"><content></content></segment>
						<segment type="BYLINE" mandatory="false"><content><xsl:value-of select="$contact"/></content></segment>
						<segment type="BODY" mandatory="true" static="true"><content></content></segment>
					</template>
					-->
				</xsl:when>
			</xsl:choose>

		</xsl:for-each>

		<!--
		The frommetadata attribute allows for a list of fallback attributes to be specified. It works like this:
		<Comma separated list of attribute names 1>;<Comma separated list of attribute names 2>;...;<CS list of attribute names n>
		It checks each list of attribute names in turn. If all of the attributes specified in one section are blank, it moves onto the next one.
		-->

		<!-- 
		Followings should not be required for CHP 16.4.2 as Telegraph are no longer using escenic 
		
		<template name="escenic_gallery" display-name="Escenic gallery template" hide-from-ui="TRUE">
			<segment type="HEADLINE" mandatory="true" static="true" textrequired="true" copyto="SegmentEditor.copyValueTo" copytoargs="Headline on summary page,Window title"></segment>
			<segment type="STANDFIRST" mandatory="true" static="true" copyto="SegmentEditor.copyValueTo" copytoargs="Abstract on summary page,Metadata description"></segment>

			<segment name="Headline on summary page" type="EMD_SLIM" mandatory="true" static="true" emdmap="ESCENIC_GALLERY__SECTION_HEADLINE" column="2" fromsegment="HEADLINE"></segment>
			<segment name="Abstract on summary page" type="EMD" mandatory="true" static="true" emdmap="ESCENIC_GALLERY__SECTION_ABSTRACT" column="2" fromsegment="STANDFIRST"></segment>
			<segment name="Window title" type="EMD_SLIM" mandatory="true" static="true" textrequired="true" emdmap="ESCENIC_GALLERY__WINDOW_TITLE" column="2" fromsegment="HEADLINE" plaintext="true"></segment>
			<segment name="Custom URL" type="EMD_SLIM" mandatory="true" static="true" emdmap="ESCENIC_GALLERY__CUSTOM_URL" column="2" plaintext="true"></segment>
			<segment name="Metadata description" type="EMD" mandatory="true" static="true" emdmap="ESCENIC_GALLERY__DESCRIPTION" column="2" fromsegment="STANDFIRST" plaintext="true"></segment>
			<segment name="Keywords" type="EMD_SLIM" mandatory="true" static="true" emdmap="ESCENIC_GALLERY__KEYWORDS" column="2" frommetadata="KEYWORDS;ON_ENTITIES,PN_ENTITIES,GL_ENTITIES" plaintext="true" copyto="SegmentEditor.extractOTCAValues" copytoargs="extract:KEYWORDS;ON_ENTITIES-PN_ENTITIES-GL_ENTITIES"></segment>
			<segment name="Label when on section page" type="EMD_SLIM" mandatory="true" static="true" emdmap="ESCENIC_GALLERY__LABEL_ON_SECTION_PAGE" column="2"></segment>
		</template>

		<template name="escenic_story" display-name="Escenic story template" hide-from-ui="TRUE">
			<segment type="HEADLINE" mandatory="true" static="true" copyto="SegmentEditor.copyValueTo" copytoargs="Headline on summary page,Window title"></segment>
			<segment type="STANDFIRST" mandatory="true" static="true" copyto="SegmentEditor.copyValueTo" copytoargs="Abstract on summary page,Metadata description"></segment>
			<segment type="BYLINE" mandatory="true" static="true"></segment>
			<segment type="BODY" mandatory="true" static="true"></segment>
			<segment type="PULLQUOTE" mandatory="true" static="true"></segment>

			<segment name="Author job title" type="EMD_SLIM" mandatory="true" static="true" emdmap="ESCENIC_STORY__AUTHOR_JOB_TITLE" column="2"></segment>
			<segment name="Author location" type="EMD_SLIM" mandatory="true" static="true" emdmap="ESCENIC_STORY__AUTHOR_LOCATION" column="2"></segment>
			<segment name="Headline on summary page" type="EMD_SLIM" mandatory="true" static="true" emdmap="ESCENIC_STORY__SECTION_HEADLINE" column="2" fromsegment="HEADLINE"></segment>
			<segment name="Abstract on summary page" type="EMD" mandatory="true" static="true" emdmap="ESCENIC_STORY__SECTION_ABSTRACT" column="2" fromsegment="STANDFIRST"></segment>
			<segment name="Window title" type="EMD_SLIM" mandatory="true" static="true" textrequired="true" emdmap="ESCENIC_STORY__WINDOW_TITLE" column="2" fromsegment="HEADLINE" plaintext="true"></segment>
			<segment name="Custom URL" type="EMD_SLIM" mandatory="true" static="true" emdmap="ESCENIC_STORY__CUSTOM_URL" column="2" plaintext="true"></segment>
			<segment name="Metadata description" type="EMD" mandatory="true" static="true" emdmap="ESCENIC_STORY__DESCRIPTION" column="2" fromsegment="STANDFIRST" plaintext="true"></segment>
			<segment name="Keywords" type="EMD_SLIM" mandatory="true" static="true" emdmap="ESCENIC_STORY__KEYWORDS" column="2" frommetadata="KEYWORDS;ON_ENTITIES,PN_ENTITIES,GL_ENTITIES" plaintext="true"></segment>
			<segment name="Pullquote source" type="EMD_SLIM" mandatory="true" static="true" emdmap="ESCENIC_STORY__PULLQUOTE_SOURCE" column="2" plaintext="true"></segment>
		</template>

		<template name="escenic_video" display-name="Escenic video template" hide-from-ui="TRUE">
			<segment type="HEADLINE" mandatory="true" static="true" copyto="SegmentEditor.copyValueTo" copytoargs="Headline on summary page,Window title"></segment>
			<segment type="STANDFIRST" mandatory="true" static="true" copyto="SegmentEditor.copyValueTo" copytoargs="Abstract on summary page,Metadata description"></segment>
			<segment type="BYLINE" mandatory="true" static="true"></segment>
			<segment type="BODY" mandatory="true" static="true"></segment>

			<segment name="Author job title" type="EMD_SLIM" mandatory="true" static="true" emdmap="ESCENIC_VIDEO__AUTHOR_JOB_TITLE" column="2"></segment>
			<segment name="Author location" type="EMD_SLIM" mandatory="true" static="true" emdmap="ESCENIC_VIDEO__AUTHOR_LOCATION" column="2"></segment>
			<segment name="Headline on summary page" type="EMD_SLIM" mandatory="true" static="true" emdmap="ESCENIC_VIDEO__SECTION_HEADLINE" column="2" fromsegment="HEADLINE"></segment>
			<segment name="Abstract on summary page" type="EMD" mandatory="true" static="true" emdmap="ESCENIC_VIDEO__SECTION_ABSTRACT" column="2" fromsegment="STANDFIRST"></segment>
			<segment name="Window title" type="EMD_SLIM" mandatory="true" static="true" textrequired="true" emdmap="ESCENIC_VIDEO__WINDOW_TITLE" column="2" fromsegment="HEADLINE" plaintext="true"></segment>
			<segment name="Custom URL" type="EMD_SLIM" mandatory="true" static="true" emdmap="ESCENIC_VIDEO__CUSTOM_URL" column="2" plaintext="true"></segment>
			<segment name="Metadata description" type="EMD" mandatory="true" static="true" emdmap="ESCENIC_VIDEO__DESCRIPTION" column="2" fromsegment="STANDFIRST" plaintext="true"></segment>
			<segment name="Keywords" type="EMD_SLIM" mandatory="true" static="true" emdmap="ESCENIC_VIDEO__KEYWORDS" column="2" frommetadata="KEYWORDS;ON_ENTITIES,PN_ENTITIES,GL_ENTITIES" plaintext="true"></segment>
		</template>
		-->
		
		<!-- 
		Followings should not be required for CHP 16.4.2 but if there is issue with DTI integration, try uncomment 

		<template name="dti_story" display-name="DTI story template">
			<segment type="HEADLINE" mandatory="true" static="true"></segment>
			<segment type="STANDFIRST" mandatory="true" static="true"></segment>
			<segment type="BYLINE" mandatory="true" static="true"></segment>
			<segment type="BODY" mandatory="true" static="true"></segment>
		</template>

		<template name="dti_collection" display-name="DTI collection template">
			<segment type="DESCRIPTION" mandatory="true" static="true"></segment>
		</template>
		--> 
		
	</segment-templates>
</config>
</media-mogul-configuration>
</xsl:template>
</xsl:stylesheet>
