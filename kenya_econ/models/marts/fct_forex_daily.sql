with indicators as (
    select * from {{ ref('int_economic_indicators') }}
)

select
    date,
    usd_kes,
    eur_kes,
    gbp_kes,
    usd_kes_daily_change_pct,
    eur_kes_daily_change_pct,
    gbp_kes_daily_change_pct,
    -- currency strength indicators
    case
        when usd_kes_daily_change_pct > 0 then 'KES_WEAKENING'
        when usd_kes_daily_change_pct < 0 then 'KES_STRENGTHENING'
        else 'STABLE'
    end as usd_kes_trend,
    case
        when eur_kes_daily_change_pct > 0 then 'KES_WEAKENING'
        when eur_kes_daily_change_pct < 0 then 'KES_STRENGTHENING'
        else 'STABLE'
    end as eur_kes_trend,
    case
        when gbp_kes_daily_change_pct > 0 then 'KES_WEAKENING'
        when gbp_kes_daily_change_pct < 0 then 'KES_STRENGTHENING'
        else 'STABLE'
    end as gbp_kes_trend,
    ingested_at
from indicators
order by date desc