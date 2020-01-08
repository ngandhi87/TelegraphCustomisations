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

	<!-- template used to display edition date or issue + year -->
	<xsl:template name="geteditiondateorissue">
		<xsl:param name="pubDate"/>
		<xsl:param name="pubIssue"/>
		<xsl:param name="pubYear"/>
		<xsl:choose>
			<xsl:when test="string-length($pubIssue) > 0">
				<xsl:value-of select="$pubIssue" />
				<xsl:text> </xsl:text>
				<xsl:value-of select="$pubYear" />
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$pubDate" />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!-- template used to display edition date or issue label -->
	<xsl:template name="geteditiondateorissuelabel">
		<xsl:param name="pubDate"/>
		<xsl:param name="pubIssue"/>
		<xsl:choose>
			<xsl:when test="string-length($pubIssue) > 0">
				<xsl:value-of select="attributes/attribute[@name='PRINT_Issue']"/><xsl:text></xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="attributes/attribute[@name='PRINT_Date']"/><xsl:text></xsl:text>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!-- template used to display page data-->
	<xsl:template name="displaypage">
		<xsl:param name="color"/>
		<fo:block background-color="$color" >
			<fo:table table-layout="fixed" font-size="10pt">
				<fo:table-column column-number="1" column-width="10mm" />
				<fo:table-column column-number="2" column-width="55mm" />
				<fo:table-column column-number="3" column-width="5mm"  />
				<fo:table-column column-number="4" column-width="115mm" />
				<fo:table-body>
				<fo:table-row>
					<fo:table-cell>
						<fo:block> </fo:block>
					</fo:table-cell>
					<!-- insert asset picture -->
					<fo:table-cell>
						<fo:block space-after="1mm">
							<fo:external-graphic width="100%" content-width="scale-to-fit" content-height="100%">
								<xsl:attribute name="src"><xsl:value-of select="/XMLData/MISCData/attributes/attribute[@name='CONTEXT_URL']"/>/GetAsset?primaryKey=<xsl:value-of select="attributes/attribute[@name='PAGE_DISPLAY_KEY']"/>&amp;type=t&amp;internal=true</xsl:attribute>
							</fo:external-graphic>
						</fo:block>
					</fo:table-cell>
					<fo:table-cell>
						<fo:block> </fo:block>
					</fo:table-cell>
					<!-- insert asset caption -->
					<fo:table-cell>
						<fo:table table-layout="fixed" font-size="10pt">
							<fo:table-column column-number="1" column-width="20mm" />
							<fo:table-column column-number="2" column-width="20mm" />
							<fo:table-body>
								<fo:table-row>
									<fo:table-cell>
										<fo:block font-weight="bold"><xsl:value-of select="attributes/attribute[@name='PRINT_Title']"/> </fo:block>
									</fo:table-cell>
									<fo:table-cell>
										<fo:block space-after="1mm">
											<xsl:value-of select="attributes/attribute[@name='__PUBLICATION_DISPLAY_TITLE']"/>
										</fo:block>
									</fo:table-cell>
								</fo:table-row>
								<fo:table-row>
									<fo:table-cell>
										<fo:block font-weight="bold">
											<xsl:call-template name="geteditiondateorissuelabel">
												<xsl:with-param name="pubDate" select="attributes/attribute[@name='PUBLICATION_DATE_STR']"/>
												<xsl:with-param name="pubIssue" select="attributes/attribute[@name='PUBLICATION_ISSUE_NAME']"/>
											</xsl:call-template>
										</fo:block>
									</fo:table-cell>
									<fo:table-cell>
										<fo:block space-after="1mm">
											<xsl:call-template name="geteditiondateorissue">
												<xsl:with-param name="pubDate" select="attributes/attribute[@name='PUBLICATION_DATE_STR']"/>
												<xsl:with-param name="pubIssue" select="attributes/attribute[@name='PUBLICATION_ISSUE_NAME']"/>
												<xsl:with-param name="pubYear" select="attributes/attribute[@name='PUBLICATION_ISSUE_YEAR']"/>
											</xsl:call-template>
										</fo:block>
									</fo:table-cell>
								</fo:table-row>
								<fo:table-row>
									<fo:table-cell>
										<fo:block font-weight="bold"><xsl:value-of select="attributes/attribute[@name='PRINT_Edition']"/> </fo:block>
									</fo:table-cell>
									<fo:table-cell>
										<fo:block space-after="1mm">
											<xsl:value-of select="attributes/attribute[@name='PUBLICATION_EDITION']"/>
										</fo:block>
									</fo:table-cell>
								</fo:table-row>
								<fo:table-row>
									<fo:table-cell>
										<fo:block font-weight="bold"><xsl:value-of select="attributes/attribute[@name='PRINT_Page']"/> </fo:block>
									</fo:table-cell>
									<fo:table-cell>
										<fo:block space-after="3mm">
											<xsl:value-of select="attributes/attribute[@name='PUBLICATION_PAGE']"/>
										</fo:block>
									</fo:table-cell>
								</fo:table-row>
								<fo:table-row>
									<fo:table-cell>
										<fo:block font-weight="bold"><xsl:value-of select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_Asset']"/> </fo:block>
									</fo:table-cell>
									<fo:table-cell>
										<fo:block space-after="1mm">
											<xsl:call-template name="generateimagetag">
												<xsl:with-param name="width" select="attributes/attribute[@name='width']"/>
												<xsl:with-param name="height" select="attributes/attribute[@name='height']"/>
												<xsl:with-param name="maxwidth">80</xsl:with-param>
												<xsl:with-param name="maxheight">80</xsl:with-param>
												<xsl:with-param name="imgURL"><xsl:value-of select="/XMLData/MISCData/attributes/attribute[@name='CONTEXT_URL']"/>/GetAsset?primaryKey=<xsl:value-of select="attributes/attribute[@name='PAGE_DISPLAY_KEY']"/>&amp;type=t</xsl:with-param>
												<xsl:with-param name="mm" select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_mm']"/>
											</xsl:call-template>
										</fo:block>
									</fo:table-cell>
								</fo:table-row>
							</fo:table-body>
						</fo:table>
					</fo:table-cell>
				</fo:table-row>
			</fo:table-body>
		</fo:table>
	</fo:block>
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
				<fo:static-content flow-name="xsl-region-before">
					<fo:block text-align="center" font-size="9pt">
						<xsl:value-of select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_Summary_print']"/> -
						(<xsl:value-of select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_CHP_MATCHES']"/>)
					</fo:block>
				<fo:block space-after="1mm" space-before="1mm" border-after-style="solid" border-after-width="thin" />
				</fo:static-content>

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

						<xsl:choose>

							<!-- Deleted asset -->

							<xsl:when test="contains('deleted', state)">

								<fo:block keep-together.within-page="always">

									<!-- insert primary key -->
									<fo:block text-align="center" font-weight="bold" font-size="12pt" space-after="5mm">
										<xsl:value-of select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_ID']"/>: <xsl:value-of select="primary_key/@type" />
										<xsl:call-template name="stripzeroes">
											<xsl:with-param name="text" select="substring(primary_key,13,16)"/>
										</xsl:call-template>
									</fo:block>

									<fo:block text-align="center" font-weight="bold" font-size="10pt">
										<xsl:value-of select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_ASSET_DELETED']"/>
									</fo:block>

									<fo:block space-before="10mm" space-after="5mm" border-after-style="solid" border-after-width="thin" />

								</fo:block>

							</xsl:when>

							<!-- PICTURE asset -->

							<xsl:when test="contains('PICTURE', primary_key/@type)">

								<fo:block keep-together.within-page="always">

									<fo:block>
										<fo:table table-layout="fixed" font-size="10pt">
											<fo:table-column column-number="1" column-width="5mm" />
											<fo:table-column column-number="2" column-width="60mm" />
											<fo:table-column column-number="3" column-width="5mm"  />
											<fo:table-column column-number="4" column-width="118mm" />
											<fo:table-body>
												<fo:table-row>
													<fo:table-cell><fo:block> </fo:block></fo:table-cell>
													<fo:table-cell>
														<fo:block space-after="1mm">
															<xsl:call-template name="generateimagetag">
																<xsl:with-param name="width" select="attributes/attribute[@name='width']"/>
																<xsl:with-param name="height" select="attributes/attribute[@name='height']"/>
																<xsl:with-param name="maxwidth">60</xsl:with-param>
																<xsl:with-param name="maxheight">50</xsl:with-param>
																<xsl:with-param name="imgURL"><xsl:value-of select="/XMLData/MISCData/attributes/attribute[@name='CONTEXT_URL']"/>/GetAsset?primaryKey=<xsl:value-of select="primary_key"/>&amp;type=t&amp;transformation=iccprofile:mode=stdonly&amp;internal=true</xsl:with-param>
																<xsl:with-param name="mm" select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_mm']"/>
															</xsl:call-template>
														</fo:block>
													</fo:table-cell>
													<fo:table-cell><fo:block> </fo:block></fo:table-cell>
													<fo:table-cell>
														<fo:table table-layout="fixed" font-size="10pt">
															<fo:table-column column-number="1" column-width="25mm" />
															<fo:table-column column-number="2" column-width="90mm" />
															<fo:table-body>
																<fo:table-row>
																	<fo:table-cell number-columns-spanned="2">
																		<fo:block>
																			<xsl:call-template name="displaycaptiontext">
																				<xsl:with-param name="text" select="attributes/attribute[@name='CAPTION']"/>
																				<xsl:with-param name="maxchar">350</xsl:with-param>
																			</xsl:call-template>
																		</fo:block>
																	</fo:table-cell>
																</fo:table-row>

																<fo:table-row>
																	<fo:table-cell number-columns-spanned="2" padding-top="2mm" padding-bottom="2mm" >
																		<fo:block border-after-style="solid" border-after-width="thin" />
																	</fo:table-cell>
																</fo:table-row>

																<!-- Customisation Start -->
																<fo:table-row>
																	<fo:table-cell padding-right=".5mm">
																		<fo:block font-weight="bold" text-align="right">Cost Indicator</fo:block>
																	</fo:table-cell>
																	<fo:table-cell>
																		<fo:block space-after="1mm">
																			<xsl:value-of select="specialist/XMLDataObject[@type='TMG_RIGHTS']/attributes/attribute[@name='COSTGROUPA']"/>
																		</fo:block>
																	</fo:table-cell>
																</fo:table-row>
																<!-- Customisation End -->																
																<fo:table-row>
																	<fo:table-cell padding-left=".5mm" padding-right=".5mm">
																		<fo:block font-weight="bold" text-align="right"><xsl:value-of select="attributes/attribute[@name='PRINT_Photographer']"/></fo:block>
																	</fo:table-cell>
																	<fo:table-cell>
																		<fo:block space-after="1mm">
																			<xsl:value-of select="attributes/attribute[@name='PHOTOGRAPHER']"/>
																		</fo:block>
																	</fo:table-cell>
																</fo:table-row>
																<fo:table-row>
																	<fo:table-cell padding-left=".5mm" padding-right=".5mm">
																		<fo:block font-weight="bold" text-align="right"><xsl:value-of select="attributes/attribute[@name='PRINT_Copyright']"/></fo:block>
																	</fo:table-cell>
																	<fo:table-cell>
																		<fo:block space-after="1mm">
																			<xsl:value-of select="attributes/attribute[@name='COPYRIGHT']"/>
																		</fo:block>
																	</fo:table-cell>
																</fo:table-row>
																<fo:table-row>
																	<fo:table-cell padding-left=".5mm" padding-right=".5mm">
																		<fo:block font-weight="bold" text-align="right"><xsl:value-of select="attributes/attribute[@name='PRINT_Provider']"/></fo:block>
																	</fo:table-cell>
																	<fo:table-cell>
																		<fo:block space-after="3mm">
																			<xsl:value-of select="attributes/attribute[@name='PROVIDER']"/>
																		</fo:block>
																	</fo:table-cell>
																</fo:table-row>
																<fo:table-row>
																	<fo:table-cell padding-left=".5mm" padding-right=".5mm">
																		<fo:block font-weight="bold" text-align="right"><xsl:value-of select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_ID']"/></fo:block>
																	</fo:table-cell>
																	<fo:table-cell>
																		<fo:block space-after="1mm">
																			<xsl:value-of select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_Picture']"/>
																			<xsl:call-template name="stripzeroes">
																				<xsl:with-param name="text" select="substring(primary_key,13,16)"/>
																			</xsl:call-template>
																		</fo:block>
																	</fo:table-cell>
																</fo:table-row>
																<fo:table-row>
																	<fo:table-cell padding-left=".5mm" padding-right=".5mm">
																		<fo:block font-weight="bold" text-align="right"><xsl:value-of select="attributes/attribute[@name='PRINT_eURN']"/></fo:block>
																	</fo:table-cell>
																	<fo:table-cell>
																		<fo:block space-after="1mm">
																			<xsl:value-of select="attributes/attribute[@name='XURN']"/>
																		</fo:block>
																	</fo:table-cell>
																</fo:table-row>
																<fo:table-row>
																	<fo:table-cell padding-left=".5mm" padding-right=".5mm">
																		<fo:block font-weight="bold" text-align="right"><xsl:value-of select="attributes/attribute[@name='PRINT_Owner']"/></fo:block>
																	</fo:table-cell>
																	<fo:table-cell>
																		<fo:block space-after="1mm">
																			<xsl:value-of select="attributes/attribute[@name='DISPLAY_OWNER_ID']"/>
																		</fo:block>
																	</fo:table-cell>
																</fo:table-row>
															</fo:table-body>
														</fo:table>
													</fo:table-cell>
												</fo:table-row>
											</fo:table-body>
										</fo:table>
									</fo:block>

									<fo:block space-before="5mm" space-after="5mm" border-after-style="solid" border-after-width="thin" />

								</fo:block>

							</xsl:when>

							<!-- PAGE asset -->

							<xsl:when test="contains('PAGE', primary_key/@type)">

								<fo:block keep-together.within-page="always">
											<xsl:choose>
												<xsl:when test="attributes/attribute[@name='PAGE_DISPLAY_TYPE'] = 'version'">
													<xsl:call-template name="displaypage">
														<xsl:with-param name="color">#FFE79D</xsl:with-param>
													</xsl:call-template>
												</xsl:when>
												<xsl:otherwise>
													<xsl:call-template name="displaypage">
														<xsl:with-param name="color">#ffffff</xsl:with-param>
													</xsl:call-template>
												</xsl:otherwise>
											</xsl:choose>
									<fo:block  space-after="5mm" border-after-style="solid" border-after-width="thin" />

								</fo:block>

							</xsl:when>

							<xsl:when test="contains('STORY', primary_key/@type)">
								<fo:block keep-together.within-page="always">
									<fo:block space-after="5mm">
										<fo:table table-layout="fixed" font-size="10pt">
										<fo:table-column column-number="1" column-width="159mm" />
										<fo:table-column column-number="2" column-width="29mm" />
										<fo:table-body>
											<fo:table-row>
												<fo:table-cell>
													<fo:table table-layout="fixed" font-size="10pt">
														<fo:table-column column-number="1" column-width="18mm" />
														<fo:table-column column-number="2" column-width="85mm" />
														<fo:table-column column-number="3" column-width="15mm" />
														<fo:table-column column-number="4" column-width="45mm" />
														<fo:table-body>

															<xsl:for-each select="attributes/attribute[@name='asset_usage']/XMLDataObjects/XMLDataObject">
																<fo:table-row>
																	<fo:table-cell number-columns-spanned="4">
																		<fo:block>
																			<xsl:value-of select="attributes/attribute[@name='__PUBLICATION_DISPLAY_TITLE']"/><xsl:text> </xsl:text>
																			<xsl:choose>
																				<xsl:when test="attributes/attribute[@name='__PUBLICATION_TYPE'] = 'issue'">
																					<xsl:value-of select="attributes/attribute[@name='PUBLICATION_ISSUE']"/><xsl:text> </xsl:text>
																					<xsl:value-of select="attributes/attribute[@name='ISSUE_YEAR']"/><xsl:text> </xsl:text>
																				</xsl:when>
																				<xsl:otherwise>
																					<xsl:value-of select="attributes/attribute[@name='PUBLICATION_DATE_STR']"/>
																				</xsl:otherwise>
																			</xsl:choose>
																			<xsl:value-of select="attributes/attribute[@name='PUBLICATION_EDITION']"/><xsl:text> p</xsl:text>
																			<xsl:value-of select="attributes/attribute[@name='PUBLICATION_PAGE']"/>
																		</fo:block>
																	</fo:table-cell>
																</fo:table-row>
															</xsl:for-each>

															<fo:table-row>
																<fo:table-cell>
																	<fo:block space-after="2mm" />
																</fo:table-cell>
															</fo:table-row>

															<fo:table-row>
																<fo:table-cell>
																	<fo:block font-weight="bold"><xsl:value-of select="attributes/attribute[@name='PRINT_Headline']"/></fo:block>
																</fo:table-cell>
																<fo:table-cell>
																	<fo:block>
																		<xsl:call-template name="displaycaptiontext">
																			<xsl:with-param name="text" select="attributes/attribute[@name='HEADLINE']"/>
																			<xsl:with-param name="maxchar">50</xsl:with-param>
																		</xsl:call-template>
																	</fo:block>
																</fo:table-cell>
																<!-- asset num -->
																<fo:table-cell padding-left=".5mm" padding-right=".5mm">
																	<fo:block font-weight="bold" text-align="right"><xsl:value-of select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_ID']"/></fo:block>
																</fo:table-cell>
																<fo:table-cell>
																	<fo:block>
																		<xsl:value-of select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_Story']"/>
																		<xsl:call-template name="stripzeroes">
																			<xsl:with-param name="text" select="substring(primary_key,13,16)"/>
																		</xsl:call-template>
																	</fo:block>
																</fo:table-cell>
															</fo:table-row>
															<fo:table-row>
																<fo:table-cell>
																	<fo:block font-weight="bold"><xsl:value-of select="attributes/attribute[@name='PRINT_Byline']"/></fo:block>
																</fo:table-cell>
																<fo:table-cell>
																	<fo:block>
																		<xsl:call-template name="displaycaptiontext">
																			<xsl:with-param name="text" select="attributes/attribute[@name='BYLINE']"/>
																			<xsl:with-param name="maxchar">50</xsl:with-param>
																		</xsl:call-template>
																	</fo:block>
																</fo:table-cell>
																<fo:table-cell padding-left=".5mm" padding-right=".5mm">
																	<fo:block font-weight="bold" text-align="right"><xsl:value-of select="attributes/attribute[@name='PRINT_Owner']"/></fo:block>
																</fo:table-cell>
																<fo:table-cell>
																	<fo:block>
																		<xsl:call-template name="displaycaptiontext">
																			<xsl:with-param name="text" select="attributes/attribute[@name='DISPLAY_OWNER_ID']"/>
																			<xsl:with-param name="maxchar">30</xsl:with-param>
																		</xsl:call-template>
																	</fo:block>
																</fo:table-cell>
															</fo:table-row>
														</fo:table-body>
													</fo:table>

													<fo:block font-size="10pt">
														<xsl:value-of select="attributes/attribute[@name='SUMMARY']"/>
													</fo:block>

												</fo:table-cell>
												<fo:table-cell>
													<fo:block space-after="1mm">
														<xsl:call-template name="generateimagetag">
															<xsl:with-param name="width" select="attributes/attribute[@name='width']"/>
															<xsl:with-param name="height" select="attributes/attribute[@name='height']"/>
															<xsl:with-param name="maxwidth">80</xsl:with-param>
															<xsl:with-param name="maxheight">80</xsl:with-param>
															<xsl:with-param name="imgURL"><xsl:value-of select="/XMLData/MISCData/attributes/attribute[@name='CONTEXT_URL']"/>/GetAsset?primaryKey=<xsl:value-of select="attributes/attribute[@name='PAGE_DISPLAY_KEY']"/>&amp;type=t</xsl:with-param>
															<xsl:with-param name="mm" select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_mm']"/>
														</xsl:call-template>
													</fo:block>
												</fo:table-cell>
											</fo:table-row>
										</fo:table-body>
									</fo:table>
									</fo:block>
									<fo:block space-before="5mm" space-after="5mm" border-after-style="solid" border-after-width="thin" />
								</fo:block>
							</xsl:when>

							<xsl:when test="contains('DOCUMENT', primary_key/@type)">

								<fo:block keep-together.within-page="always">

									<fo:block>
										<fo:table table-layout="fixed" font-size="10pt">
											<fo:table-column column-number="1" column-width="5mm" />
											<fo:table-column column-number="2" column-width="60mm" />
											<fo:table-column column-number="3" column-width="5mm" />
											<fo:table-column column-number="4" column-width="118mm" />
											<fo:table-body>
												<fo:table-cell><fo:block> </fo:block></fo:table-cell>
												<fo:table-cell>
													<fo:block space-after="1mm">
														<fo:external-graphic width="100%" content-width="scale-to-fit" content-height="100%" >
															<xsl:attribute name="src"><xsl:value-of select="/XMLData/MISCData/attributes/attribute[@name='CONTEXT_URL']"/>/GetAsset?primaryKey=<xsl:value-of select="primary_key"/>&amp;type=t&amp;transformation=iccprofile:mode=stdonly&amp;internal=true</xsl:attribute>
														</fo:external-graphic>
													</fo:block>
												</fo:table-cell>
												<fo:table-cell><fo:block> </fo:block></fo:table-cell>
												<fo:table-cell>
													<fo:table table-layout="fixed" font-size="10pt">
														<fo:table-column column-number="1" column-width="25mm" />
														<fo:table-column column-number="2" column-width="90mm" />
														<fo:table-body>
															<fo:table-row>
																<fo:table-cell number-columns-spanned="2">
																	<fo:block>
																		<xsl:call-template name="displaycaptiontext">
																			<xsl:with-param name="text" select="attributes/attribute[@name='DESCRIPTION']"/>
																			<xsl:with-param name="maxchar">350</xsl:with-param>
																		</xsl:call-template>
																	</fo:block>
																</fo:table-cell>
															</fo:table-row>
															<fo:table-row>
																<fo:table-cell number-columns-spanned="2" padding-top="2mm" padding-bottom="2mm" >
																	<fo:block border-after-style="solid" border-after-width="thin" />
																</fo:table-cell>
															</fo:table-row>
															<fo:table-row>
																<fo:table-cell>
																	<fo:block font-weight="bold" text-align="right"><xsl:value-of select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_ID']"/></fo:block>
																</fo:table-cell>
																<fo:table-cell>
																	<fo:block>
																		<xsl:value-of select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_Document']"/>
																		<xsl:call-template name="stripzeroes">
																			<xsl:with-param name="text" select="substring(primary_key,13,16)"/>
																		</xsl:call-template>
																	</fo:block>
																</fo:table-cell>
															</fo:table-row>
															<fo:table-row>
																<fo:table-cell>
																	<fo:block font-weight="bold" text-align="right"><xsl:value-of select="attributes/attribute[@name='PRINT_Caption']"/></fo:block>
																</fo:table-cell>
																<fo:table-cell>
																	<fo:block>
																		<xsl:value-of select="attributes/attribute[@name='CREATOR']"/>
																	</fo:block>
																</fo:table-cell>
															</fo:table-row>
															<fo:table-row>
																<fo:table-cell>
																	<fo:block font-weight="bold" text-align="right"><xsl:value-of select="attributes/attribute[@name='PRINT_Title']"/></fo:block>
																</fo:table-cell>
																<fo:table-cell>
																	<fo:block>
																		<xsl:value-of select="attributes/attribute[@name='TITLE']"/>
																	</fo:block>
																</fo:table-cell>
															</fo:table-row>
															<fo:table-row>
																<fo:table-cell>
																	<fo:block font-weight="bold" text-align="right"><xsl:value-of select="attributes/attribute[@name='PRINT_File_name']"/></fo:block>
																</fo:table-cell>
																<fo:table-cell>
																	<fo:block>
																		<xsl:value-of select="attributes/attribute[@name='FILE_NAME']"/>
																	</fo:block>
																</fo:table-cell>
														</fo:table-row>
														<fo:table-row>
																<fo:table-cell>
																	<fo:block font-weight="bold" text-align="right"><xsl:value-of select="attributes/attribute[@name='PRINT_Owner']"/></fo:block>
																</fo:table-cell>
																<fo:table-cell>
																	<fo:block>
																		<xsl:value-of select="attributes/attribute[@name='DISPLAY_OWNER_ID']"/>
																	</fo:block>
																</fo:table-cell>
														</fo:table-row>
														</fo:table-body>
													</fo:table>
												</fo:table-cell>
										</fo:table-body>
										</fo:table>
									</fo:block>

									<fo:block space-before="5mm" space-after="5mm" border-after-style="solid" border-after-width="thin"/>
								</fo:block>

							</xsl:when>

							<xsl:when test="contains('MEDIA', primary_key/@type)">
								<fo:block keep-together.within-page="always">
									<fo:block>
										<fo:table table-layout="fixed" font-size="10pt">
											<fo:table-column column-number="1" column-width="5mm" />
											<fo:table-column column-number="2" column-width="60mm" />
											<fo:table-column column-number="3" column-width="5mm" />
											<fo:table-column column-number="4" column-width="118mm" />
											<fo:table-body>
												<fo:table-cell><fo:block> </fo:block></fo:table-cell>
												<fo:table-cell>
													<fo:block space-after="1mm">
														<xsl:call-template name="generateimagetag">
															<xsl:with-param name="width" select="attributes/attribute[@name='width']"/>
															<xsl:with-param name="height" select="attributes/attribute[@name='height']"/>
															<xsl:with-param name="maxwidth">60</xsl:with-param>
															<xsl:with-param name="maxheight">50</xsl:with-param>
															<xsl:with-param name="imgURL"><xsl:value-of select="/XMLData/MISCData/attributes/attribute[@name='CONTEXT_URL']"/>/GetAsset?primaryKey=<xsl:value-of select="primary_key"/>&amp;type=t&amp;transformation=iccprofile:mode=stdonly&amp;internal=true</xsl:with-param>
															<xsl:with-param name="mm" select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_mm']"/>
														</xsl:call-template>
													</fo:block>
												</fo:table-cell>
												<fo:table-cell><fo:block> </fo:block></fo:table-cell>
												<fo:table-cell>
													<fo:table table-layout="fixed" font-size="10pt">
														<fo:table-column column-number="1" column-width="25mm" />
														<fo:table-column column-number="2" column-width="90mm" />
														<fo:table-body>
															<fo:table-row>
																<fo:table-cell number-columns-spanned="2">
																	<fo:block>
																		<xsl:call-template name="displaycaptiontext">
																			<xsl:with-param name="text" select="attributes/attribute[@name='CAPTION']"/>
																			<xsl:with-param name="maxchar">350</xsl:with-param>
																		</xsl:call-template>
																	</fo:block>
																</fo:table-cell>
															</fo:table-row>
															<fo:table-row>
																<fo:table-cell number-columns-spanned="2" padding-top="2mm" padding-bottom="2mm" >
																	<fo:block border-after-style="solid" border-after-width="thin" />
																</fo:table-cell>
															</fo:table-row>
															<fo:table-row>
																<fo:table-cell padding-left=".5mm" padding-right=".5mm">
																	<fo:block font-weight="bold" text-align="right"><xsl:value-of select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_ID']"/></fo:block>
																</fo:table-cell>
																<fo:table-cell>
																	<fo:block>
																		<xsl:value-of select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_Media']"/>
																		<xsl:call-template name="stripzeroes">
																			<xsl:with-param name="text" select="substring(primary_key,13,16)"/>
																		</xsl:call-template>
																	</fo:block>
																</fo:table-cell>
															</fo:table-row>
															<fo:table-row>
																<fo:table-cell>
																	<fo:block font-weight="bold" text-align="right"><xsl:value-of select="attributes/attribute[@name='PRINT_Owner']"/></fo:block>
																</fo:table-cell>
																<fo:table-cell>
																	<fo:block>
																		<xsl:value-of select="attributes/attribute[@name='DISPLAY_OWNER_ID']"/>
																	</fo:block>
																</fo:table-cell>
															</fo:table-row>
															<fo:table-row>
																<fo:table-cell>
																	<fo:block font-weight="bold" text-align="right"><xsl:value-of select="attributes/attribute[@name='PRINT_Title']"/></fo:block>
																</fo:table-cell>
																<fo:table-cell>
																	<fo:block>
																		<xsl:value-of select="attributes/attribute[@name='TITLE']"/>
																	</fo:block>
																</fo:table-cell>
															</fo:table-row>
															<fo:table-row>
																<fo:table-cell>
																	<fo:block font-weight="bold" text-align="right"><xsl:value-of select="attributes/attribute[@name='PRINT_File_name']"/></fo:block>
																</fo:table-cell>
																<fo:table-cell>
																	<fo:block>
																		<xsl:value-of select="attributes/attribute[@name='FILE_NAME']"/>
																	</fo:block>
																</fo:table-cell>
															</fo:table-row>
														</fo:table-body>
													</fo:table>
												</fo:table-cell>
											</fo:table-body>
										</fo:table>
									</fo:block>

									<fo:block space-before="5mm" space-after="5mm" border-after-style="solid" border-after-width="thin"/>

								</fo:block>

							</xsl:when>

							<!-- COMPOUND asset -->

							<xsl:when test="contains('COMPOSITE', primary_key/@type)">
								<fo:block keep-together.within-page="always">
									<fo:block>
										<fo:table table-layout="fixed" font-size="10pt">
											<fo:table-column column-number="1" column-width="5mm" />
											<fo:table-column column-number="2" column-width="60mm" />
											<fo:table-column column-number="3" column-width="5mm"  />
											<fo:table-column column-number="4" column-width="118mm" />
											<fo:table-body>
												<fo:table-row>
													<fo:table-cell><fo:block> </fo:block></fo:table-cell>
													<fo:table-cell>
														<fo:block space-after="1mm">
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
													<fo:table-cell><fo:block> </fo:block></fo:table-cell>
													<fo:table-cell>
														<fo:table table-layout="fixed" font-size="10pt">
															<fo:table-column column-number="1" column-width="25mm" />
															<fo:table-column column-number="2" column-width="90mm" />
															<fo:table-body>
																<fo:table-row>
																	<fo:table-cell number-columns-spanned="2">
																		<fo:block>
																			<xsl:call-template name="displaycaptiontext">
																				<xsl:with-param name="text" select="attributes/attribute[@name='CAPTION']"/>
																				<xsl:with-param name="maxchar">350</xsl:with-param>
																			</xsl:call-template>
																		</fo:block>
																	</fo:table-cell>
																</fo:table-row>

																<fo:table-row>
																	<fo:table-cell number-columns-spanned="2" padding-top="2mm" padding-bottom="2mm" >
																		<fo:block border-after-style="solid" border-after-width="thin" />
																	</fo:table-cell>
																</fo:table-row>

																<xsl:if test="attributes/attribute[@name='INTERNAL_NAME'] != ''">
																	<fo:table-row>
																		<fo:table-cell padding-left=".5mm" padding-right=".5mm">
																			<fo:block font-weight="bold" text-align="right"><xsl:value-of select="attributes/attribute[@name='PRINT_Name']"/></fo:block>
																		</fo:table-cell>
																		<fo:table-cell>
																			<fo:block space-after="1mm">
																				<xsl:value-of select="attributes/attribute[@name='INTERNAL_NAME']"/>
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
																			<fo:block space-after="1mm">
																				<xsl:value-of select="attributes/attribute[@name='HEADLINE']"/>
																			</fo:block>
																		</fo:table-cell>
																	</fo:table-row>
																</xsl:if>

																<xsl:if test="attributes/attribute[@name='PROVIDER'] != ''">
																	<fo:table-row>
																		<fo:table-cell padding-left=".5mm" padding-right=".5mm">
																			<fo:block font-weight="bold" text-align="right"><xsl:value-of select="attributes/attribute[@name='PRINT_Provider']"/></fo:block>
																		</fo:table-cell>
																		<fo:table-cell>
																			<fo:block space-after="3mm">
																				<xsl:value-of select="attributes/attribute[@name='PROVIDER']"/>
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
																			<fo:block space-after="1mm">
																				<xsl:value-of select="attributes/attribute[@name='BYLINE']"/>
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
																			<fo:block space-after="1mm">
																				<xsl:value-of select="attributes/attribute[@name='SUBHEADING']"/>
																			</fo:block>
																		</fo:table-cell>
																	</fo:table-row>
																</xsl:if>

																<fo:table-row>
																	<fo:table-cell padding-left=".5mm" padding-right=".5mm">
																		<fo:block font-weight="bold" text-align="right"><xsl:value-of select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_ID']"/></fo:block>
																	</fo:table-cell>
																	<fo:table-cell>
																		<fo:block space-after="1mm">
																			<xsl:if test="attributes/attribute[@name='SUB_TYPE'] = 'picturegallery'"><xsl:value-of select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_Gallery']"/> </xsl:if>
																			<xsl:if test="attributes/attribute[@name='SUB_TYPE'] = 'picturecomposite'"><xsl:value-of select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_Composite']"/> </xsl:if>
																			<xsl:if test="attributes/attribute[@name='SUB_TYPE'] = 'graphic'"><xsl:value-of select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_Graphic']"/> </xsl:if>
																			<xsl:if test="attributes/attribute[@name='SUB_TYPE'] = 'collection'"><xsl:value-of select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_Collection']"/> </xsl:if>
																			<xsl:call-template name="stripzeroes">
																				<xsl:with-param name="text" select="substring(primary_key,13,16)"/>
																			</xsl:call-template>
																		</fo:block>
																	</fo:table-cell>
																</fo:table-row>
																<fo:table-row>
																	<fo:table-cell padding-left=".5mm" padding-right=".5mm">
																		<fo:block font-weight="bold" text-align="right"><xsl:value-of select="attributes/attribute[@name='PRINT_Owner']"/></fo:block>
																	</fo:table-cell>
																	<fo:table-cell>
																		<fo:block space-after="1mm">
																			<xsl:value-of select="attributes/attribute[@name='DISPLAY_OWNER_ID']"/>
																		</fo:block>
																	</fo:table-cell>
																</fo:table-row>
															</fo:table-body>
														</fo:table>
													</fo:table-cell>
												</fo:table-row>
											</fo:table-body>
										</fo:table>
									</fo:block>
								</fo:block>

								<fo:block space-before="5mm" space-after="5mm" border-after-style="solid" border-after-width="thin" />

							</xsl:when>

							<!-- end of assets -->

						</xsl:choose>
					</xsl:for-each>
					<fo:block id="endofdoc"></fo:block>
				</fo:flow>
			</fo:page-sequence>
		</fo:root>
	</xsl:template>
</xsl:stylesheet>
