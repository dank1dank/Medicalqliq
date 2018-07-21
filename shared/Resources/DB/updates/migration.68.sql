CREATE TABLE IF NOT EXISTS qx_fax_contact (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    uuid TEXT,
    fax_number TEXT,
    voice_number TEXT,
    organization TEXT COLLATE NOCASE,
    contact_name TEXT COLLATE NOCASE,
    is_created_by_user INTEGER,
    group_qliq_id TEXT
);
CREATE INDEX IF NOT EXISTS qx_fax_contact_fax_number_idx ON qx_fax_contact(fax_number);
CREATE INDEX IF NOT EXISTS qx_fax_contact_organization_idx ON qx_fax_contact(organization);
CREATE INDEX IF NOT EXISTS qx_fax_contact_contact_name_idx ON qx_fax_contact(contact_name);