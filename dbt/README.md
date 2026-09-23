# Data models

Models live in DuckLake, attached as `lake` by an in-memory dbt-duckdb connection. PostgreSQL holds the catalog; RustFS holds the data under `s3://ytown-listings/lakehouse/`.

## Schemas

| Schema  | Contents                          | Purpose                                                                                               |
| ------- | --------------------------------- | ----------------------------------------------------------------------------------------------------- |
| `raw`   | `sale_listings`                   | External source over the landing Parquet                                                              |
| `stg`   | `sale_listings`, `listing_events` | Type columns, construct keys, deduplicate listings within each load, and filter to the three counties |
| `marts` | Dimensions and listing facts      | Model listing history and supply the dashboard                                                        |

Use the `generate_schema_name` macro to create new schemas as needed.

## Identity

RentCast's listing ID depends on address text, so staging builds two keys:

| Key            | Built from                         | Used for                                        |
| -------------- | ---------------------------------- | ----------------------------------------------- |
| `listing_key`  | MD5 of `mls_name` and `mls_number` | Following one MLS listing across loads          |
| `property_key` | MD5 of the uppercased address      | Connecting different listings for the same home |

The property key enables comparisons with a home's previous listing. It still depends on consistent address text: uppercasing handles casing, but it won't reconcile spelling or formatting changes. Hashing is not witness protection for bad identifiers.

## Grain and history

| Model                                     | Grain                                       | What it captures                                                                                 |
| ----------------------------------------- | ------------------------------------------- | ------------------------------------------------------------------------------------------------ |
| `fct_listing_snapshot`                    | One listing per load                        | Asking price, days on market, and status at collection time                                      |
| `fct_listing_lifecycle`                   | One listing                                 | First and last observation, current price, prior listing price for the property, and active flag |
| `dim_property`, `dim_agent`, `dim_office` | One version of a property, agent, or office | Changes to tracked attributes over time                                                          |
| `dim_date`                                | One date                                    | Date dimension                                                                                   |

The three versioned dimensions use dbt snapshots with the `check` strategy: a tracked change closes the old version and opens a new one. Surrogate keys end in `_sk`; validity is recorded in `valid_from` and `valid_to`. Records that disappear remain open because the source only includes active listings.

In the lifecycle fact, **active means present in the latest load**. Absence does not prove a sale, and an incomplete load can affect that flag. Snapshot history records what the pipeline observed, not every change that happened between runs.

## Exports and checks

Post-hooks export marts models and snapshots to `../evidence/sources/lake/<name>.parquet`. Change the destination with `bi_export_dir` in [dbt_project.yml](dbt_project.yml).

Tests include checks that:

* Each listing appears once per load in staging and the snapshot fact.
* The HOA flag agrees with the HOA fee.
* Lifecycle current prices match the latest open events.

See [tests/](tests/) for the singular tests.

## Run

With dependencies installed, the local services running, and `.env` values exported, run from the repo root:

```sh
make transform
make sources
```

Note that neither of the above commands calls RentCastso rewrite that SQL as many times as your emotional state requires.

Keep `threads: 1` in [profiles.yml](profiles.yml). Concurrent builds have caused temporary relations to disappear with `__dbt_tmp does not exist`. One thread is deliberate.
