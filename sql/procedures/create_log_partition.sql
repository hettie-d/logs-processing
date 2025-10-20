--call logs_meta.create_log_partition('sweets','chocolate','2024-08-20');

create or replace procedure logs_meta.create_log_partition(p_customer_name text,
p_instance_name text,
p_partition_name text)
language plpgsql as
$proc$
declare
v_sql text;
begin
v_sql :=format($$create table %s_logs.%s_log_%s
 partition of %s_logs.%s_log 
 for values from (%L) to (%L)
 partition by list (log_timestamp);$$,
 p_customer_name,
 p_instance_name,
 translate (p_partition_name,'-','_'),
 p_customer_name,
 p_instance_name,
 p_partition_name,
 (p_partition_name::date+1)::text);
 execute v_sql;
end;
$proc$;
