from __future__ import annotations

from tests.fakes import (
    error_step,
    extract_field,
    fill_choice,
    fill_multiselect,
    make_pipeline_result,
    ok_step,
)

CANDIDATES = [
    {
        "id": "yt",
        "label": "YouTube",
        "shortcut_labels": ["Search", "Subscriptions"],
        "query_door": True,
    },
    {"id": "sp", "label": "Spotify", "shortcut_labels": [], "query_door": True},
    {"id": "wa", "label": "WhatsApp", "shortcut_labels": ["Camera"], "query_door": False},
]

DEFAULT_INTENTION = "learn the G chord on YouTube and play worship on Spotify till 7"


def _plan_payload(intention: str = DEFAULT_INTENTION) -> dict:
    return {"session": "morning", "intention": intention, "candidates": CANDIDATES}


def _fields_from_steps(steps: list[dict]) -> tuple[dict, dict]:
    fill_fields = steps[0]["fill"]["fields"]
    extract_fields = steps[1]["extract"]["fields"]
    return fill_fields, extract_fields


def test_plan_maps_selected_labels_to_candidate_ids_and_resolves_doors_and_queries(make_client):
    async def handler(*, text, steps, **kwargs):
        fill_fields, extract_fields = _fields_from_steps(steps)
        fields = {"apps": fill_multiselect(["YouTube", "Spotify"])}
        fields["door_yt"] = fill_choice("Search")
        spans = {"ends": extract_field("7", start=74, end=75)}
        spans["q_yt"] = extract_field("G chord", start=15, end=22)
        spans["q_sp"] = extract_field("worship", start=38, end=45)
        return make_pipeline_result(
            [
                ok_step("plan", "fill", {"fields": fields}),
                ok_step("spans", "extract", {"fields": spans}),
            ],
            credits=18,
            model_ms=120.0,
        )

    client = make_client(handler)
    resp = client.post("/v1/plan", json=_plan_payload())
    assert resp.status_code == 200
    body = resp.json()

    apps_by_id = {app["id"]: app for app in body["apps"]}
    assert set(apps_by_id) == {"yt", "sp"}
    assert apps_by_id["yt"]["door"] == "Search"
    assert apps_by_id["yt"]["query"] == {"text": "G chord", "start": 15, "end": 22}
    assert apps_by_id["sp"]["door"] is None
    assert apps_by_id["sp"]["query"] == {"text": "worship", "start": 38, "end": 45}
    assert body["end_phrase"] == {"text": "7", "start": 74, "end": 75}
    assert body["usage"] == {"credits": 18, "model_ms": 120.0}

    # Never sends package names: only opaque ids and the labels the client gave.
    sent_text = client.fake.calls[0]["text"]
    assert "com.example" not in sent_text
    sent_fill_fields = client.fake.calls[0]["steps"][0]["fill"]["fields"]
    assert sent_fill_fields["apps"]["options"] == ["YouTube", "Spotify", "WhatsApp"]


def test_plan_door_choosing_app_itself_is_not_a_door(make_client):
    async def handler(*, text, steps, **kwargs):
        fields = {"apps": fill_multiselect(["YouTube"]), "door_yt": fill_choice("The app itself")}
        return make_pipeline_result(
            [
                ok_step("plan", "fill", {"fields": fields}),
                ok_step("spans", "extract", {"fields": {}}),
            ]
        )

    client = make_client(handler)
    resp = client.post("/v1/plan", json=_plan_payload())
    body = resp.json()
    assert body["apps"][0]["door"] is None


def test_plan_fill_step_error_returns_503(make_client):
    async def handler(*, text, steps, **kwargs):
        return make_pipeline_result(
            [error_step("plan", "fill"), error_step("spans", "extract")]
        )

    client = make_client(handler)
    resp = client.post("/v1/plan", json=_plan_payload())
    assert resp.status_code == 503


