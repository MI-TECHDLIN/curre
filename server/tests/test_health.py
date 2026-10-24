from __future__ import annotations

from fastapi.testclient import TestClient

from app.main import app


def test_healthz_does_not_require_app_key():
    with TestClient(app) as client:
        resp = client.get("/healthz")
    assert resp.status_code == 200
    assert resp.json() == {"status": "ok"}
