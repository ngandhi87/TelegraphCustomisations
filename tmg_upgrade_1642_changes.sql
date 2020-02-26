-- Run the schemaManager tool


-- 4.10.1

-- Enabling efficient locking
ALTER TABLE CHP.MM_LOCK ADD CONSTRAINT UNIQUE_LOCKS UNIQUE (TYPE,NAME);
DELETE FROM CHP.MM_LOCK;
COMMIT;

-- Tidy user profile table (CHP-2704)
DELETE FROM CHP.mm_user_profile 
WHERE name='CHP_SESSION_ID' OR name='CTRB_LOGGED_ON' OR name='CTRB_SESSION_ID' OR name='LOGGED_ON';
COMMIT;


-- 4.10.1 to 4.10.2

-- None


-- 4.10.2 to 4.10.3

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

-- Support XSLT2 transformations (CHP-3480)
-- Update connector column on asset_locator for existing assets
-- Above 2 changes will be implemented as system processes for on-going updates


-- 16.0.0 to 16.0.1

-- Initiate the audit timestamp for MM_ROLE table to enable caching of user group (CHP-5065)
insert into CHP.mm_audit(audit_id,date_created,date_modified) 
select 'MM_ROLE',update_stamp,update_stamp 
from CHP.mm_role 
where update_stamp=(select max(update_stamp) from CHP.mm_role)
and not exists (select 1 from CHP.mm_audit where audit_id = 'MM_ROLE');
COMMIT;


-- 16.0.1 to 16.2.0

-- None


-- 16.2.0 to 16.4.0

-- EMD table ASSET_ID index (CHP-5458)
SET SERVEROUTPUT ON;

DECLARE
  index_stmt varchar2(200);
  emd_kind varchar2(30);
  
  cursor c1 is
    select key
    from CHP.SPECIALISTMD_HIERARCHY
    where parent_id = (select node_id from CHP.SPECIALISTMD_HIERARCHY where key = 'Specialist Tables');

BEGIN
   FOR emd_name in c1
   LOOP
      BEGIN
        IF length(emd_name.key) > 21 THEN
            emd_kind := substr(emd_name.key, 1, 21);
        ELSE
            emd_kind := emd_name.key;
        END IF;
        
        index_stmt := 'CREATE UNIQUE INDEX CHP.' || emd_kind || '_ASSET_ID ON CHP.'  || emd_name.key || ' (ASSET_ID)';
        EXECUTE IMMEDIATE index_stmt;
        DBMS_OUTPUT.PUT_LINE('Successfully created index with ... ' || index_stmt);
        
      EXCEPTION
        WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error creating index with  ... ' || index_stmt);
        CONTINUE;  
      END;
   END LOOP;
END;
/


-- 16.4.0 to 16.4.1

-- None

-- 16.4.1 to CHP 16.4.2

-- TEMPLATE column length is 50 but KEY column on PROCESS_TEMPLATES table is 100 so increased the column to 100
ALTER TABLE CHP.MM_PROCESS_INFO MODIFY TEMPLATE VARCHAR2(100);  

-- 16.4.2.1 hotfix 2 schema update
UPDATE CHP.FIELDS
SET FLAGS = 'CMISHIDE,HIDE_FROM_UI'
WHERE NAME = 'ICON_ID' AND TABLE_NAME = 'MM_ROLE';
COMMIT;

-- Tidy up old stuff
CREATE TABLE CHP.UPLOAD_STORE_backup_v4101 as select * from UPLOAD_STORE;
TRUNCATE TABLE CHP.UPLOAD_STORE;
COMMIT;
ALTER TABLE CHP.UPLOAD_STORE MODIFY UPLOAD_ID VARCHAR2(24);  -- 3 records with length = 27 (199 records in total)

TRUNCATE TABLE CHP.UPLOAD_STORE_del;
COMMIT;
ALTER TABLE CHP.UPLOAD_STORE_del MODIFY UPLOAD_ID VARCHAR2(24);  -- 10 records with length = 27 (15,898 records in total)

ALTER TABLE CHP.PEOPLE MODIFY KEY VARCHAR2(100); -- OK (51 records in total)

-- OK (no records in DOCUMENT table)
DROP INDEX CHP.DOCUMENT_RIGHTS_QUALIFIER;
ALTER TABLE CHP.DOCUMENT DROP COLUMN RIGHTS_QUALIFIER;

DROP INDEX CHP.DOCUMENT_DATA_CHECK;
ALTER TABLE CHP.DOCUMENT DROP COLUMN DATA_CHECK;

ALTER TABLE CHP.DOCUMENT DROP COLUMN USAGE_RIGHTS;
ALTER TABLE CHP.DOCUMENT DROP COLUMN RELEASE_DATE;
ALTER TABLE CHP.DOCUMENT DROP COLUMN EXPIRATION_DATE;
ALTER TABLE CHP.DOCUMENT DROP COLUMN RIGHTS_CONTACT;

-- OK (no records in MEDIA table)
DROP INDEX CHP.MEDIA_RIGHTS_QUALIFIER;
ALTER TABLE CHP.MEDIA DROP COLUMN RIGHTS_QUALIFIER;

DROP INDEX CHP.MEDIA_DATA_CHECK;
ALTER TABLE CHP.MEDIA DROP COLUMN DATA_CHECK;

ALTER TABLE CHP.MEDIA DROP COLUMN USAGE_RIGHTS;
ALTER TABLE CHP.MEDIA DROP COLUMN RELEASE_DATE;
ALTER TABLE CHP.MEDIA DROP COLUMN EXPIRATION_DATE;
ALTER TABLE CHP.MEDIA DROP COLUMN RIGHTS_CONTACT;

ALTER TABLE CHP.PAGE_VERSION DROP COLUMN FILENAME_VERSION; -- OK (just under 60K records in total)

-- This is to make data check searchable for both v4 and v16
UPDATE FIELDS SET FREETEXT_TYPE = 'text' where NAME = 'DATA_CHECK' and TABLE_NAME = 'PICTURE';
COMMIT;