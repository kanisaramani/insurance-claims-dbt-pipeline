with staging as (

    select * from {{ ref('stg_insurance_claims') }}

),

vehicle as (

    select distinct
        policy_number,
        vehicle_make,
        vehicle_category,
        vehicle_price,
        age_of_vehicle,
        number_of_cars

    from staging

)

select * from vehicle