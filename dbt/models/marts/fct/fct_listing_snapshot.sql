with listings as (
    select * from {{ ref('stg_sale_listings') }}
),

property as (
    select property_sk, property_key, valid_from, valid_to from {{ ref('dim_property') }}
),

agent as (
    select agent_sk, agent_key, valid_from, valid_to from {{ ref('dim_agent') }}
),

office as (
    select office_sk, office_key, valid_from, valid_to from {{ ref('dim_office') }}
)

select
    l.listing_key,
    l.load_id,
    l.loaded_at,
    strftime(l.loaded_at, '%Y%m%d')::integer          as loaded_date_key,

    p.property_sk,
    a.agent_sk,
    o.office_sk,

    l.mls_name,
    l.mls_number,
    l.listing_type,
    l.listing_status,

    l.price,
    l.days_on_market,
    l.price / nullif(l.square_footage, 0)             as price_per_sqft,
    l.hoa_fee
from listings as l
left join property as p
    on  l.property_key = p.property_key
    and l.loaded_at >= p.valid_from
    and (l.loaded_at < p.valid_to or p.valid_to is null)
left join agent as a
    on  l.agent_key = a.agent_key
    and l.loaded_at >= a.valid_from
    and (l.loaded_at < a.valid_to or a.valid_to is null)
left join office as o
    on  l.office_key = o.office_key
    and l.loaded_at >= o.valid_from
    and (l.loaded_at < o.valid_to or o.valid_to is null)