def test_plan_extract_step_error_still_returns_apps_without_spans(make_client):
    async def handler(*, text, steps, **kwargs):
        fields = {"apps": fill_multiselect(["YouTube"])}
        return make_pipeline_result(
            [ok_step("plan", "fill", {"fields": fields}), error_step("spans", "extract")]
        )

    client = make_client(handler)
    resp = client.post("/v1/plan", json=_plan_payload())
    assert resp.status_code == 200
    body = resp.json()
    assert body["apps"] == [{"id": "yt", "door": None, "query": None}]
    assert body["end_phrase"] is None


def test_plan_emoji_offsets_pass_through_as_code_points_untouched(make_client):
    # "learn 🎸 the G chord" -- the guitar emoji is one code point but two
    # UTF-16 units, so a correct implementation must not touch or
    # re-derive the offsets the fake Extract step returns.
    intention = "learn \U0001f3b8 the G chord on YouTube"

    async def handler(*, text, steps, **kwargs):
        fields = {"apps": fill_multiselect(["YouTube"])}
        spans = {"q_yt": extract_field("G chord", start=14, end=21)}
        return make_pipeline_result(
            [
                ok_step("plan", "fill", {"fields": fields}),
                ok_step("spans", "extract", {"fields": spans}),
            ]
        )

    client = make_client(handler)
    resp = client.post("/v1/plan", json=_plan_payload(intention))
    body = resp.json()
    assert body["apps"][0]["query"] == {"text": "G chord", "start": 14, "end": 21}


def test_plan_requires_app_key(make_client):
    async def handler(*, text, steps, **kwargs):  # pragma: no cover - should not be called
        raise AssertionError("must not call Clocked without a valid app key")

    client = make_client(handler)
    client.headers.pop("X-App-Key")
    resp = client.post("/v1/plan", json=_plan_payload())
    assert resp.status_code == 401


def test_plan_rejects_fewer_than_two_candidates(make_client):
    async def handler(*, text, steps, **kwargs):  # pragma: no cover
        raise AssertionError("must not call Clocked on invalid input")

    client = make_client(handler)
    payload = _plan_payload()
    payload["candidates"] = CANDIDATES[:1]
    resp = client.post("/v1/plan", json=payload)
    assert resp.status_code == 422


def test_plan_rejects_more_than_thirty_candidates(make_client):
    async def handler(*, text, steps, **kwargs):  # pragma: no cover
        raise AssertionError("must not call Clocked on invalid input")

    client = make_client(handler)
    payload = _plan_payload()
    payload["candidates"] = [
        {"id": f"c{i}", "label": f"App {i}", "shortcut_labels": [], "query_door": False}
        for i in range(31)
    ]
    resp = client.post("/v1/plan", json=payload)
    assert resp.status_code == 422


def test_plan_rejects_duplicate_labels(make_client):
    async def handler(*, text, steps, **kwargs):  # pragma: no cover
        raise AssertionError("must not call Clocked on invalid input")

    client = make_client(handler)
    payload = _plan_payload()
    payload["candidates"] = [
        {"id": "a", "label": "YouTube", "shortcut_labels": [], "query_door": False},
        {"id": "b", "label": "YouTube", "shortcut_labels": [], "query_door": False},
    ]
    resp = client.post("/v1/plan", json=payload)
    assert resp.status_code == 422


def test_plan_rejects_intention_over_cap(make_client):
    async def handler(*, text, steps, **kwargs):  # pragma: no cover
        raise AssertionError("must not call Clocked on invalid input")

    client = make_client(handler)
    payload = _plan_payload("x" * 501)
    resp = client.post("/v1/plan", json=payload)
    assert resp.status_code == 422


def test_plan_rejects_label_over_cap(make_client):
    async def handler(*, text, steps, **kwargs):  # pragma: no cover
        raise AssertionError("must not call Clocked on invalid input")

    client = make_client(handler)
    payload = _plan_payload()
    payload["candidates"] = [
        {"id": "a", "label": "x" * 61, "shortcut_labels": [], "query_door": False},
        {"id": "b", "label": "y", "shortcut_labels": [], "query_door": False},
    ]
    resp = client.post("/v1/plan", json=payload)
    assert resp.status_code == 422
