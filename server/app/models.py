"""Request/response types for the SDD contract. Span offsets are Unicode
code-point offsets into the source text, end exclusive (never UTF-16 indices).
"""

from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, Field, field_validator, model_validator

Session = Literal["morning", "afternoon", "evening"]
Kind = Literal["task", "person", "time_sensitive", "browse", "unclear"]
Outcome = Literal["open", "later", "specify", "flagged", "unavailable"]
ProofOutcome = Literal["accepted", "vague", "pending"]
ProofKind = Literal["specific_completion", "vague", "future", "unrelated"]

MAX_LABEL_LEN = 60
MAX_CANDIDATES = 30
MAX_INTENTION_LEN = 500
MIN_REASON_LEN = 8
MAX_REASON_LEN = 300
MAX_PROOF_NOTE_LEN = 300


class Span(BaseModel):
    text: str
    start: int
    end: int


class Usage(BaseModel):
    credits: int
    model_ms: float


class Candidate(BaseModel):
    id: str = Field(min_length=1)
    label: str = Field(min_length=1, max_length=MAX_LABEL_LEN)
    shortcut_labels: list[str] = Field(default_factory=list)
    query_door: bool = False

    @field_validator("shortcut_labels")
    @classmethod
    def _check_shortcut_labels(cls, value: list[str]) -> list[str]:
        for label in value:
            if not label or len(label) > MAX_LABEL_LEN:
                raise ValueError(f"shortcut label must be 1-{MAX_LABEL_LEN} chars: {label!r}")
        if len(value) != len(set(value)):
            raise ValueError("shortcut_labels must be unique")
        return value


class PlanRequest(BaseModel):
    session: Session
    intention: str = Field(min_length=1, max_length=MAX_INTENTION_LEN)
    candidates: list[Candidate] = Field(min_length=2, max_length=MAX_CANDIDATES)

    @model_validator(mode="after")
    def _check_unique_labels(self) -> PlanRequest:
        labels = [c.label for c in self.candidates]
        if len(labels) != len(set(labels)):
            raise ValueError("candidate labels must be unique")
        ids = [c.id for c in self.candidates]
        if len(ids) != len(set(ids)):
            raise ValueError("candidate ids must be unique")
        return self


class PlanApp(BaseModel):
    id: str
    door: str | None = None
    query: Span | None = None


class PlanResponse(BaseModel):
    apps: list[PlanApp]
    end_phrase: Span | None = None
    usage: Usage


class UnlockRequest(BaseModel):
    app_label: str = Field(min_length=1, max_length=MAX_LABEL_LEN)
    plan_intention: str | None = Field(default=None, max_length=MAX_INTENTION_LEN)
    reason: str = Field(min_length=MIN_REASON_LEN, max_length=MAX_REASON_LEN)
    shortcut_labels: list[str] = Field(default_factory=list)
    threshold: float | None = None

    @field_validator("shortcut_labels")
    @classmethod
    def _check_shortcut_labels(cls, value: list[str]) -> list[str]:
        for label in value:
            if not label or len(label) > MAX_LABEL_LEN:
                raise ValueError(f"shortcut label must be 1-{MAX_LABEL_LEN} chars: {label!r}")
        if len(value) != len(set(value)):
            raise ValueError("shortcut_labels must be unique")
        return value


class GuardInfo(BaseModel):
    category: str
    quote: Span


class UnlockResponse(BaseModel):
    outcome: Outcome
    kind: Kind | None = None
    confidence: float | None = None
    door: str | None = None
    target: Span | None = None
    person: Span | None = None
    minutes: int | None = None
    guard: GuardInfo | None = None
    usage: Usage | None = None


class ProofRequest(BaseModel):
    task: str = Field(min_length=1, max_length=MAX_INTENTION_LEN)
    note: str = Field(min_length=1, max_length=MAX_PROOF_NOTE_LEN)


class ProofResponse(BaseModel):
    outcome: ProofOutcome
    kind: ProofKind | None = None
    specific_completion: float | None = None
    result: Span | None = None
    learning: Span | None = None
    usage: Usage | None = None
