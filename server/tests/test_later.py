"""`POST /v1/later` against a fake Clocked client whose `rerank` replies in
the shape of `fixtures/real_later_rerank.json`, the recorded real response
(see `tests/test_contract.py`)."""

from __future__ import annotations

import asyncio
import logging

from clocked_sdk import RateLimitError

from app import clocked_pipeline
from tests.fakes import make_rerank_result, rerank_entry

PLAN = "Evening off: relax, catch up with friends and see what everyone has been up to"
ITEMS = [
    {"id": "later-1", "app_label": "Instagram", "text": "see what Tolu posted today"},
    {"id": "later-2", "app_label": "YouTube", "text": "watch the guitar cover Marcus uploaded"},
    {"id": "later-3", "app_label": "X", "text": "catch up on the football transfer news"},
]


def _payload(plan: str = PLAN, items: list[dict] | None = None) -> dict:
    return {"plan": plan, "items": ITEMS if items is None else items}


def _no_pipeline(*, text, steps, **kwargs):
    raise AssertionError("/v1/later must not run a pipeline")


def test_later_returns_rerank_order_with_fits(make_client):
    async def rerank(*, query, documents, **kwargs):
        return make_rerank_result(
            [
                rerank_entry(0, "later-1", 0.995),
                rerank_entry(1, "later-2", 0.41, action="expand"),
                rerank_entry(2, "later-3", 0.0042, action="skip", reason="unrelated"),
            ],
            credits=2,
        )

    client = make_client(_no_pipeline, rerank=rerank)
    resp = client.post("/v1/later", json=_payload())

    assert resp.status_code == 200
    assert resp.json() == {
        "items": [
            {"id": "later-1", "score": 0.995, "fits": True},
            {"id": "later-2", "score": 0.41, "fits": False},
            {"id": "later-3", "score": 0.0042, "fits": False},
        ],
        "usage": {"credits": 2, "model_ms": 38.0},
    }


def test_later_sends_one_rerank_call_with_plan_as_query(make_client):
    async def rerank(*, query, documents, **kwargs):
        return make_rerank_result([rerank_entry(i, d["id"], 0.5) for i, d in enumerate(documents)])

    client = make_client(_no_pipeline, rerank=rerank)
    client.post("/v1/later", json=_payload())

    assert client.fake.calls == []
    assert len(client.fake.rerank_calls) == 1
    call = client.fake.rerank_calls[0]
    assert call["query"] == PLAN
    assert call["documents"] == [
        {"id": "later-1", "title": "Instagram", "text": "see what Tolu posted today"},
        {"id": "later-2", "title": "YouTube", "text": "watch the guitar cover Marcus uploaded"},
        {"id": "later-3", "title": "X", "text": "catch up on the football transfer news"},
    ]
    assert call["instructions"] == clocked_pipeline.LATER_INSTRUCTIONS
    assert call["max_attempts"] == clocked_pipeline.LATER_MAX_ATTEMPTS


def test_later_order_follows_the_plan(make_client):
    """The same saved items come back in a different order for another plan."""
    scores = {
        "football": {"later-3": 0.97, "later-1": 0.02, "later-2": 0.01},
        "friends": {"later-1": 0.99, "later-2": 0.03, "later-3": 0.01},
    }

    async def rerank(*, query, documents, **kwargs):
        table = scores["football" if "football" in query else "friends"]
        ordered = sorted(enumerate(documents), key=lambda pair: -table[pair[1]["id"]])
        return make_rerank_result(
            [
                rerank_entry(
                    i,
                    d["id"],
                    table[d["id"]],
                    action="use" if table[d["id"]] > 0.5 else "skip",
                    reason=None if table[d["id"]] > 0.5 else "unrelated",
                )
                for i, d in ordered
            ]
        )

    client = make_client(_no_pipeline, rerank=rerank)
    friends = client.post("/v1/later", json=_payload()).json()["items"]
    football = client.post("/v1/later", json=_payload("Watch the football tonight")).json()["items"]

    assert [item["id"] for item in friends] == ["later-1", "later-2", "later-3"]
    assert [item["id"] for item in football] == ["later-3", "later-1", "later-2"]
    assert [item["fits"] for item in football] == [True, False, False]


