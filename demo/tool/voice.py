"""Builds the film's voice track from demo/narration.json.

    voice.py speak  OUT_DIR [--voice af_heart] [--speed 1.0]
        Speaks every line with Kokoro (offline, run with the venv made by
        demo/tool/voice.sh), then places them.
    voice.py take   OUT_DIR TAKE.wav --starts STARTS.txt
        Swaps in a recorded take (your own voice, ElevenLabs, anything):
        STARTS.txt holds one start time per narration line, in order
        (seconds or m:ss.mmm; `start end` also works). Each line is cut from
        its start to the next line's start, its trailing silence trimmed,
        then placed.
    voice.py place  OUT_DIR
        Places the line files already in OUT_DIR/voice/lines.

Placing puts each line at its scene's start plus its `at` cue (scenes from
demo/motion/scenes.json), so the picture never needs re-timing for a new
voice. A line that would run into the next is fitted by up to 1.15x tempo;
past that the tool stops and names the line, so the cue or the words can be
changed. Writes OUT_DIR/voice/voice.wav (48 kHz mono), voice-timing.json and
curre-demo.srt.
"""

import argparse
import json
import pathlib
import subprocess
import sys
import wave

import numpy as np

DEMO = pathlib.Path(__file__).resolve().parent.parent
RATE = 48000
GAP = 0.18  # the least silence kept before the next line starts
MAX_TEMPO = 1.15


def load_table():
    narration = json.loads((DEMO / "narration.json").read_text())
    scenes = json.loads((DEMO / "motion" / "scenes.json").read_text())["scenes"]
    starts, t = {}, 0.0
    for scene in scenes:
        starts[scene["id"]] = t
        t += scene["duration"]
    lines = []
    for line in narration["lines"]:
        lines.append({**line, "start": round(starts[line["scene"]] + line["at"], 3)})
    return narration, lines, t


def read_wav(path):
    out = subprocess.run(
        ["ffmpeg", "-v", "error", "-i", str(path), "-f", "f32le", "-ac", "1", "-ar", str(RATE), "-"],
        check=True, capture_output=True,
    ).stdout
    return np.frombuffer(out, dtype=np.float32).copy()


def write_wav(path, samples):
    path.parent.mkdir(parents=True, exist_ok=True)
    pcm = (np.clip(samples, -1, 1) * 32767).astype(np.int16)
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(pcm.tobytes())


def trim(samples, floor=0.006, pad=0.03):
    loud = np.flatnonzero(np.abs(samples) > floor)
    if not loud.size:
        return samples[:0]
    a = max(0, loud[0] - int(pad * RATE))
    b = min(len(samples), loud[-1] + int(pad * RATE * 3))
    return samples[a:b]


def tempo(samples, factor):
    if abs(factor - 1) < 1e-3:
        return samples
    raw = subprocess.run(
        ["ffmpeg", "-v", "error", "-f", "f32le", "-ar", str(RATE), "-ac", "1", "-i", "-",
         "-filter:a", f"atempo={factor:.4f}", "-f", "f32le", "-"],
        input=samples.astype(np.float32).tobytes(), check=True, capture_output=True,
    ).stdout
    return np.frombuffer(raw, dtype=np.float32).copy()


def speak(out, voice, speed, only=None):
    from kokoro_onnx import Kokoro  # noqa: PLC0415 - only inside the TTS venv

    cache = DEMO / ".cache" / "tts"
    kokoro = Kokoro(str(cache / "kokoro-v1.0.int8.onnx"), str(cache / "voices-v1.0.bin"))
    narration, lines, _ = load_table()
    say = narration.get("say", {})
    folder = out / "voice" / "lines"
    for line in lines:
        if only and line["id"] not in only:
            continue
        text = line["text"]
        for word, spoken in say.items():
            text = text.replace(word, spoken)
        samples, rate = kokoro.create(text, voice=voice, speed=speed, lang="en-us")
        tmp = folder / f"{line['id']}.raw.wav"
        tmp.parent.mkdir(parents=True, exist_ok=True)
        pcm = (np.clip(samples, -1, 1) * 32767).astype(np.int16)
        with wave.open(str(tmp), "wb") as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(rate)
            w.writeframes(pcm.tobytes())
        write_wav(folder / f"{line['id']}.wav", trim(read_wav(tmp)))
        tmp.unlink()
        print(f"spoke {line['id']}")


