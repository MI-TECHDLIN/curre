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
_LEADING_CLOCK_WORDS = re.compile(
    r"^(?:(?:till|until|by|to|from|at)|(?:hasta(?:\s+las)?)|"
    r"(?:até(?:\s+às?)?)|(?:jusqu['’]?(?:à|a)?)|bis)\s+",
    re.IGNORECASE,
)
_NOON_WORDS = {
    "en": {"noon"},
    "es": {"mediodía", "mediodia"},
    "fr": {"midi"},
    "pt": {"meio-dia", "meiodia"},
    "de": {"mittag"},
}
_MIDNIGHT_WORDS = {
    "en": {"midnight"},
    "es": {"medianoche"},
    "fr": {"minuit"},
    "pt": {"meia-noite", "meianoite"},
    "de": {"mitternacht"},
}


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


def clock_from_phrase(value: str, language: str = "en") -> str | None:
    code = language.lower().split("-", 1)[0].split("_", 1)[0]
    words = " ".join(value.lower().split())
    words = _LEADING_CLOCK_WORDS.sub("", words)
    words = re.sub(r"\s+uhr$", "", words)
    words = re.sub(r"\bp\s*\.\s*m\s*\.?$", "pm", words)
    words = re.sub(r"\ba\s*\.\s*m\s*\.?$", "am", words)
    if words in _NOON_WORDS.get(code, _NOON_WORDS["en"]):
        return "12:00"
    if words in _MIDNIGHT_WORDS.get(code, _MIDNIGHT_WORDS["en"]):
        return "00:00"
    phrase = "".join(words.split())
    phrase = re.sub(r"^(\d{1,2})h([0-5]\d)$", r"\1:\2", phrase)
    phrase = re.sub(r"^(\d{1,2})h$", r"\1", phrase)
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


def clock_from_english(value: str) -> str | None:
    return clock_from_phrase(value, "en")


def span_from_field(field: dict[str, Any] | None, source: str | None = None) -> Span | None:
    if not field or field.get("value") is None:
        return None
    start = field.get("start")
    end = field.get("end")
    value = field.get("value")
    if not isinstance(value, str) or not isinstance(start, int) or not isinstance(end, int):
        return None
    if start < 0 or end <= start:
        return None
    if source is not None and (end > len(source) or source[start:end] != value):
        return None
    return Span(text=value, start=start, end=end)


def time_expression_from_fields(
    fields: dict[str, Any],
    *,
    duration_key: str,
    start_key: str | None = None,
    end_key: str,
    source: str | None = None,
    language: str = "en",
) -> PlanTimeExpression | None:
    duration = span_from_field(fields.get(duration_key), source)
    start = span_from_field(fields.get(start_key), source) if start_key else None
    end = span_from_field(fields.get(end_key), source)
    minutes = duration_minutes_from_english(duration.text) if duration else None
    was_clamped = minutes is not None and minutes > MAX_PLAN_MINUTES
    if minutes is not None:
        minutes = max(1, min(MAX_PLAN_MINUTES, minutes))
    expression = PlanTimeExpression(
        duration_phrase=duration,
        duration_minutes=minutes,
        start_phrase=start,
        start_clock=clock_from_phrase(start.text, language) if start else None,
        end_phrase=end,
        end_clock=clock_from_phrase(end.text, language) if end else None,
        was_clamped=was_clamped,
    )
    if duration is None and start is None and end is None:
        return None
    return expression
