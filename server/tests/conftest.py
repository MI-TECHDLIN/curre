from __future__ import annotations

import os

os.environ.setdefault("CLOCKED_API_KEY", "test-placeholder-key")
os.environ.setdefault("APP_KEY", "test-placeholder-key")

import pytest
from fastapi.testclient import TestClient

from app.config import Settings, get_settings
from app.main import (
    app,
    get_clocked_client,
    get_later_limiter,
    get_plan_limiter,
    get_proof_limiter,
    get_unlock_limiter,
)
from app.rate_limit import RateLimiter
from tests.fakes import FakeAsyncClocked

APP_KEY = "test-app-key"


@pytest.fixture
def make_client():
    created: list[TestClient] = []

    def _make(
        handler,
        *,
        threshold: float = 0.7,
        plan_limit: int = 20,
        unlock_limit: int = 30,
        proof_limit: int = 30,
        later_limit: int = 20,
        rerank=None,
    ):
        fake = FakeAsyncClocked(handler, rerank)
        settings = Settings(
            clocked_api_key="unused",
            app_key=APP_KEY,
            decide_threshold=threshold,
            plan_rate_limit_per_hour=plan_limit,
            unlock_rate_limit_per_hour=unlock_limit,
            proof_rate_limit_per_hour=proof_limit,
            later_rate_limit_per_hour=later_limit,
        )
        plan_limiter = RateLimiter(plan_limit)
        unlock_limiter = RateLimiter(unlock_limit)
        proof_limiter = RateLimiter(proof_limit)
        later_limiter = RateLimiter(later_limit)
        app.dependency_overrides[get_clocked_client] = lambda: fake
        app.dependency_overrides[get_settings] = lambda: settings
        app.dependency_overrides[get_plan_limiter] = lambda: plan_limiter
        app.dependency_overrides[get_unlock_limiter] = lambda: unlock_limiter
        app.dependency_overrides[get_proof_limiter] = lambda: proof_limiter
        app.dependency_overrides[get_later_limiter] = lambda: later_limiter
        client = TestClient(app, headers={"X-App-Key": APP_KEY})
        client.fake = fake
        created.append(client)
        return client

    yield _make

    app.dependency_overrides.clear()
    for client in created:
        client.close()
