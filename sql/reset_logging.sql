alter system reset log_rotation_age;
alter system reset log_min_duration_statement;
alter system reset log_checkpoints;
alter system reset log_connections;
alter system reset log_disconnections;
alter system reset log_duration;
alter system reset log_lock_waits;
alter system reset log_autovacuum_min_duration;
select pg_reload_conf();
