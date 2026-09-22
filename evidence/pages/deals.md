---
title: Deals
---

# Overview

What's cheap per square foot, what's priced under its neighbours, who has been trying to sell for a while.

```sql latest_load
select max(loaded_at) as loaded_at from lake.fct_listing_snapshot
```

```sql counties
select distinct county from lake.dim_property order by 1
```

<Dropdown data={counties} name=county value=county title="County">
    <DropdownOption value="%" valueLabel="All counties" />
</Dropdown>

```sql active
select
    s.listing_key,
    p.formatted_address,
    p.city,
    p.county,
    s.price,
    s.price_per_sqft,
    p.num_bedrooms,
    p.num_bathrooms,
    p.square_footage,
    p.year_built,
    s.days_on_market,
    s.listing_type
from lake.fct_listing_snapshot as s
join lake.dim_property as p using (property_sk)
where s.loaded_at = (select loaded_at from ${latest_load})
  and p.county like '${inputs.county.value}'
```

## Cheapest per square foot

Listings of at least 800 sqft are included

```sql cheapest_per_sqft
select * from ${active}
where square_footage >= 800
order by price_per_sqft asc
limit 25
```

<DataTable data={cheapest_per_sqft} rows=25>
    <Column id=formatted_address title="Address" />
    <Column id=city />
    <Column id=price fmt=usd0 />
    <Column id=square_footage fmt=num0 title="Sqft" />
    <Column id=price_per_sqft fmt=usd0 title="$/sqft" />
    <Column id=num_bedrooms fmt=num0 title="Beds" />
    <Column id=year_built fmt=id title="Built" />
</DataTable>

## Priced under the city

Listings asking less than 70% of their city's median, in cities with at least ten listings.

```sql under_city_median
with city_median as (
    select city, median(price) as city_median_price, count(*) as city_listings
    from ${active}
    group by city
    having count(*) >= 10
)
select
    a.formatted_address,
    a.city,
    a.price,
    c.city_median_price,
    a.price / c.city_median_price           as share_of_city_median,
    a.num_bedrooms,
    a.square_footage,
    a.days_on_market
from ${active} as a
join city_median as c using (city)
where a.price < 0.7 * c.city_median_price
order by a.price desc
```

<DataTable data={under_city_median} rows=25>
    <Column id=formatted_address title="Address" />
    <Column id=city />
    <Column id=price fmt=usd0 />
    <Column id=city_median_price fmt=usd0 title="City median" />
    <Column id=share_of_city_median fmt=pct0 title="Of median" />
    <Column id=num_bedrooms fmt=num0 title="Beds" />
    <Column id=square_footage fmt=num0 title="Sqft" />
</DataTable>

## Motivated sellers

Properties ranked by how far the asking price has fallen since the previous listing.

```sql relisted
select
    p.formatted_address,
    p.city,
    l.times_listed,
    l.previous_listing_price,
    l.current_price,
    l.price_change_since_previous_listing,
    l.price_change_since_previous_listing / l.previous_listing_price as change_share,
    l.days_off_market_before_listing,
    l.days_on_market
from lake.fct_listing_lifecycle as l
join lake.dim_property as p using (property_sk)
where l.is_active
  and l.times_listed > 1
  and p.county like '${inputs.county.value}'
order by change_share asc
```

```sql relisted_summary
select
    count(*)                                            as relisted,
    count(*) filter (where price_change_since_previous_listing < 0) as cheaper_than_before,
    median(days_off_market_before_listing)              as median_days_off_market
from ${relisted}
```

<BigValue data={relisted_summary} value=relisted title="Relisted properties" />
<BigValue data={relisted_summary} value=cheaper_than_before title="Back on cheaper" />
<BigValue data={relisted_summary} value=median_days_off_market fmt=num0 title="Median days off market" />

<DataTable data={relisted} rows=25>
    <Column id=formatted_address title="Address" />
    <Column id=city />
    <Column id=times_listed fmt=num0 title="Times listed" />
    <Column id=previous_listing_price fmt=usd0 title="Previous ask" />
    <Column id=current_price fmt=usd0 title="Current ask" />
    <Column id=change_share fmt=pct0 title="Change" contentType=delta downIsGood=true />
    <Column id=days_off_market_before_listing fmt=num0 title="Days off market" />
</DataTable>

## Sitting on the market

Active for more than 90 days.

```sql stale
select * from ${active}
where days_on_market > 90
order by days_on_market desc
```

```sql stale_summary
select count(*) as stale, median(days_on_market) as median_days from ${stale}
```

<Value data={stale_summary} column=stale fmt=num0 /> listings have been active for over 90 days, median <Value data={stale_summary} column=median_days fmt=num0 /> days.

<DataTable data={stale} search=true rows=25>
    <Column id=formatted_address title="Address" />
    <Column id=city />
    <Column id=price fmt=usd0 />
    <Column id=price_per_sqft fmt=usd0 title="$/sqft" />
    <Column id=days_on_market fmt=num0 title="Days on market" />
    <Column id=listing_type title="Type" />
</DataTable>
