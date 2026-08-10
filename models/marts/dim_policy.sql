with staging as (

    select * from {{ ref('stg_insurance_claims') }}

),

policy as (

    select distinct
        policy_number,
        policy_type,
        base_policy,
        deductible,
        driver_rating,
        agent_type,
        rep_number,
        policy_year

    from staging

)

select * from policy