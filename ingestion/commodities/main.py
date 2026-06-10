
import os
import requests
import json
from datetime import datetime, timezone
from google.cloud import storage, bigquery

COMMODITIES = [
    "class_3_milk",
    "cocoa",
    "coffee",
    "copper",
    "corn",
    "cotton",
    "crude_oil"
]

def ingest_commodities(request):
    api_key = os.environ.get("NINJA_API_KEY")
    base_url = "https://api.api-ninjas.com/v1/commodityprice"
    headers = {"X-Api-Key": api_key}

    ingested_at = datetime.now(timezone.utc).isoformat()
    date_str = datetime.now(timezone.utc).strftime("%Y-%m-%d")

    records = []
    skipped = []

    for commodity in COMMODITIES:
        try:
            response = requests.get(
                base_url,
                params={"name": commodity},
                headers=headers,
                timeout=10
            )
            data = response.json()

            if "error" in data:
                skipped.append(commodity)
                continue

            records.append({
                "date": date_str,
                "commodity": commodity,
                "price": round(float(data["price"]), 4),
                "unit": data["unit"],
                "currency_unit": data["currency_unit"],
                "change_24h_percent": round(float(data["change_24h_percent"]), 4),
                "ingested_at": ingested_at
            })

        except Exception as e:
            skipped.append(commodity)
            continue

    if not records:
        return f"No commodities ingested on {date_str}. All skipped: {skipped}", 200

    # save to gcs
    bucket_name = os.environ.get("GCS_BUCKET")
    gcs_path = f"raw/commodities/{date_str}.json"
    storage_client = storage.Client()
    bucket = storage_client.bucket(bucket_name)
    blob = bucket.blob(gcs_path)
    blob.upload_from_string(
        json.dumps(records),
        content_type="application/json"
    )

    # delete existing rows for this date to prevent duplicates
    bq_client = bigquery.Client()
    table_id = "gcp-de-learning-498109.kenya_econ.raw_commodities"
    bq_client.query(
        f"DELETE FROM `{table_id}` WHERE date = '{date_str}'"
    ).result()

    # load to bigquery
    errors = bq_client.insert_rows_json(table_id, records)
    if errors:
        raise RuntimeError(f"BigQuery insert failed: {errors}")

    return (
        f"Commodities ingested for {date_str}. "
        f"Success: {[r['commodity'] for r in records]}. "
        f"Skipped: {skipped}"
    ), 200
