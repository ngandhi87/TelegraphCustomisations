-- Creating new tables used for custom purposes in CHP
-- AUDIT_PDF_EXPORT
-- DELETED_USAGES
-- SEND_WORKFLOW_EMAIL_QUEUE
-- MM_PROCESS_MONITOR

-- AUDIT_PDF_EXPORT table
CREATE TABLE AUDIT_PDF_EXPORT
   (
     ASSET_ID VARCHAR(24),
	EXPORT_LOCATION VARCHAR(200),
	FILENAME VARCHAR(200),
	TIMESTAMP DATE,
	LATEST_EXPORT VARCHAR(1)
   );

   CREATE INDEX AUDIT_PDF_EXPORT_IDX ON AUDIT_PDF_EXPORT (ASSET_ID);
   CREATE INDEX AUDIT_PDF_EXPORT_IDX2 ON AUDIT_PDF_EXPORT (LATEST_EXPORT);

   ALTER TABLE AUDIT_PDF_EXPORT ALTER COLUMN ASSET_ID SET NOT NULL;

-- DELETED_USAGES table
  CREATE TABLE DELETED_USAGES
   (PROCESS_NAME VARCHAR(100),
	ASSET_ID VARCHAR(24),
	USAGE_ID VARCHAR(24)
   );

  CREATE INDEX IDX_DELETED_USAGES_PROC_NAME ON DELETED_USAGES (PROCESS_NAME);

-- SEND_WORKFLOW_EMAIL_QUEUE table
  CREATE TABLE SEND_WORKFLOW_EMAIL_QUEUE
   (
    WORKFLOW_ID VARCHAR(100),
	WORKFLOW_XML TEXT,
	STATUS VARCHAR(20)
   );

-- MM_PROCESS_MONITOR table
CREATE TABLE MM_PROCESS_MONITOR
   (	NAME VARCHAR(50),
    LAST_UPDATE DATE,
	STATUS VARCHAR(20)
   );


-- Preparation for removing the indexes
DROP INDEX asset_index_status;
DROP INDEX asset_lifecycle_status;
DROP INDEX asset_owner_id;
DROP INDEX asset_upper_lifecycle_status;
DROP INDEX asset_info_cookie;
DROP INDEX asset_locator_asset_locator_coo;
DROP INDEX page_checked_out;
DROP INDEX page_creation_stamp;
DROP INDEX page_edition_instance_id;
DROP INDEX page_external_ref;
DROP INDEX page_lower_publication_page;
DROP INDEX page_lower_publication_section;
DROP INDEX page_publication_book_name;
DROP INDEX page_publication_date;
DROP INDEX page_publication_edition;
DROP INDEX page_publication_page;
DROP INDEX page_publication_section;
DROP INDEX page_publication_title;
DROP INDEX page_section_filter;
DROP INDEX page_status;
DROP INDEX page_update_stamp;
DROP INDEX picture_checked_out;
DROP INDEX picture_copyright;
DROP INDEX picture_creation_stamp;
DROP INDEX picture_date_received;
DROP INDEX picture_external_ref;
DROP INDEX picture_feed_name;
DROP INDEX picture_filename;
DROP INDEX picture_headline;
DROP INDEX picture_job_number;
DROP INDEX picture_keywords;
DROP INDEX picture_legacy_urn;
DROP INDEX picture_people;
DROP INDEX picture_photographer;
DROP INDEX picture_picture_date;
DROP INDEX picture_price_band;
DROP INDEX picture_provider;
DROP INDEX picture_source;
DROP INDEX picture_update_stamp;
DROP INDEX picture_xurn;
DROP INDEX story_branch_id;
DROP INDEX story_byline;
DROP INDEX story_checked_out;
DROP INDEX story_creation_stamp;
DROP INDEX story_external_ref;
DROP INDEX story_external_sequence_ref;
DROP INDEX story_feed_name;
DROP INDEX story_headline;
DROP INDEX story_job_number;
DROP INDEX story_root_id;
DROP INDEX story_source;
DROP INDEX story_story_date;
DROP INDEX story_story_name;
DROP INDEX story_subheading;
DROP INDEX story_update_stamp;
DROP INDEX usage_asset_id;
DROP INDEX usage_asset_id_by_pub;
DROP INDEX usage_asset_reference;
DROP INDEX usage_asset_type;
DROP INDEX usage_order_item_id;
DROP INDEX usage_page_id;
DROP INDEX usage_publication_book_name;
DROP INDEX usage_publication_date;
DROP INDEX usage_publication_edition;
DROP INDEX usage_publication_page;
DROP INDEX usage_publication_section;
DROP INDEX usage_publication_title;

-- Migrate all of the data from Oracle to Postgres

-- Once the migration has finished, run the following SQL to add the indexes back in
CREATE INDEX ASSET_INDEX_STATUS ON ASSET(INDEX_STATUS,ASSET_ID);
CREATE INDEX asset_lifecycle_status ON public.asset (lifecycle_status, asset_id);
CREATE INDEX asset_owner_id ON public.asset (owner_id, asset_id);
CREATE INDEX asset_upper_lifecycle_status ON public.asset (upper((lifecycle_status)::text), asset_id);
CREATE INDEX asset_info_cookie ON public.asset_info (cookie, asset_id);

-- CREATE INDEX asset_locator_asset_locator_coo ON public.asset_locator (cookie);
CREATE INDEX ASSET_LOCATOR_ASSET_LOCATOR_COO ON ASSET_LOCATOR(COOKIE);

