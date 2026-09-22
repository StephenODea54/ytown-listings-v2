---
title: Areas
---

# Areas

```sql latest_load
select max(loaded_at) as loaded_at from lake.fct_listing_snapshot
```

```sql cities
select
    p.city,
    p.county,
    '/areas/' || p.city                     as area_link,
    count(*)                                as listings,
    median(s.price)                         as median_price,
    median(s.price_per_sqft)                as median_price_per_sqft,
    median(s.days_on_market)                as median_days_on_market
from lake.fct_listing_snapshot as s
join lake.dim_property as p using (property_sk)
where s.loaded_at = (select loaded_at from ${latest_load})
group by p.city, p.county
order by listings desc
```

```sql most_expensive
select * from ${cities} where listings >= 10 order by median_price desc limit 10
```

```sql most_affordable
select * from ${cities} where listings >= 10 order by median_price asc limit 10
```

## Cities by median asking price

Only cities with at least 10 active listings are considered.

<Grid cols=2>

<div>

### Most expensive

<BarChart
    data={most_expensive}
    x=city
    y=median_price
    yFmt=usd0
    swapXY=true
    sort=false
/>

<DataTable data={most_expensive} link=area_link>
    <Column id=city />
    <Column id=county />
    <Column id=listings fmt=num0 />
    <Column id=median_price fmt=usd0 title="Median price" />
    <Column id=median_price_per_sqft fmt=usd0 title="$/sqft" />
</DataTable>

</div>

<div>

### Most affordable

<BarChart
    data={most_affordable}
    x=city
    y=median_price
    yFmt=usd0
    swapXY=true
    sort=false
/>

<DataTable data={most_affordable} link=area_link>
    <Column id=city />
    <Column id=county />
    <Column id=listings fmt=num0 />
    <Column id=median_price fmt=usd0 title="Median price" />
    <Column id=median_price_per_sqft fmt=usd0 title="$/sqft" />
</DataTable>

</div>

</Grid>

## Every city

Every city with an active listing. Click on a particular row for a more detailed view of that particular city.

<DataTable data={cities} link=area_link search=true rows=60>
    <Column id=city />
    <Column id=county />
    <Column id=listings fmt=num0 />
    <Column id=median_price fmt=usd0 title="Median price" />
    <Column id=median_price_per_sqft fmt=usd0 title="$/sqft" />
    <Column id=median_days_on_market fmt=num0 title="Median DOM" />
</DataTable>
