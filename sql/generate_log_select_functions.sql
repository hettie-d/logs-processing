/*
select * from sweets_logs.select_pid('chocolate',114098,'2024-04-08')
select * from sweets_logs.select_query_pid_count('chocolate',
$$DELETE FROM customer_survey$$,'2024-05-15')
select * from sweets_logs.select_query_pid_count('chocolate',
$$BEGIN$$,'2024-05-15')

*/
	
---select * from logs_meta.generate_log_select_functions('sweets')
create or replace function logs_meta.generate_log_select_functions (p_customer_name text)
returns text
language plpgsql as
$func$
declare 
  v_create_sql text;
  v_schema_name text;
  v_log_record_type text :=$t$
	log_id bigint,
    log_time timestamptz,
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
    log_timestamp int$t$;
    v_pid_count_record_type text :=$t$
    pid int,
    sql_count bigint,
    avg_duration numeric,
	min_duration numeric,
    max_duration numeric
    $t$;
begin
v_schema_name:=p_customer_name||'_logs';
execute $ct$drop type if exists  $ct$||v_schema_name||$ct$.log_record_type cascade;
	create type $ct$||v_schema_name||$ct$.log_record_type as ($ct$||v_log_record_type||$ct$
	   );
	   drop type if exists  $ct$||v_schema_name||$ct$.pid_count_record_type cascade;
	   create type $ct$||v_schema_name||$ct$.pid_count_record_type as ($ct$||v_pid_count_record_type||$ct$
	   );
	   $ct$;
v_create_sql:=
$txt$ CREATE OR REPLACE FUNCTION $txt$||v_schema_name||
	$txt$.select_pid(p_instance_name text, p_pid bigint, p_log_date date)
returns setof $txt$||v_schema_name||
	$txt$.log_record_type
language plpgsql 
as
	$body$
	declare 
	v_sql text;
	v_full_table_name text:=$txt$||quote_literal(v_schema_name||'.')||$txt$||p_instance_name||'_log';
	begin
	v_sql:=$$select *
		from $$||v_full_table_name||$$
	where 
	pid=$$ ||p_pid::text||$$
	and log_sample_time=$$ ||quote_literal(p_log_date::text)||$$
	order by log_id$$;
return query 
	execute v_sql;
end;
$body$;
CREATE OR REPLACE FUNCTION $txt$||v_schema_name||
	$txt$.select_query_pid_count(p_instance_name text, p_query text, p_log_date date)
returns setof $txt$||v_schema_name||
	$txt$.pid_count_record_type
language plpgsql 
as
	$body$
	declare 
	v_sql text;
	v_full_table_name text:=$txt$||quote_literal(v_schema_name||'.')||$txt$||p_instance_name||'_log';
	begin
	v_sql:=format($$select pid,  count(*),
		avg(duration),
		min(duration),
		max(duration)
 		      from %s
	        where substr(lower(query),1,1000) like %L
 	        and log_sample_time=%L
	        group by 1 order by 2 desc;$$,
	v_full_table_name,
	lower(p_query) ||'%',
	p_log_date::text)
	;
return query 
	execute v_sql;
end;
$body$;

$txt$ ;
raise notice '%', v_create_sql;
execute v_create_sql;
return v_create_sql;
end; $func$;


/*

select distinct pid from cumberland_logs.reflect_cert_log
where substr (lower(query),1, 1000) like 'select message from extended_trade_response%'

	and log_sample_time='2024-05-15'

select * from cumberland_logs.reflect_cert_log
where pid=76045 and log_sample_time='2024-05-15' order by 1 desc

select min(duration), max(duration), avg(duration) from cumberland_logs.reflect_cert_log
where pid=76045 and duration is not null

*/