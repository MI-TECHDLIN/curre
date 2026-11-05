from __future__ import annotations

import pytest

from app.time_phrases import (
    clock_from_english,
    clock_from_phrase,
    duration_minutes_from_english,
    time_expression_from_fields,
)


@pytest.mark.parametrize(
    ("phrase", "minutes"),
    [
        ("2hrs", 120),
        ("2 hours", 120),
        ("an hour and a half", 90),
        ("90 min", 90),
        ("45 minutes", 45),
        ("half an hour", 30),
    ],
)
def test_normalizes_english_duration_forms(phrase: str, minutes: int) -> None:
    assert duration_minutes_from_english(phrase) == minutes


@pytest.mark.parametrize(
    ("phrase", "clock"),
    [("7", "07:00"), ("7:30pm", "19:30"), ("3pm", "15:00"), ("noon", "12:00")],
)
def test_normalizes_english_clock_forms(phrase: str, clock: str) -> None:
    assert clock_from_english(phrase) == clock


@pytest.mark.parametrize(
    ("phrase", "language", "clock"),
    [
        ("hasta las 7", "es", "07:00"),
        ("jusqu’à 7 h 30", "fr", "07:30"),
        ("até às 7", "pt", "07:00"),
        ("bis 7 Uhr", "de", "07:00"),
    ],
)
def test_normalizes_each_supported_language_end_form(
    phrase: str, language: str, clock: str
) -> None:
    assert clock_from_phrase(phrase, language) == clock


def test_structured_duration_is_clamped_to_six_hours() -> None:
    expression = time_expression_from_fields(
        {"duration": {"value": "8 hours", "start": 0, "end": 7}},
        duration_key="duration",
        end_key="ends",
    )
    assert expression is not None
    assert expression.duration_minutes == 360
    assert expression.was_clamped is True


def test_structured_time_drops_a_span_that_does_not_match_the_source() -> None:
    expression = time_expression_from_fields(
        {"duration": {"value": "2 hours", "start": 0, "end": 7}},
        duration_key="duration",
        end_key="ends",
        source="watch for 2 hours",
    )
    assert expression is None
