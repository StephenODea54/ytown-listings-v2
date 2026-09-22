# {params.city}

```sql latest_load
select max(loaded_at) as loaded_at from lake.fct_listing_snapshot
```

```sql listings
select
    s.listing_key,
    p.formatted_address,
    p.county,
    p.zip_code,
    s.price,
    s.price_per_sqft,
    p.num_bedrooms,
    p.num_bathrooms,
    p.square_footage,
    p.lot_size,
    p.year_built,
    s.days_on_market,
    s.listing_type,
    p.latitude,
    p.longitude
from lake.fct_listing_snapshot as s
join lake.dim_property as p using (property_sk)
where s.loaded_at = (select loaded_at from ${latest_load})
  and p.city = '${params.city}'
```

```sql summary
select
    count(*)                        as listings,
    any_value(county)               as county,
    median(price)                   as median_price,
    median(price_per_sqft)          as median_price_per_sqft,
    median(days_on_market)          as median_days_on_market,
    median(square_footage)          as median_sqft,
    median(year_built)              as median_year_built
from ${listings}
```

<Value data={summary} column=county /> County
<br />
<BigValue data={summary} value=listings title="Active listings" />
<BigValue data={summary} value=median_price fmt=usd0 title="Median price" />
<BigValue data={summary} value=median_price_per_sqft fmt=usd0 title="Median $/sqft" />
<BigValue data={summary} value=median_days_on_market fmt=num0 title="Median days on market" />

{#if summary[0].listings < 10}

*Fewer than ten listings.

{/if}

## Listings

<PointMap
    data={listings}
    lat=latitude
    long=longitude
    value=price
    valueFmt=usd0
    pointName=formatted_address
    height=380
    basemap={"https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{z}/{y}/{x}"}
    attribution="Tiles &copy; Esri &mdash; Esri, DeLorme, NAVTEQ"
    tooltipType=hover
    tooltip={[
        { id: 'formatted_address', showColumnName: false, valueClass: 'font-semibold' },
        { id: 'price', fmt: 'usd0', title: 'Asking' },
        { id: 'price_per_sqft', fmt: 'usd0', title: '$/sqft' },
        { id: 'num_bedrooms', fmt: 'num0', title: 'Beds' },
        { id: 'square_footage', fmt: 'num0', title: 'Sqft' }
    ]}
/>

<DataTable data={listings} search=true rows=25>
    <Column id=formatted_address title="Address" />
    <Column id=zip_code title="Zip" />
    <Column id=price fmt=usd0 />
    <Column id=price_per_sqft fmt=usd0 title="$/sqft" />
    <Column id=num_bedrooms fmt=num0 title="Beds" />
    <Column id=num_bathrooms fmt=num1 title="Baths" />
    <Column id=square_footage fmt=num0 title="Sqft" />
    <Column id=year_built fmt=id title="Built" />
    <Column id=days_on_market fmt=num0 title="DOM" />
</DataTable>

## Who's selling here

```sql agents
select
    a.agent_name,
    o.office_name,
    count(*)                        as listings,
    median(s.price)                 as median_price
from lake.fct_listing_snapshot as s
join lake.dim_property as p using (property_sk)
left join lake.dim_agent as a using (agent_sk)
left join lake.dim_office as o using (office_sk)
where s.loaded_at = (select loaded_at from ${latest_load})
  and p.city = '${params.city}'
group by 1, 2
order by listings desc
limit 15
```

<DataTable data={agents}>
    <Column id=agent_name title="Agent" />
    <Column id=office_name title="Office" />
    <Column id=listings fmt=num0 />
    <Column id=median_price fmt=usd0 title="Median price" />
</DataTable>
