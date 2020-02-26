-- Tidy up

-- Swap word_count column
--alter table STORY drop column WORD_COUNT;
--alter table STORY rename column WORD_COUNT_NUM to WORD_COUNT;

-- Remove multi-tabs feature from EMDs
UPDATE CHP.TABLES
SET FLAGS = NULL, MULTI_TABS = NULL
WHERE NAME IN ('DTI_COLLECTION', 'DTI_STORY', 'ESCENIC_GALLERY', 'ESCENIC_STORY', 'ESCENIC_VIDEO');
COMMIT;

-- 4.10.1 to 4.10.2

-- CUSTOM_ORDER fields
create table CHP.hard_categories_backup1 as select * from CHP.hard_categories;
alter table CHP.hard_categories add (temp clob);
update CHP.hard_categories set temp = custom_order where custom_order is not null;
commit;
alter table CHP.hard_categories drop column custom_order;
alter table CHP.hard_categories rename column temp to custom_order;

create table CHP.mm_shelf_backup1 as select * from CHP.mm_shelf;
alter table CHP.mm_shelf add (temp clob);
update CHP.mm_shelf set temp = custom_order where custom_order is not null;
commit;
alter table CHP.mm_shelf drop column custom_order;
alter table CHP.mm_shelf rename column temp to custom_order;

update CHP.FIELDS set type = 'CLOB', col_size = 0 where name = 'CUSTOM_ORDER';
commit;


-- 4.10.2 to 4.10.3

-- Changes to "My Viewed Items"
delete from CHP.mm_asset_shelf where node_id in (select node_id from CHP.mm_shelf where upper(key) = upper('My viewed items') and system = 1);
create table CHP.my_viewed_items_bkp4101 as select * from CHP.mm_shelf where upper(key) = upper('My viewed items') and system = 1;
delete from CHP.mm_shelf where upper(key) = upper('My viewed items') and system = 1;
commit;

-- Update stamp changes for EDITION_INSTANCE, MM_USER_PRIVILEGES and MM_ROLE_PRIVILEGES
UPDATE CHP.EDITION_INSTANCE
SET UPDATE_STAMP = cast(current_timestamp at time zone dbtimezone as date)
WHERE UPDATE_STAMP IS NULL;
COMMIT;

UPDATE CHP.MM_USER_PRIVILEGES
SET UPDATE_STAMP = cast(current_timestamp at time zone dbtimezone as date)
WHERE UPDATE_STAMP IS NULL;
COMMIT;

UPDATE CHP.MM_ROLE_PRIVILEGES
SET UPDATE_STAMP = cast(current_timestamp at time zone dbtimezone as date)
WHERE UPDATE_STAMP IS NULL;
COMMIT;


-- 4.10.3 to 16.0.0

-- Fix issues with the edition instance (CHP-4271) 
create table CHP.page_backup_v4101 as select * from CHP.page where edition_instance_id not in (select edition_instance_id from CHP.edition_instance);
create table CHP.usage_backup_v4101 as select * from CHP.usage where exists (select * from CHP.page where edition_instance_id not in (select edition_instance_id from CHP.edition_instance) and CHP.usage.page_id = CHP.page.asset_id);

delete from CHP.usage where exists (select * from CHP.page where edition_instance_id not in (select edition_instance_id from CHP.edition_instance) and CHP.usage.page_id = CHP.page.asset_id);
delete from CHP.page where edition_instance_id not in (select edition_instance_id from CHP.edition_instance);
commit;


-- 16.0.0 to 16.0.1

-- Update favorite table to correct refining saved searches in IE (CHP-4737)
UPDATE CHP.favourite 
SET information = REPLACE(information, 'criteriatype', 'criteriaType') 
where information like '%criteriatype%';
COMMIT;


-- 16.0.1 to 16.2.0

-- Search warning context field type change (CHP-5185)
ALTER TABLE CHP.SEARCH_WARNING_TERMS ADD NEW_CONTEXT CLOB;
UPDATE CHP.SEARCH_WARNING_TERMS SET NEW_CONTEXT=CONTEXT;
commit;
ALTER TABLE CHP.SEARCH_WARNING_TERMS DROP COLUMN CONTEXT;
ALTER TABLE CHP.SEARCH_WARNING_TERMS RENAME COLUMN NEW_CONTEXT TO CONTEXT;

update CHP.FIELDS set type = 'CLOB', col_size = 0 where name = 'CONTEXT' and table_name = 'SEARCH_WARNING_TERMS';
commit;


-- 16.2.0 to 16.4.0

-- Icon Manager - re-apply the change on manifest table
DELETE FROM CHP.FIELDS
WHERE TABLE_NAME = 'ICON_MANAGER' AND UPPER(NAME) = 'IMAGETYPE';
COMMIT;

ALTER TABLE ICON_MANAGER DROP COLUMN IMAGETYPE;

-- Add the new constraint (will only work on 16.4.2!) 
UPDATE CHP.CHP_NOTIFICATION_CHECK SET APP = 'CHP';
COMMIT;

ALTER TABLE CHP.CHP_NOTIFICATION_CHECK DROP PRIMARY KEY;
ALTER TABLE CHP.CHP_NOTIFICATION_CHECK ADD PRIMARY KEY (USER_ID,APP);

