"""A fake Clocked client plus builders for the response shapes recorded in
the differentiator report (section 4) and the clocked-sdk 0.7.0 README:
decide answers under `answers`, fill/extract answers under `fields`, and a
guard (injection) result with no wrapper at all.
"""

from __future__ import annotations

from collections.abc import Awaitable, Callable
from typing import Any

from clocked_sdk import Result

PipelineHandler = Callable[..., Awaitable[Result]]


class FakeAsyncClocked:
    def __init__(self, handler: PipelineHandler) -> None:
        self._handler = handler
        self.calls: list[dict[str, Any]] = []

    async def pipeline(
        self, *, text: str | None = None, steps: Any = None, **kwargs: Any
    ) -> Result:
        self.calls.append({"text": text, "steps": steps, **kwargs})
        return await self._handler(text=text, steps=steps, **kwargs)

    async def aclose(self) -> None:
        pass


def make_pipeline_result(
    steps: list[dict[str, Any]],
    stopped: dict[str, Any] | None = None,
    credits: int = 5,
    model_ms: float = 42.0,
) -> Result:
    return Result(
        {
            "model": "clocked-fake",
            "steps": steps,
            "stopped": stopped,
            "timing": {"total_ms": model_ms + 20, "model_ms": model_ms},
        },
        model_ms=model_ms,
        credits=credits,
        cost_usd=round(credits * 0.001, 5),
        cost_basis="reference",
    )


def ok_step(name: str, endpoint: str, result: dict[str, Any], ms: float = 10.0) -> dict[str, Any]:
    return {
        "step": 0,
        "endpoint": endpoint,
        "name": name,
        "status": 200,
        "ms": ms,
        "result": result,
    }


def error_step(name: str, endpoint: str, status: int = 500, ms: float = 5.0) -> dict[str, Any]:
    return {
        "step": 0,
        "endpoint": endpoint,
        "name": name,
        "status": status,
        "ms": ms,
        "error": "boom",
    }


def skipped_step(name: str, endpoint: str, reason: str) -> dict[str, Any]:
    return {"step": 0, "endpoint": endpoint, "name": name, "status": None, "skipped": reason}


def decide_choice(
    label: str, confidence: float, probabilities: dict[str, float] | None = None
) -> dict[str, Any]:
    return {
        "type": "choice",
        "choice": label,
        "confidence": confidence,
        "probabilities": probabilities or {label: confidence},
    }


def fill_multiselect(
    selected: list[str], confidence: float = 0.9, threshold: float = 0.7
) -> dict[str, Any]:
    return {
        "value": selected,
        "confidence": confidence,
        "probabilities": {label: 0.9 for label in selected},
        "threshold": threshold,
    }


def fill_choice(value: str, confidence: float = 0.9) -> dict[str, Any]:
    return {"value": value, "confidence": confidence, "probabilities": {value: confidence}}


def extract_field(
    value: str | None,
    start: int | None = None,
    end: int | None = None,
    confidence: float = 1.0,
    normalized: Any = None,
) -> dict[str, Any]:
    if value is None:
        return {"value": None, "confidence": confidence, "p_blank": 1}
    field: dict[str, Any] = {"value": value, "start": start, "end": end, "confidence": confidence}
    if normalized is not None:
        field["normalized"] = normalized
    return field


def injection_result(
    verdict: str,
    injection: float,
    category: str = "benign",
    evidence: list[dict[str, Any]] | None = None,
    threshold: float = 0.5,
) -> dict[str, Any]:
    return {
        "injection": injection,
        "verdict": verdict,
        "threshold": threshold,
        "source": "user",
        "category": category,
        "categories": {category: injection},
        "severity": "none" if verdict == "benign" else "high",
        "evidence": evidence or [],
        "residual": 0.0,
        "residual_verdict": "benign",
    }


def pii_result(*entities: tuple[str, str, int, int]) -> dict[str, Any]:
    """A Protect result in the recorded shape: findings only (no
    `anonymize`), each `(type, value, start, end)`."""
    counts: dict[str, int] = {}
    for kind, *_ in entities:
        counts[kind] = counts.get(kind, 0) + 1
    return {
        "checks": {"rejected": {}, "split": 0, "trimmed": 0},
        "counts": counts,
        "entities": [
            {
                "confidence": 1,
                "end": end,
                "mentions": 1,
                "source": "model",
                "start": start,
                "type": kind,
                "value": value,
            }
            for kind, value, start, end in entities
        ],
        "instructions_used": "default",
        "model": "clocked-fake",
        "threshold": 0.5,
        "timing": {"read_ms": 60, "total_ms": 61},
    }
