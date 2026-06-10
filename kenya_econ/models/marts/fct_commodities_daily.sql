with source as (
    select * from {{ ref('int_commodities') }}
)

select
    date,
    commodity,
    price,
    unit,
    currency_unit,
    change_24h_percent,
    price_change_pct,
    case
        when price_change_pct > 0 then 'RISING'
        when price_change_pct < 0 then 'FALLING'
        else 'STABLE'
    end as price_trend,
    ingested_at
from source
order by date desc, commodity