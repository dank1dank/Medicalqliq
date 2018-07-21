"location","CREATE TABLE IF NOT EXISTS location (id INTEGER NOT NULL, location VARCHAR(45), PRIMARY KEY (id))";
"provider_alert","CREATE TABLE IF NOT EXISTS provider_alert ( id integer NOT NULL PRIMARY KEY AUTOINCREMENT, census_id integer, receiving_provider_npi numeric, severity integer, description text, status integer, created_at datetime, last_updated datetime )";
"room","CREATE TABLE IF NOT EXISTS room ( id integer NOT NULL PRIMARY KEY AUTOINCREMENT, floor_id integer NOT NULL, room text NOT NULL, beds integer DEFAULT 1 )";
