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
CREATE INDEX asset_index_status ON public.asset USING btree (index_status, asset_id);
CREATE INDEX asset_lifecycle_status ON public.asset USING btree (lifecycle_status, asset_id);
CREATE INDEX asset_owner_id ON public.asset USING btree (owner_id, asset_id);
CREATE INDEX asset_upper_lifecycle_status ON public.asset USING btree (upper((lifecycle_status)::text), asset_id);
CREATE INDEX asset_info_cookie ON public.asset_info USING btree (cookie, asset_id);
CREATE INDEX asset_locator_asset_locator_coo ON public.asset_locator USING btree (cookie);

CREATE INDEX page_checked_out ON public.page USING btree (checked_out, asset_id);
CREATE INDEX page_creation_stamp ON public.page USING btree (creation_stamp, asset_id);
CREATE INDEX page_edition_instance_id ON public.page USING btree (edition_instance_id, asset_id);
CREATE INDEX page_external_ref ON public.page USING btree (external_ref, asset_id);
CREATE INDEX page_lower_publication_page ON public.page USING btree (lower((publication_page)::text), edition_instance_id);
CREATE INDEX page_lower_publication_section ON public.page USING btree (lower((publication_section)::text), edition_instance_id);
CREATE INDEX page_publication_book_name ON public.page USING btree (publication_book_name, asset_id);
CREATE INDEX page_publication_date ON public.page USING btree (publication_date, asset_id);
CREATE INDEX page_publication_edition ON public.page USING btree (publication_edition, asset_id);
CREATE INDEX page_publication_page ON public.page USING btree (publication_page, asset_id);
CREATE INDEX page_publication_section ON public.page USING btree (publication_section, asset_id);
CREATE INDEX page_publication_title ON public.page USING btree (publication_title, asset_id);
CREATE INDEX page_section_filter ON public.page USING btree (publication_section, publication_title, publication_edition, publication_book_name);
CREATE INDEX page_status ON public.page USING btree (status, asset_id);
CREATE INDEX page_update_stamp ON public.page USING btree (update_stamp, asset_id);
CREATE INDEX picture_checked_out ON public.picture USING btree (checked_out, asset_id);
CREATE INDEX picture_copyright ON public.picture USING btree (copyright, asset_id);
CREATE INDEX picture_creation_stamp ON public.picture USING btree (creation_stamp, asset_id);
CREATE INDEX picture_date_received ON public.picture USING btree (date_received, asset_id);
CREATE INDEX picture_external_ref ON public.picture USING btree (external_ref, asset_id);
CREATE INDEX picture_feed_name ON public.picture USING btree (feed_name, asset_id);
CREATE INDEX picture_filename ON public.picture USING btree (filename, asset_id);
CREATE INDEX picture_headline ON public.picture USING btree (headline, asset_id);
CREATE INDEX picture_job_number ON public.picture USING btree (job_number, asset_id);
CREATE INDEX picture_keywords ON public.picture USING btree (keywords, asset_id);
CREATE INDEX picture_legacy_urn ON public.picture USING btree (legacy_urn, asset_id);
CREATE INDEX picture_people ON public.picture USING btree (people, asset_id);
CREATE INDEX picture_photographer ON public.picture USING btree (photographer, asset_id);
CREATE INDEX picture_picture_date ON public.picture USING btree (picture_date, asset_id);
CREATE INDEX picture_price_band ON public.picture USING btree (price_band, asset_id);
CREATE INDEX picture_provider ON public.picture USING btree (provider, asset_id);
CREATE INDEX picture_source ON public.picture USING btree (source, asset_id);
CREATE INDEX picture_update_stamp ON public.picture USING btree (update_stamp, asset_id);
CREATE INDEX picture_xurn ON public.picture USING btree (xurn, asset_id);
CREATE INDEX story_branch_id ON public.story USING btree (branch_id, asset_id);
CREATE INDEX story_byline ON public.story USING btree (byline, asset_id);
CREATE INDEX story_checked_out ON public.story USING btree (checked_out, asset_id);
CREATE INDEX story_creation_stamp ON public.story USING btree (creation_stamp, asset_id);
CREATE INDEX story_external_ref ON public.story USING btree (external_ref, asset_id);
CREATE INDEX story_external_sequence_ref ON public.story USING btree (external_sequence_ref, asset_id);
CREATE INDEX story_feed_name ON public.story USING btree (feed_name, asset_id);
CREATE INDEX story_headline ON public.story USING btree (headline, asset_id);
CREATE INDEX story_job_number ON public.story USING btree (job_number, asset_id);
CREATE INDEX story_root_id ON public.story USING btree (root_id, asset_id);
CREATE INDEX story_source ON public.story USING btree (source, asset_id);
CREATE INDEX story_story_date ON public.story USING btree (story_date, asset_id);
CREATE INDEX story_story_name ON public.story USING btree (story_name, asset_id);
CREATE INDEX story_subheading ON public.story USING btree (subheading, asset_id);
CREATE INDEX story_update_stamp ON public.story USING btree (update_stamp, asset_id);
CREATE INDEX usage_asset_id ON public.usage USING btree (asset_id, usage_id);
CREATE INDEX usage_asset_id_by_pub ON public.usage USING btree (asset_id, publication_page, usage_id);
CREATE INDEX usage_asset_reference ON public.usage USING btree (external_ref, asset_id);
CREATE INDEX usage_asset_type ON public.usage USING btree (asset_type, usage_id);
CREATE INDEX usage_order_item_id ON public.usage USING btree (order_item_id);
CREATE INDEX usage_page_id ON public.usage USING btree (page_id, usage_id);
CREATE INDEX usage_publication_book_name ON public.usage USING btree (publication_book_name, asset_id);
CREATE INDEX usage_publication_date ON public.usage USING btree (publication_date, asset_id);
CREATE INDEX usage_publication_edition ON public.usage USING btree (publication_edition, asset_id);
CREATE INDEX usage_publication_page ON public.usage USING btree (publication_page, asset_id);
CREATE INDEX usage_publication_section ON public.usage USING btree (publication_section, asset_id);
CREATE INDEX usage_publication_title ON public.usage USING btree (publication_title, asset_id);