CREATE INDEX page_checked_out ON public.page (checked_out, asset_id);
CREATE INDEX page_creation_stamp ON public.page (creation_stamp, asset_id);
CREATE INDEX page_edition_instance_id ON public.page (edition_instance_id, asset_id);
CREATE INDEX page_external_ref ON public.page (external_ref, asset_id);
CREATE INDEX page_lower_publication_page ON public.page (lower((publication_page)::text), edition_instance_id);
CREATE INDEX page_lower_publication_section ON public.page (lower((publication_section)::text), edition_instance_id);
CREATE INDEX page_publication_book_name ON public.page (publication_book_name, asset_id);
CREATE INDEX page_publication_date ON public.page (publication_date, asset_id);
CREATE INDEX page_publication_edition ON public.page (publication_edition, asset_id);
CREATE INDEX page_publication_page ON public.page (publication_page, asset_id);
CREATE INDEX page_publication_section ON public.page (publication_section, asset_id);
CREATE INDEX page_publication_title ON public.page (publication_title, asset_id);
CREATE INDEX page_section_filter ON public.page (publication_section, publication_title, publication_edition, publication_book_name);
CREATE INDEX page_status ON public.page (status, asset_id);
CREATE INDEX page_update_stamp ON public.page (update_stamp, asset_id);
CREATE INDEX picture_checked_out ON public.picture (checked_out, asset_id);
CREATE INDEX picture_copyright ON public.picture (copyright, asset_id);
CREATE INDEX picture_creation_stamp ON public.picture (creation_stamp, asset_id);
CREATE INDEX picture_date_received ON public.picture (date_received, asset_id);
CREATE INDEX picture_external_ref ON public.picture (external_ref, asset_id);
CREATE INDEX picture_feed_name ON public.picture (feed_name, asset_id);
CREATE INDEX picture_filename ON public.picture (filename, asset_id);
CREATE INDEX picture_headline ON public.picture (headline, asset_id);
CREATE INDEX picture_job_number ON public.picture (job_number, asset_id);
CREATE INDEX picture_keywords ON public.picture (keywords, asset_id);
CREATE INDEX picture_legacy_urn ON public.picture (legacy_urn, asset_id);
-- This is unlikely to work, so use the md5 route if required as there is too much data
-- CREATE INDEX picture_people ON public.picture (people, asset_id);
CREATE INDEX PICTURE_PEOPLE ON PICTURE (ASSET_ID,md5(PEOPLE));
CREATE INDEX picture_photographer ON public.picture (photographer, asset_id);
CREATE INDEX picture_picture_date ON public.picture (picture_date, asset_id);
CREATE INDEX picture_price_band ON public.picture (price_band, asset_id);
CREATE INDEX picture_provider ON public.picture (provider, asset_id);
CREATE INDEX picture_source ON public.picture (source, asset_id);
CREATE INDEX picture_update_stamp ON public.picture (update_stamp, asset_id);
CREATE INDEX picture_xurn ON public.picture (xurn, asset_id);
CREATE INDEX story_branch_id ON public.story (branch_id, asset_id);
CREATE INDEX story_byline ON public.story (byline, asset_id);
CREATE INDEX story_checked_out ON public.story (checked_out, asset_id);
CREATE INDEX story_creation_stamp ON public.story (creation_stamp, asset_id);
CREATE INDEX story_external_ref ON public.story (external_ref, asset_id);
CREATE INDEX story_external_sequence_ref ON public.story (external_sequence_ref, asset_id);
CREATE INDEX story_feed_name ON public.story (feed_name, asset_id);
-- This is unlikely to work, so use the md5 route if required as there is too much data
--CREATE INDEX story_headline ON public.story (headline, asset_id);
CREATE INDEX story_headline ON STORY (ASSET_ID,md5(headline));
CREATE INDEX story_job_number ON public.story (job_number, asset_id);
CREATE INDEX story_root_id ON public.story (root_id, asset_id);
CREATE INDEX story_source ON public.story (source, asset_id);
CREATE INDEX story_story_date ON public.story (story_date, asset_id);
CREATE INDEX story_story_name ON public.story (story_name, asset_id);
CREATE INDEX story_subheading ON public.story (subheading, asset_id);
CREATE INDEX story_update_stamp ON public.story (update_stamp, asset_id);
CREATE INDEX usage_asset_id ON public.usage (asset_id, usage_id);
CREATE INDEX usage_asset_id_by_pub ON public.usage (asset_id, publication_page, usage_id);
CREATE INDEX usage_asset_reference ON public.usage (external_ref, asset_id);
CREATE INDEX usage_asset_type ON public.usage (asset_type, usage_id);
CREATE INDEX usage_order_item_id ON public.usage (order_item_id);
CREATE INDEX usage_page_id ON public.usage (page_id, usage_id);
CREATE INDEX usage_publication_book_name ON public.usage (publication_book_name, asset_id);
CREATE INDEX usage_publication_date ON public.usage (publication_date, asset_id);
CREATE INDEX usage_publication_edition ON public.usage (publication_edition, asset_id);
CREATE INDEX usage_publication_page ON public.usage (publication_page, asset_id);
CREATE INDEX usage_publication_section ON public.usage (publication_section, asset_id);
CREATE INDEX USAGE_PUBLICATION_TITLE ON USAGE(PUBLICATION_TITLE,ASSET_ID);
-- CREATE INDEX usage_publication_title ON public.usage (publication_title, asset_id);