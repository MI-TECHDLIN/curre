# Curre backend

FastAPI service implementing `POST /v1/plan`, `POST /v1/unlock`, and
`POST /v1/proof` per the Curre contracts, over one `clocked-sdk` (0.7.0)
`AsyncClocked.pipeline(...)` call per route. The phone owns all state; this
server turns plan, unlock, and completion text into structured decisions and
stores nothing. It also holds the Clocked API key, since a key inside the APK
could be extracted.

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
real for actual `/v1/plan`, `/v1/unlock`, and `/v1/proof` calls to Clocked.

## Test

```sh
pytest
ruff check .
```

All tests run without network calls or credit spend. Most route cases use the
fake Clocked client in `tests/fakes.py`; `tests/test_contract.py` also feeds
one recorded real pipeline response per route -- `real_plan_pipeline.json`,
`real_unlock_pipeline.json`, `real_proof_pipeline.json` (sample task/note
only, no key) -- from `tests/fixtures/` through the production parsers and
validates the resulting Pydantic response types. `modeled_proof_pipeline.json`
(marked `"recorded": false`) is a separate template `tests/test_proof.py`
reuses to build fake-client proof cases a single recorded response doesn't
cover; it is not a claim that no real `/v1/proof` call has been made.

## Environment variables

| Variable | Meaning |
| --- | --- |
| `CLOCKED_API_KEY` | Clocked API key. Never committed; `.env` is git-ignored. |
| `APP_KEY` | Shared secret the Flutter app sends as `X-App-Key`. |
| `DECIDE_THRESHOLD` | Confidence threshold for Decide's `kind` choice (default `0.7`). |
| `PLAN_RATE_LIMIT_PER_HOUR` | Per-IP cap on `/v1/plan` (default `20`). |
| `UNLOCK_RATE_LIMIT_PER_HOUR` | Per-IP cap on `/v1/unlock` (default `30`). |
| `PROOF_RATE_LIMIT_PER_HOUR` | Per-IP cap on `/v1/proof` (default `30`). |

## Endpoint map

| Route | Clocked steps (one pipeline call) | Outcome mapping |
| --- | --- | --- |
| `GET /healthz` | none | `{"status": "ok"}` |
| `POST /v1/plan` | Fill (`apps` multiselect + up to 8 `door_<id>` choice fields) -> Extract (`ends` + up to 6 `q_<id>` fields) | Selected `apps` labels map back to candidate ids; a step error on Fill is `503`. An Extract step error still returns the apps Fill chose, without spans. |
| `POST /v1/unlock` | Guard (`injection`, `stop: true`) -> Decide (`kind` choice, + `door` choice when shortcuts exist) -> Extract (`target`, `person`, `minutes` on the reason alone) | Guard stop (flagged verdict) -> `flagged`. `kind` in task/person/time_sensitive at or above the threshold -> `open` (grant = Extract `minutes` clamped 1-30, else 10 for task / 5 for person or time-sensitive). `browse` at or above the threshold -> `later`. `unclear`, or below the threshold -> `specify`. Any step error, the total timeout (6 s), or a Clocked error surviving the SDK's own retries -> `unavailable`. |
| `POST /v1/proof` | Guard (`injection`, `stop: true`) -> Decide (`proof` choice) -> Extract (`result`, `learning` on the note alone) | `specific_completion` at probability `>= 0.75` plus at least one extracted span -> `accepted`. A judged vague, future, unrelated, or guarded note -> `vague`. A step error, malformed result, total timeout (6 s), or Clocked error after retries -> `pending`. |

Credits and model time (`usage.credits`, `usage.model_ms`) come straight
from `Result.credits` / `Result.model_ms` on the pipeline call. Logs carry
route, status, latency and credits only -- never the intention, reason, task,
or completion note text.

The app starts a non-blocking `GET /healthz` when it boots and whenever a
check-in opens, so a sleeping deployment can wake while the user types. A plan
call gets one automatic retry inside its existing 12-second total budget: the
first attempt is capped at 9 seconds, the retry waits 250 ms and receives the
remaining time. Both attempts carry the same UUID `Idempotency-Key`, which
this route forwards to Clocked so a retry cannot create a second billed
pipeline run. Timeouts, transport failures, retryable HTTP statuses and a
200 response containing HTML or invalid JSON can trigger that retry. Build
with `--dart-define=CURRE_API_DEBUG=true` to log only attempt number,
status/error type, response content type, elapsed time and returned app count;
request text, response bodies and keys are never logged.

For a debug or profile build that points at a local tunnel requiring an extra
request header, set `CURRE_API_LOCAL_HEADER_NAME` and
`CURRE_API_LOCAL_HEADER_VALUE` with `--dart-define`. For example, a local
ngrok setup may use `ngrok-skip-browser-warning` and `true`. These optional
values are ignored by release builds; production should use the deployed
backend directly.

## Measuring credits and latency

Start the server with `CLOCKED_API_KEY` already present in its environment,
then run the labeled real-call suite from a second terminal:

```sh
APP_KEY=local-only uvicorn app.main:app --port 8000
APP_KEY=local-only python scripts/measure.py \
  --base-url http://127.0.0.1:8000 \
  --output /tmp/curre-clocked-measurement.json
```

The script sends 10 plan intentions and 25 unlock reasons (it does not cover
`/v1/proof` yet), prints exact credits and p50/p95 client-observed HTTP
latency, and re-scores the same unlock answers at thresholds 0.6, 0.7 and 0.8
without spending more credits.
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
- Past the app key, rate limit and input checks, `/v1/proof` always answers
  `200`. Anything that is not a judgement of the note (a step error, a
  malformed result, the 6 s timeout, a Clocked error after retries) is
  `pending`, so the phone keeps the note, retries it later and credits it to
  the task's original day. A note Guard stops is a judgement and comes back
  `vague`. `result`/`learning` offsets index the note alone, which is
  Extract's own `text`.
- `/v1/plan` has no `outcome` field, so a pipeline-level failure (the Fill
  step erroring, a timeout, or a Clocked error surviving retries) comes
  back as HTTP `503`, which the phone's existing "no network at check-in"
  fallback (manual checklist) already covers.
