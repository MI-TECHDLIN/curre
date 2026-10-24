#!/usr/bin/env python3
"""Sends N sample /v1/plan and /v1/unlock pipeline calls through the real
Clocked API and prints credit and latency percentiles.

Requires CLOCKED_API_KEY to be set to a real key. Not run as part of the
test suite or CI -- there is no key yet (see the README). Usage:

    CLOCKED_API_KEY=clk_live_... python scripts/measure.py --n 20
"""

from __future__ import annotations

import argparse
import asyncio
import os
import statistics
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from clocked_sdk import AsyncClocked  # noqa: E402

from app.clocked_pipeline import (  # noqa: E402
    build_plan_steps,
    build_unlock_steps,
)
from app.models import Candidate  # noqa: E402

SAMPLE_INTENTIONS = [
    "Pray, then learn the G chord on YouTube and play worship on Spotify till 7",
    "Reply to the team on WhatsApp about tomorrow's standup, then check my calendar",
    "Watch one video about sourdough starters on YouTube before breakfast",
]

SAMPLE_CANDIDATES = [
    Candidate(
        id="yt", label="YouTube", shortcut_labels=["Search", "Subscriptions"], query_door=True
    ),
    Candidate(id="sp", label="Spotify", shortcut_labels=[], query_door=True),
    Candidate(id="wa", label="WhatsApp", shortcut_labels=["Camera"], query_door=False),
    Candidate(id="ca", label="Calendar", shortcut_labels=[], query_door=False),
]

SAMPLE_UNLOCK_REASONS = [
    ("Instagram", "reply Ada about rehearsal", ["Messages", "Camera"]),
    ("TikTok", "just checking what's new", []),
    ("YouTube", "look up the G chord for worship practice", ["Search"]),
]


def _percentiles(values: list[float]) -> dict[str, float]:
    if not values:
        return {"p50": 0.0, "p90": 0.0, "max": 0.0}
    ordered = sorted(values)
    return {
        "p50": statistics.median(ordered),
        "p90": ordered[min(len(ordered) - 1, int(len(ordered) * 0.9))],
        "max": ordered[-1],
    }


async def _measure_plan(client: AsyncClocked, n: int) -> tuple[list[int], list[float]]:
    credits: list[int] = []
    latencies_ms: list[float] = []
    for i in range(n):
        intention = SAMPLE_INTENTIONS[i % len(SAMPLE_INTENTIONS)]
        steps = build_plan_steps(intention, SAMPLE_CANDIDATES)
        start = time.monotonic()
        result = await client.pipeline(text=intention, steps=steps)
        latencies_ms.append((time.monotonic() - start) * 1000)
        credits.append(result.credits or 0)
    return credits, latencies_ms


async def _measure_unlock(client: AsyncClocked, n: int) -> tuple[list[int], list[float]]:
    credits: list[int] = []
    latencies_ms: list[float] = []
    for i in range(n):
        app_label, reason, shortcut_labels = SAMPLE_UNLOCK_REASONS[i % len(SAMPLE_UNLOCK_REASONS)]
        text = f"App: {app_label}\nPlan: none\nReason: {reason}"
        steps = build_unlock_steps(app_label, None, reason, shortcut_labels)
        start = time.monotonic()
        result = await client.pipeline(text=text, steps=steps, max_attempts=2)
        latencies_ms.append((time.monotonic() - start) * 1000)
        credits.append(result.credits or 0)
    return credits, latencies_ms


async def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--n", type=int, default=20, help="samples per route")
    args = parser.parse_args()

    api_key = os.environ.get("CLOCKED_API_KEY")
    if not api_key:
        print("CLOCKED_API_KEY is not set; nothing to measure.", file=sys.stderr)
        raise SystemExit(1)

    async with AsyncClocked(api_key=api_key) as client:
        plan_credits, plan_latencies = await _measure_plan(client, args.n)
        unlock_credits, unlock_latencies = await _measure_unlock(client, args.n)

    for name, credits, latencies in (
        ("plan", plan_credits, plan_latencies),
        ("unlock", unlock_credits, unlock_latencies),
    ):
        lat = _percentiles(latencies)
        print(f"{name}: n={len(credits)} credits_mean={statistics.mean(credits):.1f}")
        print(f"  latency_ms p50={lat['p50']:.0f} p90={lat['p90']:.0f} max={lat['max']:.0f}")


if __name__ == "__main__":
    asyncio.run(main())
