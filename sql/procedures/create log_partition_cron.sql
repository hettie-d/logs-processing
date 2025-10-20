create or replace procedure logs_meta.create_log_partition_cron(
	in p_customer_name text,
	in p_instance_name text,
	in p_partition_name text)
language 'plpgsql'
as $body$
declare
  v_error text;
begin
  execute format ($$insert into %s_logs.partition_creation (instance_name, partition_name, partition_created_at)
  values (%l, %l, now())$$,
  p_customer_name,
  p_instance_name,
  p_partition_name);
  execute format (
  $$call logs_meta.create_log_partition(%l,%l,%l)$$,
  p_customer_name,
  p_instance_name,
  p_partition_name);
exception
  when others then
    get stacked diagnostics v_error = message_text;
    execute format ($$insert into %s_logs.partition_creation (instance_name, partition_name, partition_created_at, errors)
      values (%l, %l, now(), %l)
    on conflict (instance_name, partition_name) do update set partition_created_at=now(),errors=%l$$,
    p_customer_name,
    p_instance_name,
    p_partition_name,
    v_error,
    v_error);
 end;
$body$;
