FROM nikolaik/python-nodejs:python3.12-nodejs22-bookworm

USER root

WORKDIR /workspaces/ytown-listings

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

ENV COREPACK_ENABLE_DOWNLOAD_PROMPT=0

COPY --from=ghcr.io/astral-sh/uv:0.9 /uv /uvx /usr/local/bin/

COPY dlt ./dlt
COPY dbt ./dbt
COPY evidence ./evidence
COPY Makefile .
COPY .python-version .
COPY pyproject.toml .
COPY uv.lock .

RUN make build
