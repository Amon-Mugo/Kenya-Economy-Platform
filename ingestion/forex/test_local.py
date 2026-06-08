import requests
import json
from datetime import datetime, timezone

def test_forex_api():
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

    print(json.dumps(record, indent=2))

test_forex_api()