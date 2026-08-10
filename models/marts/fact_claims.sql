with staging as (

    select * from {{ ref('stg_insurance_claims') }}

),

claims as (

    select
        policy_number,

        -- claim event details
        month,
        week_of_month,
        day_of_week,
        accident_area,
        month_claimed,
        week_of_month_claimed,
        day_of_week_claimed,
        days_policy_to_accident,
        days_policy_to_claim,

        -- claim-specific facts
        fraud_found,
        fault_party,
        past_number_of_claims,
        police_report_filed,
        witness_present,
        number_of_supplements,
        address_change_claim

    from staging

)

select * from claims