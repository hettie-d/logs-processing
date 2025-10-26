# Description 

This repo contains DLL to set up and maintain logs processing server, using [pgBadger](https://github.com/darold/pgbadger raw output processing).

Not included: python or sh to orchestrate the process of enabling full logging, shipping log files and disabling full logging

## TOC

* sql subdirectory: server setup
* presentations subdirectory: ppt and recordings

## pgBadger execution

During the load, we calculate the actual time interval during which each query was executed. To make sure these calculations are precise enough, we suggest to use miliseconds instead of seconds in the line prefix parameter (%m instead of %t)

```log_line_prefix = '%m [%p]: user=%u,db=%d,app=%a,client=%h ```

The rest of the parameters are the same as in the standard pgBadger documentation:

```    log_checkpoints = on
    log_connections = on
    log_disconnections = on
    log_lock_waits = on
    log_temp_files = 0
    log_autovacuum_min_duration = 0
    log_error_verbosity = default
    log_rotation_age= '10min'
```    

The pgBadger is called with the following parameters:

--dump-raw-csv
--csv-separator ='#'

And the output is directed to the corresponding directory.

## Postgres functions and procs

*All functions are created in the logs_meta schema*

| Function/procedure| Parameters|Description
|-------------------------------------------------- | ----------------------------- |-----------------------------------------------| 
|**call logs_meta.create_logging** (p_customer_name)|Creates a schema \<customer_name\>_logs for a new customer and partition_create and processed_logs tables|
|**call logs_meta.create_logging_instance** (p_customer_name, p_instance_name)| **p_customer_name**: customer, points to the specific schema, **p_instance_name**: instance name, used to create a table for instance logging| Creates a table \<instance_name\>_log in \<customer_name\>_logs schema
|**call logs_meta.load_log_file** (p_customer_name, p_instance_name, p_partition_name,p_logfile_name,p_log_base)| **p_customer_name**: customer, points to the specific schema, **p_instance_name**: instance name, points to a table, **p_partition_name**: the date of logging, **p_logfile_name**: name of the log file to load, **p_log_base**: the path to the root of the logfiles directory| (re)loads a subpartition specified by the p_logfile_name parameter \<instance_name\>_log in \<customer_name\>_logs schema

## How it all works

* We process all logs from different customers in one postgres instance, which is created specifically for logs processing, so we do not interfere with normal query processing on the host which we analyze
* We create a separate schema for each customer we are processing, and restrict access to that schema to one customer only, so that the customers can't see other customers' logs
* In each schema, we create monitoring tables which record processed log files and any errors that could occur during the processing
* In addition, we create a partitioned table for each Postgres instance we are monitoring
* The upper level of partitioning is the date of logging
* The subpartitions are created for each file we load

## How we load and reload files, and other little tricks

The records in the log files are not numbered, the only way we can get an idea in which order they were written is the actual order of records in the file(s), so it is important to keep the original order of log records. At the same time, we want to be able to reload a files if an error occured, or if we accidentally missed a log file. That's how we achieve that: 

* Each logfile name is generated with the suffix which represent the time when the file was created in the EPOCH format (last ten positions in the file name)
* When we load a log file into Postgres table, we create a new subpartition and generate log_id for each record as ```<log_suffix>* 10^9 + (row_number() over ())```. That way, all ids in the "later" partition will be greater that any id in the "previous" partition, and the order within partition will be preserved as well. 
* Since each log file creates a separate partition, we can load several log files simultaneously. If an error occured, we can drop this partition and reload the same file again. 

Other cool things:

* exec_range value is calculated as a range with the start time = log_time -duration and end time=log_time, and we build a GIST index on this field. This helps identifying the statements which we executed at the same time.
* You can generate search functions for each customer by calling
```
select * from logs_meta.generate_log_select_functions (p_customer_name text);
```
When functions are created,a customer can analyze the logs using these functions, for example:

```
select * from sweets_logs.select_pid('chocolate',114098,'2024-04-08');

select * from sweets_logs.select_query_pid_count('chocolate', $$DELETE FROM customer_survey$$,'2024-05-15');

select * from sweets_logs.select_query_pid_count('chocolate', $$BEGIN$$,'2024-05-15');

```
