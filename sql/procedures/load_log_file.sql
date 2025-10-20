/*
call logs_meta.load_log_file(
	'sweets',
	'chocolate',
	'2024-08-08',
	'postgresql-chocolate-1895641980012'
	)
*/	
create or replace procedure logs_meta.load_log_file(
	in p_customer_name text,
	in p_instance_name text,
	in p_partition_name text,
	in p_logfile_name text,
	in p_log_base text default '/pgbadger_logs')
language 'plpgsql'
as $body$
declare
  v_sql text;
  v_cnt int;
  v_log_timestamp int:=(right(p_logfile_name,10))::int;
  v_partition_name text:=translate (p_partition_name,'-','_');
  v_error text;
begin
	v_sql := format (
    $$insert into %s_logs.processed_logfiles(
      instance_name,
      logfile_name,
      log_timestamp,
      log_sample_time,
      log_load_time)
    values (%l, %l, %s,%l, %l) 
    on conflict (logfile_name, instance_name) do update set log_load_time=now(), errors=null$$,
      p_customer_name,
      p_instance_name,
      p_logfile_name,
      v_log_timestamp,
      p_partition_name,
      now());
  execute v_sql;
  v_sql :=format(
    $$drop foreign table if exists logs_ft.%s_%s_%s_log;
    create foreign table logs_ft.%s_%s_%s_log(
      log_time timestamp with time zone,
      user_name text ,
      database_name text ,
      pid integer,
      client text ,
      sessionid text ,
      loglevel text ,
      sqlstate text ,
      duration numeric,
      query text ,
      parameters text ,
      appname text ,
      backend_type text ,
      query_id bigint
    )
      server pglogs
        options (filename '%s/%s/%s/csv_files/%s.csv', format 'csv', header 'true', delimiter '#');
    drop table if exists
      %s_logs.%s_log_t_%s_%s;
    create table %s_logs.%s_log_%s_%s
      partition of %s_logs.%s_log_t_%s for values in (%s);
    insert into %s_logs.%s_log (
      log_id,
      log_time ,
    	exec_range,
      user_name ,
      database_name,
      pid  ,
      client,
      sessionid,
      loglevel ,
      sqlstate ,
      duration ,
      query  ,
      parameters,
      appname ,
      backend_type,
      query_id,
      log_sample_time,
      log_timestamp)
    select (%s::bigint)*1000000000+(row_number() over ()),
      log_time ,
      tstzrange(date_add(log_time, -((duration)::text ||' ms')::interval),log_time) ,
      user_name ,
      database_name,
      pid  ,
      client,
      sessionid,
      loglevel ,
      sqlstate ,
      duration ,
      query  ,
      parameters,
      appname ,
      backend_type,
      query_id,
      %l,
      %s
    from logs_ft.%s_%s_%s_log;$$,
      p_customer_name,
      p_instance_name,
      v_log_timestamp,
      p_customer_name,
      p_instance_name,
      v_log_timestamp,
      p_log_base,
      p_customer_name,
      p_instance_name,
      p_logfile_name,
      p_customer_name,
      p_instance_name,
      v_partition_name,
      v_log_timestamp,
      p_customer_name,
      p_instance_name,
      v_partition_name,
      v_log_timestamp,
      p_customer_name,
      p_instance_name,
      v_partition_name,
      v_log_timestamp,
      p_customer_name,
      p_instance_name,
      v_log_timestamp,
      p_partition_name,
      v_log_timestamp,
      p_customer_name,
      p_instance_name,
      v_log_timestamp
     );
  execute v_sql;
  get diagnostics v_cnt:=row_count;
  v_sql := format (
    $$update %s_logs.processed_logfiles set load_count=%s
  	  where instance_name=%l and  logfile_name=%l$$,
      p_customer_name,
      v_cnt,	
      p_instance_name,
      p_logfile_name
      );
  execute v_sql;
  execute format ($$drop foreign table if exists logs_ft.%s_%s_%s_log$$,
  	p_customer_name,
    p_instance_name,
    v_log_timestamp);
exception when others then
  get stacked diagnostics v_error = message_text;
  v_sql := format (
    $$insert into %s_logs.processed_logfiles(
      instance_name,
      logfile_name,
      log_timestamp,
      log_sample_time,
      log_load_time,
    	  errors)
    values
      (%l, %l, %s,%l, %l,%l) on conflict (logfile_name, instance_name) do update set log_load_time=now(), errors=%l$$,
      p_customer_name,
      p_instance_name,
      p_logfile_name,
      v_log_timestamp,
      p_partition_name,
      now(),
      v_error,
      v_error);
  execute v_sql;
end;
$body$;





