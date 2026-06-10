# Kenya Economic Intelligence Platform

A data engineering portfolio project that builds an end-to-end pipeline tracking forex exchange rates and commodity prices relevant to the Kenyan economy — from live API ingestion through cloud storage, transformation, and a Looker Studio dashboard.

Here is the link https://datastudio.google.com/reporting/99b3a062-2781-4e68-b979-0f1b68959861



![image alt]
---

## Architecture

```
open.er-api.com (Forex API)          api.api-ninjas.com (Commodities API)
        │                                        │
        ▼                                        ▼
Cloud Function (ingest_forex)     Cloud Function (ingest_commodities)
8AM EAT daily                     9AM EAT daily
        │                                        │
        ├──► GCS (raw/forex/YYYY-MM-DD.json)     ├──► GCS (raw/commodities/YYYY-MM-DD.json)
        │                                        │
        └──► BigQuery (raw_forex)                └──► BigQuery (raw_commodities)
                         │                │
                         └──────┬─────────┘
                                ▼
                            dbt Core
                ┌─────────────────────────────────────┐
                │  stg_forex            (view)         │
                │  stg_commodities      (view)         │
                │  int_economic_indicators (view)      │
                │  int_commodities      (view)         │
                │  fct_forex_daily      (table)        │
                │  fct_commodities_daily (table)       │
                └─────────────────────────────────────┘
                                │
                                ▼
                        Looker Studio Dashboard
```

---

## Tech Stack

| Layer | Tool |
|---|---|
| Ingestion | Python 3.12, Google Cloud Functions (Gen2) |
| Scheduling | Google Cloud Scheduler |
| Raw Storage | Google Cloud Storage (GCS) |
| Data Warehouse | Google BigQuery |
| Transformation | dbt Core 1.11 (BigQuery adapter) |
| Dashboard | Looker Studio |

---

## Data Sources

| Source | API | Frequency | Commodities |
|---|---|---|---|
| Forex rates | open.er-api.com | Daily | USD/KES, EUR/KES, GBP/KES |
| Commodity prices | api-ninjas.com | Daily | Coffee, Crude Oil, Corn, Cocoa, Copper, Cotton, Class 3 Milk |

---

## Pipeline Layers

**Layer 1 — Source**
Two live APIs: forex rates from open.er-api.com and commodity prices from API Ninjas. Both are free tiers with sufficient daily quota.

**Layer 2 — Ingestion**
Two Cloud Functions deployed on GCP Gen2:
- `ingest_forex` — fetches USD/KES, derives EUR/KES and GBP/KES, runs at 8AM EAT
- `ingest_commodities` — fetches 7 commodities with graceful skipping if any move to premium tier, runs at 9AM EAT

Both functions are idempotent — existing rows for the same date are deleted before inserting to prevent duplicates on retries.

**Layer 3 — Storage**
Raw JSON files land in GCS daily:
- `gs://gcp-de-learning-amon-kariuki/raw/forex/YYYY-MM-DD.json`
- `gs://gcp-de-learning-amon-kariuki/raw/commodities/YYYY-MM-DD.json`

BigQuery raw tables:
- `kenya_econ.raw_forex` — `date, usd_kes, eur_kes, gbp_kes, ingested_at`
- `kenya_econ.raw_commodities` — `date, commodity, price, unit, currency_unit, change_24h_percent, ingested_at`

**Layer 4 — Transformation (dbt)**
Six models across two pipelines:

Forex pipeline:
- `stg_forex` — cleans raw_forex, filters nulls
- `int_economic_indicators` — adds daily % change per currency using LAG() window function
- `fct_forex_daily` — dashboard-ready table with trend labels (KES_WEAKENING, KES_STRENGTHENING, STABLE)

Commodities pipeline:
- `stg_commodities` — cleans raw_commodities, filters nulls
- `int_commodities` — adds price_change_pct per commodity using LAG() partitioned by commodity
- `fct_commodities_daily` — dashboard-ready table with trend labels (RISING, FALLING, STABLE)

8 dbt tests passing across both pipelines. Source freshness monitoring configured for both raw tables.

**Layer 5 — Dashboard**
Looker Studio connected to `fct_forex_daily` and `fct_commodities_daily` in BigQuery.

---

## Project Structure

```
kenya-econ-platform/
├── ingestion/
│   ├── forex/
│   │   ├── main.py              # Forex Cloud Function
│   │   └── requirements.txt
│   └── commodities/
│       ├── main.py              # Commodities Cloud Function
│       └── requirements.txt
├── kenya_econ/                  # dbt project
│   ├── models/
│   │   ├── staging/
│   │   │   ├── stg_forex.sql
│   │   │   ├── stg_commodities.sql
│   │   │   └── schema.yml
│   │   ├── intermediate/
│   │   │   ├── int_economic_indicators.sql
│   │   │   └── int_commodities.sql
│   │   └── marts/
│   │       ├── fct_forex_daily.sql
│   │       └── fct_commodities_daily.sql
│   └── dbt_project.yml
├── requirements.txt
└── .gitignore
```

---

## GCP Setup

| Resource | Value |
|---|---|
| Project ID | `gcp-de-learning-498109` |
| Region | `us-central1` |
| GCS Bucket | `gcp-de-learning-amon-kariuki` |
| BigQuery Dataset | `kenya_econ` |
| Cloud Functions | `ingest_forex`, `ingest_commodities` |
| Cloud Schedulers | `forex-daily-ingest` (8AM EAT), `commodities-daily-ingest` (9AM EAT) |

---

## Local Setup

**Prerequisites**
- Python 3.12
- GCP account with BigQuery and GCS access
- `gcloud` CLI authenticated
- dbt Core with BigQuery adapter

**1. Clone the repo**
```bash
git clone https://github.com/Amon-Mugo/Kenya-Economy-Platform.git
cd Kenya-Economy-Platform
```

**2. Create and activate virtual environment**
```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

**3. Configure dbt**
```bash
cd kenya_econ
dbt debug
```

**4. Run dbt models and tests**
```bash
dbt run
dbt test
dbt source freshness
```

---

## What I Learned

- Building and deploying serverless ingestion pipelines with Google Cloud Functions (Gen2)
- Scheduling automated cloud jobs with Cloud Scheduler
- Designing a layered dbt project (staging → intermediate → marts) for two independent data sources
- Writing window functions (LAG, PARTITION BY) in BigQuery SQL for time-series analysis
- Making pipelines idempotent using delete-before-insert to handle retries safely
- Declaring dbt sources with freshness monitoring to detect ingestion failures
- Managing environment variables in Cloud Functions to avoid hardcoded secrets
- Graceful error handling in ingestion — skipping unavailable API endpoints without failing the pipeline

---

## Author

**Amon Mugo**
- GitHub: [@Amon-Mugo](https://github.com/Amon-Mugo)
