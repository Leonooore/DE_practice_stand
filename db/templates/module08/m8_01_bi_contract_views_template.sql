-- db/templates/module08/m8_01_bi_contract_views_template.sql
-- Goal: stable bi.* contract layer for Metabase.
-- Map mart columns to BI names once and keep dashboard logic out of UI.

\set ON_ERROR_STOP on

create schema if not exists bi;

-- Rebuild the base contract views because CREATE OR REPLACE cannot remove or
-- reorder columns from views left by an earlier course version.
drop view if exists bi.v_reconcile_sales_daily;
drop view if exists bi.v_sales_daily;
drop view if exists bi.v_order_items_wide;

-- 1) Daily contract.
do $$
begin
  if to_regclass('marts.sales_daily') is not null then
    execute $sql$
      create or replace view bi.v_sales_daily as
      select
        sales_date,
        coalesce(nullif(btrim(product_category_name), ''), 'unknown')::varchar as category,
        coalesce(nullif(btrim(customer_state), ''), 'unknown')::varchar as customer_state,
        total_revenue as net_revenue,
        orders_cnt,
        items_cnt,
        uniq_customers_cnt,
        uniq_sellers_cnt,
        src_ingest_date,
        load_dttm
      from marts.sales_daily
    $sql$;
  else
    execute $sql$
      create or replace view bi.v_sales_daily as
      select
        null::date as sales_date,
        null::varchar as category,
        null::varchar as customer_state,
        null::numeric as net_revenue,
        null::bigint as orders_cnt,
        null::bigint as items_cnt,
        null::bigint as uniq_customers_cnt,
        null::bigint as uniq_sellers_cnt,
        null::date as src_ingest_date,
        null::timestamptz as load_dttm
      where false
    $sql$;
  end if;
end $$;

-- 2) Wide fact contract.
-- Grain: order_id + order_item_id.
do $$
begin
  if to_regclass('marts.fct_order_items_wide') is not null then
    execute $sql$
      create or replace view bi.v_order_items_wide as
      select
        order_id,
        order_item_id,
        order_date as sales_date,
        coalesce(nullif(btrim(product_category_name), ''), 'unknown')::varchar as category,
        coalesce(nullif(btrim(customer_state), ''), 'unknown')::varchar as customer_state,
        (coalesce(price, 0) + coalesce(freight_value, 0)) as net_revenue,
        customer_sk,
        product_sk,
        seller_sk,
        src_ingest_date,
        load_dttm
      from marts.fct_order_items_wide
      where order_date is not null
    $sql$;
  else
    execute $sql$
      create or replace view bi.v_order_items_wide as
      select
        null::varchar as order_id,
        null::int as order_item_id,
        null::date as sales_date,
        null::varchar as category,
        null::varchar as customer_state,
        null::numeric as net_revenue,
        null::bigint as customer_sk,
        null::bigint as product_sk,
        null::bigint as seller_sk,
        null::date as src_ingest_date,
        null::timestamptz as load_dttm
      where false
    $sql$;
  end if;
end $$;

-- 3) Reconcile wide vs daily by net_revenue on daily grain.
create or replace view bi.v_reconcile_sales_daily as
with wide as (
  select
    sales_date,
    category,
    customer_state,
    sum(net_revenue) as revenue_wide
  from bi.v_order_items_wide
  group by 1, 2, 3
),
daily as (
  select
    sales_date,
    category,
    customer_state,
    sum(net_revenue) as revenue_daily
  from bi.v_sales_daily
  group by 1, 2, 3
)
select
  coalesce(w.sales_date, d.sales_date) as sales_date,
  coalesce(w.category, d.category) as category,
  coalesce(w.customer_state, d.customer_state) as customer_state,
  coalesce(d.revenue_daily, 0) as revenue_daily,
  coalesce(w.revenue_wide, 0) as revenue_wide,
  (coalesce(w.revenue_wide, 0) - coalesce(d.revenue_daily, 0)) as diff
from wide w
full join daily d using (sales_date, category, customer_state);

-- 4) Last pipeline run from audit.
-- The course audit table uses event_type. Older stand volumes used status,
-- so normalize both source layouts to the current BI contract.
drop view if exists bi.v_pipeline_last_run;

