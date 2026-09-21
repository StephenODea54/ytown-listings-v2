with observations as (
    select
        listing_key,
        property_key,
        loaded_at,
        price,
        days_on_market,
        listed_date,
        lag(price) over (partition by listing_key order by loaded_at) as previous_price
    from {{ ref('stg_sale_listings') }}
),

per_listing as (
    select
        listing_key,
        any_value(property_key)                                as property_key,
        any_value(listed_date)                                 as listed_date,
        min(loaded_at)                                         as first_seen_at,
        max(loaded_at)                                         as last_seen_at,
        count(*)                                               as times_observed,
        arg_min(price, loaded_at)                              as initial_price,
        arg_max(price, loaded_at)                              as current_price,
        min(price)                                             as min_price,
        max(price)                                             as max_price,
        count(*) filter (where price < previous_price)         as price_cut_count,
        count(*) filter (where price > previous_price)         as price_increase_count,
        arg_max(days_on_market, loaded_at)                     as days_on_market
    from observations
    group by listing_key
),

events as (
    select
        listing_key,
        count(*)                                                       as times_listed,
        max(removed_date) filter (where removed_date is not null)      as previous_removed_at,
        min(listed_date)  filter (where removed_date is null)          as current_listed_at
    from {{ ref('stg_listing_events') }}
    group by listing_key
),

latest_load as (
    select max(loaded_at) as loaded_at from {{ ref('stg_sale_listings') }}
),

current_property as (
    select property_sk, property_key from {{ ref('dim_property') }} where valid_to is null
)

select
    pl.listing_key,
    cp.property_sk,
    pl.listed_date,
    pl.first_seen_at,
    pl.last_seen_at,
    pl.last_seen_at = (select loaded_at from latest_load)                    as is_active,
    pl.times_observed,
    pl.initial_price,
    pl.current_price,
    pl.min_price,
    pl.max_price,
    pl.current_price - pl.initial_price                                       as price_change_since_first_seen,
    pl.price_cut_count,
    pl.price_increase_count,
    pl.days_on_market,
    e.times_listed,
    e.times_listed - 1                                                        as prior_listing_count,
    e.previous_removed_at,
    date_diff('day', e.previous_removed_at, e.current_listed_at)              as days_off_market_before_listing
from per_listing as pl
left join events as e using (listing_key)
left join current_property as cp using (property_key)
