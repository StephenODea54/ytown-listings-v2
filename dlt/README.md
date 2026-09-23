# Ingestion

## What gets collected

Searches cover Trumbull, Mahoning, and Columbiana counties using a center point and radius for each. Settings live in [.dlt/config.toml](.dlt/config.toml).

| Setting | Default |
|---|---|
| Property type | Single Family |
| Status | Active |
| Minimum asking price | $25,000 |
| Page size | 500 |
| Maximum listings per county search | 3,000 |
| Request budget | 25 per run |

Note that these are just search radiuses and not county boundaries. This means it is possible for listings to duplicate. Duplicates are handled in downstream layers.

## Loads and limits

Two helpers in [rentcast_pipeline.py](rentcast_pipeline.py) keep pagination on a leash as the free tier for the API includes 50 requests a month:

- `BudgetedSession` counts requests and raises an error when the budget is exhausted. It is currently capped at 25.
- `ShortPagePaginator` stops when a page contains fewer than 500 results.

A typical three-county run uses about five requests. Note that the 25-request cap applies to each run, not the billing period. Repeated runs still count as the API does not recognize “I was debugging” as a coupon code.

## Configuration

Keep search settings, limits, and destination layout in `.dlt/config.toml`. For local credentials, create `.dlt/secrets.toml`:

```toml
[sources.rentcast]
api_key = "..."

[destination.filesystem.credentials]
aws_access_key_id = "..."
aws_secret_access_key = "..."
endpoint_url = "http://localhost:9000"
region_name = "us-east-1"
```

Production supplies credentials through `SOURCES__RENTCAST__API_KEY` and `DESTINATION__FILESYSTEM__CREDENTIALS__*` environment variables. See [deployment](../docs/deploy.md).

## Run

With RustFS running, credentials configured, and the `ytown-listings` bucket created, run from the repo root:

```sh
make build
make ingest
```