def test_later_maps_results_by_index_when_id_is_missing(make_client):
    async def rerank(*, query, documents, **kwargs):
        return make_rerank_result([rerank_entry(2, None, 0.9), rerank_entry(0, None, 0.1)])

    client = make_client(_no_pipeline, rerank=rerank)
    body = client.post("/v1/later", json=_payload()).json()

    # later-2 never came back: kept last, as not fitting.
    assert body["items"] == [
        {"id": "later-3", "score": 0.9, "fits": True},
        {"id": "later-1", "score": 0.1, "fits": True},
        {"id": "later-2", "score": 0.0, "fits": False},
    ]


def test_later_ignores_unknown_and_repeated_ids(make_client):
    async def rerank(*, query, documents, **kwargs):
        return make_rerank_result(
            [
                rerank_entry(0, "someone-else", 0.99),
                rerank_entry(1, "later-2", 0.8),
                rerank_entry(1, "later-2", 0.7),
                rerank_entry(0, "later-1", 0.6),
                rerank_entry(2, "later-3", 0.5),
            ]
        )

    client = make_client(_no_pipeline, rerank=rerank)
    ids = [item["id"] for item in client.post("/v1/later", json=_payload()).json()["items"]]
    assert ids == ["later-2", "later-1", "later-3"]


def test_later_clocked_error_is_503(make_client):
    async def rerank(*, query, documents, **kwargs):
        raise RateLimitError("slow down", status=429)

    client = make_client(_no_pipeline, rerank=rerank)
    resp = client.post("/v1/later", json=_payload())
    assert resp.status_code == 503
    assert resp.json() == {"detail": "later unavailable"}


def test_later_malformed_result_is_503(make_client):
    async def rerank(*, query, documents, **kwargs):
        return make_rerank_result([{"id": "later-1", "action": "use"}])

    client = make_client(_no_pipeline, rerank=rerank)
    assert client.post("/v1/later", json=_payload()).status_code == 503


def test_later_empty_result_is_503(make_client):
    async def rerank(*, query, documents, **kwargs):
        return make_rerank_result([])

    client = make_client(_no_pipeline, rerank=rerank)
    assert client.post("/v1/later", json=_payload()).status_code == 503


def test_later_times_out_as_503(make_client, monkeypatch):
    monkeypatch.setattr(clocked_pipeline, "LATER_TIMEOUT_SECONDS", 0.01)

    async def rerank(*, query, documents, **kwargs):
        await asyncio.sleep(1)
        return make_rerank_result([rerank_entry(0, "later-1", 0.9)])

    client = make_client(_no_pipeline, rerank=rerank)
    assert client.post("/v1/later", json=_payload()).status_code == 503


def test_later_requires_app_key(make_client):
    client = make_client(_no_pipeline)
    resp = client.post("/v1/later", json=_payload(), headers={"X-App-Key": "wrong"})
    assert resp.status_code == 401


def test_later_rejects_bad_input(make_client):
    client = make_client(_no_pipeline)
    too_many = [{"id": f"later-{i}", "app_label": "YouTube", "text": "watch"} for i in range(21)]
    repeated = [ITEMS[0], {**ITEMS[1], "id": "later-1"}]
    long_text = [{**ITEMS[0], "text": "x" * 301}]
    long_id = [{**ITEMS[0], "id": "x" * 65}]
    for payload in (
        _payload(items=[]),
        _payload(items=too_many),
        _payload(items=repeated),
        _payload(items=long_text),
        _payload(items=long_id),
        _payload(plan=""),
        _payload(plan="x" * 501),
    ):
        assert client.post("/v1/later", json=payload).status_code == 422
    assert client.fake.rerank_calls == []


def test_later_rate_limited_after_hourly_cap(make_client):
    async def rerank(*, query, documents, **kwargs):
        return make_rerank_result([rerank_entry(0, "later-1", 0.9)])

    client = make_client(_no_pipeline, rerank=rerank, later_limit=1)
    assert client.post("/v1/later", json=_payload()).status_code == 200
    assert client.post("/v1/later", json=_payload()).status_code == 429


def test_later_logs_no_text(make_client, caplog):
    async def rerank(*, query, documents, **kwargs):
        return make_rerank_result([rerank_entry(0, "later-1", 0.9)], credits=3)

    client = make_client(_no_pipeline, rerank=rerank)
    with caplog.at_level(logging.INFO, logger="curre.server"):
        client.post("/v1/later", json=_payload())

    logged = "\n".join(record.getMessage() for record in caplog.records)
    assert "route=later status=200" in logged
    assert "credits=3" in logged
    for words in (PLAN, "Tolu", "Marcus", "football", "Instagram"):
        assert words not in logged
