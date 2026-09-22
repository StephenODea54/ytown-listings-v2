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
	cd evidence && pnpm exec http-server ./build -p 3001

evidence-build:
	cd evidence && pnpm build

docker-build:
	docker build -t ytown .
