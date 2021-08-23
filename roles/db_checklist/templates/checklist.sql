ttitle "========== Oracle Version =========="
select instance_name, host_name, version from v$instance;


ttitle "========== Database Name =========="
select name, created, log_mode, open_mode, database_role from v$database;

ttitle "========== Service Name(s) =========="
sho parameter service_names


exit