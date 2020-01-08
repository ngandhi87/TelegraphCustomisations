<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:svg="http://www.w3.org/2000/svg">
	<xsl:output method="xml" version="1.0" encoding="UTF-8"/>

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

	<!-- template used to truncate and display caption text -->
	<xsl:template name="displaycaptiontext">
		<xsl:param name="text"/>
		<xsl:param name="maxchar"/>
		<xsl:choose>
			<xsl:when test="string-length($text) &gt; $maxchar">
				<xsl:value-of select="concat(substring(string($text),1,$maxchar - 2),'..')"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$text" />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

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

	<xsl:template match="*">
		<fo:table table-layout="fixed" font-size="10pt" height="82mm" keep-together.within-page="always">
			<fo:table-column column-number="1" column-width="61mm"/>
			<fo:table-body>
				<xsl:choose>
					<xsl:when test="contains('deleted', state)">
						<fo:table-row height="71mm">
								<fo:table-cell display-align="center">
								<fo:block text-align="center" font-weight="bold" font-size="10pt">
									<xsl:call-template name="stripzeroes">
										<xsl:with-param name="text" select="substring(primary_key,13,16)"/>
									</xsl:call-template>
								</fo:block>
								<fo:block text-align="center" font-size="10pt">
									<xsl:value-of select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_ASSET_DELETED']"/>
								</fo:block>
							</fo:table-cell>
						</fo:table-row>
						<fo:table-row height="6mm">
								<fo:table-cell>
								<fo:block space-before="1mm" space-after="1mm" border-after-style="solid" border-after-width="thin" />

							</fo:table-cell>
						</fo:table-row>
					</xsl:when>

					<xsl:when test="contains('PICTURE', primary_key/@type)">
						<fo:table-row height="71mm">
								<fo:table-cell display-align="center">
								<!-- insert asset picture -->
								<fo:block text-align="center">
									<xsl:call-template name="generateimagetag">
										<xsl:with-param name="width" select="attributes/attribute[@name='width']"/>
										<xsl:with-param name="height" select="attributes/attribute[@name='height']"/>
										<xsl:with-param name="maxwidth">62</xsl:with-param>
										<xsl:with-param name="maxheight">68</xsl:with-param>
										<xsl:with-param name="imgURL">
											<xsl:choose>
												<xsl:when test="attributes/attribute[@name='has_Preview_Privilege']='true'"><xsl:value-of select="/XMLData/MISCData/attributes/attribute[@name='CONTEXT_URL']"/>/GetAsset?primaryKey=<xsl:value-of select="primary_key"/>&amp;type=p</xsl:when>
												<xsl:otherwise><xsl:value-of select="/XMLData/MISCData/attributes/attribute[@name='CONTEXT_URL']"/>/GetAsset?primaryKey=<xsl:value-of select="primary_key"/>&amp;type=t</xsl:otherwise>
											</xsl:choose>
										</xsl:with-param>
										<xsl:with-param name="mm" select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_mm']"/>
									</xsl:call-template>
								</fo:block>
							</fo:table-cell>
						</fo:table-row>
						<xsl:variable name="cost_indicator">
							<xsl:value-of select="specialist/XMLDataObject[@type='TMG_RIGHTS']/attributes/attribute[@name='COSTGROUPA']"/>
						</xsl:variable>
						<xsl:choose>
							<xsl:when test="$cost_indicator='No Cost'">
								<fo:table-row height="10mm">
									<fo:table-cell>
										<fo:block background-color="#008000" text-align="center" font-size="9pt">
											<xsl:call-template name="displaycaptiontext">
												<xsl:with-param name="text" select="attributes/attribute[@name='XURN']"/>
												<xsl:with-param name="maxchar">36</xsl:with-param>
											</xsl:call-template>
											<xsl:text> - </xsl:text>
											<xsl:value-of select="$cost_indicator"/>
										</fo:block>
									</fo:table-cell>
								</fo:table-row>
							</xsl:when>						
							<xsl:when test="$cost_indicator='May Incur Cost'">
								<fo:table-row height="10mm">
									<fo:table-cell>
										<fo:block background-color="#FFA500" text-align="center" font-size="9pt">
											<xsl:call-template name="displaycaptiontext">
												<xsl:with-param name="text" select="attributes/attribute[@name='XURN']"/>
												<xsl:with-param name="maxchar">36</xsl:with-param>
											</xsl:call-template>
											<xsl:text> - </xsl:text>
											<xsl:value-of select="$cost_indicator"/>
										</fo:block>
									</fo:table-cell>
								</fo:table-row>
							</xsl:when>						
							<xsl:when test="$cost_indicator='Will Incur Cost'">
								<fo:table-row height="10mm">
									<fo:table-cell>
										<fo:block background-color="#FF0000" text-align="center" font-size="9pt">
											<xsl:call-template name="displaycaptiontext">
												<xsl:with-param name="text" select="attributes/attribute[@name='XURN']"/>
												<xsl:with-param name="maxchar">36</xsl:with-param>
											</xsl:call-template>
											<xsl:text> - </xsl:text>
											<xsl:value-of select="$cost_indicator"/>
										</fo:block>
									</fo:table-cell>
								</fo:table-row>
							</xsl:when>
							<!-- Add another condition with when block here -->
							<xsl:otherwise>
								<fo:table-row height="10mm">
									<fo:table-cell>
										<fo:block background-color="#FF0000" text-align="center" font-size="9pt">
											<xsl:call-template name="displaycaptiontext">
												<xsl:with-param name="text" select="attributes/attribute[@name='XURN']"/>
												<xsl:with-param name="maxchar">36</xsl:with-param>
											</xsl:call-template>
											<xsl:text> - </xsl:text>
											<xsl:value-of select="$cost_indicator"/>
										</fo:block>
									</fo:table-cell>
								</fo:table-row>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:when>

					<xsl:when test="contains('PAGE', primary_key/@type)">
						<fo:table-row height="68mm">
								<fo:table-cell display-align="center">
								<xsl:choose>
									<xsl:when test="attributes/attribute[@name='PAGE_DISPLAY_TYPE'] = 'version'">
										<!-- insert asset picture -->
										<fo:block text-align="center" background-color="#FFE79D">
											<xsl:call-template name="generateimagetag">
												<xsl:with-param name="width" select="attributes/attribute[@name='width']"/>
												<xsl:with-param name="height" select="attributes/attribute[@name='height']"/>
												<xsl:with-param name="maxwidth">62</xsl:with-param>
												<xsl:with-param name="maxheight">65</xsl:with-param>
												<xsl:with-param name="imgURL"><xsl:value-of select="/XMLData/MISCData/attributes/attribute[@name='CONTEXT_URL']"/>/GetAsset?primaryKey=<xsl:value-of select="attributes/attribute[@name='PAGE_DISPLAY_KEY']"/>&amp;type=t</xsl:with-param>
												<xsl:with-param name="mm" select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_mm']"/>
											</xsl:call-template>
										</fo:block>
									</xsl:when>
									<xsl:otherwise>
										<fo:block text-align="center">
											<xsl:call-template name="generateimagetag">
												<xsl:with-param name="width" select="attributes/attribute[@name='width']"/>
												<xsl:with-param name="height" select="attributes/attribute[@name='height']"/>
												<xsl:with-param name="maxwidth">62</xsl:with-param>
												<xsl:with-param name="maxheight">65</xsl:with-param>
												<xsl:with-param name="imgURL"><xsl:value-of select="/XMLData/MISCData/attributes/attribute[@name='CONTEXT_URL']"/>/GetAsset?primaryKey=<xsl:value-of select="attributes/attribute[@name='PAGE_DISPLAY_KEY']"/>&amp;type=t</xsl:with-param>
												<xsl:with-param name="mm" select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_mm']"/>
											</xsl:call-template>
										</fo:block>
									</xsl:otherwise>
								</xsl:choose>
							</fo:table-cell>
						</fo:table-row>
						<fo:table-row height="10mm">
							<fo:table-cell display-align="center">
								<fo:block background-color="#909090" text-align="center" font-size="9pt">
									<xsl:value-of select="attributes/attribute[@name='__PUBLICATION_DISPLAY_TITLE']"/>,<xsl:value-of select="attributes/attribute[@name='PUBLICATION_EDITION']"/>,<xsl:value-of select="attributes/attribute[@name='PUBLICATION_DATE_STR']"/>,pg <xsl:value-of select="attributes/attribute[@name='PUBLICATION_PAGE']"/>
								</fo:block>
							</fo:table-cell>
						</fo:table-row>
					</xsl:when>

					<xsl:when test="contains('STORY', primary_key/@type)">
						<fo:table-row height="71mm">
								<fo:table-cell display-align="center">
								<fo:block font-size="10pt" font-weight="bold" space-after="2mm">
									<xsl:call-template name="displaycaptiontext">
										<xsl:with-param name="text" select="attributes/attribute[@name='HEADLINE']"/>
										<xsl:with-param name="maxchar">60</xsl:with-param>
									</xsl:call-template>
								</fo:block>
								<fo:block font-size="9pt">
									<xsl:call-template name="displaycaptiontext">
										<xsl:with-param name="text" select="attributes/attribute[@name='STORY']"/>
										<xsl:with-param name="maxchar">600</xsl:with-param>
									</xsl:call-template>
								</fo:block>
							</fo:table-cell>
						</fo:table-row>
						<fo:table-row height="10mm">
								<fo:table-cell>
								<fo:block background-color="#909090" text-align="center" font-size="9pt">
									<xsl:value-of select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_Story']"/> <xsl:call-template name="stripzeroes">
										<xsl:with-param name="text" select="substring(primary_key,13,16)"/>
									</xsl:call-template>
								</fo:block>
							</fo:table-cell>
						</fo:table-row>
					</xsl:when>

					<xsl:when test="contains('DOCUMENT', primary_key/@type)">
						<fo:table-row height="71mm">
								<fo:table-cell display-align="center">
								<fo:block font-size="10pt" font-weight="bold" space-after="2mm">
									<xsl:call-template name="displaycaptiontext">
										<xsl:with-param name="text" select="attributes/attribute[@name='TITLE']"/>
										<xsl:with-param name="maxchar">60</xsl:with-param>
									</xsl:call-template>
								</fo:block>
								<fo:block font-size="10pt">
									<xsl:call-template name="displaycaptiontext">
										<xsl:with-param name="text" select="attributes/attribute[@name='DESCRIPTION']"/>
										<xsl:with-param name="maxchar">520</xsl:with-param>
									</xsl:call-template>
								</fo:block>
							</fo:table-cell>
						</fo:table-row>
						<fo:table-row height="10mm">
							<fo:table-cell>
								<fo:block background-color="#909090" text-align="center" font-size="9pt">
									<xsl:value-of select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_Document']"/> <xsl:call-template name="stripzeroes">
										<xsl:with-param name="text" select="substring(primary_key,13,16)"/>
									</xsl:call-template>
								</fo:block>
							</fo:table-cell>
						</fo:table-row>
					</xsl:when>

					<xsl:when test="contains('MEDIA', primary_key/@type)">
						<fo:table-row height="71mm">
								<fo:table-cell display-align="center">
								<fo:block font-size="10pt" font-weight="bold" space-after="2mm">
									<xsl:call-template name="displaycaptiontext">
										<xsl:with-param name="text" select="attributes/attribute[@name='TITLE']"/>
										<xsl:with-param name="maxchar">60</xsl:with-param>
									</xsl:call-template>
								</fo:block>
								<fo:block font-size="10pt">
									<xsl:call-template name="displaycaptiontext">
										<xsl:with-param name="text" select="attributes/attribute[@name='CAPTION']"/>
										<xsl:with-param name="maxchar">520</xsl:with-param>
									</xsl:call-template>
								</fo:block>
							</fo:table-cell>
						</fo:table-row>
						<fo:table-row height="10mm">
							<fo:table-cell>
								<fo:block background-color="#909090" text-align="center" font-size="9pt">
									<xsl:value-of select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_Media']"/> <xsl:call-template name="stripzeroes">
										<xsl:with-param name="text" select="substring(primary_key,13,16)"/>
									</xsl:call-template>
								</fo:block>
							</fo:table-cell>
						</fo:table-row>
					</xsl:when>

				</xsl:choose>

			</fo:table-body>
		</fo:table>
	</xsl:template>

	<xsl:template match="/">

		<fo:root xmlns:fo="http://www.w3.org/1999/XSL/Format" font-family="Liberation Sans">
			<!-- define page template -->
			<fo:layout-master-set>
				<fo:simple-page-master master-name="PageMaster" page-height="297mm" page-width="210mm" margin-top="5mm" margin-bottom="2mm" margin-left="9mm" margin-right="9mm">
					<fo:region-body margin-bottom="3cm" margin-top="1cm"/>
					<fo:region-before extent="5mm" />
					<fo:region-after extent="5mm" />
				</fo:simple-page-master>
			</fo:layout-master-set>

			<!-- use page template -->

			<fo:page-sequence initial-page-number="1" master-reference="PageMaster">
				<fo:static-content flow-name="xsl-region-before">
					<fo:block text-align="center" font-size="9pt">
						<xsl:value-of select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_Standard_A4_contact']"/> -
						(<xsl:value-of select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_CHP_MATCHES']"/>)
					</fo:block>
				<fo:block space-after="1mm" space-before="1mm" border-after-style="solid" border-after-width="thin" />
				</fo:static-content>

				<fo:static-content flow-name="xsl-region-after">

					<fo:block space-after="1mm" border-after-style="solid" border-after-width="thin" />
					<fo:table table-layout="fixed" font-size="9pt">
						<fo:table-column column-number="1" column-width="153mm" />
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
									<fo:page-number/> / <fo:page-number-citation ref-id="endofdoc"/>
								</fo:block>
							</fo:table-cell>
						</fo:table-row>
						</fo:table-body>
					</fo:table>

				</fo:static-content>

				<fo:flow flow-name="xsl-region-body">
					<fo:table table-layout="fixed" font-size="10pt">
						<fo:table-column column-number="1" column-width="65mm" />
						<fo:table-column column-number="2" column-width="65mm" />
						<fo:table-column column-number="3" column-width="62mm" />

						<fo:table-body>
							<!--
								fop 0.20.5 doest support 'ends-row' therefore using a work around here
								until column-grouping is fully supported
							-->
							<fo:table-row>
								<fo:table-cell>
									<fo:block>
										<xsl:apply-templates select="XMLData/XMLDataObjects/XMLDataObject[position() mod 3 = 1]"/>
									</fo:block>
								</fo:table-cell>

								<fo:table-cell>
									<fo:block>
										<xsl:apply-templates select="XMLData/XMLDataObjects/XMLDataObject[position() mod 3 = 2]"/>
									</fo:block>
								</fo:table-cell>

								<fo:table-cell>
									<fo:block>
										<xsl:apply-templates select="XMLData/XMLDataObjects/XMLDataObject[position() mod 3 = 0]"/>
									</fo:block>
								</fo:table-cell>
						</fo:table-row>
						</fo:table-body>
					</fo:table>
					<fo:block id="endofdoc"></fo:block>
				</fo:flow>
			</fo:page-sequence>
		</fo:root>
	</xsl:template>
</xsl:stylesheet>
