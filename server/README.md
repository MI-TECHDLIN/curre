# Curre backend

FastAPI service implementing `POST /v1/plan` and `POST /v1/unlock` per the
Curre SDD, over one `clocked-sdk` (0.7.0) `AsyncClocked.pipeline(...)` call
per route. The phone owns all state; this server turns an intention or
unlock reason into a structured decision and stores nothing. It also holds
the Clocked API key, since a key inside the APK could be extracted.

## Run locally

```sh
cd server
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements-dev.txt
cp .env.example .env   # fill in CLOCKED_API_KEY and APP_KEY
uvicorn app.main:app --reload
```

`CLOCKED_API_KEY` must be a non-empty string for the server to start (the
SDK checks this at construction), but it does not need to be a real key to
run locally against the fake-client test suite below -- it only needs to be
real for actual `/v1/plan` and `/v1/unlock` calls to Clocked.

## Test

```sh
pytest
ruff check .
```

All routes are tested against a fake Clocked client (`tests/fakes.py`)
built from the response shapes recorded in
`data/curre-differentiator/report.md` section 4 and the clocked-sdk 0.7.0
README -- no network calls, no credits spent. `tests/test_contract.py`
additionally validates real route responses against the Pydantic
request/response types.

## Environment variables

| Variable | Meaning |
| --- | --- |
| `CLOCKED_API_KEY` | Clocked API key. Never committed; `.env` is git-ignored. |
| `APP_KEY` | Shared secret the Flutter app sends as `X-App-Key`. |
| `DECIDE_THRESHOLD` | Confidence threshold for Decide's `kind` choice (default `0.7`). |
| `PLAN_RATE_LIMIT_PER_HOUR` | Per-IP cap on `/v1/plan` (default `20`). |
| `UNLOCK_RATE_LIMIT_PER_HOUR` | Per-IP cap on `/v1/unlock` (default `30`). |

## Endpoint map

| Route | Clocked steps (one pipeline call) | Outcome mapping |
| --- | --- | --- |
| `GET /healthz` | none | `{"status": "ok"}` |
| `POST /v1/plan` | Fill (`apps` multiselect + up to 8 `door_<id>` choice fields) -> Extract (`ends` + up to 6 `q_<id>` fields) | Selected `apps` labels map back to candidate ids; a step error on Fill is `503`. An Extract step error still returns the apps Fill chose, without spans. |
| `POST /v1/unlock` | Guard (`injection`, `stop: true`) -> Decide (`kind` choice, + `door` choice when shortcuts exist) -> Extract (`target`, `person`, `minutes` on the reason alone) | Guard stop (flagged verdict) -> `flagged`. `kind` in task/person/time_sensitive at or above the threshold -> `open` (grant = Extract `minutes` clamped 1-30, else 10 for task / 5 for person or time-sensitive). `browse` at or above the threshold -> `later`. `unclear`, or below the threshold -> `specify`. Any step error, the total timeout (6 s), or a Clocked error surviving the SDK's own retries -> `unavailable`. |

Credits and model time (`usage.credits`, `usage.model_ms`) come straight
from `Result.credits` / `Result.model_ms` on the pipeline call. Logs carry
route, status, latency and credits only -- never the intention or reason
text.

## Measuring credits and latency

`scripts/measure.py` sends a handful of sample plan and unlock requests
through the *real* pipeline and prints credit and latency percentiles.
**Not run as part of this change** -- there is no Clocked key yet:

```sh
CLOCKED_API_KEY=clk_live_... python scripts/measure.py --n 20
```

## Deploy notes

One container, one process (`uvicorn app.main:app`), stateless. Build with
`docker build -t curre-server server/` and run with `CLOCKED_API_KEY` and
`APP_KEY` as environment variables; `GET /healthz` is the readiness check.
Free tiers that sleep need warming before a demo. HTTPS termination is the
host's job, not the container's.

## Known behaviors worth knowing

- A guard quote's `start`/`end` index the composed Guard text
  (`App: ...\nPlan: ...\nReason: ...`), not the bare `reason` string, since
  the SDD only promises reason-relative offsets for `target`/`person`
  (Extract gets the reason alone as its own `text`). The phone should treat
  `guard.quote` as a literal copy of flagged words, not assume it slices
  the reason it sent.
- `/v1/plan` has no `outcome` field, so a pipeline-level failure (the Fill
  step erroring, a timeout, or a Clocked error surviving retries) comes
  back as HTTP `503`, which the phone's existing "no network at check-in"
  fallback (manual checklist) already covers.
