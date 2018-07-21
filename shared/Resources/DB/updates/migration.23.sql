# Recipients

ALTER TABLE recipients ADD COLUMN recipients_qliq_id TEXT;

# Running objective-c migration. Performing selector below from class DBUtilObjcMigration.

objc: migration_to_23;

# Drop unused tables

DROP TABLE conversation_leg;
DROP TABLE multiparty;
DROP TABLE multiparty_participants;


# Recreate conversation table to remove column

CREATE TABLE conversation_db23 (id integer NOT NULL PRIMARY KEY AUTOINCREMENT, recipients_id INTEGER NOT NULL, subject text NOT NULL,created_at datetime NOT NULL,last_updated datetime NOT NULL,archived integer DEFAULT 0,deleted integer DEFAULT 0);

INSERT INTO conversation_db23 (id, recipients_id, subject, created_at, last_updated, archived, deleted)
SELECT id, recipients_id, subject, created_at, last_updated, archived, deleted FROM conversation;

PRAGMA foreign_keys = OFF;
DROP TABLE conversation;
PRAGMA foreign_keys = ON;

ALTER TABLE conversation_db23 RENAME TO conversation;