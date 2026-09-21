select listing_key, load_id, has_hoa, hoa_fee
from {{ ref('stg_sale_listings') }}
where has_hoa != (hoa_fee is not null)
