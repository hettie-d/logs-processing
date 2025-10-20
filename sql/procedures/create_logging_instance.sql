--call logs_meta.create_logging_instance('sweets,'chocolate')
create or replace procedure logs_meta.create_logging_instance(
	in p_customer_name text,
	in p_instance_name text)
language 'plpgsql'
as $body$
declare
  v_sql text;
begin
	if not exists (select 1 from information_schema.tables
    where table_schema=p_customer_name||'_logs'  and  table_name =p_instance_name||'_log')
  then
    v_sql :=format(
    $$create table %s_logs.%s_log
    (
        log_id bigint,
        log_time timestamptz,
    	  exec_range tstzrange,
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
        query_id bigint,
        log_sample_time timestamptz,
        log_timestamp int,
        primary key (log_id,log_sample_time,log_timestamp)
    ) partition by range (log_sample_time);
    create index %s_log_pid_time_log_id on %s_logs.%s_log
      (pid, log_time, log_id);
    create index %s_log_t_query_pattern on %s_logs.%s_log (substr(lower(query),1,1000) text_pattern_ops);
    $$,
      p_customer_name,
      p_instance_name,
      p_instance_name,
      p_customer_name,
      p_instance_name,
      p_instance_name,
      p_customer_name,
      p_instance_name);
    execute v_sql;
  end if;
end;
$body$;
