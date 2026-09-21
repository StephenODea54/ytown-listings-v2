select
    strftime(d, '%Y%m%d')::integer  as date_key,
    d::date                         as date_day,
    year(d)                         as year,
    quarter(d)                      as quarter,
    month(d)                        as month,
    monthname(d)                    as month_name,
    day(d)                          as day_of_month,
    isodow(d)                       as day_of_week,
    dayname(d)                      as day_name,
    isodow(d) >= 6                  as is_weekend
from generate_series(date '2020-01-01', date '2030-12-31', interval 1 day) as t(d)
