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

	<!-- template used to insert tabular usage history -->
	<xsl:template name="includetabularhistory">
		<fo:block>
			<fo:table table-layout="fixed" font-size="10pt">
				<fo:table-column column-number="1" column-width="50mm" />
				<fo:table-column column-number="2" column-width="42mm" />
				<fo:table-column column-number="3" column-width="36mm" />
				<fo:table-column column-number="4" column-width="30mm" />
				<fo:table-column column-number="5" column-width="30mm" />

				<fo:table-header>

					<!-- Headings first -->
					<fo:table-row>
						<!-- publication title -->
						<fo:table-cell font-weight="bold">
							<fo:block>
								<xsl:value-of select="attributes/attribute[@name='PRINT_Title']"/>
							</fo:block>
						</fo:table-cell>

						<!-- publication date -->
						<fo:table-cell font-weight="bold">
							<fo:block>
								<xsl:value-of select="attributes/attribute[@name='PRINT_Date_Issue']"/>
							</fo:block>
						</fo:table-cell>

						<!-- publication edition -->
						<fo:table-cell font-weight="bold">
							<fo:block>
								<xsl:value-of select="attributes/attribute[@name='PRINT_Edition']"/>
							</fo:block>
						</fo:table-cell>

						<!-- publication page -->
						<fo:table-cell font-weight="bold">
							<fo:block>
								<xsl:value-of select="attributes/attribute[@name='PRINT_Page']"/>
							</fo:block>
						</fo:table-cell>

						<!-- publication book -->
						<fo:table-cell font-weight="bold">
							<fo:block>
								<xsl:value-of select="attributes/attribute[@name='PRINT_Book']"/>
							</fo:block>
						</fo:table-cell>
					</fo:table-row>
				</fo:table-header>

				<fo:table-body>

					<!-- Then the data for each asset_usage record -->
					<xsl:for-each select="attributes/attribute[@name='asset_usage']/XMLDataObjects/XMLDataObject">
						<fo:table-row>
							<!-- publication title -->
							<fo:table-cell >
								<fo:block>
									<xsl:value-of select="attributes/attribute[@name='__PUBLICATION_DISPLAY_TITLE']"/>
								</fo:block>
							</fo:table-cell>

							<!-- publication date -->
							<fo:table-cell>
								<fo:block>
									<xsl:choose>
										<xsl:when test="attributes/attribute[@name='__PUBLICATION_TYPE'] = 'issue'">
											<xsl:value-of select="attributes/attribute[@name='PUBLICATION_ISSUE']"/><xsl:text> </xsl:text>
											<xsl:value-of select="attributes/attribute[@name='ISSUE_YEAR']"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="attributes/attribute[@name='PUBLICATION_DATE_STR']"/>
										</xsl:otherwise>
									</xsl:choose>
								</fo:block>
							</fo:table-cell>

							<!-- publication edition -->
							<fo:table-cell>
								<fo:block>
									<xsl:value-of select="attributes/attribute[@name='PUBLICATION_EDITION']"/>
								</fo:block>
							</fo:table-cell>

							<!-- publication page -->
							<fo:table-cell>
								<fo:block>
									<xsl:value-of select="attributes/attribute[@name='PUBLICATION_PAGE']"/>
								</fo:block>
							</fo:table-cell>

							<!-- publication book -->
							<fo:table-cell>
								<fo:block>
									<xsl:value-of select="attributes/attribute[@name='PUBLICATION_BOOK_NAME']"/>
								</fo:block>
							</fo:table-cell>
						</fo:table-row>
					</xsl:for-each>
				</fo:table-body>
			</fo:table>
		</fo:block>

		<xsl:if test="count(attributes/attribute[@name='asset_usage']/XMLDataObjects/XMLDataObject) &gt; 0">
			<fo:block space-before="7mm" space-after="5mm" border-after-style="solid" border-after-width="thin" />
		</xsl:if>
	</xsl:template>

	<xsl:template match="/">
		<fo:root xmlns:fo="http://www.w3.org/1999/XSL/Format" font-family="Liberation Sans">
			<!-- define page template -->
			<fo:layout-master-set>
				<fo:simple-page-master master-name="PageMaster" page-height="297mm" page-width="210mm" margin-top="1cm" margin-bottom="5mm" margin-left="1cm" margin-right="1cm">
					<fo:region-body margin-bottom="1cm"/>
					<fo:region-before extent="1mm" />
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
							<xsl:value-of select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_Detail_picture']"/>
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

							<!-- PICTURE asset -->

							<xsl:when test="contains('PICTURE', primary_key/@type)">

								<fo:block keep-with-next.within-page="always">
									<fo:table table-layout="fixed" font-size="10pt">
										<fo:table-column column-number="1" column-width="90mm" />
										<fo:table-column column-number="2" column-width="8mm" />
										<fo:table-column column-number="3" column-width="90mm" />
										<fo:table-body>
											<!-- insert asset picture -->
											<fo:table-row>
												<fo:table-cell>
													<!-- asset eURN -->
													<fo:block text-align="center">
														<fo:inline font-weight="bold"><xsl:value-of select="attributes/attribute[@name='PRINT_eURN']"/>: </fo:inline> <xsl:value-of select="attributes/attribute[@name='XURN']"/>
													</fo:block>
													<!-- insert picture -->
													<fo:block text-align="center">
														<xsl:call-template name="generateimagetag">
															<xsl:with-param name="width" select="attributes/attribute[@name='width']"/>
															<xsl:with-param name="height" select="attributes/attribute[@name='height']"/>
															<xsl:with-param name="maxwidth">90</xsl:with-param>
															<xsl:with-param name="maxheight">90</xsl:with-param>
															<xsl:with-param name="imgURL">
																<xsl:choose>
																	<xsl:when test="attributes/attribute[@name='has_Preview_Privilege']='true'"><xsl:value-of select="/XMLData/MISCData/attributes/attribute[@name='CONTEXT_URL']"/>/GetAsset?primaryKey=<xsl:value-of select="primary_key"/>&amp;type=p</xsl:when>
																	<xsl:otherwise><xsl:value-of select="/XMLData/MISCData/attributes/attribute[@name='CONTEXT_URL']"/>/GetAsset?primaryKey=<xsl:value-of select="primary_key"/>&amp;type=t</xsl:otherwise>
																</xsl:choose>
															</xsl:with-param>
															<xsl:with-param name="mm" select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_mm']"/>
														</xsl:call-template>
													</fo:block>
													<!-- insert picture properties -->
													<fo:block space-before="1mm" text-align="center" font-size="9pt">
														<xsl:value-of select="attributes/attribute[@name='colourspace']"/>,
														<xsl:value-of select="attributes/attribute[@name='fftype']"/>,
														<xsl:value-of select="attributes/attribute[@name='filesize']"/> <xsl:value-of select="attributes/attribute[@name='PRINT_bytes']"/>,
														<xsl:value-of select="attributes/attribute[@name='width']"/>w x <xsl:value-of select="attributes/attribute[@name='height']"/>h,
														<xsl:value-of select="attributes/attribute[@name='vres']"/> x <xsl:value-of select="attributes/attribute[@name='hres']"/> dpi
													</fo:block>
												</fo:table-cell>
												<fo:table-cell>
													<fo:block />
												</fo:table-cell>
												<fo:table-cell>
													<fo:table table-layout="fixed" font-size="9pt">
														<fo:table-column column-number="1" column-width="22mm" />
														<fo:table-column column-number="2" column-width="70mm" />
														<fo:table-body>
															<fo:table-row>
																<fo:table-cell number-columns-spanned="2">
																	<fo:block>
																		<xsl:value-of select="attributes/attribute[@name='CAPTION']"/>
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
																	<fo:block><xsl:value-of select="specialist/XMLDataObject[@type='TMG_RIGHTS']/attributes/attribute[@name='COSTGROUPA']"/></fo:block>
																</fo:table-cell>
															</fo:table-row>
															<!-- Customisation End -->															

															<fo:table-row>
																<fo:table-cell padding-left=".5mm" padding-right=".5mm">
																	<fo:block font-weight="bold" text-align="right"><xsl:value-of select="attributes/attribute[@name='PRINT_People']"/></fo:block>
																</fo:table-cell>
																<fo:table-cell>
																	<fo:block><xsl:value-of select="attributes/attribute[@name='PEOPLE']"/></fo:block>
																</fo:table-cell>
															</fo:table-row>
															<fo:table-row>
																<fo:table-cell padding-left=".5mm" padding-right=".5mm">
																	<fo:block font-weight="bold" text-align="right"><xsl:value-of select="attributes/attribute[@name='PRINT_Keywords']"/></fo:block>
																</fo:table-cell>
																<fo:table-cell>
																	<fo:block><xsl:value-of select="attributes/attribute[@name='KEYWORDS']"/></fo:block>
																</fo:table-cell>
															</fo:table-row>
															<fo:table-row>
																<fo:table-cell padding-left=".5mm" padding-right=".5mm">
																	<fo:block font-weight="bold" text-align="right"><xsl:value-of select="attributes/attribute[@name='PRINT_Owner']"/></fo:block>
																</fo:table-cell>
																<fo:table-cell>
																	<fo:block><xsl:value-of select="attributes/attribute[@name='DISPLAY_OWNER_ID']"/></fo:block>
																</fo:table-cell>
															</fo:table-row>
															<fo:table-row>
																<fo:table-cell padding-left=".5mm" padding-right=".5mm">
																	<fo:block font-weight="bold" text-align="right"><xsl:value-of select="attributes/attribute[@name='PRINT_Taken_on']"/></fo:block>
																</fo:table-cell>
																<fo:table-cell>
																	<fo:block>
																		<xsl:value-of select="attributes/attribute[@name='PICTURE_DATE_STR']"/>
																	</fo:block>
																</fo:table-cell>
															</fo:table-row>
															<fo:table-row>
																<fo:table-cell padding-left=".5mm" padding-right=".5mm">
																	<fo:block font-weight="bold" text-align="right"><xsl:value-of select="attributes/attribute[@name='PRINT_Date_received']"/></fo:block>
																</fo:table-cell>
																<fo:table-cell>
																	<fo:block>
																		<xsl:value-of select="attributes/attribute[@name='DATE_RECEIVED_STR']"/>
																	</fo:block>
																</fo:table-cell>
															</fo:table-row>
															<fo:table-row>
																<fo:table-cell padding-left=".5mm" padding-right=".5mm">
																	<fo:block font-weight="bold" text-align="right"><xsl:value-of select="attributes/attribute[@name='PRINT_Photographer']"/></fo:block>
																</fo:table-cell>
																<fo:table-cell>
																	<fo:block>
																		<xsl:value-of select="attributes/attribute[@name='PHOTOGRAPHER']"/>
																	</fo:block>
																</fo:table-cell>
															</fo:table-row>
															<fo:table-row>
																<fo:table-cell padding-left=".5mm" padding-right=".5mm">
																	<fo:block font-weight="bold" text-align="right"><xsl:value-of select="attributes/attribute[@name='PRINT_Copyright']"/></fo:block>
																</fo:table-cell>
																<fo:table-cell>
																	<fo:block>
																		<xsl:value-of select="attributes/attribute[@name='COPYRIGHT']"/>
																	</fo:block>
																</fo:table-cell>
															</fo:table-row>
															<fo:table-row>
																<fo:table-cell padding-left=".5mm" padding-right=".5mm">
																	<fo:block font-weight="bold" text-align="right"><xsl:value-of select="attributes/attribute[@name='PRINT_Provider']"/></fo:block>
																</fo:table-cell>
																<fo:table-cell>
																	<fo:block>
																		<xsl:value-of select="attributes/attribute[@name='PROVIDER']"/>
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

								<fo:block space-before="4mm" space-after="4mm" border-after-style="solid" border-after-width="thin" />

								<!-- insert Notices -->
								<fo:block>
									<!-- include Legal message -->
									<xsl:if test="string-length(attributes/attribute[@name='Legal_msg']) &gt; 0">
										<fo:block font-size="10pt" font-weight="bold" background-color="red" color="white">
											<xsl:value-of select="attributes/attribute[@name='PRINT_Legal_Warnings']"/>
										</fo:block>
										<fo:block font-size="10pt" space-after="5mm" background-color="pink">
											<xsl:value-of select="attributes/attribute[@name='Legal_msg']"/>
										</fo:block>
									</xsl:if>

									<!-- include fee message -->
									<xsl:if test="string-length(attributes/attribute[@name='Fee_msg']) &gt; 0">
										<fo:block font-size="10pt" font-weight="bold" background-color="red" color="white">
											<xsl:value-of select="attributes/attribute[@name='PRINT_Fee_Warnings']"/>
										</fo:block>
										<fo:block font-size="10pt" space-after="5mm" background-color="pink">
											<xsl:value-of select="attributes/attribute[@name='Fee_msg']"/>
										</fo:block>
									</xsl:if>

									<!-- include copyright message -->
									<xsl:if test="string-length(attributes/attribute[@name='Copyright_msg']) &gt; 0">
										<fo:block font-size="10pt" font-weight="bold">
											<xsl:value-of select="attributes/attribute[@name='PRINT_Copyright_Warnings']"/>
										</fo:block>
										<fo:block font-size="10pt" space-after="5mm">
											<xsl:value-of select="attributes/attribute[@name='Copyright_msg']"/>
										</fo:block>
									</xsl:if>

									<!-- include correction message -->
									<xsl:if test="string-length(attributes/attribute[@name='Correction_msg']) &gt; 0">
										<fo:block font-size="10pt" font-weight="bold">
											<xsl:value-of select="attributes/attribute[@name='PRINT_Correction_Warnings']"/>
										</fo:block>
										<fo:block font-size="10pt" space-after="5mm">
											<xsl:value-of select="attributes/attribute[@name='Correction_msg']"/>
										</fo:block>
									</xsl:if>

									<!-- include Information message -->
									<xsl:if test="string-length(attributes/attribute[@name='Information_msg']) &gt; 0">
										<fo:block font-size="10pt" font-weight="bold">
											<xsl:value-of select="attributes/attribute[@name='PRINT_Information']"/>
										</fo:block>
										<fo:block font-size="10pt" space-after="5mm">
											<xsl:value-of select="attributes/attribute[@name='Information_msg']"/>
										</fo:block>
									</xsl:if>

								</fo:block>

								<xsl:if test="string-length(attributes/attribute[@name='Copyright_msg']) &gt; 0 or
									string-length(attributes/attribute[@name='Correction_msg']) &gt; 0 or
									string-length(attributes/attribute[@name='Legal_msg']) &gt; 0 or
									string-length(attributes/attribute[@name='fee_msg']) &gt; 0 or
									string-length(attributes/attribute[@name='Information_msg']) &gt; 0">
									<fo:block space-after="5mm" border-after-style="solid" border-after-width="thin" />
								</xsl:if>


								<fo:table table-layout="fixed" font-size="9pt">
									<fo:table-column column-number="1" column-width="25mm" />
									<fo:table-column column-number="2" column-width="50mm" />
									<fo:table-column column-number="3" column-width="18mm" />
									<fo:table-column column-number="4" column-width="50mm" />
									<fo:table-column column-number="5" column-width="18mm" />
									<fo:table-column column-number="6" column-width="55mm" />
									<fo:table-body>
										<fo:table-row>
											<!-- Note -->
											<fo:table-cell padding-left=".5mm" padding-right=".5mm">
												<fo:block font-weight="bold" text-align="right"><xsl:value-of select="attributes/attribute[@name='PRINT_Notes']"/></fo:block>
											</fo:table-cell>
											<fo:table-cell number-columns-spanned="5">
												<fo:block>
													<xsl:value-of select="attributes/attribute[@name='NOTES']"/>
												</fo:block>
											</fo:table-cell>
										</fo:table-row>

										<fo:table-row>
											<!-- created -->
											<fo:table-cell padding-left=".5mm" padding-right=".5mm">
												<fo:block font-weight="bold" text-align="right"><xsl:value-of select="attributes/attribute[@name='PRINT_Date_loaded']"/></fo:block>
											</fo:table-cell>
											<fo:table-cell>
												<fo:block>
													<xsl:value-of select="attributes/attribute[@name='CREATION_STAMP_STR']"/>
												</fo:block>
											</fo:table-cell>
											<fo:table-cell padding-left=".5mm" padding-right=".5mm">
												<fo:block font-weight="bold" text-align="right"><xsl:value-of select="attributes/attribute[@name='PRINT_Modified']"/></fo:block>
											</fo:table-cell>
											<fo:table-cell>
												<fo:block>
													<xsl:value-of select="attributes/attribute[@name='UPDATE_STAMP_STR']"/>
												</fo:block>
											</fo:table-cell>
											<!-- status -->
											<fo:table-cell padding-left=".5mm" padding-right=".5mm">
												<fo:block font-weight="bold" text-align="right"><xsl:value-of select="attributes/attribute[@name='PRINT_Status']"/></fo:block>
											</fo:table-cell>
											<fo:table-cell>
												<fo:block><xsl:value-of select="attributes/attribute[@name='STATUS']"/></fo:block>
											</fo:table-cell>
										</fo:table-row>

										<fo:table-row>
											<!-- filename -->
											<fo:table-cell padding-left=".5mm" padding-right=".5mm">
												<fo:block font-weight="bold" text-align="right"><xsl:value-of select="attributes/attribute[@name='PRINT_File_name']"/></fo:block>
											</fo:table-cell>
											<fo:table-cell number-columns-spanned="5">
												<fo:block>
													<fo:block><xsl:value-of select="attributes/attribute[@name='FILENAME']"/></fo:block>
												</fo:block>
											</fo:table-cell>
										</fo:table-row>

										<fo:table-row>
											<!-- filepath -->
											<fo:table-cell padding-left=".5mm" padding-right=".5mm">
												<fo:block font-weight="bold" text-align="right"><xsl:value-of select="attributes/attribute[@name='PRINT_Loaded_from']"/></fo:block>
											</fo:table-cell>
											<fo:table-cell number-columns-spanned="5">
												<fo:block>
													<xsl:value-of select="attributes/attribute[@name='FILEPATH']"/>
												</fo:block>
											</fo:table-cell>
										</fo:table-row>
									</fo:table-body>
								</fo:table>

								<fo:block space-before="4mm" space-after="4mm" border-after-style="solid" border-after-width="thin" />

								<!-- insert asset versions -->
								<xsl:if test="attributes/attribute[@name='ASSET_VERSION']/XMLDataObjects/XMLDataObject">
								<fo:block>
									<fo:table table-layout="fixed" font-size="10pt">
										<fo:table-column column-number="1" column-width="60mm" />
										<fo:table-column column-number="2" column-width="130mm" />
										<fo:table-body>

										<xsl:for-each select="attributes/attribute[@name='ASSET_VERSION']/XMLDataObjects/XMLDataObject">
											<fo:table-row>
												<fo:table-cell>
													<fo:block>
														<xsl:call-template name="generateimagetag">
															<xsl:with-param name="width" select="attributes/attribute[@name='width']"/>
															<xsl:with-param name="height" select="attributes/attribute[@name='height']"/>
															<xsl:with-param name="maxwidth">55</xsl:with-param>
															<xsl:with-param name="maxheight">60</xsl:with-param>
															<xsl:with-param name="imgURL"><xsl:value-of select="/XMLData/MISCData/attributes/attribute[@name='CONTEXT_URL']"/>/GetAsset?primaryKey=<xsl:value-of select="primary_key"/>&amp;type=t</xsl:with-param>
															<xsl:with-param name="mm" select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_mm']"/>
														</xsl:call-template>
													</fo:block>
												</fo:table-cell>
												<fo:table-cell>
													<fo:block>
													<fo:table table-layout="fixed" font-size="9pt">
														<fo:table-column column-number="1" column-width="12mm" />
														<fo:table-column column-number="2" column-width="115mm" />
														<fo:table-body>
															<fo:table-row>
																<fo:table-cell padding-left=".5mm" padding-right=".5mm">
																	<fo:block font-weight="bold" text-align="right">
																		<xsl:value-of select="attributes/attribute[@name='PRINT_Version']"/>
																	</fo:block>
																</fo:table-cell>
																<fo:table-cell >
																	<fo:block>
																		<xsl:value-of select="substring(primary_key,9,16)" />
																	</fo:block>
																</fo:table-cell>
															</fo:table-row>
															<fo:table-row>
																<fo:table-cell padding-left=".5mm" padding-right=".5mm" >
																	<fo:block font-weight="bold" text-align="right">
																		<xsl:value-of select="attributes/attribute[@name='PRINT_Notes']"/>
																	</fo:block>
																</fo:table-cell>
																<fo:table-cell>
																	<fo:block>
																		<xsl:value-of select="attributes/attribute[@name='NOTES']"/>
																	</fo:block>
																</fo:table-cell>
															</fo:table-row>
															<fo:table-row>
																<fo:table-cell padding-left=".5mm" padding-right=".5mm">
																	<fo:block font-weight="bold" text-align="right">
																		<xsl:value-of select="attributes/attribute[@name='PRINT_Created']"/>
																	</fo:block>
																</fo:table-cell>
																<fo:table-cell>
																	<fo:block>
																		<xsl:value-of select="attributes/attribute[@name='CREATION_STAMP_STR']"/>
																	</fo:block>
																</fo:table-cell>
															</fo:table-row>
															<fo:table-row>
																<fo:table-cell padding-left=".5mm" padding-right=".5mm">
																	<fo:block font-weight="bold" text-align="right">
																		<xsl:value-of select="attributes/attribute[@name='PRINT_Modified']"/>
																	</fo:block>
																</fo:table-cell>
																<fo:table-cell>
																	<fo:block>
																		<xsl:value-of select="attributes/attribute[@name='UPDATE_STAMP_STR']"/>
																	</fo:block>
																</fo:table-cell>
															</fo:table-row>
														</fo:table-body>
													</fo:table>
													</fo:block>
												</fo:table-cell>
											</fo:table-row>
											<fo:table-row>
												<fo:table-cell number-columns-spanned="2" padding-top="2mm" padding-bottom="2mm" >
													<fo:block border-after-style="solid" border-after-width="thin" />
												</fo:table-cell>
											</fo:table-row>
											</xsl:for-each>
										</fo:table-body>
									</fo:table>
								</fo:block>
								</xsl:if>

								<!-- insert Usage history -->
								<xsl:if test="attributes/attribute[@name='asset_usage']/XMLDataObjects/XMLDataObject">
									<!-- insert tabular Usage history -->
									<xsl:call-template name="includetabularhistory" />
								</xsl:if>

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
