with forex as (
    select * from {{ ref('stg_forex') }}
)

select
    date,
    usd_kes,
    eur_kes,
    gbp_kes,
    ingested_at,
    -- daily change percentages for all three currencies
    round((usd_kes - lag(usd_kes) over (order by date)) / lag(usd_kes) over (order by date) * 100, 2) as usd_kes_daily_change_pct,
    round((eur_kes - lag(eur_kes) over (order by date)) / lag(eur_kes) over (order by date) * 100, 2) as eur_kes_daily_change_pct,
    round((gbp_kes - lag(gbp_kes) over (order by date)) / lag(gbp_kes) over (order by date) * 100, 2) as gbp_kes_daily_change_pct
from forex