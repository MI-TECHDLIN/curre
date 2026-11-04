"""Writes the film's music bed: soft, warm and original, synthesised here
with numpy (no samples, no third-party material). Output is 48 kHz stereo
WAV.

    python3 make_music.py OUT.wav SECONDS [--lift T] [--resolve T]
                          [--clicks CLICKS.wav --at T,T,...]

A slow D major progression on a warm pad, sparse felt-piano notes and a
light low pulse at 72 bpm, with a little room reverb. Nothing carries a
melody, so it never competes with the narration. --lift starts a gentle
lift (a high shimmer, keys moving in eighths, a fuller pulse) for the
pipeline card; --resolve is where the close begins: the chord grid is
anchored so a suspended dominant lands on the tonic there, and the bed
settles on it and fades. --clicks writes a separate track of soft, quiet
clicks at the given times (Curre's film uses tool/sfx.py instead).

Ported unchanged from the Pinne demo film's engine.
"""

import argparse
import wave

import numpy as np

RATE = 48000
BPM = 72
BEAT = 60 / BPM
BAR = 4 * BEAT
CHORD = 2 * BAR

# D major, as MIDI notes: Dmaj9, Bm9, Gmaj9, A9sus4. Low to high; the first
# note is the bass.
PROGRESSION = [
    [38, 57, 61, 64, 66, 69],
    [35, 54, 57, 61, 62, 66],
    [31, 55, 59, 62, 66, 69],
    [33, 55, 59, 62, 64, 69],
]
TONIC = [38, 57, 62, 64, 66, 69, 73]


def hz(note):
    return 440.0 * 2 ** ((note - 69) / 12)


def tone(freq, seconds, harmonics, detune_cents=0.0, phase=0.0):
    t = np.arange(int(seconds * RATE)) / RATE
    f = freq * 2 ** (detune_cents / 1200)
    out = np.zeros_like(t)
    for k, amp in enumerate(harmonics, start=1):
        if f * k < RATE / 2.2:
            out += amp * np.sin(2 * np.pi * f * k * t + phase * k)
    return out


def envelope(n, attack, release, curve=2.0):
    env = np.ones(n)
    a = min(n, int(attack * RATE))
    r = min(n - a, int(release * RATE))
    if a:
        env[:a] = np.linspace(0, 1, a) ** curve
    if r:
        env[n - r:] *= np.linspace(1, 0, r) ** curve
    return env


class Bus:
    def __init__(self, n):
        self.l = np.zeros(n)
        self.r = np.zeros(n)

    def add(self, signal, start, pan=0.0, gain=1.0):
        i = int(round(start * RATE))
        if i < 0:
            signal, i = signal[-i:], 0
        if i >= len(self.l) or len(signal) == 0:
            return
        j = min(len(self.l), i + len(signal))
        seg = signal[: j - i] * gain
        self.l[i:j] += seg * np.sqrt((1 - pan) / 2)
        self.r[i:j] += seg * np.sqrt((1 + pan) / 2)

    def stereo(self):
        return np.stack([self.l, self.r], axis=1)


def reverb(stereo, seconds=2.4, seed=7):
    """A soft room: convolution with decaying, darkened noise."""
    rng = np.random.default_rng(seed)
    n = int(seconds * RATE)
    t = np.arange(n) / RATE
    out = np.zeros_like(stereo)
    for ch in range(2):
        ir = rng.standard_normal(n) * np.exp(-t * 6.9 / seconds)
        # Darken: a few passes of a one-pole low-pass.
        for _ in range(3):
            ir = np.convolve(ir, np.ones(24) / 24, mode="same")
        ir[: int(0.012 * RATE)] = 0  # pre-delay
        ir /= np.sqrt(np.sum(ir ** 2))
        size = 1 << int(np.ceil(np.log2(len(stereo) + n)))
        wet = np.fft.irfft(np.fft.rfft(stereo[:, ch], size) * np.fft.rfft(ir, size), size)
        out[:, ch] = wet[: len(stereo)]
    return out


def lift_curve(times, lift, resolve):
    if lift is None:
        return np.zeros_like(times)
    up = np.clip((times - lift) / 2.5, 0, 1)
    down = 1 - np.clip((times - (resolve - 1.5)) / 2.0, 0, 1) if resolve else 1
    return (np.sin(up * np.pi / 2) ** 2) * down


