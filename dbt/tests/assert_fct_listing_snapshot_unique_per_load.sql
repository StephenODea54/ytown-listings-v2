select listing_key, load_id, count(*) as n
from {{ ref('fct_listing_snapshot') }}
group by listing_key, load_id
having count(*) > 1
