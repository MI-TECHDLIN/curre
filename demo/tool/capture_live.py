"""Replays the film's recorded requests against the deployed Curre server.

    python3 demo/tool/capture_live.py OUT_DIR [--base-url URL] [--key-file PATH]
                                      [--only NAME ...] [--refresh]

Each request the real app sent during a render is in OUT_DIR/requests/
(written by demo/film/demo_server.dart). This sends that exact body to the
deployed route and saves the status and JSON answer in demo/film/fixtures/
under the same name, so the next render shows a real answer to the real
request. Existing fixtures are kept unless --refresh is given.

The app key is read from --key-file (or $CURRE_APP_KEY_FILE) and sent only as
the X-App-Key header. It is never printed, logged, or written to a fixture.
"""

import argparse
import json
import os
import pathlib
import sys
import time
import urllib.error
import urllib.request
import uuid

DEMO = pathlib.Path(__file__).resolve().parent.parent
FIXTURES = DEMO / "film" / "fixtures"
DEFAULT_BASE = "https://curre-zdfr.onrender.com"


def post(base, route, body, key, timeout=60):
    data = json.dumps(body).encode()
    headers = {"content-type": "application/json", "X-App-Key": key}
    if route == "/v1/plan":
        headers["Idempotency-Key"] = str(uuid.uuid4())
    req = urllib.request.Request(base + route, data=data, headers=headers, method="POST")
    started = time.monotonic()
    try:
        with urllib.request.urlopen(req, timeout=timeout) as res:
            status, raw = res.status, res.read()
    except urllib.error.HTTPError as err:
        status, raw = err.code, err.read()
    elapsed = (time.monotonic() - started) * 1000
    return status, json.loads(raw.decode() or "null"), elapsed


def wake(base):
    for _ in range(6):
        try:
            with urllib.request.urlopen(base + "/healthz", timeout=40) as res:
                if res.status == 200:
                    return
        except Exception:  # noqa: BLE001 - a sleeping host may reset the socket
            time.sleep(3)
    sys.exit("The deployed server did not wake up.")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("out")
    parser.add_argument("--base-url", default=DEFAULT_BASE)
    parser.add_argument("--key-file", default=os.environ.get("CURRE_APP_KEY_FILE"))
    parser.add_argument("--only", nargs="*")
    parser.add_argument("--refresh", action="store_true")
    args = parser.parse_args()
    if not args.key_file:
        sys.exit("Pass --key-file or set CURRE_APP_KEY_FILE.")
    key = pathlib.Path(args.key_file).read_text().strip()
    base = args.base_url.rstrip("/")

    requests = sorted((pathlib.Path(args.out) / "requests").glob("*.json"))
    todo = []
    for path in requests:
        name = path.stem
        if args.only and name not in args.only:
            continue
        if (FIXTURES / path.name).exists() and not args.refresh:
            continue
        todo.append(path)
    if not todo:
        print("Every recorded request already has a captured answer.")
        return
    FIXTURES.mkdir(parents=True, exist_ok=True)
    wake(base)
    for path in todo:
        recorded = json.loads(path.read_text())
        status, answer, elapsed = post(base, recorded["route"], recorded["request"], key)
        fixture = {
            "route": recorded["route"],
            "captured_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
            "source": base,
            "round_trip_ms": round(elapsed, 1),
            "request": recorded["request"],
            "status": status,
            "response": answer,
        }
        (FIXTURES / path.name).write_text(json.dumps(fixture, indent=2, ensure_ascii=False) + "\n")
        print(f"{path.stem}: {status} in {elapsed:.0f} ms")


if __name__ == "__main__":
    main()
