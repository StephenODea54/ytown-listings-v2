from typing import Any

from dlt.sources.helpers.rest_client.paginators import OffsetPaginator
from dlt.sources.rest_api import EndpointResource, RESTAPIConfig, rest_api_resources
from requests import PreparedRequest, Response, Session

import dlt

RENTCAST_BASE_URL = "https://api.rentcast.io/v1/"
MAX_PAGE_SIZE = 500
LISTINGS_TABLE = "sale_listings"


class RequestBudgetExceeded(Exception):
    pass


class BudgetedSession(Session):
    """Refuses to send more than `budget` requests."""

    def __init__(self, budget: int) -> None:
        super().__init__()
        self.budget = budget
        self.request_count = 0

    def send(self, request: PreparedRequest, **kwargs: Any) -> Response:
        if self.request_count >= self.budget:
            raise RequestBudgetExceeded(
                f"refusing to exceed the budget of {self.budget} RentCast requests"
            )
        self.request_count += 1
        return super().send(request, **kwargs)


class ShortPagePaginator(OffsetPaginator):
    """Stops on the first page shorter than the page size."""

    def _stop_after_this_page(self, data: list[Any] | None = None) -> bool:
        return not data or len(data) < self.limit


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
    session: Session,
    api_key: str = dlt.secrets.value,
    counties: list[dict[str, Any]] = dlt.config.value,
    property_type: str = dlt.config.value,
    status: str = dlt.config.value,
    price: str = dlt.config.value,
    max_listings_per_area: int = dlt.config.value,
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
            "session": session,
            "paginator": ShortPagePaginator(
                limit=MAX_PAGE_SIZE,
                # RentCast returns a bare array with no total count
                total_path=None,
                maximum_offset=max_listings_per_area,
            ),
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
    session = BudgetedSession(dlt.config["sources.rentcast.request_budget"])
    pipeline = dlt.pipeline(
        pipeline_name="rentcast",
        destination="filesystem",
        dataset_name="landing",
    )

    try:
        load_info = pipeline.run(
            rentcast_source(session=session), loader_file_format="parquet"
        )
        print(load_info)
    finally:
        print(f"RentCast requests used this run: {session.request_count}")


if __name__ == "__main__":
    load_sale_listings()
