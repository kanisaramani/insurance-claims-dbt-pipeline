with staging as (

    select * from {{ ref('stg_insurance_claims') }}

),

policyholder as (

    select distinct
        policy_number,
        policyholder_sex,
        marital_status,
        policyholder_age,
        address_change_claim

    from staging

)

select * from policyholder