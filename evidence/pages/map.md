---
title: Map
---

# Where the listings are

Every active listing, coloured by asking price. Hover for details, click a point to open its city.

```sql latest_load
select max(loaded_at) as loaded_at from lake.fct_listing_snapshot
```

```sql counties
select distinct county from lake.dim_property order by 1
```

<Dropdown data={counties} name=county value=county title="County">
    <DropdownOption value="%" valueLabel="All counties" />
</Dropdown>

<Dropdown name=max_price title="Asking price up to" defaultValue=99999999>
    <DropdownOption value=100000  valueLabel="$100k" />
    <DropdownOption value=200000  valueLabel="$200k" />
    <DropdownOption value=350000  valueLabel="$350k" />
    <DropdownOption value=500000  valueLabel="$500k" />
    <DropdownOption value=1000000 valueLabel="$1M" />
    <DropdownOption value=99999999 valueLabel="Any" />
</Dropdown>

```sql points
select
    p.formatted_address,
    p.city,
    p.county,
    '/areas/' || p.city                     as area_link,
    s.price,
    s.price_per_sqft,
    p.num_bedrooms,
    p.num_bathrooms,
    p.square_footage,
    p.year_built,
    s.days_on_market,
    p.latitude,
    p.longitude
from lake.fct_listing_snapshot as s
join lake.dim_property as p using (property_sk)
where s.loaded_at = (select loaded_at from ${latest_load})
  and p.county like '${inputs.county.value}'
  and s.price <= ${inputs.max_price.value}
```

<PointMap
    data={points}
    lat=latitude
    long=longitude
    value=price
    valueFmt=usd0
    pointName=formatted_address
    link=area_link
    height=620
    basemap={"https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{z}/{y}/{x}"}
    attribution="Tiles &copy; Esri &mdash; Esri, DeLorme, NAVTEQ"
    startingZoom=9
    tooltipType=hover
    tooltip={[
        { id: 'formatted_address', showColumnName: false, valueClass: 'font-semibold' },
        { id: 'price', fmt: 'usd0', title: 'Asking' },
        { id: 'price_per_sqft', fmt: 'usd0', title: '$/sqft' },
        { id: 'num_bedrooms', fmt: 'num0', title: 'Beds' },
        { id: 'num_bathrooms', fmt: 'num1', title: 'Baths' },
        { id: 'square_footage', fmt: 'num0', title: 'Sqft' },
        { id: 'days_on_market', fmt: 'num0', title: 'Days on market' }
    ]}
/>

```sql shown
select count(*) as listings, median(price) as median_price from ${points}
```

Showing <Value data={shown} column=listings fmt=num0 /> listings, median <Value data={shown} column=median_price fmt=usd0 />.

<DataTable data={points} search=true rows=15>
    <Column id=formatted_address title="Address" />
    <Column id=city />
    <Column id=price fmt=usd0 />
    <Column id=price_per_sqft fmt=usd0 title="$/sqft" />
    <Column id=num_bedrooms fmt=num0 title="Beds" />
    <Column id=num_bathrooms fmt=num1 title="Baths" />
    <Column id=square_footage fmt=num0 title="Sqft" />
    <Column id=days_on_market fmt=num0 title="DOM" />
</DataTable>
