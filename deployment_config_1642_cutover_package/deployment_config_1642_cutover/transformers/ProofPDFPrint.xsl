<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:svg="http://www.w3.org/2000/svg">
	<xsl:output method="xml" version="1.0" encoding="UTF-8"/>

	<!-- template used to strip leading zeros -->
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
						<xsl:attribute name="height"><xsl:value-of select="$maxheight"/><xsl:value-of select="$mm"/></xsl:attribute>
						<xsl:attribute name="width"><xsl:value-of select="$maxwidth"/><xsl:value-of select="$mm"/></xsl:attribute>
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
				<xsl:value-of select="attributes/attribute[@name='PRINT_Issue']"/><xsl:text>:</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="attributes/attribute[@name='PRINT_Date']"/><xsl:text>:</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!-- template used to insert Notices -->
	<xsl:template name="includenotices">
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

			<!-- include Caution message -->
			<xsl:if test="string-length(attributes/attribute[@name='Caution_msg']) &gt; 0">
				<fo:block font-size="10pt" font-weight="bold" background-color="red" color="white">
					<xsl:value-of select="attributes/attribute[@name='PRINT_Caution']"/>
				</fo:block>
				<fo:block font-size="10pt" space-after="5mm" background-color="green">
					<xsl:value-of select="attributes/attribute[@name='Caution_msg']"/>
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
					<xsl:value-of select="attributes/attribute[@name='PRINT_Corrections']"/>
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
	</xsl:template>

	<!-- template used to insert usage history -->
	<xsl:template name="includehistory">
		<fo:block>
			<fo:table table-layout="fixed" font-size="10pt">
				<fo:table-column column-number="1" column-width="12mm" />
				<fo:table-column column-number="2" column-width="50mm" />
				<fo:table-column column-number="3" column-width="12mm" />
				<fo:table-column column-number="4" column-width="40mm" />
				<fo:table-column column-number="5" column-width="17mm" />
				<fo:table-column column-number="6" column-width="23mm" />
				<fo:table-column column-number="7" column-width="14mm" />
				<fo:table-column column-number="8" column-width="20mm" />
				<fo:table-body>
				<xsl:for-each select="attributes/attribute[@name='asset_usage']/XMLDataObjects/XMLDataObject">
					<fo:table-row>
						<!-- publication title -->
						<fo:table-cell font-weight="bold">
							<fo:block>
								<xsl:value-of select="attributes/attribute[@name='PRINT_Title']"/>:
							</fo:block>
						</fo:table-cell>
						<fo:table-cell >
							<fo:block>
								<xsl:value-of select="attributes/attribute[@name='__PUBLICATION_DISPLAY_TITLE']"/>
							</fo:block>
						</fo:table-cell>

						<!-- publication date -->
						<fo:table-cell font-weight="bold">
							<fo:block>
								<xsl:value-of select="attributes/attribute[@name='PRINT_Date']"/>:
							</fo:block>
						</fo:table-cell>
						<fo:table-cell>
							<fo:block>
								<xsl:value-of select="attributes/attribute[@name='PUBLICATION_DATE_STR']"/>
							</fo:block>
						</fo:table-cell>

						<!-- publication edition -->
						<fo:table-cell font-weight="bold">
							<fo:block>
								<xsl:value-of select="attributes/attribute[@name='PRINT_Edition']"/>:
							</fo:block>
						</fo:table-cell>
						<fo:table-cell>
							<fo:block>
								<xsl:value-of select="attributes/attribute[@name='PUBLICATION_EDITION']"/>
							</fo:block>
						</fo:table-cell>

						<!-- publication page -->
						<fo:table-cell font-weight="bold">
							<fo:block>
								<xsl:value-of select="attributes/attribute[@name='PRINT_Page']"/>:
							</fo:block>
						</fo:table-cell>
						<fo:table-cell>
							<fo:block>
								<xsl:value-of select="attributes/attribute[@name='PUBLICATION_PAGE']"/>
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
				<fo:simple-page-master master-name="PageMaster" page-height="11.69in" page-width="8.26in" margin-top="1cm" margin-bottom="5mm" margin-left="1cm" margin-right="1cm">
					<fo:region-body margin-bottom="12mm"/>
					<fo:region-before />
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

						<xsl:choose>

							<!-- Deleted asset -->

							<xsl:when test="contains('deleted', state)">

									<!-- insert primary key -->
								<fo:block text-align="center" font-weight="bold" font-size="12pt">
									<xsl:value-of select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_Proof_print']"/>
									<xsl:call-template name="stripzeroes">
										<xsl:with-param name="text" select="substring(primary_key,13,16)"/>
									</xsl:call-template>
								</fo:block>

								<fo:block space-before="7mm" space-after="5mm" border-after-style="solid" border-after-width="thin" />

								<fo:block text-align="center" font-weight="bold" font-size="12pt">
									<xsl:value-of select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_ASSET_DELETED']"/>
								</fo:block>
							</xsl:when>

							<!-- PICTURE asset -->

							<xsl:when test="contains('PICTURE', primary_key/@type)">

								<!-- insert primary key -->
								<fo:block text-align="center" font-weight="bold" font-size="12pt">
									<xsl:value-of select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_Proof_print_of']"/> <xsl:value-of select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_picture']"/>
									<xsl:call-template name="stripzeroes">
										<xsl:with-param name="text" select="substring(primary_key,13,16)"/>
									</xsl:call-template>
								</fo:block>

								<fo:block space-before="7mm" space-after="5mm" border-after-style="solid" border-after-width="thin" />

								<!-- insert asset picture -->
								<fo:block text-align="center">
									<xsl:call-template name="generateimagetag">
										<xsl:with-param name="width" select="attributes/attribute[@name='width']"/>
										<xsl:with-param name="height" select="attributes/attribute[@name='height']"/>
										<xsl:with-param name="maxwidth">170</xsl:with-param>
										<xsl:with-param name="maxheight">150</xsl:with-param>
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
								<fo:block space-before="1mm" text-align="center" font-size="10pt">
									<xsl:value-of select="attributes/attribute[@name='colourspace']"/>,
									<xsl:value-of select="attributes/attribute[@name='fftype']"/>,
									<xsl:value-of select="attributes/attribute[@name='filesize']"/> <xsl:value-of select="attributes/attribute[@name='PRINT_bytes']"/>,
									<xsl:value-of select="attributes/attribute[@name='width']"/><xsl:value-of select="attributes/attribute[@name='PRINT_w']"/> x <xsl:value-of select="attributes/attribute[@name='height']"/><xsl:value-of select="attributes/attribute[@name='PRINT_h']"/>,
									<xsl:value-of select="attributes/attribute[@name='vres']"/> x <xsl:value-of select="attributes/attribute[@name='hres']"/> <xsl:value-of select="attributes/attribute[@name='PRINT_dpi']"/>
								</fo:block>

								<fo:block space-before="5mm" space-after="5mm" border-after-style="solid" border-after-width="thin" />

								<!-- insert Notices -->
								<xsl:call-template name="includenotices" />

								<!-- insert asset meta -->
								<fo:block>
									<fo:table table-layout="fixed" font-size="10pt">
										<fo:table-column column-number="1" column-width="30mm" />
										<fo:table-column column-number="2" column-width="65mm" />
										<fo:table-column column-number="3" column-width="30mm" />
										<fo:table-column column-number="4" column-width="65mm" />
										<fo:table-body>
											<!-- Customisation Start -->
											<fo:table-row>
												<fo:table-cell padding-right=".5mm">
													<fo:block font-weight="bold" text-align="right">
														Cost Indicator
													</fo:block>
												</fo:table-cell>
												<fo:table-cell>
													<fo:block>
														<xsl:value-of select="specialist/XMLDataObject[@type='TMG_RIGHTS']/attributes/attribute[@name='COSTGROUPA']"/>
													</fo:block>
												</fo:table-cell>
											<!-- Customisation End -->
										
												<!-- Owner -->
												<fo:table-cell padding-left=".5mm" padding-right=".5mm">
													<fo:block font-weight="bold" text-align="right">
														<xsl:value-of select="attributes/attribute[@name='PRINT_Owner']"/>
													</fo:block>
												</fo:table-cell>
												<fo:table-cell>
													<fo:block>
														<xsl:value-of select="attributes/attribute[@name='DISPLAY_OWNER_ID']"/>
													</fo:block>
												</fo:table-cell>
											</fo:table-row>

											<fo:table-row>
												<!-- eURN -->
												<fo:table-cell padding-left=".5mm" padding-right=".5mm">
													<fo:block font-weight="bold" text-align="right">
														<xsl:value-of select="attributes/attribute[@name='PRINT_eURN']"/>
													</fo:block>
												</fo:table-cell>
												<fo:table-cell>
													<fo:block>
														<xsl:value-of select="attributes/attribute[@name='XURN']"/>
													</fo:block>
												</fo:table-cell>

												<!-- created -->
												<fo:table-cell padding-left=".5mm" padding-right=".5mm">
													<fo:block font-weight="bold" text-align="right">
														<xsl:value-of select="attributes/attribute[@name='PRINT_Date_loaded']"/>
													</fo:block>
												</fo:table-cell>
												<fo:table-cell>
													<fo:block>
														<xsl:value-of select="attributes/attribute[@name='CREATION_STAMP_STR']"/>
													</fo:block>
												</fo:table-cell>
											</fo:table-row>

											<fo:table-row>
												<!-- photographer -->
												<fo:table-cell padding-left=".5mm" padding-right=".5mm">
													<fo:block font-weight="bold" text-align="right">
														<xsl:value-of select="attributes/attribute[@name='PRINT_Photographer']"/>
													</fo:block>
												</fo:table-cell>
												<fo:table-cell>
													<fo:block>
														<xsl:value-of select="attributes/attribute[@name='PHOTOGRAPHER']"/>
													</fo:block>
												</fo:table-cell>

												<!-- copyright -->
												<fo:table-cell padding-left=".5mm" padding-right=".5mm">
													<fo:block font-weight="bold" text-align="right">
														<xsl:value-of select="attributes/attribute[@name='PRINT_Copyright']"/>
													</fo:block>
												</fo:table-cell>
												<fo:table-cell>
													<fo:block>
														<xsl:value-of select="attributes/attribute[@name='COPYRIGHT']"/>
													</fo:block>
												</fo:table-cell>
											</fo:table-row>

											<fo:table-row>
												<!-- provider -->
												<fo:table-cell padding-left=".5mm" padding-right=".5mm">
													<fo:block font-weight="bold" text-align="right">
														<xsl:value-of select="attributes/attribute[@name='PRINT_Provider']"/>
													</fo:block>
												</fo:table-cell>
												<fo:table-cell>
													<fo:block>
														<xsl:value-of select="attributes/attribute[@name='PROVIDER']"/>
													</fo:block>
												</fo:table-cell>

												<!-- Date Taken -->
												<fo:table-cell padding-left=".5mm" padding-right=".5mm">
													<fo:block font-weight="bold" text-align="right">
														<xsl:value-of select="attributes/attribute[@name='PRINT_Taken_on']"/>
													</fo:block>
												</fo:table-cell>
												<fo:table-cell>
													<fo:block>
														<xsl:value-of select="attributes/attribute[@name='PICTURE_DATE_STR']"/>
													</fo:block>
												</fo:table-cell>
											</fo:table-row>

											<fo:table-row>
												<!-- Caption -->
												<fo:table-cell padding-left=".5mm" padding-right=".5mm">
													<fo:block font-weight="bold" text-align="right">
														<xsl:value-of select="attributes/attribute[@name='PRINT_Caption']"/>
													</fo:block>
												</fo:table-cell>
												<fo:table-cell number-columns-spanned="3">
													<fo:block>
														<xsl:value-of select="attributes/attribute[@name='CAPTION']"/>
													</fo:block>
												</fo:table-cell>
											</fo:table-row>
										</fo:table-body>
									</fo:table>
								</fo:block>

								<fo:block space-before="5mm" space-after="5mm" border-after-style="solid" border-after-width="thin" />



							</xsl:when>

							<!-- PAGE asset -->

							<xsl:when test="contains('PAGE', primary_key/@type)">

							<!-- insert primary key -->
								<fo:block text-align="center" font-weight="bold" font-size="12pt">
									<xsl:value-of select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_Proof_print_of']"/> <xsl:value-of select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_page']"/>
									<xsl:call-template name="stripzeroes">
										<xsl:with-param name="text" select="substring(primary_key,13,16)"/>
									</xsl:call-template>
								</fo:block>

								<fo:block space-before="7mm" space-after="5mm" border-after-style="solid" border-after-width="thin" />

								<xsl:choose>
									<xsl:when test="attributes/attribute[@name='PAGE_DISPLAY_TYPE'] = 'version'">
										<fo:block text-align="center" background-color="#FFE79D" margin-top="20mm" margin-bottom="20mm" margin-left="60mm" margin-right="60mm">
										<xsl:call-template name="generateimagetag">
											<xsl:with-param name="width" select="attributes/attribute[@name='width']"/>
											<xsl:with-param name="height" select="attributes/attribute[@name='height']"/>
											<xsl:with-param name="maxwidth">170</xsl:with-param>
											<xsl:with-param name="maxheight">150</xsl:with-param>
											<xsl:with-param name="imgURL"><xsl:value-of select="/XMLData/MISCData/attributes/attribute[@name='CONTEXT_URL']"/>/GetAsset?primaryKey=<xsl:value-of select="attributes/attribute[@name='PAGE_DISPLAY_KEY']"/>&amp;type=p</xsl:with-param>
											<xsl:with-param name="mm" select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_mm']"/>
										</xsl:call-template>

									</fo:block>
									</xsl:when>
									<xsl:otherwise>
										<fo:block text-align="center" >
										<xsl:call-template name="generateimagetag">
											<xsl:with-param name="width" select="attributes/attribute[@name='width']"/>
											<xsl:with-param name="height" select="attributes/attribute[@name='height']"/>
											<xsl:with-param name="maxwidth">170</xsl:with-param>
											<xsl:with-param name="maxheight">150</xsl:with-param>
											<xsl:with-param name="imgURL"><xsl:value-of select="/XMLData/MISCData/attributes/attribute[@name='CONTEXT_URL']"/>/GetAsset?primaryKey=<xsl:value-of select="attributes/attribute[@name='PAGE_DISPLAY_KEY']"/>&amp;type=p</xsl:with-param>
											<xsl:with-param name="mm" select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_mm']"/>
										</xsl:call-template>

									</fo:block>
									</xsl:otherwise>
								</xsl:choose>

								<!-- insert picture properties -->
								<fo:block space-before="1mm" text-align="center" font-size="10pt">
									<xsl:value-of select="concat(attributes/attribute[@name='fftype'], ' ')"/>
									<xsl:value-of select="attributes/attribute[@name='ffcategory']"/>,
									<!-- uncomment to include maccreator
									<xsl:if test="string-length(attributes/attribute[@name='maccreator']) &gt; 0">
										(<xsl:value-of select="attributes/attribute[@name='maccreator']"/>)
									</xsl:if>
									-->

									<xsl:value-of select="attributes/attribute[@name='filesize']"/> <xsl:value-of select="attributes/attribute[@name='PRINT_bytes']"/>;
								</fo:block>

								<fo:block space-before="5mm" space-after="5mm" border-after-style="solid" border-after-width="thin" />

								<!-- insert Usage history -->
								<fo:block>
									<fo:table table-layout="fixed" font-size="10pt">
										<fo:table-column column-number="1" column-width="12mm" />
										<fo:table-column column-number="2" column-width="50mm" />
										<fo:table-column column-number="3" column-width="12mm" />
										<fo:table-column column-number="4" column-width="40mm" />
										<fo:table-column column-number="5" column-width="17mm" />
										<fo:table-column column-number="6" column-width="23mm" />
										<fo:table-column column-number="7" column-width="14mm" />
										<fo:table-column column-number="8" column-width="20mm" />
										<fo:table-body>
											<fo:table-row>
												<!-- publication title -->
												<fo:table-cell font-weight="bold">
													<fo:block>
														<xsl:value-of select="attributes/attribute[@name='PRINT_Title']"/>:
													</fo:block>
												</fo:table-cell>
												<fo:table-cell >
													<fo:block>
														<xsl:value-of select="attributes/attribute[@name='PUBLICATION_TITLE']"/>
													</fo:block>
												</fo:table-cell>

												<!-- publication date -->
												<fo:table-cell font-weight="bold">
													<fo:block>
														<xsl:call-template name="geteditiondateorissuelabel">
															<xsl:with-param name="pubDate" select="attributes/attribute[@name='PUBLICATION_DATE_STR']"/>
															<xsl:with-param name="pubIssue" select="attributes/attribute[@name='PUBLICATION_ISSUE_NAME']"/>
														</xsl:call-template>
													</fo:block>
												</fo:table-cell>
												<fo:table-cell>
													<fo:block>
														<xsl:call-template name="geteditiondateorissue">
															<xsl:with-param name="pubDate" select="attributes/attribute[@name='PUBLICATION_DATE_STR']"/>
															<xsl:with-param name="pubIssue" select="attributes/attribute[@name='PUBLICATION_ISSUE_NAME']"/>
															<xsl:with-param name="pubYear" select="attributes/attribute[@name='PUBLICATION_ISSUE_YEAR']"/>
														</xsl:call-template>
													</fo:block>
												</fo:table-cell>

												<!-- publication edition -->
												<fo:table-cell font-weight="bold">
													<fo:block>
														<xsl:value-of select="attributes/attribute[@name='PRINT_Edition']"/>:
													</fo:block>
												</fo:table-cell>
												<fo:table-cell>
													<fo:block>
														<xsl:value-of select="attributes/attribute[@name='PUBLICATION_EDITION']"/>
													</fo:block>
												</fo:table-cell>

												<!-- publication page -->
												<fo:table-cell font-weight="bold">
													<fo:block>
														<xsl:value-of select="attributes/attribute[@name='PRINT_Page']"/>:
													</fo:block>
												</fo:table-cell>
												<fo:table-cell>
													<fo:block>
														<xsl:value-of select="attributes/attribute[@name='PUBLICATION_PAGE']"/>
													</fo:block>
												</fo:table-cell>
											</fo:table-row>
										</fo:table-body>
									</fo:table>
								</fo:block>

								<fo:block space-before="7mm" space-after="5mm" border-after-style="solid" border-after-width="thin" />

								<!-- insert Notices -->
								<xsl:call-template name="includenotices" />

							</xsl:when>

							<!-- STORY asset -->

							<xsl:when test="contains('STORY', primary_key/@type)">

								<!-- insert primary key -->
								<fo:block text-align="center" font-weight="bold" font-size="12pt">
									<xsl:value-of select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_Proof_print_of']"/> <xsl:value-of select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_story']"/>
									<xsl:call-template name="stripzeroes">
										<xsl:with-param name="text" select="substring(primary_key,13,16)"/>
									</xsl:call-template>
								</fo:block>

								<fo:block space-before="7mm" space-after="5mm" border-after-style="solid" border-after-width="thin" />

								<!-- if story PDF is present then indent first 5 paragraph of the story text -->
								<xsl:choose>
								<xsl:when test="(count(attributes/attribute[@name='PAGE_DISPLAY_EXIST']) &gt; 0) and (contains('yes', attributes/attribute[@name='PAGE_DISPLAY_EXIST']))">
									<fo:table table-layout="fixed" font-size="10pt">
										<fo:table-column column-number="1" column-width="130mm" />
										<fo:table-column column-number="2" column-width="200mm" />
										<fo:table-body>
											<fo:table-row>
												<fo:table-cell>
													<fo:block>
														<fo:table table-layout="fixed" font-size="10pt">
															<fo:table-column column-number="1" column-width="25mm" />
															<fo:table-column column-number="2" column-width="165mm" />
															<fo:table-body>
																<fo:table-row>
																	<fo:table-cell number-columns-spanned="2" padding-left=".5mm" padding-right=".5mm">
																		<fo:block>
																			<fo:inline font-weight="bold"> <xsl:value-of select="attributes/attribute[@name='PRINT_Title']"/></fo:inline>
																			<xsl:value-of select="attributes/attribute[@name='asset_usage']/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='__PUBLICATION_DISPLAY_TITLE']"/>
																			<xsl:choose>
																				<xsl:when test="attributes/attribute[@name='asset_usage']/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='__PUBLICATION_TYPE'] = 'issue'">
																					<fo:inline font-weight="bold"> <xsl:value-of select="attributes/attribute[@name='PRINT_Issue']"/> </fo:inline>
																					<xsl:value-of select="attributes/attribute[@name='asset_usage']/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PUBLICATION_ISSUE']"/>
																					<xsl:text> </xsl:text>
																					<xsl:value-of select="attributes/attribute[@name='asset_usage']/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='ISSUE_YEAR']"/>
																				</xsl:when>
																				<xsl:otherwise>
																					<fo:inline font-weight="bold"> <xsl:value-of select="attributes/attribute[@name='PRINT_Date']"/> </fo:inline>
																					<xsl:value-of select="attributes/attribute[@name='asset_usage']/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PUBLICATION_DATE_STR']"/>
																				</xsl:otherwise>
																			</xsl:choose>
																			<fo:inline font-weight="bold"> <xsl:value-of select="attributes/attribute[@name='PRINT_Edition']"/> </fo:inline>
																			<xsl:value-of select="attributes/attribute[@name='asset_usage']/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PUBLICATION_EDITION']"/>
																			<fo:inline font-weight="bold"> <xsl:value-of select="attributes/attribute[@name='PRINT_Page']"/> </fo:inline>
																			<xsl:value-of select="attributes/attribute[@name='asset_usage']/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PUBLICATION_PAGE']"/>
																		</fo:block>
																	</fo:table-cell>
																</fo:table-row>
																<fo:table-row>
																	<fo:table-cell padding-left=".5mm" padding-right=".5mm">
																		<fo:block font-weight="bold">
																			<xsl:value-of select="attributes/attribute[@name='PRINT_Owner']"/>
																		</fo:block>
																	</fo:table-cell>
																	<fo:table-cell>
																		<fo:block>
																			<xsl:value-of select="attributes/attribute[@name='DISPLAY_OWNER_ID']"/>
																		</fo:block>
																	</fo:table-cell>
																</fo:table-row>
																<fo:table-row>
																	<fo:table-cell padding-left=".5mm" padding-right=".5mm">
																		<fo:block font-weight="bold">
																			<xsl:value-of select="attributes/attribute[@name='PRINT_Byline']"/>
																		</fo:block>
																	</fo:table-cell>
																	<fo:table-cell>
																		<fo:block>
																			<xsl:value-of select="attributes/attribute[@name='BYLINE']"/>
																		</fo:block>
																	</fo:table-cell>
																</fo:table-row>
																<fo:table-row>
																	<fo:table-cell padding-left=".5mm" padding-right=".5mm">
																		<fo:block font-weight="bold">
																			<xsl:value-of select="attributes/attribute[@name='PRINT_Headline']"/>
																		</fo:block>
																	</fo:table-cell>
																	<fo:table-cell>
																		<fo:block>
																			<xsl:value-of select="attributes/attribute[@name='HEADLINE']"/>
																		</fo:block>
																	</fo:table-cell>
																</fo:table-row>
																<fo:table-row>
																	<fo:table-cell padding-left=".5mm" padding-right=".5mm">
																		<fo:block font-weight="bold">
																			<xsl:value-of select="attributes/attribute[@name='PRINT_Sub_Heading']"/>
																		</fo:block>
																	</fo:table-cell>
																	<fo:table-cell>
																		<fo:block>
																			<xsl:value-of select="attributes/attribute[@name='SUBHEADING']"/>
																		</fo:block>
																	</fo:table-cell>
																</fo:table-row>
																<fo:table-row>
																	<fo:table-cell padding-left=".5mm" padding-right=".5mm">
																		<fo:block font-weight="bold">
																			<xsl:value-of select="attributes/attribute[@name='PRINT_Keywords']"/>
																		</fo:block>
																	</fo:table-cell>
																	<fo:table-cell>
																		<fo:block>
																			<xsl:value-of select="attributes/attribute[@name='KEYWORDS']"/>
																		</fo:block>
																	</fo:table-cell>
																</fo:table-row>
															</fo:table-body>
														</fo:table>
													</fo:block>

													<fo:block></fo:block>

													<fo:block space-before="2mm" space-after="2mm"/>

													<!-- insert story text -->
													<xsl:for-each select="attributes/attribute[@name='STORY']/p">
													<xsl:if test="position() &lt; 5">
													<fo:block space-after="3mm" font-size="10pt">
													<xsl:value-of select="."/>
													</fo:block>
													</xsl:if>
													</xsl:for-each>
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
									<!-- insert story text -->
									<xsl:for-each select="attributes/attribute[@name='STORY']/p">
										<xsl:if test="position() &gt; 4">
											<fo:block space-after="3mm" font-size="10pt">
												<xsl:value-of select="."/>
											</fo:block>
										</xsl:if>
									</xsl:for-each>

								</xsl:when>

							<xsl:otherwise>

									<fo:block>
										<fo:table table-layout="fixed" font-size="10pt">
											<fo:table-column column-number="1" column-width="25mm" />
											<fo:table-column column-number="2" column-width="165mm" />
											<fo:table-body>
											<xsl:for-each select="attributes/attribute[@name='asset_usage']/XMLDataObjects/XMLDataObject">
												<fo:table-row>
													<fo:table-cell number-columns-spanned="2" padding-left=".5mm" padding-right=".5mm">
														<fo:block>
															<fo:inline font-weight="bold"> <xsl:value-of select="attributes/attribute[@name='PRINT_Title']"/> </fo:inline>
															<xsl:value-of select="attributes/attribute[@name='__PUBLICATION_DISPLAY_TITLE']"/>
															<xsl:choose>
																<xsl:when test="attributes/attribute[@name='__PUBLICATION_TYPE'] = 'issue'">
																	<fo:inline font-weight="bold"> <xsl:value-of select="attributes/attribute[@name='PRINT_Issue']"/> </fo:inline>
																	<xsl:value-of select="attributes/attribute[@name='PUBLICATION_ISSUE']"/>
																	<xsl:text> </xsl:text>
																	<xsl:value-of select="attributes/attribute[@name='ISSUE_YEAR']"/>
																</xsl:when>
																<xsl:otherwise>
																	<fo:inline font-weight="bold"> <xsl:value-of select="attributes/attribute[@name='PRINT_Date']"/> </fo:inline>
																	<xsl:value-of select="attributes/attribute[@name='PUBLICATION_DATE_STR']"/>
																</xsl:otherwise>
															</xsl:choose>
															<fo:inline font-weight="bold"> <xsl:value-of select="attributes/attribute[@name='PRINT_Edition']"/> </fo:inline>
															<xsl:value-of select="attributes/attribute[@name='PUBLICATION_EDITION']"/>
															<fo:inline font-weight="bold"> <xsl:value-of select="attributes/attribute[@name='PRINT_Page']"/> </fo:inline>
															<xsl:value-of select="attributes/attribute[@name='PUBLICATION_PAGE']"/>
														</fo:block>
													</fo:table-cell>
												</fo:table-row>
											</xsl:for-each>
												<fo:table-row>
													<fo:table-cell padding-left=".5mm" padding-right=".5mm">
														<fo:block font-weight="bold">
															<xsl:value-of select="attributes/attribute[@name='PRINT_Owner']"/>
														</fo:block>
													</fo:table-cell>
													<fo:table-cell>
														<fo:block>
															<xsl:value-of select="attributes/attribute[@name='DISPLAY_OWNER_ID']"/>
														</fo:block>
													</fo:table-cell>
												</fo:table-row>
												<fo:table-row>
													<fo:table-cell padding-left=".5mm" padding-right=".5mm">
														<fo:block font-weight="bold">
															<xsl:value-of select="attributes/attribute[@name='PRINT_Byline']"/>
														</fo:block>
													</fo:table-cell>
													<fo:table-cell>
														<fo:block>
															<xsl:value-of select="attributes/attribute[@name='BYLINE']"/>
														</fo:block>
													</fo:table-cell>
												</fo:table-row>
												<fo:table-row>
													<fo:table-cell padding-left=".5mm" padding-right=".5mm">
														<fo:block font-weight="bold">
															<xsl:value-of select="attributes/attribute[@name='PRINT_Headline']"/>
														</fo:block>
													</fo:table-cell>
													<fo:table-cell>
														<fo:block>
															<xsl:value-of select="attributes/attribute[@name='HEADLINE']"/>
														</fo:block>
													</fo:table-cell>
												</fo:table-row>
												<fo:table-row>
													<fo:table-cell padding-left=".5mm" padding-right=".5mm">
														<fo:block font-weight="bold">
															<xsl:value-of select="attributes/attribute[@name='PRINT_Sub_Heading']"/>
														</fo:block>
													</fo:table-cell>
													<fo:table-cell>
														<fo:block>
															<xsl:value-of select="attributes/attribute[@name='SUBHEADING']"/>
														</fo:block>
													</fo:table-cell>
												</fo:table-row>
												<fo:table-row>
													<fo:table-cell padding-left=".5mm" padding-right=".5mm">
														<fo:block font-weight="bold">
															<xsl:value-of select="attributes/attribute[@name='PRINT_Keywords']"/>
														</fo:block>
													</fo:table-cell>
													<fo:table-cell>
														<fo:block>
															<xsl:value-of select="attributes/attribute[@name='KEYWORDS']"/>
														</fo:block>
													</fo:table-cell>
												</fo:table-row>
											</fo:table-body>
										</fo:table>
									</fo:block>

									<fo:block space-before="2mm" space-after="2mm"/>

									<!-- insert story text -->
									<xsl:for-each select="attributes/attribute[@name='STORY']/p">
											<fo:block space-after="3mm" font-size="10pt">
											<xsl:value-of select="."/>
										</fo:block>
										</xsl:for-each>

								</xsl:otherwise>
								</xsl:choose>

								<fo:block space-before="5mm" space-after="5mm" border-after-style="solid" border-after-width="thin" />

								<!-- insert Notices -->
								<xsl:call-template name="includenotices" />

								<!-- insert asset meta -->
								<fo:block>
									<fo:table table-layout="fixed" font-size="10pt">
										<fo:table-column column-number="1" column-width="30mm" />
										<fo:table-column column-number="2" column-width="100mm" />
										<fo:table-column column-number="3" column-width="20mm" />
										<fo:table-column column-number="4" column-width="40mm" />
										<fo:table-body>

											<fo:table-row>
												<!-- source title -->
												<fo:table-cell padding-left=".5mm" padding-right=".5mm">
													<fo:block font-weight="bold" text-align="right">
														<xsl:value-of select="attributes/attribute[@name='PRINT_Load_source']"/>
													</fo:block>
												</fo:table-cell>
												<fo:table-cell>
													<fo:block>
														<xsl:value-of select="attributes/attribute[@name='SOURCE']"/>
													</fo:block>
												</fo:table-cell>

												<!-- Words -->
												<fo:table-cell padding-left=".5mm" padding-right=".5mm">
													<fo:block font-weight="bold" text-align="right">
														<xsl:value-of select="attributes/attribute[@name='PRINT_Words']"/>
													</fo:block>
												</fo:table-cell>
												<fo:table-cell>
													<fo:block>
														<xsl:value-of select="attributes/attribute[@name='WORD_COUNT']"/>
													</fo:block>
												</fo:table-cell>
											</fo:table-row>

											<fo:table-row>
												<!-- external ref -->
												<fo:table-cell padding-left=".5mm" padding-right=".5mm">
													<fo:block font-weight="bold" text-align="right">
														<xsl:value-of select="attributes/attribute[@name='PRINT_External_ref']"/>
													</fo:block>
												</fo:table-cell>
												<fo:table-cell number-columns-spanned="3">
													<fo:block>
														<xsl:value-of select="attributes/attribute[@name='EXTERNAL_REF']"/>
													</fo:block>
												</fo:table-cell>
											</fo:table-row>

											<fo:table-row>
												<!-- Caption -->
												<fo:table-cell padding-left=".5mm" padding-right=".5mm">
													<fo:block font-weight="bold" text-align="right">
														<xsl:value-of select="attributes/attribute[@name='PRINT_Caption']"/>
													</fo:block>
												</fo:table-cell>
												<fo:table-cell number-columns-spanned="3">
													<fo:block>
														<xsl:value-of select="attributes/attribute[@name='CAPTION']"/>
													</fo:block>
												</fo:table-cell>
											</fo:table-row>

											<fo:table-row>
												<!-- Date loaded -->
												<fo:table-cell padding-left=".5mm" padding-right=".5mm">
													<fo:block font-weight="bold" text-align="right">
														<xsl:value-of select="attributes/attribute[@name='PRINT_Date_loaded']"/>
													</fo:block>
												</fo:table-cell>
												<fo:table-cell>
													<fo:block>
														<xsl:value-of select="attributes/attribute[@name='CREATION_STAMP_STR']"/>
													</fo:block>
												</fo:table-cell>

												<!-- Modified -->
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

											<fo:table-row>
												<!-- loaded from -->
												<fo:table-cell padding-left=".5mm" padding-right=".5mm">
													<fo:block font-weight="bold" text-align="right">
														<xsl:value-of select="attributes/attribute[@name='PRINT_Original_filename']"/>
													</fo:block>
												</fo:table-cell>
												<fo:table-cell number-columns-spanned="3">
													<fo:block>
														<xsl:value-of select="attributes/attribute[@name='FILE_NAME']"/>
													</fo:block>
												</fo:table-cell>
											</fo:table-row>

											<fo:table-row>
												<!-- load path -->
												<fo:table-cell padding-left=".5mm" padding-right=".5mm">
													<fo:block font-weight="bold" text-align="right">
														<xsl:value-of select="attributes/attribute[@name='PRINT_Loaded_from']"/>
													</fo:block>
												</fo:table-cell>
												<fo:table-cell number-columns-spanned="3">
													<fo:block>
														<xsl:value-of select="attributes/attribute[@name='FULL_PATH']"/>
													</fo:block>
												</fo:table-cell>
											</fo:table-row>
										</fo:table-body>
									</fo:table>
								</fo:block>

								<fo:block space-before="5mm" space-after="5mm" border-after-style="solid" border-after-width="thin" />
							</xsl:when>

							<!-- Document asset -->

							<xsl:when test="contains('DOCUMENT', primary_key/@type)">

								<!-- insert primary key -->
								<fo:block text-align="center" font-weight="bold" font-size="12pt">
									<xsl:value-of select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_Proof_print_of']"/> <xsl:value-of select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_document']"/>
									<xsl:call-template name="stripzeroes">
										<xsl:with-param name="text" select="substring(primary_key,13,16)"/>
									</xsl:call-template>
								</fo:block>

								<fo:block space-before="7mm" space-after="5mm" border-after-style="solid" border-after-width="thin" />

								<!-- insert document preview -->
								<fo:block text-align="center">
									<xsl:call-template name="generateimagetag">
										<xsl:with-param name="width" select="attributes/attribute[@name='width']"/>
										<xsl:with-param name="height" select="attributes/attribute[@name='height']"/>
										<xsl:with-param name="maxwidth">170</xsl:with-param>
										<xsl:with-param name="maxheight">150</xsl:with-param>
										<xsl:with-param name="imgURL">
											<xsl:choose>
												<xsl:when test="attributes/attribute[@name='has_Preview_Privilege']='true'"><xsl:value-of select="/XMLData/MISCData/attributes/attribute[@name='CONTEXT_URL']"/>/GetAsset?primaryKey=<xsl:value-of select="primary_key"/>&amp;type=p</xsl:when>
												<xsl:otherwise><xsl:value-of select="/XMLData/MISCData/attributes/attribute[@name='CONTEXT_URL']"/>/GetAsset?primaryKey=<xsl:value-of select="primary_key"/>&amp;type=t</xsl:otherwise>
											</xsl:choose>
										</xsl:with-param>
										<xsl:with-param name="mm" select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_mm']"/>
									</xsl:call-template>
								</fo:block>

								<!-- insert document properties -->
								<fo:block space-before="1mm" text-align="center" font-size="10pt">
									<xsl:value-of select="attributes/attribute[@name='fftype']"/>,
									<xsl:value-of select="attributes/attribute[@name='filesize']"/> <xsl:value-of select="attributes/attribute[@name='PRINT_bytes']"/>
								</fo:block>

								<fo:block space-before="5mm" space-after="5mm" border-after-style="solid" border-after-width="thin" />

								<!-- insert Notices -->
								<xsl:call-template name="includenotices"/>

								<fo:block>
									<fo:table table-layout="fixed" font-size="10pt">
										<fo:table-column column-number="1" column-width="30mm" />
										<fo:table-column column-number="2" column-width="65mm" />
										<fo:table-column column-number="3" column-width="30mm" />
										<fo:table-column column-number="4" column-width="65mm" />
										<fo:table-body>

											<fo:table-row>
												<!-- Owner -->
												<fo:table-cell padding-left=".5mm" padding-right=".5mm">
													<fo:block font-weight="bold" text-align="right">
														<xsl:value-of select="attributes/attribute[@name='PRINT_Owner']"/>
													</fo:block>
												</fo:table-cell>
												<fo:table-cell  number-columns-spanned="3">
													<fo:block>
														<xsl:value-of select="attributes/attribute[@name='DISPLAY_OWNER_ID']"/>
													</fo:block>
												</fo:table-cell>
											</fo:table-row>

											<fo:table-row>
												<!-- Title -->
												<fo:table-cell padding-left=".5mm" padding-right=".5mm">
													<fo:block font-weight="bold" text-align="right">
														<xsl:value-of select="attributes/attribute[@name='PRINT_Title']"/>
													</fo:block>
												</fo:table-cell>
												<fo:table-cell  number-columns-spanned="3">
													<fo:block>
														<xsl:value-of select="attributes/attribute[@name='TITLE']"/>
													</fo:block>
												</fo:table-cell>
											</fo:table-row>

											<fo:table-row>
												<!-- Description -->
												<fo:table-cell padding-left=".5mm" padding-right=".5mm">
													<fo:block font-weight="bold" text-align="right">
														<xsl:value-of select="attributes/attribute[@name='PRINT_Description']"/>
													</fo:block>
												</fo:table-cell>
												<fo:table-cell  number-columns-spanned="3">
													<fo:block>
														<xsl:value-of select="attributes/attribute[@name='DESCRIPTION']"/>
													</fo:block>
												</fo:table-cell>
											</fo:table-row>

											<fo:table-row>
												<fo:table-cell number-columns-spanned="4" padding-top="5mm" padding-bottom="5mm" >
													<fo:block border-after-style="solid" border-after-width="thin" />
												</fo:table-cell>
											</fo:table-row>

											<fo:table-row>
												<fo:table-cell padding-left=".5mm" padding-right=".5mm">
													<fo:block font-weight="bold" text-align="right">
														<xsl:value-of select="attributes/attribute[@name='PRINT_Creator']"/>
													</fo:block>
												</fo:table-cell>
												<fo:table-cell>
													<fo:block>
														<xsl:value-of select="attributes/attribute[@name='CREATOR']"/>
													</fo:block>
												</fo:table-cell>

												<fo:table-cell padding-left=".5mm" padding-right=".5mm">
													<fo:block font-weight="bold" text-align="right">
														<xsl:value-of select="attributes/attribute[@name='PRINT_Creator_title']"/>
													</fo:block>
												</fo:table-cell>
												<fo:table-cell>
													<fo:block>
														<xsl:value-of select="attributes/attribute[@name='CREATOR_TITLE']"/>
													</fo:block>
												</fo:table-cell>
											</fo:table-row>

											<fo:table-row>
												<fo:table-cell padding-left=".5mm" padding-right=".5mm">
													<fo:block font-weight="bold" text-align="right">
														<xsl:value-of select="attributes/attribute[@name='PRINT_Copyright']"/>
													</fo:block>
												</fo:table-cell>
												<fo:table-cell>
													<fo:block>
														<xsl:value-of select="attributes/attribute[@name='COPYRIGHT']"/>
													</fo:block>
												</fo:table-cell>

												<fo:table-cell padding-left=".5mm" padding-right=".5mm">
													<fo:block font-weight="bold" text-align="right">
														<xsl:value-of select="attributes/attribute[@name='PRINT_Provider']"/>
													</fo:block>
												</fo:table-cell>
												<fo:table-cell>
													<fo:block>
														<xsl:value-of select="attributes/attribute[@name='PROVIDER']"/>
													</fo:block>
												</fo:table-cell>
											</fo:table-row>

											<fo:table-row>
												<fo:table-cell padding-left=".5mm" padding-right=".5mm">
													<fo:block font-weight="bold" text-align="right">
														<xsl:value-of select="attributes/attribute[@name='PRINT_Instructions']"/>
													</fo:block>
												</fo:table-cell>
												<fo:table-cell number-columns-spanned="3">
													<fo:block>
														<xsl:value-of select="attributes/attribute[@name='INSTRUCTIONS']"/>
													</fo:block>
												</fo:table-cell>
											</fo:table-row>

											<fo:table-row>
												<fo:table-cell number-columns-spanned="4" padding-top="5mm" padding-bottom="5mm" >
													<fo:block border-after-style="solid" border-after-width="thin" />
												</fo:table-cell>
											</fo:table-row>

											<fo:table-row>
												<fo:table-cell padding-left=".5mm" padding-right=".5mm">
													<fo:block font-weight="bold" text-align="right">
														<xsl:value-of select="attributes/attribute[@name='PRINT_Keywords']"/>
													</fo:block>
												</fo:table-cell>
												<fo:table-cell number-columns-spanned="3">
													<fo:block>
														<xsl:value-of select="attributes/attribute[@name='KEYWORDS']"/>
													</fo:block>
												</fo:table-cell>

											</fo:table-row>

											<fo:table-row>
												<fo:table-cell padding-left=".5mm" padding-right=".5mm">
													<fo:block font-weight="bold" text-align="right">
														<xsl:value-of select="attributes/attribute[@name='PRINT_Loaded_from']"/>
													</fo:block>
												</fo:table-cell>
												<fo:table-cell>
													<fo:block number-columns-spanned="3">
														<xsl:value-of select="attributes/attribute[@name='FILE_PATH']"/>
													</fo:block>
												</fo:table-cell>
											</fo:table-row>

											<fo:table-row>
												<fo:table-cell padding-left=".5mm" padding-right=".5mm">
													<fo:block font-weight="bold" text-align="right">
														<xsl:value-of select="attributes/attribute[@name='PRINT_File_name']"/>
													</fo:block>
												</fo:table-cell>
												<fo:table-cell number-columns-spanned="3">
													<fo:block>
														<xsl:value-of select="attributes/attribute[@name='FILE_NAME']"/>
													</fo:block>
												</fo:table-cell>
											</fo:table-row>

											<fo:table-row>
												<fo:table-cell padding-left=".5mm" padding-right=".5mm">
													<fo:block font-weight="bold" text-align="right">
														<xsl:value-of select="attributes/attribute[@name='PRINT_Date_loaded']"/>
													</fo:block>
												</fo:table-cell>
												<fo:table-cell>
													<fo:block>
														<xsl:value-of select="attributes/attribute[@name='CREATION_STAMP_STR']"/>
													</fo:block>
												</fo:table-cell>

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

								<fo:block space-before="5mm" space-after="5mm" border-after-style="solid" border-after-width="thin"/>
							</xsl:when>

							<xsl:when test="contains('MEDIA', primary_key/@type)">

								<!-- insert primary key -->
								<fo:block text-align="center" font-weight="bold" font-size="12pt">
									<xsl:value-of select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_Proof_print_of']"/> <xsl:value-of select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_media']"/>
									<xsl:call-template name="stripzeroes">
										<xsl:with-param name="text" select="substring(primary_key,13,16)"/>
									</xsl:call-template>
								</fo:block>

								<fo:block space-before="7mm" space-after="5mm" border-after-style="solid" border-after-width="thin" />

								<!-- insert media thumbnail -->
								<fo:block text-align="center">
									<xsl:call-template name="generateimagetag">
										<xsl:with-param name="width" select="attributes/attribute[@name='width']"/>
										<xsl:with-param name="height" select="attributes/attribute[@name='height']"/>
										<xsl:with-param name="maxwidth">80</xsl:with-param>
										<xsl:with-param name="maxheight">80</xsl:with-param>
										<xsl:with-param name="imgURL"><xsl:value-of select="/XMLData/MISCData/attributes/attribute[@name='CONTEXT_URL']"/>/GetAsset?primaryKey=<xsl:value-of select="primary_key"/>&amp;type=t</xsl:with-param>
										<xsl:with-param name="mm" select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_mm']"/>
									</xsl:call-template>
								</fo:block>

								<!-- insert media properties -->
								<fo:block space-before="1mm" text-align="center" font-size="10pt">
									<xsl:value-of select="attributes/attribute[@name='fftype']"/>,
									<xsl:value-of select="attributes/attribute[@name='filesize']"/> <xsl:value-of select="attributes/attribute[@name='PRINT_bytes']"/>,
									<xsl:value-of select="attributes/attribute[@name='width']"/><xsl:value-of select="attributes/attribute[@name='PRINT_w']"/> x <xsl:value-of select="attributes/attribute[@name='height']"/><xsl:value-of select="attributes/attribute[@name='PRINT_h']"/>
								</fo:block>

								<fo:block space-before="5mm" space-after="5mm" border-after-style="solid" border-after-width="thin" />

								<!-- insert Notices -->
								<xsl:call-template name="includenotices" />

								<fo:block>
									<fo:table table-layout="fixed" font-size="10pt">
										<fo:table-column column-number="1" column-width="30mm" />
										<fo:table-column column-number="2" column-width="65mm" />
										<fo:table-column column-number="3" column-width="30mm" />
										<fo:table-column column-number="4" column-width="65mm" />
										<fo:table-body>
											<fo:table-row>
												<!-- Owner -->
												<fo:table-cell padding-left=".5mm" padding-right=".5mm">
													<fo:block font-weight="bold" text-align="right">
														<xsl:value-of select="attributes/attribute[@name='PRINT_Owner']"/>
													</fo:block>
												</fo:table-cell>
												<fo:table-cell  number-columns-spanned="3">
													<fo:block>
														<xsl:value-of select="attributes/attribute[@name='DISPLAY_OWNER_ID']"/>
													</fo:block>
												</fo:table-cell>
											</fo:table-row>

											<fo:table-row>
												<!-- Title -->
												<fo:table-cell padding-left=".5mm" padding-right=".5mm">
													<fo:block font-weight="bold" text-align="right">
														<xsl:value-of select="attributes/attribute[@name='PRINT_Title']"/>
													</fo:block>
												</fo:table-cell>
												<fo:table-cell  number-columns-spanned="3">
													<fo:block>
														<xsl:value-of select="attributes/attribute[@name='TITLE']"/>
													</fo:block>
												</fo:table-cell>
											</fo:table-row>

											<fo:table-row>
												<!-- Headline -->
												<fo:table-cell padding-left=".5mm" padding-right=".5mm">
													<fo:block font-weight="bold" text-align="right">
														<xsl:value-of select="attributes/attribute[@name='PRINT_Headline']"/>
													</fo:block>
												</fo:table-cell>
												<fo:table-cell  number-columns-spanned="3">
													<fo:block>
														<xsl:value-of select="attributes/attribute[@name='HEADLINE']"/>
													</fo:block>
												</fo:table-cell>
											</fo:table-row>

											<fo:table-row>
												<!-- Description -->
												<fo:table-cell padding-left=".5mm" padding-right=".5mm">
													<fo:block font-weight="bold" text-align="right">
														<xsl:value-of select="attributes/attribute[@name='PRINT_Caption']"/>
													</fo:block>
												</fo:table-cell>
												<fo:table-cell  number-columns-spanned="3">
													<fo:block>
														<xsl:value-of select="attributes/attribute[@name='CAPTION']"/>
													</fo:block>
												</fo:table-cell>
											</fo:table-row>

											<fo:table-row>
												<fo:table-cell number-columns-spanned="4" padding-top="5mm" padding-bottom="5mm" >
													<fo:block border-after-style="solid" border-after-width="thin" />
												</fo:table-cell>
											</fo:table-row>

											<fo:table-row>
												<fo:table-cell padding-left=".5mm" padding-right=".5mm">
													<fo:block font-weight="bold" text-align="right">
														<xsl:value-of select="attributes/attribute[@name='PRINT_Artists']"/>
													</fo:block>
												</fo:table-cell>
												<fo:table-cell>
													<fo:block>
														<xsl:value-of select="attributes/attribute[@name='ARTIST']" />
													</fo:block>
												</fo:table-cell>

												<fo:table-cell padding-left=".5mm" padding-right=".5mm">
													<fo:block font-weight="bold" text-align="right">
														<xsl:value-of select="attributes/attribute[@name='PRINT_Creator']"/>
													</fo:block>
												</fo:table-cell>
												<fo:table-cell>
													<fo:block>
														<xsl:value-of select="attributes/attribute[@name='CREATOR']" />
													</fo:block>
												</fo:table-cell>
											</fo:table-row>

											<fo:table-row>
												<fo:table-cell padding-left=".5mm" padding-right=".5mm">
													<fo:block font-weight="bold" text-align="right">
														<xsl:value-of select="attributes/attribute[@name='PRINT_Copyright']"/>
													</fo:block>
												</fo:table-cell>
												<fo:table-cell>
													<fo:block>
														<xsl:value-of select="attributes/attribute[@name='COPYRIGHT']" />
													</fo:block>
												</fo:table-cell>

												<fo:table-cell padding-left=".5mm" padding-right=".5mm">
													<fo:block font-weight="bold" text-align="right">
														<xsl:value-of select="attributes/attribute[@name='PRINT_Provider']"/>
													</fo:block>
												</fo:table-cell>
												<fo:table-cell>
													<fo:block>
														<xsl:value-of select="attributes/attribute[@name='PROVIDER']" />
													</fo:block>
												</fo:table-cell>
											</fo:table-row>

											<fo:table-row>
												<fo:table-cell padding-left=".5mm" padding-right=".5mm">
													<fo:block font-weight="bold" text-align="right">
														<xsl:value-of select="attributes/attribute[@name='PRINT_Instructions']"/>
													</fo:block>
												</fo:table-cell>
												<fo:table-cell number-columns-spanned="3">
													<fo:block>
														<xsl:value-of select="attributes/attribute[@name='INSTRUCTIONS']"/>
													</fo:block>
												</fo:table-cell>
											</fo:table-row>

											<fo:table-row>
												<fo:table-cell number-columns-spanned="4" padding-top="5mm" padding-bottom="5mm" >
													<fo:block border-after-style="solid" border-after-width="thin" />
												</fo:table-cell>
											</fo:table-row>

											<fo:table-row>
												<fo:table-cell padding-left=".5mm" padding-right=".5mm">
													<fo:block font-weight="bold" text-align="right">
														<xsl:value-of select="attributes/attribute[@name='PRINT_Keywords']"/>
													</fo:block>
												</fo:table-cell>
												<fo:table-cell number-columns-spanned="3">
													<fo:block>
														<xsl:value-of select="attributes/attribute[@name='KEYWORDS']" />
													</fo:block>
												</fo:table-cell>

											</fo:table-row>

											<fo:table-row>
												<fo:table-cell padding-left=".5mm" padding-right=".5mm">
													<fo:block font-weight="bold" text-align="right">
														<xsl:value-of select="attributes/attribute[@name='PRINT_Loaded_from']"/>
													</fo:block>
												</fo:table-cell>
												<fo:table-cell>
													<fo:block number-columns-spanned="3">
														<xsl:value-of select="attributes/attribute[@name='FILE_PATH']" />
													</fo:block>
												</fo:table-cell>
											</fo:table-row>

											<fo:table-row>
												<fo:table-cell padding-left=".5mm" padding-right=".5mm">
													<fo:block font-weight="bold" text-align="right">
														<xsl:value-of select="attributes/attribute[@name='PRINT_File_name']"/>
													</fo:block>
												</fo:table-cell>
												<fo:table-cell number-columns-spanned="3">
													<fo:block>
														<xsl:value-of select="attributes/attribute[@name='FILE_NAME']" />
													</fo:block>
												</fo:table-cell>
											</fo:table-row>

											<fo:table-row>
												<fo:table-cell padding-left=".5mm" padding-right=".5mm">
													<fo:block font-weight="bold" text-align="right">
														<xsl:value-of select="attributes/attribute[@name='PRINT_Date_loaded']"/>
													</fo:block>
												</fo:table-cell>
												<fo:table-cell>
													<fo:block>
														<xsl:value-of select="attributes/attribute[@name='CREATION_STAMP_STR']"/>
													</fo:block>
												</fo:table-cell>

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

								<fo:block space-before="5mm" space-after="5mm" border-after-style="solid" border-after-width="thin" />
							</xsl:when>

							<!-- COMPOUND asset -->

							<xsl:when test="contains('COMPOSITE', primary_key/@type)">

								<!-- insert primary key -->
								<fo:block text-align="center" font-weight="bold" font-size="12pt">
									<xsl:value-of select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_Proof_print_of']"/>
									<xsl:if test="attributes/attribute[@name='SUB_TYPE'] = 'picturegallery'"><xsl:value-of select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_Gallery']"/> </xsl:if>
									<xsl:if test="attributes/attribute[@name='SUB_TYPE'] = 'picturecomposite'"><xsl:value-of select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_Composite']"/> </xsl:if>
									<xsl:if test="attributes/attribute[@name='SUB_TYPE'] = 'graphic'"><xsl:value-of select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_Graphic']"/> </xsl:if>
									<xsl:if test="attributes/attribute[@name='SUB_TYPE'] = 'collection'"><xsl:value-of select="/XMLData/XMLDataObjects/XMLDataObject[1]/attributes/attribute[@name='PRINT_Collection']"/> </xsl:if>
									<xsl:call-template name="stripzeroes">
										<xsl:with-param name="text" select="substring(primary_key,13,16)"/>
									</xsl:call-template>
								</fo:block>

								<fo:block space-before="7mm" space-after="5mm" border-after-style="solid" border-after-width="thin" />

								<!-- insert composite picture -->
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

								<fo:block space-before="5mm" space-after="5mm" border-after-style="solid" border-after-width="thin" />

								<!-- insert Notices -->
								<xsl:call-template name="includenotices" />

								<!-- insert asset meta -->
								<fo:block>
									<fo:table table-layout="fixed" font-size="10pt">
										<fo:table-column column-number="1" column-width="30mm" />
										<fo:table-column column-number="2" column-width="65mm" />
										<fo:table-column column-number="3" column-width="30mm" />
										<fo:table-column column-number="4" column-width="65mm" />
										<fo:table-body>
											<fo:table-row>
												<!-- Owner -->
												<fo:table-cell padding-left=".5mm" padding-right=".5mm">
													<fo:block font-weight="bold" text-align="right">
														<xsl:value-of select="attributes/attribute[@name='PRINT_Owner']"/>
													</fo:block>
												</fo:table-cell>
												<fo:table-cell>
													<fo:block>
														<xsl:value-of select="attributes/attribute[@name='DISPLAY_OWNER_ID']"/>
													</fo:block>
												</fo:table-cell>

												<!-- created -->
												<fo:table-cell padding-left=".5mm" padding-right=".5mm">
													<fo:block font-weight="bold" text-align="right">
														<xsl:value-of select="attributes/attribute[@name='PRINT_Date_loaded']"/>
													</fo:block>
												</fo:table-cell>
												<fo:table-cell>
													<fo:block>
														<xsl:value-of select="attributes/attribute[@name='CREATION_STAMP_STR']"/>
													</fo:block>
												</fo:table-cell>
											</fo:table-row>

											<fo:table-row>
												<!-- name -->
												<fo:table-cell padding-left=".5mm" padding-right=".5mm">
													<fo:block font-weight="bold" text-align="right">
														<xsl:value-of select="attributes/attribute[@name='PRINT_Name']"/>
													</fo:block>
												</fo:table-cell>
												<fo:table-cell number-columns-spanned="3">
													<fo:block>
														<xsl:value-of select="attributes/attribute[@name='INTERNAL_NAME']"/>
													</fo:block>
												</fo:table-cell>
											</fo:table-row>

											<xsl:if test="attributes/attribute[@name='HEADLINE'] != ''">
												<fo:table-row>
													<!-- headline -->
													<fo:table-cell padding-left=".5mm" padding-right=".5mm">
														<fo:block font-weight="bold" text-align="right">
															<xsl:value-of select="attributes/attribute[@name='PRINT_Headline']"/>
														</fo:block>
													</fo:table-cell>
													<fo:table-cell number-columns-spanned="3">
														<fo:block>
															<xsl:value-of select="attributes/attribute[@name='HEADLINE']"/>
														</fo:block>
													</fo:table-cell>
												</fo:table-row>
											</xsl:if>

											<xsl:if test="attributes/attribute[@name='CAPTION'] != ''">
												<fo:table-row>
													<!-- caption -->
													<fo:table-cell padding-left=".5mm" padding-right=".5mm">
														<fo:block font-weight="bold" text-align="right">
															<xsl:value-of select="attributes/attribute[@name='PRINT_Caption']"/>
														</fo:block>
													</fo:table-cell>
													<fo:table-cell number-columns-spanned="3">
														<fo:block>
															<xsl:value-of select="attributes/attribute[@name='CAPTION']"/>
														</fo:block>
													</fo:table-cell>
												</fo:table-row>
											</xsl:if>

											<xsl:if test="attributes/attribute[@name='BYLINE'] != ''">
												<fo:table-row>
													<!-- author -->
													<fo:table-cell padding-left=".5mm" padding-right=".5mm">
														<fo:block font-weight="bold" text-align="right">
															<xsl:value-of select="attributes/attribute[@name='PRINT_Author']"/>
														</fo:block>
													</fo:table-cell>
													<fo:table-cell number-columns-spanned="3">
														<fo:block>
															<xsl:value-of select="attributes/attribute[@name='BYLINE']"/>
														</fo:block>
													</fo:table-cell>
												</fo:table-row>
											</xsl:if>

											<xsl:if test="attributes/attribute[@name='SUBHEADING'] != ''">
												<fo:table-row>
													<!-- standfirst -->
													<fo:table-cell padding-left=".5mm" padding-right=".5mm">
														<fo:block font-weight="bold" text-align="right">
															<xsl:value-of select="attributes/attribute[@name='PRINT_Standfirst']"/>
														</fo:block>
													</fo:table-cell>
													<fo:table-cell number-columns-spanned="3">
														<fo:block>
															<xsl:value-of select="attributes/attribute[@name='SUBHEADING']"/>
														</fo:block>
													</fo:table-cell>
												</fo:table-row>
											</xsl:if>

										</fo:table-body>
									</fo:table>
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
