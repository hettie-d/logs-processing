--call logs_meta.create_logging('test');
create or replace procedure logs_meta.create_logging(
	in p_customer_name text)
language 'plpgsql'
as $body$
declare
v_result text;
begin
if not exists (select 1 from pg_namespace where nspname=p_customer_name||'_logs')
then
   execute 'create schema '||p_customer_name||'_logs';
   execute format ($$create table %s_logs.processed_logfiles(
     instance_name text,
     logfile_name text,
     log_timestamp int,
     log_sample_time timestamptz,
     log_load_time timestamptz,
     errors text,
     load_count int,
     primary key (logfile_name, instance_name));$$,
     p_customer_name);
   execute format ($$create table %s_logs.partition_creation (
     instance_name text,
     partition_name text,
     partition_created_at timestamptz,
     errors text,
     primary key (instance_name, partition_name));$$,
     p_customer_name);
 end if;
end;
$body$;

