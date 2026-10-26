from __future__ import annotations

import logging
import time
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from uuid import UUID

from clocked_sdk import AsyncClocked
from fastapi import Depends, FastAPI, Header, HTTPException, Request

from app.clocked_pipeline import (
    PipelineUnavailable,
    run_plan_pipeline,
    run_unlock_pipeline,
)
from app.config import Settings, get_settings
from app.models import PlanRequest, PlanResponse, UnlockRequest, UnlockResponse
from app.rate_limit import RateLimiter, client_ip

logger = logging.getLogger("curre.server")
logging.basicConfig(level=logging.INFO)


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    settings = get_settings()
    app.state.clocked = AsyncClocked(api_key=settings.clocked_api_key or None)
    app.state.plan_limiter = RateLimiter(settings.plan_rate_limit_per_hour)
    app.state.unlock_limiter = RateLimiter(settings.unlock_rate_limit_per_hour)
    try:
        yield
    finally:
        await app.state.clocked.aclose()


app = FastAPI(title="Curre backend", lifespan=lifespan)


def get_clocked_client(request: Request) -> AsyncClocked:
    return request.app.state.clocked


def get_plan_limiter(request: Request) -> RateLimiter:
    return request.app.state.plan_limiter


def get_unlock_limiter(request: Request) -> RateLimiter:
    return request.app.state.unlock_limiter


def require_app_key(
    x_app_key: str = Header(default=""), settings: Settings = Depends(get_settings)
) -> None:
    if not settings.app_key or x_app_key != settings.app_key:
        raise HTTPException(status_code=401, detail="invalid or missing X-App-Key")


def _log_call(route: str, status: int, latency_ms: float, credits: int | None) -> None:
    logger.info("route=%s status=%s latency_ms=%.1f credits=%s", route, status, latency_ms, credits)


@app.get("/healthz")
async def healthz() -> dict[str, str]:
    return {"status": "ok"}


@app.post("/v1/plan", response_model=PlanResponse, dependencies=[Depends(require_app_key)])
async def plan(
    req: PlanRequest,
    request: Request,
    idempotency_key: UUID | None = Header(default=None, alias="Idempotency-Key"),
    clocked: AsyncClocked = Depends(get_clocked_client),
    limiter: RateLimiter = Depends(get_plan_limiter),
) -> PlanResponse:
    limiter.check(client_ip(request))
    start = time.monotonic()
    try:
        response = await run_plan_pipeline(
            clocked,
            req.intention,
            req.candidates,
            idempotency_key=idempotency_key,
        )
    except PipelineUnavailable:
        latency_ms = (time.monotonic() - start) * 1000
        _log_call("plan", 503, latency_ms, None)
        raise HTTPException(status_code=503, detail="plan unavailable") from None
    latency_ms = (time.monotonic() - start) * 1000
    _log_call("plan", 200, latency_ms, response.usage.credits)
    return response


@app.post("/v1/unlock", response_model=UnlockResponse, dependencies=[Depends(require_app_key)])
async def unlock(
    req: UnlockRequest,
    request: Request,
    clocked: AsyncClocked = Depends(get_clocked_client),
    limiter: RateLimiter = Depends(get_unlock_limiter),
    settings: Settings = Depends(get_settings),
) -> UnlockResponse:
    limiter.check(client_ip(request))
    start = time.monotonic()
    response = await run_unlock_pipeline(
        clocked,
        req.app_label,
        req.plan_intention,
        req.reason,
        req.shortcut_labels,
        settings.decide_threshold,
    )
    latency_ms = (time.monotonic() - start) * 1000
    credits = response.usage.credits if response.usage else None
    _log_call("unlock", 200, latency_ms, credits)
    return response
