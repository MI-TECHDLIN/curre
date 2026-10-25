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

All tests run without network calls or credit spend. Most route cases use the
fake Clocked client in `tests/fakes.py`; `tests/test_contract.py` also feeds
one recorded real pipeline response per route from `tests/fixtures/` through
the production parsers and validates the resulting Pydantic response types.

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

Start the server with `CLOCKED_API_KEY` already present in its environment,
then run the labeled real-call suite from a second terminal:

```sh
APP_KEY=local-only uvicorn app.main:app --port 8000
APP_KEY=local-only python scripts/measure.py \
  --base-url http://127.0.0.1:8000 \
  --output /tmp/curre-clocked-measurement.json
```

The script sends 10 plan intentions and 25 unlock reasons, prints exact
credits and p50/p95 client-observed HTTP latency, and re-scores the same
unlock answers at thresholds 0.6, 0.7 and 0.8 without spending more credits.
The optional JSON report contains only the authored samples, route responses
and measurements; it never contains either key.

## Measured with real Clocked calls

Measured 2026-10-25 against `clocked-sdk` 0.7.0 and the local FastAPI server,
sequentially, using the reproducible samples in `scripts/measure.py`.
Latency is full client-observed HTTP round-trip time, not only model time.

| Route | Samples | Credits/call, mean (range) | Total credits | p50 | p95 |
| --- | ---: | ---: | ---: | ---: | ---: |
| `/v1/plan` | 10 | 5.30 (4-11) | 53 | 274 ms | 858 ms |
| `/v1/unlock` | 25 | 4.76 (4-7) | 119 | 260 ms | 344 ms |

Unlock outcome accuracy by authored sample category:

| Threshold | Overall | Task | Person | Time-sensitive | Browse | Unclear | Honest urgent | Injection |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 0.6 | 84% | 100% | 75% | 75% | 75% | 100% | 50% | 100% |
| **0.7** | **84%** | **100%** | **75%** | **75%** | **75%** | **100%** | **50%** | **100%** |
| 0.8 | 76% | 100% | 50% | 50% | 75% | 100% | 50% | 100% |

The default stays at **0.7**. It tied 0.6 overall, but one browse reason was
misclassified as a task at 0.628 confidence: 0.6 would open it, while 0.7
asks the user to specify. Raising the threshold to 0.8 rejected additional
legitimate person and time-sensitive reasons. Guard flagged all 4 injection
attempts and neither of the 2 honest urgent/pleading reasons, so its custom
instructions did not need adjustment.

The measurement suite used 172 credits. Capturing the two real contract
fixtures used 9 more, and the initial key verification used 1, for an exact
task total of **182 credits**. No rejected-key attempt was billed.

### SDK response notes

The real responses matched the production parser: Decide choices are under
`result.answers.*.choice`, while Fill choices/multiselects and Extract fields
are under `result.fields.*` with Fill selections in `value`. Two details are
worth preserving in tests: a missing Extract value may be only
`{"value": null, "confidence": 1}` (no `p_blank`), and an integer field that
cannot be normalized returns `normalized: null` plus a
`normalization_reason`. The parser intentionally keys missingness from
`value`/`normalized`, not either diagnostic field.

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
