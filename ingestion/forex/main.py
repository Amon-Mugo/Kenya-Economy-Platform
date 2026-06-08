import requests
import json
from datetime import datetime, timezone
from google.cloud import storage, bigquery

def ingest_forex(request):
    base_url = "https://open.er-api.com/v6/latest/USD"

    response = requests.get(base_url)
    response.raise_for_status()
    data = response.json()

    rates = data["rates"]

    date_str = datetime.strptime(
        data["time_last_update_utc"],
        "%a, %d %b %Y %H:%M:%S %z"
    ).strftime("%Y-%m-%d")

    record = {
        "date": date_str,
        "usd_kes": round(rates["KES"], 2),
        "eur_kes": round(rates["KES"] / rates["EUR"], 2),
        "gbp_kes": round(rates["KES"] / rates["GBP"], 2),
        "ingested_at": datetime.now(timezone.utc).isoformat()
    }

    # save to gcs
    bucket_name = "gcp-de-learning-amon-kariuki"
    gcs_path = f"raw/forex/{record['date']}.json"
    storage_client = storage.Client()
    bucket = storage_client.bucket(bucket_name)
    blob = bucket.blob(gcs_path)
    blob.upload_from_string(json.dumps(record), content_type="application/json")

    # load to bigquery
    bq_client = bigquery.Client()
    table_id = "gcp-de-learning-498109.kenya_econ.raw_forex"
    errors = bq_client.insert_rows_json(table_id, [record])

    if errors:
        raise RuntimeError(f"BigQuery insert failed: {errors}")

    return f"Forex ingested for {record['date']}", 200