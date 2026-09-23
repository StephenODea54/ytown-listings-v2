# Deploying on Dokploy

The site runs as one Dokploy application on a VPS. rustfs and Postgres are Dokploy services on the same host. The container only serves the built Evidence site; a Dokploy schedule runs the data pipeline inside it.

`compose.yaml` in this repo is for local development only. It does not have to match what runs on the VPS.

## Before you start

- A VPS running Docker with Dokploy installed.
- A domain with an A record pointing at the VPS.
- A RentCast API key.
- This repo on GitHub, connected to Dokploy through the GitHub App.

## 1. Lock down the VPS

1. Enable two factor authentication on the Dokploy login. The Dokploy UI is now the way into the box.
2. Restrict SSH in the firewall to your own IP. Nothing in this deploy needs SSH.

## 2. Create the project and its services

1. In Dokploy, create a project named `ytown`.
2. Add a **Database** of type Postgres. Name it `ducklake-catalog`. Copy the generated user, password, database name and internal host.
3. Add the **rustfs** template. Set an access key and secret key. Copy the internal host.
4. Open the rustfs console and create a bucket named `ytown-listings`. Neither dlt nor DuckLake creates the bucket.

## 3. Create the application

1. Add an **Application** to the project.
2. Source: this GitHub repo, branch `main`.
3. Build type: Dockerfile, path `Dockerfile`, context `.`.
4. Under **Domains**, add your domain and set the container port to `3001`.
5. Under **Advanced → Volumes**, add a volume mount:

   ```text
   /workspaces/ytown-listings/evidence/build
   ```

   This holds the built site so a redeploy serves the last good build straight away.

6. Turn on auto deploy so a push to `main` rebuilds the image.

## 4. Set the environment variables

Under **Environment**, add these. The first three take the place of `dlt/.dlt/secrets.toml`, which never leaves your machine. The rest match `.env.example`. Replace the angle bracket values with the hosts and credentials from step 2.

```text
SOURCES__RENTCAST__API_KEY=<rentcast key>

DESTINATION__FILESYSTEM__CREDENTIALS__AWS_ACCESS_KEY_ID=<rustfs access key>
DESTINATION__FILESYSTEM__CREDENTIALS__AWS_SECRET_ACCESS_KEY=<rustfs secret key>
DESTINATION__FILESYSTEM__CREDENTIALS__ENDPOINT_URL=http://<rustfs host>:9000

RUSTFS_ACCESS_KEY=<rustfs access key>
RUSTFS_SECRET_KEY=<rustfs secret key>
RUSTFS_ENDPOINT=<rustfs host>:9000

DUCKLAKE_CATALOG_HOST=<postgres host>
DUCKLAKE_CATALOG_PORT=5432
DUCKLAKE_CATALOG_DB=<postgres database>
DUCKLAKE_CATALOG_USER=<postgres user>
DUCKLAKE_CATALOG_PASSWORD=<postgres password>
```

## 5. Deploy

Click **Deploy**. Dokploy builds the image, which installs the Python venv and the Evidence node modules, then starts `make serve`. The container serves an empty directory until the pipeline has run once.

Deploying never calls RentCast. Only the schedule does.

## 6. Add the refresh schedule

1. Under **Schedules**, add a job.
2. Cron expression: `0 9 * * 1` (Mondays at 09:00 in the server timezone).
3. Command:

   ```text
   make run evidence-build
   ```

4. Save, then click **Run** once to populate the site.

The job runs dlt, dbt and the Evidence build inside the running container. Each run pulls listings from RentCast, so the cron expression is the API budget. Every run appears in the schedule's log tab.

## Updating

- Code change: push to `main`. Dokploy rebuilds the image and restarts the container. The site keeps serving from the volume.
- Data refresh: wait for the schedule, or click **Run** on it.
- Full reset: delete the `ytown-listings` bucket contents and the Postgres database in Dokploy, recreate the bucket, then run the schedule.
