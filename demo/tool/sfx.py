"""Synthesises the film's few sound effects, in code (no samples).

    python3 sfx.py SFX.json OUT.wav

SFX.json (written by build_motion.py) lists each effect and when it lands.
Following the motion-graphics guide's rule, sounds sit only on things that
matter: a soft tap when the finger lands, a tick when a check appears, a
light counter while a number rolls, a pop as each pulling notification
lands in the opening, and a chime on the end card. No whooshes, and nothing
for cards sliding in or out. Each sound lands one frame after its picture.
"""

import json
import sys
import wave

import numpy as np

RATE = 48000
FRAME = 1 / 30


def env(n, attack, decay):
    t = np.arange(n) / RATE
    e = np.minimum(1, t / max(attack, 1e-4)) * np.exp(-t / decay)
    return e


def tap():
    n = int(0.05 * RATE)
    t = np.arange(n) / RATE
    body = np.sin(2 * np.pi * 1450 * t) * 0.6 + np.sin(2 * np.pi * 720 * t) * 0.4
    return body * env(n, 0.001, 0.008) * 0.10


def tick():
    n = int(0.09 * RATE)
    t = np.arange(n) / RATE
    body = np.sin(2 * np.pi * 2350 * t) + 0.45 * np.sin(2 * np.pi * 3520 * t)
    return body * env(n, 0.0008, 0.018) * 0.16


def pop():
    n = int(0.14 * RATE)
    t = np.arange(n) / RATE
    freq = 520 + 420 * np.exp(-t * 40)
    body = np.sin(2 * np.pi * np.cumsum(freq) / RATE)
    return body * env(n, 0.002, 0.035) * 0.16


def counter(duration):
    out = np.zeros(int((duration + 0.1) * RATE))
    one = tick() * 0.45
    # Ticks that slow down like the number's ease-out.
    k = 0
    while True:
        p = k / 14
        at = duration * (1 - (1 - p) ** 2) if p <= 1 else None
        if at is None:
            break
        i = int(at * RATE)
        out[i:i + len(one)] += one[: len(out) - i]
        k += 1
    return out


def chime():
    n = int(2.6 * RATE)
    t = np.arange(n) / RATE
    out = np.zeros(n)
    for i, (f, g) in enumerate([(1174.66, 1.0), (1479.98, 0.7), (1760.0, 0.55)]):
        d = int(i * 0.07 * RATE)
        tt = t[: n - d]
        bell = np.sin(2 * np.pi * f * tt) + 0.25 * np.sin(2 * np.pi * f * 2.76 * tt)
        out[d:] += g * bell * env(len(tt), 0.002, 0.7)
    return out * 0.10


def render(events, seconds):
    track = np.zeros(int((seconds + 3) * RATE))
    for e in events:
        sound = {
            "tap": tap, "tick": tick, "pop": pop, "chime": chime,
            "counter": lambda: counter(e.get("duration", 1.0)),
        }[e["kind"]]()
        i = int((e["at"] + FRAME) * RATE)
        track[i:i + len(sound)] += sound[: len(track) - i]
    return track[: int(seconds * RATE)]


def main():
    spec = json.loads(open(sys.argv[1]).read())
    mono = render(spec["events"], spec["seconds"])
    pcm = (np.clip(np.stack([mono, mono], 1), -1, 1) * 32767).astype(np.int16)
    with wave.open(sys.argv[2], "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(pcm.tobytes())


if __name__ == "__main__":
    main()
