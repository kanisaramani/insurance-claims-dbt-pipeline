with source as (

    select * from {{ source('raw', 'raw_insurance_claims') }}

),

renamed as (

    select
        policynumber              as policy_number,
        month                      as month,
        weekofmonth                as week_of_month,
        dayofweek                  as day_of_week,
        make                       as vehicle_make,
        accidentarea                as accident_area,
        dayofweekclaimed            as day_of_week_claimed,
        monthclaimed                as month_claimed,
        weekofmonthclaimed          as week_of_month_claimed,
        sex                        as policyholder_sex,
        maritalstatus                as marital_status,
        age                        as policyholder_age,
        fault                      as fault_party,
        policytype                  as policy_type,
        vehiclecategory              as vehicle_category,
        vehicleprice                as vehicle_price,
        fraudfound_p::boolean        as fraud_found,
        repnumber                  as rep_number,
        deductible                  as deductible,
        driverrating                as driver_rating,
        days_policy_accident          as days_policy_to_accident,
        days_policy_claim            as days_policy_to_claim,
        pastnumberofclaims            as past_number_of_claims,
        ageofvehicle                as age_of_vehicle,
        ageofpolicyholder            as age_of_policyholder,
        policereportfiled            as police_report_filed,
        witnesspresent              as witness_present,
        agenttype                  as agent_type,
        numberofsuppliments          as number_of_supplements,
        addresschange_claim          as address_change_claim,
        numberofcars                as number_of_cars,
        year                       as policy_year,
        basepolicy                  as base_policy

    from source

)

select * from renamed