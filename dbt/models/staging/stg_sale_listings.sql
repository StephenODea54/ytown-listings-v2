{{ config(alias='sale_listings') }}

with deduped as (
    select *
    from {{ ref('sale_listings') }}
    where (state, county) in (('OH', 'Mahoning'), ('OH', 'Trumbull'), ('OH', 'Columbiana'))
    qualify row_number() over (
        partition by md5(mls_name || '|' || mls_number), _dlt_load_id
        order by last_seen_date desc, search_area
    ) = 1
)

select
    md5(mls_name || '|' || mls_number)                                      as listing_key,
    md5(upper(formatted_address))                                           as property_key,
    md5(coalesce(listing_agent ->> '$.email', listing_agent ->> '$.name'))  as agent_key,
    md5(listing_office ->> '$.name')                                        as office_key,
    _dlt_load_id                                                            as load_id,
    make_timestamp((_dlt_load_id::double * 1e6)::bigint)                    as loaded_at,

    formatted_address,
    property_type,
    listing_type,
    status                                                                  as listing_status,
    price,

    listing_agent  ->> '$.name'                                             as agent_name,
    listing_agent  ->> '$.phone'                                            as agent_phone_number,
    listing_agent  ->> '$.email'                                            as agent_email,
    listing_agent  ->> '$.website'                                          as agent_website,

    listing_office ->> '$.name'                                             as listing_office_name,
    listing_office ->> '$.phone'                                            as listing_office_phone_number,
    listing_office ->> '$.email'                                            as listing_office_email,
    listing_office ->> '$.website'                                          as listing_office_website,

    address_line1                                                           as primary_address,
    address_line2                                                           as secondary_address,
    city,
    state,
    state_fips,
    zip_code,
    county,
    county_fips,
    latitude,
    longitude,

    bedrooms                                                                as num_bedrooms,
    coalesce(bathrooms, bathrooms__v_double)                                as num_bathrooms,
    square_footage,
    lot_size,
    year_built,

    hoa is not null                                                         as has_hoa,
    cast(hoa ->> '$.fee' as integer)                                        as hoa_fee,

    mls_name,
    mls_number,

    listed_date,
    created_date,
    last_seen_date,
    days_on_market,

    history
from deduped
