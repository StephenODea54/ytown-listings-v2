select listing_key, load_id, count(*) as n
from {{ ref('stg_sale_listings') }}
group by listing_key, load_id
having count(*) > 1