def compose(seconds, lift=None, resolve=None):
    tail = 4.0
    n = int((seconds + tail) * RATE)
    pad, keys, low, air = Bus(n), Bus(n), Bus(n), Bus(n)
    resolve = resolve if resolve is not None and resolve < seconds else None
    # The grid is anchored on the resolve, so the A9sus4 chord ends there.
    anchor = resolve if resolve is not None else 0.0
    first = int(np.floor((0 - anchor) / CHORD)) - 1
    last = int(np.ceil(((resolve if resolve is not None else seconds) - anchor) / CHORD))
    rng = np.random.default_rng(2026)

    def lifted(at):
        return float(lift_curve(np.array([at]), lift, resolve)[0])

    for c in range(first, last):
        start = anchor + c * CHORD
        end = start + CHORD
        if end <= 0:
            continue
        chord = PROGRESSION[c % len(PROGRESSION)]
        # Pad: three slightly detuned voices per note, slow swell, overlap.
        length = CHORD + 2.2
        for note in chord[1:]:
            for cents, pan in ((-5, -0.6), (0, 0.0), (5, 0.6)):
                v = tone(hz(note), length, (1.0, 0.32, 0.12, 0.05), cents, rng.uniform(0, 6.28))
                v *= envelope(len(v), 1.8, 2.2)
                pad.add(v, start - 0.4, pan, 0.016)
        # Bass: a soft sine root.
        b = tone(hz(chord[0]), CHORD + 0.8, (1.0, 0.18, 0.04))
        b *= envelope(len(b), 0.6, 1.4)
        low.add(b, start, 0.0, 0.065)
        # Shimmer during the lift: chord tones two octaves up.
        lf = lifted(start + CHORD / 2)
        if lf > 0.01:
            for i, note in enumerate(chord[2:5]):
                s = tone(hz(note + 24), length, (1.0, 0.1), 3 * (i - 1))
                s *= envelope(len(s), 2.0, 2.4) * (0.6 + 0.4 * np.sin(np.arange(len(s)) / RATE * 2.1 + i))
                air.add(s, start - 0.3, (i - 1) * 0.7, 0.006 * lf)
        # Keys and pulse, bar by bar.
        for bar in range(2):
            bar_at = start + bar * BAR
            if bar_at < BAR * 2:  # the first bars are pad only
                continue
            lf = lifted(bar_at)
            if lf < 0.5:
                pattern = [(0.0, 1), (1.5, 3), (2.5, 2)]
            else:
                pattern = [(k * 0.5, [1, 3, 2, 4, 1, 3, 2, 5][k]) for k in range(8)]
            for beat, idx in pattern:
                note = chord[min(idx, len(chord) - 1)] + (12 if idx < 2 else 0)
                when = bar_at + beat * BEAT + rng.uniform(-0.008, 0.008)
                k = tone(hz(note), 2.6, (1.0, 0.42, 0.16, 0.06, 0.02))
                tt = np.arange(len(k)) / RATE
                k *= np.exp(-tt * (1.6 + 1.2 * lf)) * envelope(len(k), 0.006, 0.3)
                vel = rng.uniform(0.75, 1.0) * (0.75 if beat % 1 else 1.0)
                keys.add(k, when, 0.25 if idx % 2 else -0.25, 0.045 * vel)
            # Light pulse: a soft low thump on 1 and 3, every beat when lifted.
            beats = range(4) if lf >= 0.5 else (0, 2)
            for beat in beats:
                when = bar_at + beat * BEAT
                m = int(0.32 * RATE)
                tt = np.arange(m) / RATE
                freq = 58 + 26 * np.exp(-tt * 30)
                thump = np.sin(2 * np.pi * np.cumsum(freq) / RATE) * np.exp(-tt * 13)
                thump *= envelope(m, 0.004, 0.05)
                low.add(thump, when, 0.0, 0.07 if beat in (0, 2) else 0.045)

    if resolve is not None:
        # The close: the tonic, held, with one soft bell high above.
        length = seconds - resolve + tail
        for i, note in enumerate(TONIC[1:]):
            for cents, pan in ((-4, -0.5), (4, 0.5)):
                v = tone(hz(note), length, (1.0, 0.3, 0.1), cents)
                v *= envelope(len(v), 1.2, length * 0.7, 1.6)
                pad.add(v, resolve - 0.2, pan, 0.016)
        b = tone(hz(TONIC[0]), length, (1.0, 0.15))
        low.add(b * envelope(len(b), 0.4, length * 0.7), resolve, 0.0, 0.065)
        for i, note in enumerate([74, 78, 81]):
            bell = tone(hz(note + 12), 4.0, (1.0, 0.0, 0.25, 0.0, 0.08))
            bell *= np.exp(-np.arange(len(bell)) / RATE * 1.1) * envelope(len(bell), 0.004, 0.5)
            keys.add(bell, resolve + 0.1 + i * 0.55, (i - 1) * 0.4, 0.02)

    dry = pad.stereo() + keys.stereo() + air.stereo()
    mix = dry + 0.42 * reverb(dry) + low.stereo() + 0.12 * reverb(low.stereo(), 1.2, 3)
    mix = mix[: int(seconds * RATE)]
    fade_in, fade_out = int(2.0 * RATE), int(3.5 * RATE)
    mix[:fade_in] *= (np.linspace(0, 1, fade_in) ** 2)[:, None]
    mix[-fade_out:] *= (np.linspace(1, 0, fade_out) ** 1.6)[:, None]
    mix /= np.max(np.abs(mix)) / 0.5  # peak at -6 dBFS
    return mix


def clicks(seconds, times):
    """Soft, short clicks: a muted tick, no whoosh."""
    out = np.zeros((int(seconds * RATE), 2))
    rng = np.random.default_rng(5)
    m = int(0.06 * RATE)
    tt = np.arange(m) / RATE
    tick = np.sin(2 * np.pi * 2100 * tt) * np.exp(-tt * 140)
    tick += 0.5 * np.sin(2 * np.pi * 950 * tt) * np.exp(-tt * 90)
    noise = rng.standard_normal(m) * np.exp(-tt * 400)
    tick += 0.15 * np.convolve(noise, np.ones(6) / 6, mode="same")
    tick *= envelope(m, 0.0015, 0.01)
    tick /= np.max(np.abs(tick))
    for at in times:
        i = int(at * RATE)
        if 0 <= i < len(out) - m:
            out[i:i + m] += tick[:, None] * 0.07  # about -23 dBFS peak
    return out


def write(path, stereo):
    pcm = (np.clip(stereo, -1, 1) * 32767).astype(np.int16)
    with wave.open(path, "wb") as f:
        f.setnchannels(2)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(pcm.tobytes())


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("out")
    parser.add_argument("seconds", type=float)
    parser.add_argument("--lift", type=float)
    parser.add_argument("--resolve", type=float)
    parser.add_argument("--clicks")
    parser.add_argument("--at", default="")
    args = parser.parse_args()
    write(args.out, compose(args.seconds, args.lift, args.resolve))
    if args.clicks:
        times = [float(x) for x in args.at.split(",") if x]
        write(args.clicks, clicks(args.seconds, times))


if __name__ == "__main__":
    main()
