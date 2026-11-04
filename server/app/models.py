"""Request/response types for the SDD contract. Span offsets are Unicode
code-point offsets into the source text, end exclusive (never UTF-16 indices).
"""

from __future__ import annotations

from typing import Any, Literal

from pydantic import BaseModel, Field, ValidationError, field_validator, model_validator

Session = Literal["morning", "afternoon", "evening"]
Kind = Literal["task", "person", "time_sensitive", "browse", "unclear"]
Outcome = Literal["open", "later", "specify", "flagged", "unavailable"]
ProofOutcome = Literal["accepted", "vague", "pending"]
ProofKind = Literal["specific_completion", "vague", "future", "unrelated"]
PersonalDetail = Literal["person", "phone", "email", "address", "credit_card", "bank_account"]

MAX_LABEL_LEN = 60
MAX_CANDIDATES = 30
MAX_INTENTION_LEN = 500
MIN_REASON_LEN = 8
MAX_REASON_LEN = 300
MAX_PROOF_NOTE_LEN = 300
MAX_LATER_ITEMS = 20
MAX_LATER_ID_LEN = 64
MIN_CANDIDATES = 2
MAX_SHORTCUT_LABELS = 15
# Answers the plan and unlock steps already use for "no specific part of the
# app"; a shortcut with the same label would make that option ambiguous.
RESERVED_SHORTCUT_LABELS = frozenset({"The app itself", "app"})


def clean_label(value: Any) -> str | None:
    """A label a phone sent, tidied: whitespace (including the newlines some
    launchers put in app names) collapsed and the result cut to
    MAX_LABEL_LEN. None when nothing usable is left."""
    if not isinstance(value, str):
        return None
    label = " ".join(value.split())[:MAX_LABEL_LEN].rstrip()
    return label or None


def clean_shortcut_labels(value: Any) -> list[str]:
    """Usable shortcut labels in their original order. An empty, over-long,
    repeated or reserved label is dropped, never a reason to turn the whole
    request down: a shortcut is only an optional door into its app."""
    if not isinstance(value, list):
        return []
    labels: list[str] = []
    for raw in value:
        if not isinstance(raw, str):
            continue
        label = " ".join(raw.split())
        if not label or len(label) > MAX_LABEL_LEN or label in RESERVED_SHORTCUT_LABELS:
            continue
        if label in labels:
            continue
        labels.append(label)
        if len(labels) == MAX_SHORTCUT_LABELS:
            break
    return labels


def _clean_candidates(value: Any) -> Any:
    """Keeps every usable candidate (at most MAX_CANDIDATES) instead of
    rejecting the plan over one odd app: one with an empty id or label, a
    repeated id or label, or a field of the wrong type is dropped."""
    if not isinstance(value, list):
        return value
    cleaned: list[Candidate] = []
    ids: set[str] = set()
    labels: set[str] = set()
    for raw in value:
        if len(cleaned) == MAX_CANDIDATES:
            break
        try:
            candidate = Candidate.model_validate(raw)
        except ValidationError:
            continue
        if candidate.id in ids or candidate.label in labels:
            continue
        ids.add(candidate.id)
        labels.add(candidate.label)
        cleaned.append(candidate)
    return cleaned


class Span(BaseModel):
    text: str
    start: int
    end: int


class Redaction(BaseModel):
    """A personal detail Protect found in the reason or note the phone sent,
    as code-point offsets into that text. It carries no copy of the words."""

    kind: PersonalDetail
    start: int
    end: int


class Usage(BaseModel):
    credits: int
    model_ms: float


class Candidate(BaseModel):
    """One app the plan may pick. Its id is opaque and echoed back exactly,
    so it is never altered; the labels are cleaned on the way in."""

    id: str = Field(min_length=1)
    label: str = Field(min_length=1, max_length=MAX_LABEL_LEN)
    shortcut_labels: list[str] = Field(default_factory=list)
    query_door: bool = False

    @field_validator("id")
    @classmethod
    def _check_id(cls, value: str) -> str:
        if not value.strip():
            raise ValueError("id must not be blank")
        return value

    @field_validator("label", mode="before")
    @classmethod
    def _clean_label(cls, value: Any) -> Any:
        return clean_label(value) if isinstance(value, str) else value

    @field_validator("shortcut_labels", mode="before")
    @classmethod
    def _clean_shortcut_labels(cls, value: Any) -> list[str]:
        return clean_shortcut_labels(value)


class PlanRequest(BaseModel):
    session: Session
    intention: str = Field(min_length=1, max_length=MAX_INTENTION_LEN)
    # Cleaned before validation, so only the "at least two usable apps" rule
    # can turn the request down.
    candidates: list[Candidate] = Field(min_length=MIN_CANDIDATES, max_length=MAX_CANDIDATES)

    _clean = field_validator("candidates", mode="before")(_clean_candidates)


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

    @field_validator("app_label", mode="before")
    @classmethod
    def _clean_app_label(cls, value: Any) -> Any:
        return clean_label(value) if isinstance(value, str) else value

    @field_validator("shortcut_labels", mode="before")
    @classmethod
    def _clean_shortcut_labels(cls, value: Any) -> list[str]:
        return clean_shortcut_labels(value)


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
    # None when Protect did not answer: the phone then keeps the reason as is.
    redactions: list[Redaction] | None = None
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
    # The note's own claim Verify found contradicting the planned task, when
    # that contradiction kept the note from counting.
    mismatch: str | None = None
    # None when Protect did not answer: the phone then keeps the note as is.
    redactions: list[Redaction] | None = None
    usage: Usage | None = None


class LaterItem(BaseModel):
    id: str = Field(min_length=1, max_length=MAX_LATER_ID_LEN)
    app_label: str = Field(min_length=1, max_length=MAX_LABEL_LEN)
    text: str = Field(min_length=1, max_length=MAX_REASON_LEN)


class LaterRequest(BaseModel):
    plan: str = Field(min_length=1, max_length=MAX_INTENTION_LEN)
    items: list[LaterItem] = Field(min_length=1, max_length=MAX_LATER_ITEMS)

    @model_validator(mode="after")
    def _check_unique_ids(self) -> LaterRequest:
        ids = [item.id for item in self.items]
        if len(ids) != len(set(ids)):
            raise ValueError("item ids must be unique")
        return self


class LaterRank(BaseModel):
    id: str
    score: float = Field(ge=0.0, le=1.0)
    fits: bool


class LaterResponse(BaseModel):
    items: list[LaterRank]
    usage: Usage
