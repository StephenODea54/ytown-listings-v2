# ytown listings

A self-hosted real estate data platform for Mahoning, Trumbull, and Columbiana counties, Ohio.

I wanted to know what the housing market around Youngstown was doing. Apparently that required a lakehouse.

**[View the dashboard →](https://ytown-listings.stephenodea.me)**

## What it does

Collects weekly snapshots of homes for sale and builds a history of asking prices, time on market, and inventory across the three counties.

The questions are pretty straightforward:

* Where are asking prices dropping?
* Which homes have been sitting forever?
* How does the market differ between cities?

## The stack

The whole thing runs on one VPS: ingestion, object storage, lakehouse, transformations, and dashboard. RentCast supplies the listing data.

| Tool                      | What it does                                                                          |
| ------------------------- | ------------------------------------------------------------------------------------- |
| **dlt**                   | Pulls listings from RentCast and appends raw Parquet files to RustFS                  |
| **RustFS**                | Stores raw loads and DuckLake data through an S3-compatible API                       |
| **DuckLake + PostgreSQL** | Stores the analytical tables, with PostgreSQL holding the catalog                     |
| **dbt**                   | Builds and tests a star schema with historical snapshots, then exports dashboard data |
| **Evidence**              | Builds a static dashboard from the exported Parquet                                   |

## Run locally

Requires Docker, uv, Node.js 22, pnpm, and a RentCast API key.

1. Copy `.env.example` to `.env` and configure the local credentials.

2. Add the RentCast key and RustFS credentials to `dlt/.dlt/secrets.toml`. See [ingestion setup](dlt/README.md).

3. Start the services:

   ```sh
   docker compose up -d
   ```

4. Install dependencies and run:

   ```sh
   make build
   make run
   make dev
   ```

Open [localhost:3001](http://localhost:3001).

**NOTE**: `make run` executes ingestion, dbt models and tests, and the Evidence source refresh. It calls RentCast and consumes API requests. So please don't Enthusiastically rerunning the pipeline if you are on the free tier :)

## Deployment

Dokploy manages three pieces on the VPS: the application, RustFS, and PostgreSQL. The repo’s `compose.yaml` is for local development.

The application container serves the built Evidence site. A weekly Dokploy schedule runs:

```sh
make run evidence-build
```

See [the deployment guide](docs/deploy.md) for service setup, environment variables, and scheduling.

## Documentation

* [Ingestion](dlt/README.md)
* [Data models](dbt/README.md)
* [Dashboard](evidence/README.md)
* [Deployment](docs/deploy.md)

## License

[MIT](LICENSE)
