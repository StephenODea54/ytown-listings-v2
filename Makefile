build:
	uv venv --clear && uv sync
	cd evidence && pnpm install --frozen-lockfile

run:
	cd dlt && ../.venv/bin/python3 rentcast_pipeline.py
	cd dbt && ../.venv/bin/dbt build
	cd evidence && pnpm sources

dev:
	cd evidence && pnpm dev -- --host 0.0.0.0

serve:
	rm -rf evidence/build
	cd evidence && pnpm build
	cd evidence && pnpm dlx http-server ./build -p 3001

evidence-build:
	cd evidence && pnpm build

docker-build:
	docker build -t ytown .

docker-run-evidence:
	docker run \
		--publish 3001:3001 \
		--network ytown-listings-v2_default \
		--env-file .env \
		--env RUSTFS_ENDPOINT=rustfs:9000 \
		--env DUCKLAKE_CATALOG_HOST=ducklake-catalog \
		--env DUCKLAKE_CATALOG_PORT=5432 \
		--env DESTINATION__FILESYSTEM__CREDENTIALS__ENDPOINT_URL=http://rustfs:9000 \
		--volume ./dlt/.dlt/secrets.toml:/workspaces/ytown-listings/dlt/.dlt/secrets.toml:ro \
		ytown make run serve

docker-dev:
	docker run \
		--publish 3001:3001 \
		--network ytown-listings-v2_default \
		--env-file .env \
		--env RUSTFS_ENDPOINT=rustfs:9000 \
		--env DUCKLAKE_CATALOG_HOST=ducklake-catalog \
		--env DUCKLAKE_CATALOG_PORT=5432 \
		--env DESTINATION__FILESYSTEM__CREDENTIALS__ENDPOINT_URL=http://rustfs:9000 \
		--volume ./dlt/.dlt/secrets.toml:/workspaces/ytown-listings/dlt/.dlt/secrets.toml:ro \
		ytown make run dev
