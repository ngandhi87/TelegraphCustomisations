<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:svg="http://www.w3.org/2000/svg">
	<xsl:output method="xml" version="1.0" encoding="UTF-8"/>

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

	<!-- template used to generate external image tag also resize -->
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

	<!-- change case-->
	<xsl:variable name="lcletters" select="'abcdefghijklmnopqrstuvwxyz'"/>
	<xsl:variable name="ucletters" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'"/>

	<xsl:template name="str-initialupper">
		<xsl:param name="str"/>
		<xsl:choose>
			<xsl:when test="string-length($str) > 1">
				<xsl:value-of select="concat(translate(substring($str,1,1), $lcletters, $ucletters),translate(substring($str, 2,string-length($str)), $ucletters, $lcletters))" />
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$str" />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="/">
		<fo:root xmlns:fo="http://www.w3.org/1999/XSL/Format" font-family="Liberation Sans">
			<!-- define page template -->
			<fo:layout-master-set>
				<fo:simple-page-master master-name="PageMaster" page-height="11.69in" page-width="8.26in" margin-top="5mm" margin-bottom="5mm" margin-left="1cm" margin-right="1cm">
					<fo:region-body margin-bottom="1cm" margin-top="1cm"/>
					<fo:region-before extent="5mm" />
					<fo:region-after extent="5mm" />
				</fo:simple-page-master>
			</fo:layout-master-set>
			<!-- use page template -->

			<fo:page-sequence initial-page-number="1" master-reference="PageMaster">

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
										<fo:page-number/> / <fo:page-number-citation ref-id="endofdoc"/>
									</fo:block>
								</fo:table-cell>
							</fo:table-row>
						</fo:table-body>
					</fo:table>
				</fo:static-content>

				<fo:flow flow-name="xsl-region-body">
					<xsl:for-each select="XMLData/XMLDataObjects/XMLDataObject">
						<!-- insert page break if current page is not first page -->
						<xsl:if test="position() &gt; 1">
							<fo:block text-align="center" break-after="page" />
						</xsl:if>

						<!-- insert primary key -->
						<fo:block text-align="center" font-weight="bold" font-size="12pt">
							<xsl:value-of select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_Row_print_of']"/>
							<xsl:if test="attributes/attribute[@name='SUB_TYPE'] = 'picturegallery'"><xsl:value-of select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_Gallery']"/> </xsl:if>
							<xsl:if test="attributes/attribute[@name='SUB_TYPE'] = 'picturecomposite'"><xsl:value-of select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_Composite']"/> </xsl:if>
							<xsl:if test="attributes/attribute[@name='SUB_TYPE'] = 'graphic'"><xsl:value-of select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_Graphic']"/> </xsl:if>
							<xsl:if test="attributes/attribute[@name='SUB_TYPE'] = 'collection'"><xsl:value-of select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_Collection']"/> </xsl:if>
							<xsl:call-template name="stripzeroes">
								<xsl:with-param name="text" select="substring(primary_key,13,16)"/>
							</xsl:call-template>
						</fo:block>

						<fo:block space-before="4mm" space-after="5mm" border-after-style="solid" border-after-width="thin" />

						<xsl:choose>

							<!-- Deleted asset -->

							<xsl:when test="contains('deleted', state) &gt; 0">
								<fo:block text-align="center" font-weight="bold" font-size="12pt">
									<xsl:value-of select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_ASSET_DELETED']"/>
								</fo:block>
							</xsl:when>

							<!-- COMPOSITE asset -->

							<xsl:when test="contains('COMPOSITE', primary_key/@type)">

								<fo:block keep-with-next.within-page="always">
									<fo:table table-layout="fixed" font-size="10pt">
										<fo:table-column column-number="1" column-width="90mm" />
										<fo:table-column column-number="2" column-width="8mm" />
										<fo:table-column column-number="3" column-width="90mm" />
										<fo:table-body>
											<!-- insert asset picture -->
											<fo:table-row>
												<fo:table-cell>
													<!-- insert picture / poster -->
													<fo:block text-align="center">
														<xsl:choose>
															<xsl:when test="attributes/attribute[@name='SUB_TYPE'] = 'picturegallery' or attributes/attribute[@name='SUB_TYPE'] = 'collection'">
																<xsl:choose>
																	<xsl:when test="attributes/attribute[@name='__poster_links']/XMLDataObjects/XMLDataObject">
																		<xsl:for-each select="attributes/attribute[@name='__poster_links']/XMLDataObjects/XMLDataObject">
																			<fo:block>
																				<xsl:call-template name="generateimagetag">
																					<xsl:with-param name="width" select="attributes/attribute[@name='width']"/>
																					<xsl:with-param name="height" select="attributes/attribute[@name='height']"/>
																					<xsl:with-param name="maxwidth">55</xsl:with-param>
																					<xsl:with-param name="maxheight">60</xsl:with-param>
																					<xsl:with-param name="imgURL">
																						<xsl:choose>
																							<xsl:when test="attributes/attribute[@name='has_Preview_Privilege']='true'"><xsl:value-of select="/XMLData/MISCData/attributes/attribute[@name='CONTEXT_URL']"/>/GetAsset?primaryKey=<xsl:value-of select="primary_key"/>&amp;type=p&amp;streamAsset=false</xsl:when>
																							<xsl:otherwise><xsl:value-of select="/XMLData/MISCData/attributes/attribute[@name='CONTEXT_URL']"/>/GetAsset?primaryKey=<xsl:value-of select="primary_key"/>&amp;type=t&amp;internal=true&amp;streamAsset=false</xsl:otherwise>
																						</xsl:choose>
																					</xsl:with-param>
																					<xsl:with-param name="mm" select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_mm']"/>
																				</xsl:call-template>
																			</fo:block>
																		</xsl:for-each>
																	</xsl:when>
																	<xsl:otherwise>
																		<xsl:if test="attributes/attribute[@name='__member_links']/XMLDataObjects/XMLDataObject">
																			<fo:block>
																				<xsl:call-template name="generateimagetag">
																					<xsl:with-param name="width" select="attributes/attribute[@name='__member_links']/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='width']"/>
																					<xsl:with-param name="height" select="attributes/attribute[@name='__member_links']/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='height']"/>
																					<xsl:with-param name="maxwidth">55</xsl:with-param>
																					<xsl:with-param name="maxheight">60</xsl:with-param>
																					<xsl:with-param name="imgURL">
																						<xsl:choose>
																							<xsl:when test="attributes/attribute[@name='__member_links']/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='has_Preview_Privilege']='true'"><xsl:value-of select="/XMLData/MISCData/attributes/attribute[@name='CONTEXT_URL']"/>/GetAsset?primaryKey=<xsl:value-of select="attributes/attribute[@name='__member_links']/XMLDataObjects/XMLDataObject[1]/primary_key"/>&amp;type=p&amp;streamAsset=false</xsl:when>
																							<xsl:otherwise><xsl:value-of select="/XMLData/MISCData/attributes/attribute[@name='CONTEXT_URL']"/>/GetAsset?primaryKey=<xsl:value-of select="attributes/attribute[@name='__member_links']/XMLDataObjects/XMLDataObject[1]/primary_key"/>&amp;type=t&amp;internal=true&amp;streamAsset=false</xsl:otherwise>
																						</xsl:choose>
																					</xsl:with-param>
																					<xsl:with-param name="mm" select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_mm']"/>
																				</xsl:call-template>
																			</fo:block>
																		</xsl:if>
																	</xsl:otherwise>
																</xsl:choose>
															</xsl:when>
															<xsl:otherwise>
																<fo:block>
																	<xsl:call-template name="generateimagetag">
																		<xsl:with-param name="width" select="attributes/attribute[@name='width']"/>
																		<xsl:with-param name="height" select="attributes/attribute[@name='height']"/>
																		<xsl:with-param name="maxwidth">55</xsl:with-param>
																		<xsl:with-param name="maxheight">60</xsl:with-param>
																		<xsl:with-param name="imgURL">
																			<xsl:choose>
																				<xsl:when test="attributes/attribute[@name='has_Preview_Privilege']='true'"><xsl:value-of select="/XMLData/MISCData/attributes/attribute[@name='CONTEXT_URL']"/>/GetAsset?primaryKey=<xsl:value-of select="primary_key"/>&amp;type=p&amp;transformation=iccprofile:mode=stdonly&amp;streamAsset=false</xsl:when>
																				<xsl:otherwise><xsl:value-of select="/XMLData/MISCData/attributes/attribute[@name='CONTEXT_URL']"/>/GetAsset?primaryKey=<xsl:value-of select="primary_key"/>&amp;type=t&amp;transformation=iccprofile:mode=stdonly&amp;internal=true&amp;streamAsset=false</xsl:otherwise>
																			</xsl:choose>
																		</xsl:with-param>
																		<xsl:with-param name="mm" select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_mm']"/>
																	</xsl:call-template>
																</fo:block>
															</xsl:otherwise>
														</xsl:choose>
													</fo:block>
												</fo:table-cell>
												<fo:table-cell>
													<fo:block />
												</fo:table-cell>
												<fo:table-cell>
													<fo:table table-layout="fixed" font-size="9pt">
														<fo:table-column column-number="1" column-width="24mm" />
														<fo:table-column column-number="2" column-width="2mm" />
														<fo:table-column column-number="3" column-width="64mm" />

														<fo:table-body>
															<fo:table-row>
																<fo:table-cell number-columns-spanned="3">
																	<fo:block>
																		<xsl:call-template name="displaycaptiontext">
																			<xsl:with-param name="text" select="attributes/attribute[@name='CAPTION']"/>
																			<xsl:with-param name="maxchar">500</xsl:with-param>
																		</xsl:call-template>
																	</fo:block>
																</fo:table-cell>
															</fo:table-row>

															<xsl:if test="attributes/attribute[@name='CAPTION'] != ''">
																<fo:table-row>
																	<fo:table-cell number-columns-spanned="3" padding-top="2mm" padding-bottom="2mm" >
																		<fo:block border-after-style="dotted" border-after-width="thin" />
																	</fo:table-cell>
																</fo:table-row>
															</xsl:if>

															<xsl:if test="attributes/attribute[@name='INTERNAL_NAME'] != ''">
																<fo:table-row>
																	<fo:table-cell padding-left=".5mm" padding-right=".5mm">
																		<fo:block font-weight="bold" text-align="right"><xsl:value-of select="attributes/attribute[@name='PRINT_Name']"/></fo:block>
																	</fo:table-cell>
																	<fo:table-cell>
																		<fo:block />
																	</fo:table-cell>
																	<fo:table-cell>
																		<fo:block>
																			<xsl:call-template name="displaycaptiontext">
																				<xsl:with-param name="text" select="attributes/attribute[@name='INTERNAL_NAME']"/>
																				<xsl:with-param name="maxchar">80</xsl:with-param>
																			</xsl:call-template>
																		</fo:block>
																	</fo:table-cell>
																</fo:table-row>
															</xsl:if>

															<xsl:if test="attributes/attribute[@name='DISPLAY_OWNER_ID'] != ''">
																<fo:table-row>
																	<fo:table-cell padding-left=".5mm" padding-right=".5mm">
																		<fo:block font-weight="bold" text-align="right"><xsl:value-of select="attributes/attribute[@name='PRINT_Owner']"/></fo:block>
																	</fo:table-cell>
																	<fo:table-cell>
																		<fo:block />
																	</fo:table-cell>
																	<fo:table-cell>
																		<fo:block>
																			<xsl:call-template name="displaycaptiontext">
																				<xsl:with-param name="text" select="attributes/attribute[@name='DISPLAY_OWNER_ID']"/>
																				<xsl:with-param name="maxchar">80</xsl:with-param>
																			</xsl:call-template>
																		</fo:block>
																	</fo:table-cell>
																</fo:table-row>
															</xsl:if>

															<xsl:if test="attributes/attribute[@name='HEADLINE'] != ''">
																<fo:table-row>
																	<fo:table-cell padding-left=".5mm" padding-right=".5mm">
																		<fo:block font-weight="bold" text-align="right"><xsl:value-of select="attributes/attribute[@name='PRINT_Headline']"/></fo:block>
																	</fo:table-cell>
																	<fo:table-cell>
																		<fo:block />
																	</fo:table-cell>
																	<fo:table-cell>
																		<fo:block>
																			<xsl:call-template name="displaycaptiontext">
																				<xsl:with-param name="text" select="attributes/attribute[@name='HEADLINE']"/>
																				<xsl:with-param name="maxchar">80</xsl:with-param>
																			</xsl:call-template>
																		</fo:block>
																	</fo:table-cell>
																</fo:table-row>
															</xsl:if>

															<xsl:if test="attributes/attribute[@name='BYLINE'] != ''">
																<fo:table-row>
																	<fo:table-cell padding-left=".5mm" padding-right=".5mm">
																		<fo:block font-weight="bold" text-align="right"><xsl:value-of select="attributes/attribute[@name='PRINT_Author']"/></fo:block>
																	</fo:table-cell>
																	<fo:table-cell>
																		<fo:block />
																	</fo:table-cell>
																	<fo:table-cell>
																		<fo:block>
																			<xsl:call-template name="displaycaptiontext">
																				<xsl:with-param name="text" select="attributes/attribute[@name='BYLINE']"/>
																				<xsl:with-param name="maxchar">80</xsl:with-param>
																			</xsl:call-template>
																		</fo:block>
																	</fo:table-cell>
																</fo:table-row>
															</xsl:if>

															<xsl:if test="attributes/attribute[@name='SUBHEADING'] != ''">
																<fo:table-row>
																	<fo:table-cell padding-left=".5mm" padding-right=".5mm">
																		<fo:block font-weight="bold" text-align="right"><xsl:value-of select="attributes/attribute[@name='PRINT_Standfirst']"/></fo:block>
																	</fo:table-cell>
																	<fo:table-cell>
																		<fo:block />
																	</fo:table-cell>
																	<fo:table-cell>
																		<fo:block>
																			<xsl:call-template name="displaycaptiontext">
																				<xsl:with-param name="text" select="attributes/attribute[@name='SUBHEADING']"/>
																				<xsl:with-param name="maxchar">80</xsl:with-param>
																			</xsl:call-template>
																		</fo:block>
																	</fo:table-cell>
																</fo:table-row>
															</xsl:if>

															<xsl:if test="attributes/attribute[@name='CONTRIBUTOR_SUPPLIER_DISPLAY'] != ''">
																<fo:table-row>
																	<fo:table-cell padding-left=".5mm" padding-right=".5mm">
																		<fo:block font-weight="bold" text-align="right"><xsl:value-of select="attributes/attribute[@name='PRINT_Contributor']"/></fo:block>
																	</fo:table-cell>
																	<fo:table-cell>
																		<fo:block />
																	</fo:table-cell>
																	<fo:table-cell>
																		<fo:block>
																			<xsl:value-of select="attributes/attribute[@name='CONTRIBUTOR_SUPPLIER_DISPLAY']"/>
																		</fo:block>
																	</fo:table-cell>
																</fo:table-row>
															</xsl:if>

															<xsl:if test="attributes/attribute[@name='CONTRIBUTOR_ROYALTY_DISPLAY'] != ''">
																<fo:table-row>
																	<fo:table-cell padding-left=".5mm" padding-right=".5mm">
																		<fo:block font-weight="bold" text-align="right"><xsl:value-of select="attributes/attribute[@name='PRINT_Rights_contract']"/></fo:block>
																	</fo:table-cell>
																	<fo:table-cell>
																		<fo:block />
																	</fo:table-cell>
																	<fo:table-cell>
																		<fo:block>
																			<xsl:value-of select="attributes/attribute[@name='CONTRIBUTOR_ROYALTY_DISPLAY']"/>
																		</fo:block>
																	</fo:table-cell>
																</fo:table-row>
															</xsl:if>

															<xsl:if test="attributes/attribute[@name='CREATION_STAMP'] != ''">
																<fo:table-row>
																	<fo:table-cell padding-left=".5mm" padding-right=".5mm">
																		<fo:block font-weight="bold" text-align="right"><xsl:value-of select="attributes/attribute[@name='PRINT_Date_loaded']"/></fo:block>
																	</fo:table-cell>
																	<fo:table-cell>
																		<fo:block />
																	</fo:table-cell>
																	<fo:table-cell>
																		<fo:block>
																			<xsl:value-of select="attributes/attribute[@name='CREATION_STAMP_STR']"/>
																		</fo:block>
																	</fo:table-cell>
																</fo:table-row>
															</xsl:if>

														</fo:table-body>
													</fo:table>
												</fo:table-cell>
											</fo:table-row>
										</fo:table-body>
									</fo:table>
								</fo:block>

								<fo:block space-before="4mm" space-after="4mm" border-after-style="solid" border-after-width="thin" />

								<!-- insert members -->

								<xsl:if test="attributes/attribute[@name='__member_links']/XMLDataObjects/XMLDataObject">
								<fo:block>
									<fo:table table-layout="fixed" font-size="10pt">
										<fo:table-column column-number="1" column-width="90mm" />
										<fo:table-column column-number="2" column-width="8mm" />
										<fo:table-column column-number="3" column-width="90mm" />
										<fo:table-body>
											<xsl:for-each select="attributes/attribute[@name='__member_links']/XMLDataObjects/XMLDataObject">
												<xsl:variable name="memberType">
													<xsl:call-template name="str-initialupper">
														<xsl:with-param name="str" select="primary_key/@type"/>
													</xsl:call-template>
												</xsl:variable>
												<xsl:choose>
													<!-- Story member -->
													<!-- First row: Headline and id -->
													<!-- Second row: Body -->
													<xsl:when test="$memberType='Story'">
														<fo:table-row>
															<fo:table-cell>
																<fo:block>
																	<fo:table table-layout="fixed" font-size="9pt">
																		<fo:table-column column-number="1" column-width="18mm" />
																		<fo:table-column column-number="2" column-width="2mm" />
																		<fo:table-column column-number="3" column-width="70mm" />
																		<fo:table-body>
																			<fo:table-row>
																				<fo:table-cell>
																					<fo:block font-weight="bold"><xsl:value-of select="attributes/attribute[@name='PRINT_Headline']"/></fo:block>
																				</fo:table-cell>
																				<fo:table-cell>
																					<fo:block />
																				</fo:table-cell>
																				<fo:table-cell>
																					<fo:block>
																						<xsl:call-template name="displaycaptiontext">
																							<xsl:with-param name="text" select="attributes/attribute[@name='HEADLINE']"/>
																							<xsl:with-param name="maxchar">50</xsl:with-param>
																						</xsl:call-template>
																					</fo:block>
																				</fo:table-cell>
																			</fo:table-row>
																		</fo:table-body>
																	</fo:table>
																</fo:block>
															</fo:table-cell>
															<fo:table-cell>
																<fo:block />
															</fo:table-cell>
															<fo:table-cell>
																<fo:block>
																	<fo:table table-layout="fixed" font-size="9pt">
																		<fo:table-column column-number="1" column-width="18mm" />
																		<fo:table-column column-number="2" column-width="2mm" />
																		<fo:table-column column-number="3" column-width="70mm" />
																		<fo:table-body>
																			<fo:table-row>
																				<fo:table-cell>
																					<fo:block font-weight="bold" text-align="right">
																						<xsl:value-of select="$memberType" />
																					</fo:block>
																				</fo:table-cell>
																				<fo:table-cell>
																					<fo:block />
																				</fo:table-cell>
																				<fo:table-cell>
																					<fo:block>
																						<xsl:call-template name="stripzeroes">
																							<xsl:with-param name="text" select="substring(primary_key,13,16)"/>
																						</xsl:call-template>
																					</fo:block>
																				</fo:table-cell>
																			</fo:table-row>
																		</fo:table-body>
																	</fo:table>
																</fo:block>
															</fo:table-cell>
														</fo:table-row>
														<fo:table-row>
															<fo:table-cell number-columns-spanned="3">
																<fo:block>
																	<xsl:call-template name="displaycaptiontext">
																		<xsl:with-param name="text" select="attributes/attribute[@name='STORY']"/>
																		<xsl:with-param name="maxchar">400</xsl:with-param>
																	</xsl:call-template>
																</fo:block>
															</fo:table-cell>
														</fo:table-row>
														<fo:table-row>
															<fo:table-cell number-columns-spanned="3" padding-top="2mm" padding-bottom="2mm" >
																<fo:block border-after-style="solid" border-after-width="thin" />
															</fo:table-cell>
														</fo:table-row>
													</xsl:when>
													<!-- Document member -->
													<!-- First row: Title and id -->
													<!-- Second row: Description -->
													<xsl:when test="$memberType='Document'">
														<fo:table-row>
															<fo:table-cell>
																<fo:block>
																	<fo:table table-layout="fixed" font-size="9pt">
																		<fo:table-column column-number="1" column-width="18mm" />
																		<fo:table-column column-number="2" column-width="2mm" />
																		<fo:table-column column-number="3" column-width="70mm" />
																		<fo:table-body>
																			<fo:table-row>
																				<fo:table-cell>
																					<fo:block font-weight="bold"><xsl:value-of select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_Title']"/></fo:block>
																				</fo:table-cell>
																				<fo:table-cell>
																					<fo:block />
																				</fo:table-cell>
																				<fo:table-cell>
																					<fo:block>
																						<xsl:call-template name="displaycaptiontext">
																							<xsl:with-param name="text" select="attributes/attribute[@name='TITLE']"/>
																							<xsl:with-param name="maxchar">50</xsl:with-param>
																						</xsl:call-template>
																					</fo:block>
																				</fo:table-cell>
																			</fo:table-row>
																		</fo:table-body>
																	</fo:table>
																</fo:block>
															</fo:table-cell>
															<fo:table-cell>
																<fo:block />
															</fo:table-cell>
															<fo:table-cell>
																<fo:block>
																	<fo:table table-layout="fixed" font-size="9pt">
																		<fo:table-column column-number="1" column-width="18mm" />
																		<fo:table-column column-number="2" column-width="2mm" />
																		<fo:table-column column-number="3" column-width="70mm" />
																		<fo:table-body>
																			<fo:table-row>
																				<fo:table-cell>
																					<fo:block font-weight="bold" text-align="right">
																						<xsl:value-of select="$memberType" />
																					</fo:block>
																				</fo:table-cell>
																				<fo:table-cell>
																					<fo:block />
																				</fo:table-cell>
																				<fo:table-cell>
																					<fo:block>
																						<xsl:call-template name="stripzeroes">
																							<xsl:with-param name="text" select="substring(primary_key,13,16)"/>
																						</xsl:call-template>
																					</fo:block>
																				</fo:table-cell>
																			</fo:table-row>
																		</fo:table-body>
																	</fo:table>
																</fo:block>
															</fo:table-cell>
														</fo:table-row>
														<fo:table-row>
															<fo:table-cell number-columns-spanned="3">
																<fo:block>
																	<xsl:call-template name="displaycaptiontext">
																		<xsl:with-param name="text" select="attributes/attribute[@name='DESCRIPTION']"/>
																		<xsl:with-param name="maxchar">400</xsl:with-param>
																	</xsl:call-template>
																</fo:block>
															</fo:table-cell>
														</fo:table-row>
														<fo:table-row>
															<fo:table-cell number-columns-spanned="3" padding-top="2mm" padding-bottom="2mm" >
																<fo:block border-after-style="solid" border-after-width="thin" />
															</fo:table-cell>
														</fo:table-row>
													</xsl:when>
													<!-- Media member -->
													<xsl:when test="$memberType='Media'">
														<fo:table-row>
															<fo:table-cell text-align="center">
																<fo:block>
																	<xsl:call-template name="generateimagetag">
																		<xsl:with-param name="width" select="attributes/attribute[@name='width']"/>
																		<xsl:with-param name="height" select="attributes/attribute[@name='height']"/>
																		<xsl:with-param name="maxwidth">55</xsl:with-param>
																		<xsl:with-param name="maxheight">60</xsl:with-param>
																		<xsl:with-param name="imgURL"><xsl:value-of select="/XMLData/MISCData/attributes/attribute[@name='CONTEXT_URL']"/>/GetAsset?primaryKey=<xsl:value-of select="primary_key"/>&amp;type=t&amp;internal=true&amp;streamAsset=false</xsl:with-param>
																		<xsl:with-param name="mm" select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_mm']"/>
																	</xsl:call-template>
																</fo:block>
															</fo:table-cell>
															<fo:table-cell>
																<fo:block />
															</fo:table-cell>
															<fo:table-cell>
																<fo:block>
																	<fo:table table-layout="fixed" font-size="9pt">
																		<fo:table-column column-number="1" column-width="18mm" />
																		<fo:table-column column-number="2" column-width="2mm" />
																		<fo:table-column column-number="3" column-width="70mm" />

																		<fo:table-body>
																			<fo:table-row>
																				<fo:table-cell number-columns-spanned="3" padding-left=".5mm" padding-right=".5mm">
																					<fo:block>
																						<xsl:call-template name="displaycaptiontext">
																							<xsl:with-param name="text" select="attributes/attribute[@name='CAPTION']"/>
																							<xsl:with-param name="maxchar">500</xsl:with-param>
																						</xsl:call-template>
																					</fo:block>
																				</fo:table-cell>
																			</fo:table-row>

																			<xsl:if test="attributes/attribute[@name='CAPTION'] != ''">
																				<fo:table-row>
																					<fo:table-cell number-columns-spanned="3" padding-top="2mm" padding-bottom="2mm" >
																						<fo:block border-after-style="dotted" border-after-width="thin" />
																					</fo:table-cell>
																				</fo:table-row>
																			</xsl:if>

																			<fo:table-row>
																				<fo:table-cell padding-left=".5mm" padding-right=".5mm">
																					<fo:block font-weight="bold" text-align="right">
																						<xsl:value-of select="$memberType" />
																					</fo:block>
																				</fo:table-cell>
																				<fo:table-cell>
																					<fo:block />
																				</fo:table-cell>
																				<fo:table-cell >
																					<fo:block>
																						<xsl:call-template name="stripzeroes">
																							<xsl:with-param name="text" select="substring(primary_key,13,16)"/>
																						</xsl:call-template>
																					</fo:block>
																				</fo:table-cell>
																			</fo:table-row>

																			<xsl:if test="attributes/attribute[@name='TITLE'] != ''">
																				<fo:table-row>
																					<fo:table-cell padding-left=".5mm" padding-right=".5mm" >
																						<fo:block font-weight="bold" text-align="right"><xsl:value-of select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_Title']"/></fo:block>
																					</fo:table-cell>
																					<fo:table-cell>
																						<fo:block />
																					</fo:table-cell>
																					<fo:table-cell>
																						<fo:block>
																							<xsl:call-template name="displaycaptiontext">
																								<xsl:with-param name="text" select="attributes/attribute[@name='TITLE']"/>
																								<xsl:with-param name="maxchar">80</xsl:with-param>
																							</xsl:call-template>
																						</fo:block>
																					</fo:table-cell>
																				</fo:table-row>
																			</xsl:if>

																			<xsl:if test="attributes/attribute[@name='COPYRIGHT'] != ''">
																				<fo:table-row>
																					<fo:table-cell padding-left=".5mm" padding-right=".5mm" >
																						<fo:block font-weight="bold" text-align="right"><xsl:value-of select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_Copyright']"/></fo:block>
																					</fo:table-cell>
																					<fo:table-cell>
																						<fo:block />
																					</fo:table-cell>
																					<fo:table-cell>
																						<fo:block>
																							<xsl:call-template name="displaycaptiontext">
																								<xsl:with-param name="text" select="attributes/attribute[@name='COPYRIGHT']"/>
																								<xsl:with-param name="maxchar">80</xsl:with-param>
																							</xsl:call-template>
																						</fo:block>
																					</fo:table-cell>
																				</fo:table-row>
																			</xsl:if>
																		</fo:table-body>
																	</fo:table>
																</fo:block>
															</fo:table-cell>
														</fo:table-row>
														<fo:table-row>
															<fo:table-cell number-columns-spanned="3" padding-top="2mm" padding-bottom="2mm" >
																<fo:block border-after-style="solid" border-after-width="thin" />
															</fo:table-cell>
														</fo:table-row>
													</xsl:when>
													<!-- Picture member -->
													<xsl:otherwise>
														<fo:table-row>
															<fo:table-cell text-align="center">
																<fo:block>
																	<xsl:call-template name="generateimagetag">
																		<xsl:with-param name="width" select="attributes/attribute[@name='width']"/>
																		<xsl:with-param name="height" select="attributes/attribute[@name='height']"/>
																		<xsl:with-param name="maxwidth">55</xsl:with-param>
																		<xsl:with-param name="maxheight">60</xsl:with-param>
																		<xsl:with-param name="imgURL">
																			<xsl:choose>
																				<xsl:when test="attributes/attribute[@name='has_Preview_Privilege']='true'"><xsl:value-of select="/XMLData/MISCData/attributes/attribute[@name='CONTEXT_URL']"/>/GetAsset?primaryKey=<xsl:value-of select="primary_key"/>&amp;type=p&amp;streamAsset=false</xsl:when>
																				<xsl:otherwise><xsl:value-of select="/XMLData/MISCData/attributes/attribute[@name='CONTEXT_URL']"/>/GetAsset?primaryKey=<xsl:value-of select="primary_key"/>&amp;type=t&amp;internal=true&amp;streamAsset=false</xsl:otherwise>
																			</xsl:choose>
																		</xsl:with-param>
																		<xsl:with-param name="mm" select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_mm']"/>
																	</xsl:call-template>
																</fo:block>
															</fo:table-cell>
															<fo:table-cell>
																<fo:block />
															</fo:table-cell>
															<fo:table-cell>
																<fo:block>
																	<fo:table table-layout="fixed" font-size="9pt">
																		<fo:table-column column-number="1" column-width="18mm" />
																		<fo:table-column column-number="2" column-width="2mm" />
																		<fo:table-column column-number="3" column-width="70mm" />

																		<fo:table-body>
																			<fo:table-row>
																				<fo:table-cell number-columns-spanned="3" padding-left=".5mm" padding-right=".5mm">
																					<fo:block>
																						<xsl:call-template name="displaycaptiontext">
																							<xsl:with-param name="text" select="attributes/attribute[@name='CAPTION']"/>
																							<xsl:with-param name="maxchar">500</xsl:with-param>
																						</xsl:call-template>
																					</fo:block>
																				</fo:table-cell>
																			</fo:table-row>

																			<xsl:if test="attributes/attribute[@name='CAPTION'] != ''">
																				<fo:table-row>
																					<fo:table-cell number-columns-spanned="3" padding-top="2mm" padding-bottom="2mm" >
																						<fo:block border-after-style="dotted" border-after-width="thin" />
																					</fo:table-cell>
																				</fo:table-row>
																			</xsl:if>

																			<fo:table-row>
																				<fo:table-cell padding-left=".5mm" padding-right=".5mm">
																					<fo:block font-weight="bold" text-align="right">
																						<xsl:value-of select="$memberType" />
																					</fo:block>
																				</fo:table-cell>
																				<fo:table-cell>
																					<fo:block />
																				</fo:table-cell>
																				<fo:table-cell >
																					<fo:block>
																						<xsl:call-template name="stripzeroes">
																							<xsl:with-param name="text" select="substring(primary_key,13,16)"/>
																						</xsl:call-template>
																					</fo:block>
																				</fo:table-cell>
																			</fo:table-row>

																			<xsl:if test="attributes/attribute[@name='HEADLINE'] != ''">
																				<fo:table-row>
																					<fo:table-cell padding-left=".5mm" padding-right=".5mm" >
																						<fo:block font-weight="bold" text-align="right"><xsl:value-of select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_Headline']"/></fo:block>
																					</fo:table-cell>
																					<fo:table-cell>
																						<fo:block />
																					</fo:table-cell>
																					<fo:table-cell>
																						<fo:block>
																							<xsl:call-template name="displaycaptiontext">
																								<xsl:with-param name="text" select="attributes/attribute[@name='HEADLINE']"/>
																								<xsl:with-param name="maxchar">80</xsl:with-param>
																							</xsl:call-template>
																						</fo:block>
																					</fo:table-cell>
																				</fo:table-row>
																			</xsl:if>

																			<xsl:if test="attributes/attribute[@name='COPYRIGHT'] != ''">
																				<fo:table-row>
																					<fo:table-cell padding-left=".5mm" padding-right=".5mm" >
																						<fo:block font-weight="bold" text-align="right"><xsl:value-of select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_Copyright']"/></fo:block>
																					</fo:table-cell>
																					<fo:table-cell>
																						<fo:block />
																					</fo:table-cell>
																					<fo:table-cell>
																						<fo:block>
																							<xsl:call-template name="displaycaptiontext">
																								<xsl:with-param name="text" select="attributes/attribute[@name='COPYRIGHT']"/>
																								<xsl:with-param name="maxchar">80</xsl:with-param>
																							</xsl:call-template>
																						</fo:block>
																					</fo:table-cell>
																				</fo:table-row>
																			</xsl:if>
																		</fo:table-body>
																	</fo:table>
																</fo:block>
															</fo:table-cell>
														</fo:table-row>
														<fo:table-row>
															<fo:table-cell number-columns-spanned="3" padding-top="2mm" padding-bottom="2mm" >
																<fo:block border-after-style="solid" border-after-width="thin" />
															</fo:table-cell>
														</fo:table-row>
													</xsl:otherwise>
												</xsl:choose>
											</xsl:for-each>
										</fo:table-body>
									</fo:table>
								</fo:block>
								</xsl:if>

							</xsl:when>

						</xsl:choose>

					</xsl:for-each>
					<fo:block id="endofdoc"></fo:block>
				</fo:flow>

			</fo:page-sequence>

		</fo:root>
	</xsl:template>

</xsl:stylesheet>
