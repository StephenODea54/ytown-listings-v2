from typing import Any

from dlt.sources.rest_api import EndpointResource, RESTAPIConfig, rest_api_resources

import dlt

RENTCAST_BASE_URL = "https://api.rentcast.io/v1/"
MAX_PAGE_SIZE = 500
LISTINGS_TABLE = "sale_listings"


def build_county_resource(
    county: dict[str, Any],
    property_type: str,
    status: str,
    price: str,
) -> EndpointResource:
    county_name = county["name"]
    return {
        "name": f"{LISTINGS_TABLE}_{county_name.lower()}",
        "table_name": LISTINGS_TABLE,
        "processing_steps": [
            {"map": lambda listing: {**listing, "search_area": county_name}}
        ],
        "endpoint": {
            "path": "listings/sale",
            "data_selector": "$",
            "params": {
                "latitude": county["latitude"],
                "longitude": county["longitude"],
                "radius": county["radius"],
                "propertyType": property_type,
                "status": status,
                "price": price,
            },
        },
    }


@dlt.source(name="rentcast", section="rentcast")
def rentcast_source(
    api_key: str = dlt.secrets.value,
    counties: list[dict[str, Any]] = dlt.config.value,
    property_type: str = dlt.config.value,
    status: str = dlt.config.value,
    price: str = dlt.config.value,
) -> Any:
    config: RESTAPIConfig = {
        "client": {
            "base_url": RENTCAST_BASE_URL,
            "auth": {
                "type": "api_key",
                "name": "X-Api-Key",
                "api_key": api_key,
                "location": "header",
            },
            "paginator": {
                "type": "offset",
                "limit": MAX_PAGE_SIZE,
                "offset_param": "offset",
                "limit_param": "limit",
                # RentCast returns a bare array with no total count
                "total_path": None,
                "stop_after_empty_page": True,
            },
        },
        "resource_defaults": {
            "write_disposition": "append",
            "max_table_nesting": 0,
        },
        "resources": [
            build_county_resource(county, property_type, status, price)
            for county in counties
        ],
    }

    yield from rest_api_resources(config)


def load_sale_listings() -> None:
    pipeline = dlt.pipeline(
        pipeline_name="rentcast",
        destination="filesystem",
        dataset_name="landing",
    )

    load_info = pipeline.run(rentcast_source(), loader_file_format="parquet")
    print(load_info)


if __name__ == "__main__":
    load_sale_listings()
