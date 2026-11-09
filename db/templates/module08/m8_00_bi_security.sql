-- db/templates/module08/m8_00_bi_security.sql
-- Goal: create a readonly BI role and grant minimal read access.
-- Run this file again when BI role or grants must be recreated.

\set ON_ERROR_STOP on

\if :{?bi_pg_password}
\else
\set bi_pg_password bi_readonly_change_me
\endif

select format('create role bi_readonly login password %L', :'bi_pg_password')
where not exists (
  select 1
  from pg_roles
  where rolname = 'bi_readonly'
)
\gexec

alter role bi_readonly with login password :'bi_pg_password';
alter role bi_readonly nosuperuser nocreatedb nocreaterole noinherit;

grant connect on database dwh to bi_readonly;

create schema if not exists marts;
create schema if not exists airflow_log;
create schema if not exists bi;
create schema if not exists dq;

grant usage on schema marts to bi_readonly;
grant usage on schema airflow_log to bi_readonly;
grant usage on schema bi to bi_readonly;
grant usage on schema dq to bi_readonly;

grant select on all tables in schema marts to bi_readonly;
grant select on all tables in schema airflow_log to bi_readonly;
grant select on all tables in schema bi to bi_readonly;
grant select on all tables in schema dq to bi_readonly;

alter default privileges in schema marts grant select on tables to bi_readonly;
alter default privileges in schema airflow_log grant select on tables to bi_readonly;
alter default privileges in schema bi grant select on tables to bi_readonly;
alter default privileges in schema dq grant select on tables to bi_readonly;
