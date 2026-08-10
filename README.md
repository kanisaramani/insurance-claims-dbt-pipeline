# Insurance Claims Analytics Pipeline

An end-to-end analytics engineering project that transforms a raw, denormalized insurance claims export into a tested, documented dimensional model in Snowflake using dbt, then surfaces business insights through a Power BI dashboard.

**Stack:** Snowflake · dbt Core · Power BI · SQL

---

## The Business Problem

An insurance company sells policies and pays out claims. Raw operational data — one flat table of claims, policies, and customer details — can't answer the questions underwriting, claims investigation, and leadership actually ask: *Which policy types carry the most fraud risk? Does missing documentation correlate with fraudulent claims? Is claims history actually predictive of fraud, or a red herring?*

This project turns that raw export into a clean, tested star schema, and then a dashboard that answers those questions directly.

---

## Dataset

[Vehicle Insurance Claim Fraud Detection](https://www.kaggle.com/datasets/shivamb/vehicle-claim-fraud-detection) (Kaggle) — ~15,420 claims, one denormalized source table containing policyholder demographics, vehicle details, policy terms, and claim-specific fields including a fraud flag.

The dataset arrives as a single flat table, deliberately mirroring how a real-world data export often looks — messy, mixed-grain, and in need of proper modeling rather than a pre-built schema. That modeling work is the actual point of this project.

---

## Architecture


Raw CSV
   │
   ▼
Snowflake (raw schema)
   │
   ▼
dbt staging model  →  type casting, renaming to snake_case, boolean conversion
   │
   ▼
dbt dimensional model (analytics schema)
   ├── dim_policyholder
   ├── dim_vehicle
   ├── dim_policy
   └── fact_claims
   │
   ▼
Power BI  →  relationships, DAX measures, dashboard


### dbt Lineage Graph

![dbt lineage graph](assets/dbt_lineage.png)

*(Add your `dbt docs generate` / `dbt docs serve` lineage screenshot here.)*

One staging model sits between the raw source and every downstream model — nothing queries `raw` directly. Three dimensions and one fact table make up the analytics-ready layer, each dimension deduplicated on `policy_number`, the fact table left undeduplicated by design so duplicate claim rows would surface as a genuine data quality issue rather than being silently hidden.

---

## Data Model

| Table | Grain | Description |
|---|---|---|
| `dim_policyholder` | one row per policy_number | Policyholder demographics — sex, marital status, age |
| `dim_vehicle` | one row per policy_number | Insured vehicle details — make, category, price, age |
| `dim_policy` | one row per policy_number | Policy contract terms — type, deductible, agent, rep |
| `fact_claims` | one row per claim | Claim event details and outcomes — fraud flag, documentation, claims history |

**Known simplification:** `policy_number` doubles as the natural key across all three dimensions since this dataset has exactly one vehicle and one claim per policy. A production system would use dedicated `vehicle_id` and `customer_id` keys to support one policyholder insuring multiple vehicles.

---

## Data Quality Testing

9 dbt tests validate the model on every run:

- `unique` and `not_null` on `policy_number` across all three dimensions
- `not_null` on `fraud_found` and `policy_number` in the fact table
- `relationships` test enforcing that every claim in `fact_claims` references a real, existing policyholder — proving referential integrity, not just assuming it

```
Done. PASS=9 WARN=0 ERROR=0 SKIP=0
```

---

## Dashboard






Key Findings

1. All Perils policies show dramatically higher fraud rates than Liability policies.**
All Perils: 10.2% · Collision: 7.3% · Liability: 0.7% — roughly a 14x difference between the highest- and lowest-risk policy types.

**2. Claims without a police report are filed fraudulently at a higher rate.**
No report: 6.0% fraud rate vs. With report: 3.7% — missing documentation is a meaningful (though not definitive) risk signal.

**3. First-time claimants show higher fraud rates than repeat claimants.**
Fraud rate declines steadily from "none" (no prior claims) through "more than 4" prior claims — a counterintuitive result worth flagging: claims history isn't a red flag for fraud in this data; if anything, it's mildly protective.

**4. Claims volume is heavily concentrated by vehicle make.**
Pontiac and Toyota account for a disproportionate share of total claims relative to other makes in the dataset.

---

## Tech Decisions Worth Explaining

Why Snowflake over the existing Azure stack: this portfolio already includes an Azure Databricks pipeline. Building this one on Snowflake (AWS-hosted) demonstrates range across cloud ecosystems rather than depth in only one.

Why dbt Core, not a GUI transformation tool:** dbt Core plus a proper GitHub repo is the industry-standard setup and what "dbt experience" actually means on a job spec — version-controlled SQL, tested, documented, not a point-and-click pipeline.

Why relationships matter more than they look like they should:** a real bug encountered during this build (see below) came from Power BI auto-detecting relationship cardinality backwards because every table in this dataset happens to have the same row count. Fixing it was the difference between every chart showing identical, meaningless bars and a dashboard that actually reveals the findings above.

---

## Challenges & Debugging

1. Table loaded into the wrong Snowflake schema.
Snowsight's upload wizard silently defaulted to the `PUBLIC` schema instead of the `raw` schema I'd already created. Caught by running `SHOW TABLES IN DATABASE`, which showed ground truth rather than trusting the UI. Fixed with `ALTER TABLE ... RENAME TO` — no data loss, no re-upload needed. Lesson: verify against system metadata, don't assume a wizard preserved context.

2. Corrupted `dbt_project.yml` 
Removing dbt's boilerplate `example` config left a duplicated, malformed `models:` block — invalid YAML nesting. dbt didn't hard-crash; it threw a soft "custom key" warning and then silently skipped building affected models. Fixed by rewriting the block with correct indentation. Lesson: when a tool's behavior doesn't match its error message, check the raw file structure directly.

3. A model that was valid but wouldn't build via `--select`.**
`dim_policyholder` was correctly configured, enabled, and connected in the dependency graph — confirmed via `dbt ls`, JSON config output, and the lineage graph — yet `dbt run --select dim_policyholder` repeatedly returned "nothing to do," even after a full cache clear. Diagnosed by systematically ruling out causes: checked for a disabled config (wasn't), checked for a `selectors.yml` override (didn't exist), checked environment variables (blank), then tested the inverse (`--exclude`), which worked and proved the model itself was healthy. Root cause was likely a CLI flag-parsing quirk in that session; the practical fix was relying on plain `dbt run` going forward. Lesson: isolate whether a problem is your code or your tooling before assuming either.

4. Power BI relationships auto-detected with reversed cardinality.
Every mart table in this dataset happens to have the same row count (15,420), since it's one claim per policy. Power BI's auto-relationship detection couldn't tell which table should be the "one" side and which the "many" side, and got it backwards for all three dimension-to-fact relationships. Every chart sliced by a dimension showed identical bars — a genuine data-integrity red flag, not a display bug. Diagnosed by testing a simple `Total Claims` measure sliced by category: if a dimension's filter isn't reaching the fact table, even a basic count won't vary. Fixed by manually setting each relationship to "One to many" with the dimension explicitly on the "one" side. Lesson: equal row counts between related tables can defeat automatic relationship detection — don't trust it blindly, verify with a simple test measure.

---

## Project Structure


insurance_claims/
├── models/
│   ├── staging/
│   │   ├── stg_insurance_claims.sql
│   │   └── sources.yml
│   └── marts/
│       ├── dim_policyholder.sql
│       ├── dim_vehicle.sql
│       ├── dim_policy.sql
│       ├── fact_claims.sql
│       └── schema.yml
├── dbt_project.yml
└── README.md


---

## Running This Project
bash
# Install dependencies
uv venv
.venv\Scripts\activate
uv pip install dbt-snowflake

# Configure your Snowflake connection
dbt init insurance_claims

# Build the full model
dbt run

# Run data quality tests
dbt test

# Generate and view documentation/lineage
dbt docs generate
dbt docs serve
