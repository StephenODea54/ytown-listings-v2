.PHONY: build ingest transform sources run dev serve evidence-build docker-build

build:
	uv venv --clear && uv sync
	cd evidence && pnpm install --frozen-lockfile

ingest:
	cd dlt && ../.venv/bin/python3 rentcast_pipeline.py

transform:
	cd dbt && ../.venv/bin/dbt build

sources:
	cd evidence && pnpm sources

run:
	$(MAKE) ingest
	$(MAKE) transform
	$(MAKE) sources

dev:
	cd evidence && pnpm dev -- --host 0.0.0.0

serve:
	cd evidence && pnpm exec http-server ./build -p 3001

evidence-build:
	cd evidence && pnpm build

docker-build:
	docker build -t ytown .