def parse_time(text):
    text = text.strip()
    if ":" in text:
        m, s = text.split(":", 1)
        return int(m) * 60 + float(s)
    return float(text)


def take(out, path, starts_file):
    _, lines, _ = load_table()
    rows = [r.split() for r in pathlib.Path(starts_file).read_text().splitlines()
            if r.strip() and not r.lstrip().startswith("#")]
    if len(rows) != len(lines):
        sys.exit(f"{starts_file} has {len(rows)} starts; narration.json has {len(lines)} lines.")
    audio = read_wav(path)
    folder = out / "voice" / "lines"
    for i, (line, row) in enumerate(zip(lines, rows)):
        a = parse_time(row[0])
        b = parse_time(row[1]) if len(row) > 1 else (
            parse_time(rows[i + 1][0]) if i + 1 < len(rows) else len(audio) / RATE)
        write_wav(folder / f"{line['id']}.wav", trim(audio[int(a * RATE):int(b * RATE)]))
    print(f"cut {len(lines)} lines from {path}")


def place(out):
    narration, lines, total = load_table()
    folder = out / "voice" / "lines"
    track = np.zeros(int((total + 1) * RATE), dtype=np.float32)
    timing, problems = [], []
    for i, line in enumerate(lines):
        samples = read_wav(folder / f"{line['id']}.wav")
        limit = (lines[i + 1]["start"] if i + 1 < len(lines) else total) - GAP - line["start"]
        length = len(samples) / RATE
        factor = 1.0
        if length > limit:
            factor = length / limit
            if factor > MAX_TEMPO:
                problems.append(f"{line['id']}: {length:.2f}s spoken, {limit:.2f}s free")
                factor = MAX_TEMPO
            samples = tempo(samples, factor)
        a = int(line["start"] * RATE)
        track[a:a + len(samples)] += samples
        timing.append({"id": line["id"], "text": line["text"], "start": line["start"],
                       "end": round(line["start"] + len(samples) / RATE, 3),
                       "tempo": round(factor, 3)})
    if problems:
        sys.exit("Lines that do not fit:\n  " + "\n  ".join(problems))
    track = track[: int(total * RATE)]
    write_wav(out / "voice" / "voice.wav", track)
    (out / "voice" / "voice-timing.json").write_text(json.dumps(
        {"seconds": total, "voice": narration.get("voice"), "lines": timing}, indent=2) + "\n")
    srt = []
    for n, row in enumerate(timing, 1):
        srt.append(f"{n}\n{stamp(row['start'])} --> {stamp(row['end'])}\n{row['text']}\n")
    (out / "voice" / "curre-demo.srt").write_text("\n".join(srt))
    for row in timing:
        print(f"{row['id']:>3} {row['start']:7.2f}-{row['end']:7.2f} x{row['tempo']}  {row['text'][:60]}")


def stamp(t):
    ms = int(round(t * 1000))
    h, ms = divmod(ms, 3600000)
    m, ms = divmod(ms, 60000)
    s, ms = divmod(ms, 1000)
    return f"{h:02}:{m:02}:{s:02},{ms:03}"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("mode", choices=["speak", "take", "place"])
    parser.add_argument("out")
    parser.add_argument("take", nargs="?")
    parser.add_argument("--starts")
    parser.add_argument("--voice")
    parser.add_argument("--speed", type=float)
    parser.add_argument("--only", nargs="*")
    args = parser.parse_args()
    out = pathlib.Path(args.out)
    narration, _, _ = load_table()
    if args.mode == "speak":
        speak(out, args.voice or narration["voice"], args.speed or narration["speed"], args.only)
    elif args.mode == "take":
        if not (args.take and args.starts):
            sys.exit("take needs TAKE.wav and --starts STARTS.txt")
        take(out, args.take, args.starts)
    place(out)


if __name__ == "__main__":
    main()
