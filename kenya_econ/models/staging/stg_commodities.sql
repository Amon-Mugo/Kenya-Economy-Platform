with source as (
    select * from {{ source('kenya_econ', 'raw_commodities') }}
),
cleaned as (
    select
        date,
        commodity,
        price,
        unit,
        currency_unit,
        change_24h_percent,
        ingested_at
    from source
    where date is not null
      and commodity is not null
      and price is not null
)
select * from cleaned