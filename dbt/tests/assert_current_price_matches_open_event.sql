select l.listing_key, l.current_price, e.price as open_event_price
from {{ ref('fct_listing_lifecycle') }} as l
join {{ ref('stg_listing_events') }} as e
    on e.listing_key = l.listing_key and e.removed_date is null
where l.is_active and l.current_price != e.price
