---
title: Overview
---

# Sale listings

Active single-family listings in Mahoning, Trumbull and Columbiana counties (OH).

```sql latest_load
select max(loaded_at) as loaded_at from lake.fct_listing_snapshot
```

```sql summary
select
    count(*)                        as listings,
    median(price)                   as median_price,
    median(price_per_sqft)          as median_price_per_sqft,
    median(days_on_market)          as median_days_on_market
from lake.fct_listing_snapshot
where loaded_at = (select loaded_at from ${latest_load})
```

<BigValue data={latest_load} value=loaded_at fmt=longdate title="Last loaded" />
<br />
<BigValue data={summary} value=listings title="Active listings" />
<BigValue data={summary} value=median_price fmt=usd0 title="Median price" />
<BigValue data={summary} value=median_price_per_sqft fmt=usd0 title="Median $/sqft" />
<BigValue data={summary} value=median_days_on_market fmt=num0 title="Median days on market" />

## Pages

**[Map](/map)** provides a geographical view of all of the listings

**[Deals](/deals)** is the buyer's view. Cheapest per square foot, listings asking well under their city's median, properties that have been listed before and come back cheaper, and anything that has sat for more than 90 days.

**[Areas](/areas)** ranks cities by median price, most expensive and most affordable, and lists every city with an active listing. Each city has its own page with a map, the listings, what is being sold there and who is selling it.

## Notes about the data

- Listings come from [RentCast](https://www.rentcast.io/)
- City is the postal city, so township addresses can fall under a neighbouring city's name.
