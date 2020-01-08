-- 4.10.1 to 4.10.2

-- CUSTOM_ORDER fields - revert the changes on manifest table for dual running
update CHP.FIELDS set type = 'STRING', col_size = 4000 where name = 'CUSTOM_ORDER';
commit;


-- 4.10.2 to 4.10.3

-- None


-- 4.10.3 to 16.0.0

-- None


-- 16.0.0 to 16.0.1

-- None


-- 16.0.1 to 16.2.0

-- Search warning context field type change - revert the change on manifest table for dual running
update CHP.FIELDS set type = 'STRING', col_size = 200 where name = 'CONTEXT' and table_name = 'SEARCH_WARNING_TERMS';
commit;


-- 16.2.0 to 16.4.0

-- Icon Manager - restore record on manifest table for dual running
INSERT INTO CHP.FIELDS (TABLE_NAME, NAME, ALIASES, FREETEXT_TYPE, HAS_SEQUENCE, HAS_INDEX, COL_ORDER, FLAGS, NON_NULL, TYPE, COL_SIZE) 
VALUES ('ICON_MANAGER', 'imagetype', null, null, '0', '0', 0, null, '0', 'STRING', 24);
commit;


-- 16.4.0 to 16.4.1

-- None


-- 16.4.1 to CHP 16.4.2

-- None


-- Triggger for live update during dual running
CREATE or REPLACE TRIGGER CHP.DUAL_RUNNING_INDEX
AFTER INSERT ON CHP.MM_INDEX_QUEUE FOR EACH ROW
BEGIN
	INSERT INTO CHP.chp_index_queue (creation_stamp, update_stamp, queue_name, status, item_key, index_id, priority)
	VALUES (:new.creation_stamp, :new.update_stamp, 'MM_INDEX_QUEUE', :new.status, :new.item_key, chp_index_queue_seq.nextval, 1);
END;
/

ALTER TRIGGER CHP.DUAL_RUNNING_INDEX DISABLE;
