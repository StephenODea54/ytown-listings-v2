{% snapshot dim_office %}

{{ config(
    unique_key='office_key',
    strategy='check',
    check_cols=['office_name', 'office_phone_number', 'office_email', 'office_website'],
    updated_at='loaded_at',
    hard_deletes='ignore',
    snapshot_meta_column_names={
        'dbt_scd_id': 'office_sk',
        'dbt_valid_from': 'valid_from',
        'dbt_valid_to': 'valid_to'
    }
) }}

with latest_load as (
    select max(load_id) as load_id from {{ ref('stg_sale_listings') }}
)

select
    office_key,
    loaded_at,
    listing_office_name          as office_name,
    listing_office_phone_number  as office_phone_number,
    listing_office_email         as office_email,
    listing_office_website       as office_website
from {{ ref('stg_sale_listings') }}
where load_id = (select load_id from latest_load)
  and office_key is not null
qualify row_number() over (partition by office_key order by last_seen_date desc) = 1

{% endsnapshot %}
