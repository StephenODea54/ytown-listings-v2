{% snapshot dim_property %}

{{ config(
    unique_key='property_key',
    strategy='check',
    check_cols=[
        'formatted_address', 'primary_address', 'secondary_address',
        'city', 'state', 'state_fips', 'zip_code', 'county', 'county_fips',
        'latitude', 'longitude', 'property_type',
        'num_bedrooms', 'num_bathrooms', 'square_footage', 'lot_size', 'year_built'
    ],
    updated_at='loaded_at',
    hard_deletes='ignore',
    snapshot_meta_column_names={
        'dbt_scd_id': 'property_sk',
        'dbt_valid_from': 'valid_from',
        'dbt_valid_to': 'valid_to'
    }
) }}

with latest_load as (
    select max(load_id) as load_id from {{ ref('stg_sale_listings') }}
)

select
    property_key,
    loaded_at,
    formatted_address,
    primary_address,
    secondary_address,
    city,
    state,
    state_fips,
    zip_code,
    county,
    county_fips,
    latitude,
    longitude,
    property_type,
    num_bedrooms,
    num_bathrooms,
    square_footage,
    lot_size,
    year_built
from {{ ref('stg_sale_listings') }}
where load_id = (select load_id from latest_load)
qualify row_number() over (partition by property_key order by last_seen_date desc) = 1

{% endsnapshot %}
