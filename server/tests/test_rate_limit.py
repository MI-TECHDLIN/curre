from __future__ import annotations

from tests.fakes import decide_choice, fill_multiselect, make_pipeline_result, ok_step
from tests.test_plan import _plan_payload
from tests.test_unlock import _benign_guard_step, _unlock_payload


def test_plan_rate_limited_after_hourly_cap(make_client):
    async def handler(*, text, steps, **kwargs):
        return make_pipeline_result(
            [
                ok_step("plan", "fill", {"fields": {"apps": fill_multiselect(["YouTube"])}}),
                ok_step("spans", "extract", {"fields": {}}),
            ]
        )

    client = make_client(handler, plan_limit=2)
    assert client.post("/v1/plan", json=_plan_payload()).status_code == 200
    assert client.post("/v1/plan", json=_plan_payload()).status_code == 200
    resp = client.post("/v1/plan", json=_plan_payload())
    assert resp.status_code == 429


def test_unlock_rate_limited_after_hourly_cap(make_client):
    async def handler(*, text, steps, **kwargs):
        decide_fields = {"kind": decide_choice("task", 0.9)}
        return make_pipeline_result(
            [
                _benign_guard_step(),
                ok_step("gate", "decide", {"answers": decide_fields}),
                ok_step("task", "extract", {"fields": {}}),
            ]
        )

    client = make_client(handler, unlock_limit=1)
    assert client.post("/v1/unlock", json=_unlock_payload()).status_code == 200
    resp = client.post("/v1/unlock", json=_unlock_payload())
    assert resp.status_code == 429
