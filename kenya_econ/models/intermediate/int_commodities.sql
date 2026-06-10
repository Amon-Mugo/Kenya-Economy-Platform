with source as (
    select * from {{ ref('stg_commodities') }}
)

select
    date,
    commodity,
    price,
    unit,
    currency_unit,
    change_24h_percent,
    ingested_at,
    round(
        (price - lag(price) over (partition by commodity order by date))
        / nullif(lag(price) over (partition by commodity order by date), 0) * 100,
    2) as price_change_pct
from source