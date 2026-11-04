"""Small, deterministic normalization for English plan time phrases.

Clocked chooses the verbatim spans. This module turns only those copied words
into bounded values; it does not generate or infer a time that was not in the
person's input. Keeping it separate makes a language-specific normalizer easy
to add without changing the API contract.
"""

from __future__ import annotations

import re
from typing import Any

from app.models import PlanTimeExpression, Span

MAX_PLAN_MINUTES = 6 * 60

_NUMBERED_DURATION = re.compile(
    r"^(\d+(?:\.\d+)?)\s*(hours?|hrs?|hr|h|minutes?|mins?|min|m)$",
    re.IGNORECASE,
)
_CLOCK = re.compile(
    r"^(?P<hour>0?[1-9]|1[0-2])(?:(?::|\.)(?P<minute>[0-5]\d))?\s*"
    r"(?P<meridiem>am|pm)?$",
    re.IGNORECASE,
)


def duration_minutes_from_english(value: str) -> int | None:
    phrase = " ".join(value.lower().split())
    if phrase in {"an hour and a half", "a hour and a half", "one hour and a half"}:
        return 90
    if phrase in {"half an hour", "half a hour"}:
        return 30
    if phrase in {"an hour", "a hour", "one hour"}:
        return 60
    match = _NUMBERED_DURATION.fullmatch(phrase)
    if match is None:
        return None
    amount = float(match.group(1))
    if amount <= 0:
        return None
    minutes = amount * 60 if match.group(2).lower().startswith("h") else amount
    return round(minutes)


def clock_from_english(value: str) -> str | None:
    phrase = "".join(value.lower().split())
    if phrase == "noon":
        return "12:00"
    if phrase == "midnight":
        return "00:00"
    match = _CLOCK.fullmatch(phrase)
    if match is None:
        return None
    hour = int(match.group("hour"))
    minute = int(match.group("minute") or 0)
    meridiem = match.group("meridiem")
    if meridiem == "am":
        hour = 0 if hour == 12 else hour
    elif meridiem == "pm":
        hour = 12 if hour == 12 else hour + 12
    return f"{hour:02d}:{minute:02d}"


def span_from_field(field: dict[str, Any] | None) -> Span | None:
    if not field or field.get("value") is None:
        return None
    start = field.get("start")
    end = field.get("end")
    value = field.get("value")
    if not isinstance(value, str) or not isinstance(start, int) or not isinstance(end, int):
        return None
    if start < 0 or end <= start:
        return None
    return Span(text=value, start=start, end=end)


def time_expression_from_fields(
    fields: dict[str, Any],
    *,
    duration_key: str,
    start_key: str | None = None,
    end_key: str,
) -> PlanTimeExpression | None:
    duration = span_from_field(fields.get(duration_key))
    start = span_from_field(fields.get(start_key)) if start_key else None
    end = span_from_field(fields.get(end_key))
    minutes = duration_minutes_from_english(duration.text) if duration else None
    was_clamped = minutes is not None and minutes > MAX_PLAN_MINUTES
    if minutes is not None:
        minutes = max(1, min(MAX_PLAN_MINUTES, minutes))
    expression = PlanTimeExpression(
        duration_phrase=duration,
        duration_minutes=minutes,
        start_phrase=start,
        start_clock=clock_from_english(start.text) if start else None,
        end_phrase=end,
        end_clock=clock_from_english(end.text) if end else None,
        was_clamped=was_clamped,
    )
    if duration is None and start is None and end is None:
        return None
    return expression