do $$
begin
  if to_regclass('airflow_log.pipeline_audit') is not null
     and exists (
       select 1
       from information_schema.columns
       where table_schema = 'airflow_log'
         and table_name = 'pipeline_audit'
         and column_name = 'event_type'
     ) then
    execute $sql$
      create or replace view bi.v_pipeline_last_run as
      with last_run as (
        select dag_id, run_id
        from airflow_log.pipeline_audit
        order by event_ts desc
        limit 1
      )
      select
        max(a.ingest_date) as last_ingest_date,
        max(a.event_ts) as last_event_ts,
        count(*) as audit_events_cnt,
        count(*) filter (
          where lower(a.event_type) like '%start%'
        ) as start_events_cnt,
        count(*) filter (
          where lower(a.event_type) like '%finish%'
             or lower(a.event_type) like '%success%'
        ) as finish_events_cnt,
        count(*) filter (
          where lower(a.event_type) like '%fail%'
             or lower(a.event_type) like '%error%'
        ) as failed_events_cnt
      from airflow_log.pipeline_audit a
      join last_run r on r.dag_id = a.dag_id and r.run_id = a.run_id
    $sql$;
  elsif to_regclass('airflow_log.pipeline_audit') is not null
     and exists (
       select 1
       from information_schema.columns
       where table_schema = 'airflow_log'
         and table_name = 'pipeline_audit'
         and column_name = 'status'
     ) then
    execute $sql$
      create or replace view bi.v_pipeline_last_run as
      with last_run as (
        select dag_id, run_id
        from airflow_log.pipeline_audit
        order by event_ts desc
        limit 1
      )
      select
        max(a.ingest_date) as last_ingest_date,
        max(a.event_ts) as last_event_ts,
        count(*) as audit_events_cnt,
        count(*) filter (where lower(a.status) like '%start%') as start_events_cnt,
        count(*) filter (
          where lower(a.status) like '%finish%'
             or lower(a.status) like '%success%'
        ) as finish_events_cnt,
        count(*) filter (
          where lower(a.status) like '%fail%'
             or lower(a.status) like '%error%'
        ) as failed_events_cnt
      from airflow_log.pipeline_audit a
      join last_run r on r.dag_id = a.dag_id and r.run_id = a.run_id
    $sql$;
  else
    execute $sql$
      create or replace view bi.v_pipeline_last_run as
      select
        null::date as last_ingest_date,
        null::timestamptz as last_event_ts,
        null::bigint as audit_events_cnt,
        null::bigint as start_events_cnt,
        null::bigint as finish_events_cnt,
        null::bigint as failed_events_cnt
      where false
    $sql$;
  end if;
end $$;

-- 5) Smoke checks from the latest run.
-- checked_at/smoke_name are the course names; event_ts/check_id are legacy.
drop view if exists bi.v_smoke_last_run;

do $$
begin
  if to_regclass('airflow_log.pipeline_smoke_check') is not null
     and to_regclass('airflow_log.pipeline_audit') is not null
     and exists (
       select 1
       from information_schema.columns
       where table_schema = 'airflow_log'
         and table_name = 'pipeline_smoke_check'
         and column_name = 'checked_at'
     ) then
    execute $sql$
      create or replace view bi.v_smoke_last_run as
      with last_run as (
        select dag_id, run_id
        from airflow_log.pipeline_audit
        order by event_ts desc
        limit 1
      )
      select
        s.checked_at,
        s.dag_id,
        s.run_id,
        s.ingest_date,
        s.smoke_name,
        s.status,
        s.metric_value::numeric as metric_value,
        s.details
      from airflow_log.pipeline_smoke_check s
      join last_run r on r.dag_id = s.dag_id and r.run_id = s.run_id
      order by s.checked_at desc, s.smoke_name
    $sql$;
  elsif to_regclass('airflow_log.pipeline_smoke_check') is not null
     and to_regclass('airflow_log.pipeline_audit') is not null
     and exists (
       select 1
       from information_schema.columns
       where table_schema = 'airflow_log'
         and table_name = 'pipeline_smoke_check'
         and column_name = 'event_ts'
     ) then
    execute $sql$
      create or replace view bi.v_smoke_last_run as
      with last_run as (
        select dag_id, run_id
        from airflow_log.pipeline_audit
        order by event_ts desc
        limit 1
      )
      select
        s.event_ts as checked_at,
        s.dag_id,
        s.run_id,
        null::date as ingest_date,
        s.check_id as smoke_name,
        s.status,
        s.metric_value::numeric as metric_value,
        s.details
      from airflow_log.pipeline_smoke_check s
      join last_run r on r.dag_id = s.dag_id and r.run_id = s.run_id
      order by s.event_ts desc, s.check_id
    $sql$;
  else
    execute $sql$
      create or replace view bi.v_smoke_last_run as
      select
        null::timestamptz as checked_at,
        null::text as dag_id,
        null::text as run_id,
        null::date as ingest_date,
        null::text as smoke_name,
        null::text as status,
        null::numeric as metric_value,
        null::text as details
      where false
    $sql$;
  end if;
end $$;

-- 6) Recent DQ results from module 5.
do $$
begin
  if to_regclass('dq.check_results') is not null then
    execute $sql$
      create or replace view bi.v_dq_recent_results as
      select
        checked_at,
        run_id,
        check_no,
        check_name,
        layer,
        dataset,
        status,
        details
      from dq.check_results
      where checked_at >= now() - interval '30 days'
      order by checked_at desc, run_id, check_no
    $sql$;
  else
    execute $sql$
      create or replace view bi.v_dq_recent_results as
      select
        null::timestamptz as checked_at,
        null::text as run_id,
        null::int as check_no,
        null::text as check_name,
        null::text as layer,
        null::text as dataset,
        null::text as status,
        null::jsonb as details
      where false
    $sql$;
  end if;
end $$;

-- Grants for the contract layer.
grant usage on schema bi to bi_readonly;
grant select on all tables in schema bi to bi_readonly;
alter default privileges in schema bi grant select on tables to bi_readonly;