CREATE INDEX CHP.CHP_NOTIFICATION_CHECK_APP_CHE ON CHP.CHP_NOTIFICATION_CHECK(USER_ID,APP,CHECK_STAMP);


-- 16.4.0 to 16.4.1

-- None


-- 16.4.1 to CHP 16.4.2

-- Changes to EMD pick list fields
SET SERVEROUTPUT ON;

DECLARE
  alter_stmt varchar2(200);
  
  cursor c1 is
	select distinct(TABLE_NAME) as TABLE_NAME 
	from CHP.FIELDS 
	where TABLE_NAME like 'pl\_%' escape '\' and TABLE_NAME NOT IN (select distinct(TABLE_NAME) from Fields where TABLE_NAME like 'pl\_%' escape '\' and NAME = 'UPDATE_STAMP');	

  cursor c2 is
	select distinct(NAME) as NAME
	from CHP.TABLES 
	where NAME like 'pl\_%' escape '\'; 	
	
BEGIN
   FOR t_name1 in c1
   LOOP
      BEGIN
        
        INSERT INTO CHP.FIELDS (TABLE_NAME,NAME,TYPE,NON_NULL,LIST_OPTIONS,COL_ORDER,HAS_SEQUENCE,ALIASES,PROPERTIES,XPATH,HAS_INDEX,FREETEXT_TYPE,FIELD_GROUP,DEFAULT_VALUE,COL_SIZE,FLAGS) values (t_name1.TABLE_NAME,'CREATION_STAMP','CREATION_STAMP','0',null,0,'0',null,null,null,'0',null,null,null,0,'CREATION_STAMP');
        INSERT INTO CHP.FIELDS (TABLE_NAME,NAME,TYPE,NON_NULL,LIST_OPTIONS,COL_ORDER,HAS_SEQUENCE,ALIASES,PROPERTIES,XPATH,HAS_INDEX,FREETEXT_TYPE,FIELD_GROUP,DEFAULT_VALUE,COL_SIZE,FLAGS) values (t_name1.TABLE_NAME,'UPDATE_STAMP','UPDATE_STAMP','0',null,0,'0',null,null,null,'0',null,null,null,0,'UPDATE_STAMP');
        commit;

        DBMS_OUTPUT.PUT_LINE('Successfully inserted records on manifest table for ' || t_name1.TABLE_NAME);
        
      EXCEPTION
        WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error inserted records on manifest table for ' || t_name1.TABLE_NAME);
        CONTINUE;  
      END;
   END LOOP;
   
   FOR t_name2 in c2
   LOOP
      BEGIN
        
        alter_stmt := 'ALTER TABLE CHP.' || t_name2.NAME || ' ADD (CREATION_STAMP DATE, UPDATE_STAMP DATE)';
        EXECUTE IMMEDIATE alter_stmt;
        DBMS_OUTPUT.PUT_LINE('Successfully added columns with ... ' || alter_stmt);
        
      EXCEPTION
        WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error adding columns with  ... ' || alter_stmt);
        CONTINUE;  
      END;
   END LOOP;
   
END;
/


ALTER TRIGGER CHP.DUAL_RUNNING_INDEX DISABLE;


CREATE or REPLACE TRIGGER CHP.POST_GO_LIVE_INDEX
AFTER INSERT ON CHP.CHP_INDEX_QUEUE FOR EACH ROW
BEGIN

INSERT INTO CHP.MM_INDEX_QUEUE (CREATION_STAMP, ATTEMPT_COUNT, QUEUE_NAME, STATUS, ITEM_KEY, USER_NAME, ACTION, INDEX_ID, UPDATE_STAMP)
VALUES (:new.creation_stamp, 0,
CASE WHEN (INSTRC(:new.item_key, 'PICT') <> 0) THEN 'MM_PICTURE_INDEX'
  WHEN (INSTRC(:new.item_key, 'STRY') <> 0) THEN 'MM_STORY_INDEX'
  WHEN (INSTRC(:new.item_key, 'COMP') <> 0) THEN 'MM_COMPOSITE_INDEX'
  WHEN (INSTRC(:new.item_key, 'MEDA') <> 0) THEN 'MM_MEDIA_INDEX'
  WHEN (INSTRC(:new.item_key, 'DOCU') <> 0) THEN 'MM_DOCUMENT_INDEX'
  WHEN (INSTRC(:new.item_key, 'PAGE') <> 0) THEN 'MM_PAGE_INDEX' END,
:new.status, :new.item_key, 'Solr Queue', 'Index' , mm_index_queue_seq.nextval, :new.update_stamp);

INSERT INTO CHP.MM_INDEX_QUEUE (CREATION_STAMP, ATTEMPT_COUNT, QUEUE_NAME, STATUS, ITEM_KEY, USER_NAME, ACTION, INDEX_ID, UPDATE_STAMP)
VALUES (:new.creation_stamp, 0, 'MM_COMBINED_INDEX', :new.status, :new.item_key, 'Solr Queue', 'Index' , mm_index_queue_seq.nextval, :new.update_stamp);

END;
/

