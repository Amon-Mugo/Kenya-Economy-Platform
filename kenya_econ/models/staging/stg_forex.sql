with source as(
    select*from{{source('kenya_econ','raw_forex')}}
),
renamed as (
    select 
        date,
        usd_kes,
        eur_kes,
        gbp_kes,
        ingested_at
    from source
    where date is not null and usd_kes is not null and eur_kes is not null and gbp_kes is not null

)
select * from renamed