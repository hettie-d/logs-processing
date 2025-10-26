--create database
create extension if not exists file_fdw;
CREATE SERVER if not exists pglogs
    FOREIGN DATA WRAPPER file_fdw;
create schema logs_ft;
create schema logs_meta;

\ir procedures/create_logging.sql
\ir procedures/create_logging_instance.sql
\ir procedures/create_log_partition.sql
\ir procedures/create_log_partition_cron.sql
\ir procedures/load_log_file.sql
\ir generate_search_functions.sql
