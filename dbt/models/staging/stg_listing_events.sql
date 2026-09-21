{{ config(alias='listing_events') }}

with exploded as (
    select
        listing_key,
        property_key,
        load_id,
        unnest(json_keys(history))           as event_date,
        unnest(json_extract(history, '$.*')) as event
    from {{ ref('stg_sale_listings') }}
),

typed as (
    select
        listing_key,
        property_key,
        load_id,
        event_date::date                          as event_date,
        event ->> '$.event'                       as event_type,
        (event ->> '$.price')::bigint             as price,
        event ->> '$.listingType'                 as listing_type,
        (event ->> '$.daysOnMarket')::integer     as days_on_market,
        (event ->> '$.listedDate')::timestamptz   as listed_date,
        (event ->> '$.removedDate')::timestamptz  as removed_date
    from exploded
)

select * exclude (load_id)
from typed
qualify row_number() over (partition by listing_key, event_date order by load_id desc) = 1
