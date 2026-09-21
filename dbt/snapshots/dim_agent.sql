{% snapshot dim_agent %}

{{ config(
    unique_key='agent_key',
    strategy='check',
    check_cols=['agent_name', 'agent_phone_number', 'agent_email', 'agent_website'],
    updated_at='loaded_at',
    hard_deletes='ignore',
    snapshot_meta_column_names={
        'dbt_scd_id': 'agent_sk',
        'dbt_valid_from': 'valid_from',
        'dbt_valid_to': 'valid_to'
    }
) }}

with latest_load as (
    select max(load_id) as load_id from {{ ref('stg_sale_listings') }}
)

select
    agent_key,
    loaded_at,
    agent_name,
    agent_phone_number,
    agent_email,
    agent_website
from {{ ref('stg_sale_listings') }}
where load_id = (select load_id from latest_load)
  and agent_key is not null
qualify row_number() over (partition by agent_key order by last_seen_date desc) = 1

{% endsnapshot %}
