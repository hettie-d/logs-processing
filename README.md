# Description 

This repo contains DLL to set up and maintain logs processing server, using [pgBadger](https://github.com/darold/pgbadger raw output processing).
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

