"""In-memory per-IP, per-route rate limiting. A key inside an APK can be
extracted, so this and the Clocked spending limit are the real controls
(not the X-App-Key header alone).
"""

from __future__ import annotations

import time
from collections import defaultdict, deque

from fastapi import HTTPException, Request

WINDOW_SECONDS = 3600.0


class RateLimiter:
    def __init__(self, limit_per_hour: int) -> None:
        self._limit = limit_per_hour
        self._hits: dict[str, deque[float]] = defaultdict(deque)

    def check(self, key: str) -> None:
        now = time.monotonic()
        hits = self._hits[key]
        while hits and now - hits[0] > WINDOW_SECONDS:
            hits.popleft()
        if len(hits) >= self._limit:
            raise HTTPException(status_code=429, detail="rate limit exceeded")
        hits.append(now)


def client_ip(request: Request) -> str:
    if request.client is None:
        return "unknown"
    return request.client.host
