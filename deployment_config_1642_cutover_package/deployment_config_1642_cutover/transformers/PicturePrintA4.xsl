<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:svg="http://www.w3.org/2000/svg">
	<xsl:output method="xml" version="1.0" encoding="UTF-8"/>

	<!-- template used to generate external image tag also resize-->
	<xsl:template name="generateimagetag">
		<xsl:param name="width"/>
		<xsl:param name="height"/>
		<xsl:param name="maxwidth"/>
		<xsl:param name="maxheight"/>
		<xsl:param name="imgURL"/>
		<xsl:param name="mm"/>
		<xsl:choose>
			<xsl:when test="not(number($height)) or not(number($width))">
				<fo:external-graphic width="100%" height="100%" content-width="scale-to-fit" content-height="scale-to-fit">
					<xsl:attribute name="src"><xsl:value-of select="$imgURL"/>&amp;streamAsset=false&amp;internal=true</xsl:attribute>
					<xsl:if test="number($maxheight) and number($maxwidth)">
						<xsl:choose>
							<xsl:when test="$maxheight &gt; $maxwidth">
								<xsl:attribute name="height"><xsl:value-of select="$maxheight"/><xsl:value-of select="$mm"/></xsl:attribute>
							</xsl:when>
							<xsl:otherwise>
								<xsl:attribute name="width"><xsl:value-of select="$maxwidth"/><xsl:value-of select="$mm"/></xsl:attribute>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:if>
				</fo:external-graphic>
			</xsl:when>
			<xsl:when test="($height div $width) &gt; ($maxheight div $maxwidth)">
				<fo:external-graphic height="number($height)mm" width="number($width)mm" content-width="scale-to-fit">
					<xsl:attribute name="height"><xsl:value-of select="$maxheight"/><xsl:value-of select="$mm"/></xsl:attribute>
					<xsl:attribute name="width"><xsl:value-of select="($width div $height) * $maxheight"/><xsl:value-of select="$mm"/></xsl:attribute>
					<xsl:attribute name="src"><xsl:value-of select="$imgURL"/>&amp;streamAsset=false&amp;internal=true</xsl:attribute>
				</fo:external-graphic>
			</xsl:when>
			<xsl:otherwise>
				<fo:external-graphic height="number($height)mm" width="number($width)mm" content-height="scale-to-fit">
					<xsl:attribute name="width"><xsl:value-of select="$maxwidth"/><xsl:value-of select="$mm"/></xsl:attribute>
					<xsl:attribute name="height"><xsl:value-of select="($height div $width) * $maxwidth"/><xsl:value-of select="$mm"/></xsl:attribute>
					<xsl:attribute name="src"><xsl:value-of select="$imgURL"/>&amp;streamAsset=false&amp;internal=true</xsl:attribute>
				</fo:external-graphic>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!-- template used to generate external image tag also resize-->
	<xsl:template name="stripzeroes">
		<xsl:param name="text"/>
		<xsl:choose>
			<xsl:when test="substring(string($text),1,1) = '0'">
				<xsl:call-template name="stripzeroes">
					<xsl:with-param name="text" select="substring($text,2,string-length($text))"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$text" />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!-- portrait orientation -->

	<xsl:template name="portrait">
		<fo:page-sequence master-reference="PortraitMasterPage">
			<fo:static-content flow-name="xsl-region-after">
				<fo:block space-after="1mm" border-after-style="solid" border-after-width="thin" />
				<fo:table table-layout="fixed" font-size="9pt">
					<fo:table-column column-number="1" column-width="150mm" />
					<fo:table-column column-number="2" column-width="39mm" />
					<fo:table-body>
					<fo:table-row>
						<fo:table-cell>
							<fo:block text-align="left" font-size="9pt">
								<xsl:value-of select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_CHP_REPORT']"/>
							</fo:block>
						</fo:table-cell>
						<fo:table-cell>
							<fo:block text-align="right" font-size="9pt">
								<fo:page-number/> / <xsl:value-of select="count(/XMLData/XMLDataObjects/XMLDataObject)" />
							</fo:block>
						</fo:table-cell>
					</fo:table-row>
					</fo:table-body>
				</fo:table>
			</fo:static-content>

			<fo:flow flow-name="xsl-region-body">

				<!-- insert header -->
				<fo:table table-layout="fixed" font-size="9pt">
					<fo:table-column column-number="1" column-width="95mm" />
					<fo:table-column column-number="2" column-width="95mm" />
					<fo:table-body>
					<fo:table-row>
						<fo:table-cell>
							<fo:block text-align="left" font-weight="bold" font-size="10pt">
								<xsl:value-of select="attributes/attribute[@name='XURN']"/>
							</fo:block>
						</fo:table-cell>
						<fo:table-cell>
							<fo:block text-align="right" font-weight="bold" font-size="10pt">
								<xsl:value-of select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_Print_picture']"/>
								<xsl:call-template name="stripzeroes">
									<xsl:with-param name="text" select="substring(primary_key,13,16)"/>
								</xsl:call-template>
							</fo:block>
						</fo:table-cell>
					</fo:table-row>
					</fo:table-body>
				</fo:table>

				<fo:block space-before="1mm" space-after="5mm" border-after-style="solid" border-after-width="thin" />

				<xsl:choose>

					<!-- Deleted asset -->

					<xsl:when test="contains('deleted', state)">
						<fo:block text-align="center" font-weight="bold" font-size="12pt">
							<xsl:value-of select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_ASSET_DELETED']"/>
						</fo:block>
					</xsl:when>

					<!-- PICTURE asset -->

					<xsl:when test="contains('PICTURE', primary_key/@type)">

						<!-- insert asset picture -->
						<fo:block text-align="center">
							<xsl:call-template name="generateimagetag">
								<xsl:with-param name="width" select="attributes/attribute[@name='width']"/>
								<xsl:with-param name="height" select="attributes/attribute[@name='height']"/>
								<xsl:with-param name="maxwidth">175</xsl:with-param>
								<xsl:with-param name="maxheight">230</xsl:with-param>
								<xsl:with-param name="imgURL">
									<xsl:choose>
										<xsl:when test="attributes/attribute[@name='has_Production_Privilege']='true'"><xsl:value-of select="/XMLData/MISCData/attributes/attribute[@name='CONTEXT_URL']"/>/GetAsset?primaryKey=<xsl:value-of select="primary_key"/>&amp;type=o&amp;transformation=return:type=JPEG,quality=90;colourspace:rgb;</xsl:when>
										<xsl:otherwise><xsl:value-of select="/XMLData/MISCData/attributes/attribute[@name='CONTEXT_URL']"/>/GetAsset?primaryKey=<xsl:value-of select="primary_key"/>&amp;type=t</xsl:otherwise>
									</xsl:choose>
								</xsl:with-param>
								<xsl:with-param name="mm" select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_mm']"/>
							</xsl:call-template>

						</fo:block>

						<!-- insert picture properties -->
						<fo:block space-before="1mm" text-align="center" font-size="9pt" keep-with-previous="always">
							<xsl:value-of select="attributes/attribute[@name='colourspace']"/>,
							<xsl:value-of select="attributes/attribute[@name='fftype']"/>,
							<xsl:value-of select="attributes/attribute[@name='filesize']"/> <xsl:value-of select="attributes/attribute[@name='PRINT_bytes']"/>,
							<xsl:value-of select="attributes/attribute[@name='width']"/><xsl:value-of select="attributes/attribute[@name='PRINT_w']"/> x <xsl:value-of select="attributes/attribute[@name='height']"/><xsl:value-of select="attributes/attribute[@name='PRINT_h']"/>,
							<xsl:value-of select="attributes/attribute[@name='vres']"/> x <xsl:value-of select="attributes/attribute[@name='hres']"/> <xsl:value-of select="attributes/attribute[@name='PRINT_dpi']"/>
						</fo:block>

					</xsl:when>

					<!-- end of assets -->

				</xsl:choose>
			</fo:flow>
		</fo:page-sequence>
	</xsl:template>

	<!-- landscape orientation -->

	<xsl:template name="landscape">
		<fo:page-sequence master-reference="LandscapeMasterPage">
			<fo:static-content flow-name="xsl-region-after">
				<fo:block space-after="1mm" border-after-style="solid" border-after-width="thin" />
				<fo:table table-layout="fixed" font-size="9pt">
					<fo:table-column column-number="1" column-width="237mm" />
					<fo:table-column column-number="2" column-width="39mm" />
					<fo:table-body>
					<fo:table-row>
						<fo:table-cell>
							<fo:block text-align="left" font-size="9pt">
								<xsl:value-of select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_CHP_REPORT']"/>
							</fo:block>
						</fo:table-cell>
						<fo:table-cell>
							<fo:block text-align="right" font-size="9pt">
								<fo:page-number/> / <xsl:value-of select="count(/XMLData/XMLDataObjects/XMLDataObject)" />
							</fo:block>
						</fo:table-cell>
					</fo:table-row>
					</fo:table-body>
				</fo:table>
			</fo:static-content>

			<fo:flow flow-name="xsl-region-body">

				<!-- insert header -->
				<fo:table table-layout="fixed" font-size="9pt">
					<fo:table-column column-number="1" column-width="138mm" />
					<fo:table-column column-number="2" column-width="138mm" />
					<fo:table-body>
					<fo:table-row>
						<fo:table-cell>
							<fo:block text-align="left" font-weight="bold" font-size="10pt">
								<xsl:value-of select="attributes/attribute[@name='XURN']"/>
							</fo:block>
						</fo:table-cell>
						<fo:table-cell>
							<fo:block text-align="right" font-weight="bold" font-size="10pt">
								<xsl:value-of select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_Print_picture']"/>
								<xsl:call-template name="stripzeroes">
									<xsl:with-param name="text" select="substring(primary_key,13,16)"/>
								</xsl:call-template>
							</fo:block>
						</fo:table-cell>
					</fo:table-row>
					</fo:table-body>
				</fo:table>

				<fo:block space-before="1mm" space-after="5mm" border-after-style="solid" border-after-width="thin" />

				<xsl:choose>

					<!-- Deleted asset -->

					<xsl:when test="contains('deleted', state)">
						<fo:block text-align="center" font-weight="bold" font-size="12pt">
							<xsl:value-of select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_ASSET_DELETED']"/>
						</fo:block>
					</xsl:when>

					<!-- PICTURE asset -->

					<xsl:when test="contains('PICTURE', primary_key/@type)">

						<!-- insert asset picture -->
						<fo:block text-align="center">
							<xsl:call-template name="generateimagetag">
								<xsl:with-param name="width" select="attributes/attribute[@name='width']"/>
								<xsl:with-param name="height" select="attributes/attribute[@name='height']"/>
								<xsl:with-param name="maxwidth">233</xsl:with-param>
								<xsl:with-param name="maxheight">165</xsl:with-param>
								<xsl:with-param name="imgURL">
									<xsl:choose>
										<xsl:when test="attributes/attribute[@name='has_Production_Privilege']='true'"><xsl:value-of select="/XMLData/MISCData/attributes/attribute[@name='CONTEXT_URL']"/>/GetAsset?primaryKey=<xsl:value-of select="primary_key"/>&amp;type=o&amp;transformation=return:type=JPEG,quality=90;colourspace:rgb;</xsl:when>
										<xsl:otherwise><xsl:value-of select="/XMLData/MISCData/attributes/attribute[@name='CONTEXT_URL']"/>/GetAsset?primaryKey=<xsl:value-of select="primary_key"/>&amp;type=t</xsl:otherwise>
									</xsl:choose>
								</xsl:with-param>
								<xsl:with-param name="mm" select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_mm']"/>
							</xsl:call-template>

						</fo:block>

						<!-- insert picture properties -->
						<fo:block space-before="1mm" text-align="center" font-size="9pt" keep-with-previous="always">
							<xsl:value-of select="attributes/attribute[@name='colourspace']"/>,
							<xsl:value-of select="attributes/attribute[@name='fftype']"/>,
							<xsl:value-of select="attributes/attribute[@name='filesize']"/> <xsl:value-of select="attributes/attribute[@name='PRINT_bytes']"/>,
							<xsl:value-of select="attributes/attribute[@name='width']"/><xsl:value-of select="attributes/attribute[@name='PRINT_w']"/> x <xsl:value-of select="attributes/attribute[@name='height']"/><xsl:value-of select="attributes/attribute[@name='PRINT_h']"/>,
							<xsl:value-of select="attributes/attribute[@name='vres']"/> x <xsl:value-of select="attributes/attribute[@name='hres']"/> <xsl:value-of select="attributes/attribute[@name='PRINT_dpi']"/>
						</fo:block>

					</xsl:when>

					<!-- end of assets -->

				</xsl:choose>
			</fo:flow>
		</fo:page-sequence>
	</xsl:template>

	<xsl:template match="/">
		<fo:root xmlns:fo="http://www.w3.org/1999/XSL/Format" font-family="Liberation Sans">
			<!-- define page template -->
			<fo:layout-master-set>
				<fo:simple-page-master master-name="PortraitMasterPage" page-height="297mm" page-width="210mm" margin-top="1cm" margin-bottom="5mm" margin-left="1cm" margin-right="1cm">
					<fo:region-body margin-bottom="1cm"/>
					<fo:region-before />
					<fo:region-after extent="5mm" />
				</fo:simple-page-master>
				<fo:simple-page-master master-name="LandscapeMasterPage" page-height="210mm" page-width="297mm" margin-top="1cm" margin-bottom="5mm" margin-left="1cm" margin-right="1cm">
					<fo:region-body margin-bottom="1cm"/>
					<fo:region-before />
					<fo:region-after extent="5mm" />
				</fo:simple-page-master>
			</fo:layout-master-set>
			<!-- use page template -->

			<xsl:for-each select="XMLData/XMLDataObjects/XMLDataObject">

				<xsl:if test="contains('PICTURE', primary_key/@type)">
					<xsl:choose>
						<xsl:when test="not(number(attributes/attribute[@name='height'])) or not(number(attributes/attribute[@name='width']))">
							<xsl:call-template name="portrait" />
						</xsl:when>
						<xsl:when test="attributes/attribute[@name='width'] &gt; attributes/attribute[@name='height']">
							<xsl:call-template name="landscape" />
						</xsl:when>
						<xsl:otherwise>
							<xsl:call-template name="portrait" />
						</xsl:otherwise>
					</xsl:choose>
				</xsl:if>

			</xsl:for-each>
		</fo:root>
	</xsl:template>

</xsl:stylesheet>
