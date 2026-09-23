# Dashboard

The UI is powered by [Evidence](https://evidence.dev).

## Pages

| Route           | What it answers                                                                                                                        |
| --------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| `/`             | How much inventory is active, what are the median asking price, price per square foot, and days on market, and when was the last load? |
| `/map`          | Where are the active listings?                                                                                                         |
| `/deals`        | Which listings are cheap per square foot, below their city's median asking price, relisted cheaper, or sitting for more than 90 days?  |
| `/areas`        | How do cities compare by median asking price?                                                                                          |
| `/areas/[city]` | What's for sale in a city, where is it, and who's selling it?                                                                          |

City tables link to the corresponding city page.

“Deals” are screening criteria, not valuations. Below-median asking price can mean a bargain. It can also mean the kitchen has seen things.

## Refreshing the data

The connection in [sources/lake/connection.yaml](sources/lake/connection.yaml) uses an in-memory DuckDB instance. Adjacent SQL files read dbt’s Parquet exports.

**New Parquet files do not automatically refresh Evidence.** Evidence keeps its own source copy, so refresh it after rebuilding the models.

Run from the repo root:

```sh
make sources  # refresh data from the existing exports
make dev      # start the dashboard at http://localhost:3001
```

For a static build and local preview:

```sh
make evidence-build  # build the site
make serve           # serve it at http://localhost:3001
```

To fetch fresh listings and rebuild everything:

```sh
make run && make evidence-build
```

Only that last workflow calls RentCast. Moving a chart six pixels to the left should remain a private financial decision.

## Configuration

* `evidence.config.yaml`: theme and plugins.
* `package.json`: scripts, including the development port.
* `.npmrc`: keep `node-linker=hoisted` and use pnpm. Evidence’s package resolution depends on that layout in this project.

Dokploy serves the built site on port `3001`, with `build/` mounted to a persistent volume. Its scheduled job runs `make run evidence-build` to refresh the data and rebuild the site. See [deployment](../docs/deploy.md) for the full setup.

