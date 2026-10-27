# Curre backend

FastAPI service implementing `POST /v1/plan`, `POST /v1/unlock`,
`POST /v1/proof`, and `POST /v1/later` per the Curre contracts. Plan,
unlock, and proof each make one `clocked-sdk` 0.7.0
`AsyncClocked.pipeline(...)` call; Later makes one
`AsyncClocked.rerank(...)` call. The phone owns all state; this server turns
plan, unlock, completion, and saved-reason text into structured decisions
and stores nothing. It also holds the Clocked API key, since a key inside the
APK could be extracted.

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
real for actual `/v1/plan`, `/v1/unlock`, `/v1/proof`, and `/v1/later`
calls to Clocked.

## Test

```sh
pytest
ruff check .
```

All tests run without network calls or credit spend. Most route cases use the
fake Clocked client in `tests/fakes.py`; `tests/test_contract.py` also feeds
one recorded real response per route -- `real_plan_pipeline.json`,
`real_unlock_pipeline.json`, `real_proof_pipeline.json`, and
`real_later_rerank.json` (fictional sample text only, no key) -- from
`tests/fixtures/` through the production parsers and validates the resulting
Pydantic response types. A second sanitized fixture,
`real_verify_contradiction_steps.json`, records the Protect and Verify shapes
for a note that conflicts with its plan. `modeled_proof_pipeline.json`
(marked `"recorded": false`) is a separate template `tests/test_proof.py`
reuses to build fake-client proof cases a single recorded response doesn't
cover; it is not a claim that no real `/v1/proof` call has been made.

## Environment variables

| Variable | Meaning |
| --- | --- |
| `CLOCKED_API_KEY` | Clocked API key. Never committed; `.env` is git-ignored. |
| `APP_KEY` | Shared secret the Flutter app sends as `X-App-Key`. |
| `DECIDE_THRESHOLD` | Fallback confidence threshold for Decide's `kind` choice (default `0.7`). Each unlock request may supply the user's saved threshold; the server clamps it to `0.5`-`0.9`. |
| `PLAN_RATE_LIMIT_PER_HOUR` | Per-IP cap on `/v1/plan` (default `20`). |
| `UNLOCK_RATE_LIMIT_PER_HOUR` | Per-IP cap on `/v1/unlock` (default `30`). |
| `PROOF_RATE_LIMIT_PER_HOUR` | Per-IP cap on `/v1/proof` (default `30`). |
| `LATER_RATE_LIMIT_PER_HOUR` | Per-IP cap on `/v1/later` (default `20`). |

## Endpoint map

| Route | Clocked call | Outcome mapping |
| --- | --- | --- |
| `GET /healthz` | none | `{"status": "ok"}` |
| `POST /v1/plan` | Fill (`apps` multiselect + up to 8 `door_<id>` choice fields) -> Extract (`ends` + up to 6 `q_<id>` fields) | Selected `apps` labels map back to candidate ids; a step error on Fill is `503`. An Extract step error still returns the apps Fill chose, without spans. |
| `POST /v1/unlock` | Protect (`pii` on the reason alone) -> Guard (`injection`, `stop: true`) -> Decide (`kind` choice, + `door` choice when shortcuts exist) -> Extract (`target`, `person`, `minutes` on the reason alone) | Protect returns source spans that make the phone's History copy show `[name]`, `[phone]`, and similar placeholders; it never changes the live gate or outcome. Guard stop -> `flagged`. A confident task/person/time_sensitive -> `open`; `browse` -> `later`; unclear or below threshold -> `specify`. A required-step error or timeout -> `unavailable`. |
| `POST /v1/proof` | Protect (`pii` on the note alone) -> Guard (`injection`, `stop: true`) -> Decide (`proof` choice) -> Extract (`result`, `learning` on the note alone) -> Verify (`grounding`, plan as document and note as answer) | Protect changes only the History copy. Decide must return `specific_completion` at `>= 0.75` and Extract must return a result or learning span. Verify then vetoes only a claim with `contradicted >= 0.6`; `not_stated` does not veto it. The response carries that claim as the plain follow-up reason. A judged vague, future, unrelated, guarded, or contradicted note -> `vague`; an unanswered required step -> `pending`. |
| `POST /v1/later` | One Rerank call (`query` is the new plan; 1–20 documents carry opaque id, app label as title, and saved reason as text) | Returns every known id in descending `relevance_score`. `fits` is true only for Rerank's `use` action; the phone shows at most three fitting items. A timeout, Clocked error, empty result, or malformed result is `503`, and the phone quietly falls back to newest first. |

Credits and model time (`usage.credits`, `usage.model_ms`) come straight
from `Result.credits` / `Result.model_ms` on the Clocked call. Logs carry
route, status, latency and credits only -- never the intention, reason,
saved item, task, or completion note text.

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

### Protect and Verify measurements (2026-10-26)

This change used **16 credits**, below its 20-credit cap. Both inputs are
fictional and saved in `tests/fixtures/`; neither fixture contains a key.

| Call | Samples | Credits | Client round trip | Pipeline total | Relevant step times |
| --- | ---: | ---: | ---: | ---: | --- |
| Current `/v1/proof` pipeline (Protect, Guard, Decide, Extract, Verify) | 1 | 10 | 899.7 ms | 324 ms | Protect 65 ms; Verify 56 ms |
| Contradiction calibration (Protect, Verify) | 1 | 6 | not recorded | 139 ms | Protect 72 ms; Verify 66 ms |

The existing 25-call `/v1/unlock` baseline above predates Protect. The
current unlock route adds the same Protect request body used by `/v1/proof`
inside its one pipeline call; the two real observations put that step at
65–72 ms. Pipeline credits are billed as one total, so there is no honest
per-step credit to add to the 4.76-credit baseline. A further full-route
sample was deliberately not spent after the two calls reached 16 credits.

Compare and Inspect are not called. Compare would duplicate the plan-versus-
note decision Verify already makes, while Inspect reviews scripts rather than
these short user notes. Neither has a separate output that could truthfully
change Curre's behavior or UI. `grounding` is the SDK/API name of Verify, not
an additional endpoint.

### Rerank measurement (2026-10-26)

The sanitized real response in `tests/fixtures/real_later_rerank.json`
ranked six fictional saved reasons against one plan. It cost **2 credits**
and the SDK reported **38.3 ms** of billable model time; the response's own
timing reported 119 ms total. This was one contract-shape sample, not a
latency distribution. No key or real personal text is in the fixture.

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
- Protect also receives the bare reason or note as step-local `text`, so its
  code-point offsets index exactly the copy the phone may keep. A missing,
  failed, malformed, overlapping or out-of-range Protect result changes
  nothing; Curre stores the original and does not claim it was redacted.
- `/v1/plan` has no `outcome` field, so a pipeline-level failure (the Fill
  step erroring, a timeout, or a Clocked error surviving retries) comes
  back as HTTP `503`, which the phone's existing "no network at check-in"
  fallback (manual checklist) already covers.
