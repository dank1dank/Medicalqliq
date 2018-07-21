DROP TABLE IF EXISTS network_status;

CREATE TABLE IF NOT EXISTS network_status (id INTEGER PRIMARY KEY AUTOINCREMENT, timestamp DATETIME, callback_name text, curr_val text, reg_status text, transport_up text, reachable_via text, cell_ip text, wifi_ip text, app_state text);
