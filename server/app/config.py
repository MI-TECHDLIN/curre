"""Environment-only configuration. No secrets have defaults."""

from __future__ import annotations

import os
from dataclasses import dataclass
from functools import lru_cache


@dataclass(frozen=True)
class Settings:
    clocked_api_key: str
    app_key: str
    decide_threshold: float
    plan_rate_limit_per_hour: int
    unlock_rate_limit_per_hour: int
    proof_rate_limit_per_hour: int = 30


@lru_cache
def get_settings() -> Settings:
    return Settings(
        clocked_api_key=os.environ.get("CLOCKED_API_KEY", ""),
        app_key=os.environ.get("APP_KEY", ""),
        decide_threshold=float(os.environ.get("DECIDE_THRESHOLD", "0.7")),
        plan_rate_limit_per_hour=int(os.environ.get("PLAN_RATE_LIMIT_PER_HOUR", "20")),
        unlock_rate_limit_per_hour=int(os.environ.get("UNLOCK_RATE_LIMIT_PER_HOUR", "30")),
        proof_rate_limit_per_hour=int(os.environ.get("PROOF_RATE_LIMIT_PER_HOUR", "30")),
    )
