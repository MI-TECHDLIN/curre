"""Mixes the film's sound and writes the delivery files.

    python3 mix.py FILM_OUT [--no-voice]

Inputs in FILM_OUT: curre-demo-picture.mp4 (the HyperFrames render),
voice/voice.wav (demo/tool/voice.sh) and sfx.json (build_motion.py).
Writes:
  curre-demo.mp4             voice over the music bed, ducked under speech,
                             plus effects; -16 LUFS, -1.5 dBTP
  curre-demo-music-only.mp4  music and effects only; -18 LUFS
  music.wav, sfx.wav         the stems
"""

import json
import pathlib
import subprocess
import sys

DEMO = pathlib.Path(__file__).resolve().parent.parent
SCENES = json.loads((DEMO / "motion" / "scenes.json").read_text())["scenes"]


def start_of(scene_id):
    t = 0.0
    for s in SCENES:
        if s["id"] == scene_id:
            return t
        t += s["duration"]
    raise KeyError(scene_id)


def run(args):
    subprocess.run(args, check=True)


def loudnorm(src, dst, lufs):
    """Two-pass loudness normalisation to `lufs` integrated, -1.5 dBTP."""
    probe = subprocess.run(
        ["ffmpeg", "-hide_banner", "-i", str(src), "-af",
         f"loudnorm=I={lufs}:TP=-1.5:LRA=11:print_format=json", "-f", "null", "-"],
        check=True, capture_output=True, text=True).stderr
    m = json.loads(probe[probe.rindex("{"):])
    run(["ffmpeg", "-v", "error", "-y", "-i", str(src), "-af",
         f"loudnorm=I={lufs}:TP=-1.5:LRA=11:measured_I={m['input_i']}:measured_TP={m['input_tp']}:"
         f"measured_LRA={m['input_lra']}:measured_thresh={m['input_thresh']}:offset={m['target_offset']}:linear=true,"
         "aresample=48000", "-c:a", "pcm_s16le", str(dst)])


def mux(picture, audio, dst):
    run(["ffmpeg", "-v", "error", "-y", "-i", str(picture), "-i", str(audio),
         "-map", "0:v:0", "-map", "1:a:0", "-c:v", "copy", "-c:a", "aac", "-b:a", "256k",
         "-ar", "48000", "-shortest", "-movflags", "+faststart", str(dst)])


def main():
    out = pathlib.Path(sys.argv[1])
    voiced = "--no-voice" not in sys.argv
    sfx_spec = json.loads((out / "sfx.json").read_text())
    seconds = sfx_spec["seconds"]
    tool = DEMO / "tool"
    music, sfx = out / "music.wav", out / "sfx.wav"
    run([sys.executable, str(tool / "make_music.py"), str(music), str(seconds),
         "--lift", str(start_of("arch")), "--resolve", str(start_of("end"))])
    run([sys.executable, str(tool / "sfx.py"), str(out / "sfx.json"), str(sfx)])
    picture = out / "curre-demo-picture.mp4"

    # Music only: bed and effects.
    bed = out / "mix-music.wav"
    run(["ffmpeg", "-v", "error", "-y", "-i", str(music), "-i", str(sfx), "-filter_complex",
         "[0:a]volume=0.9[m];[1:a]volume=1.0[s];[m][s]amix=inputs=2:normalize=0[a]",
         "-map", "[a]", str(bed)])
    norm = out / "mix-music-norm.wav"
    loudnorm(bed, norm, -18)
    mux(picture, norm, out / "curre-demo-music-only.mp4")

    if voiced:
        voice = out / "voice" / "voice.wav"
        mixed = out / "mix-voiced.wav"
        # The bed sits well under the voice and ducks a little more while it
        # speaks; effects sit about 18 dB under the voice.
        run(["ffmpeg", "-v", "error", "-y", "-i", str(music), "-i", str(voice), "-i", str(sfx),
             "-filter_complex",
             "[1:a]aresample=48000,pan=stereo|c0=c0|c1=c0,asplit=2[v][key];"
             "[0:a]volume=0.42[m];"
             "[m][key]sidechaincompress=threshold=0.03:ratio=5:attack=25:release=600:makeup=1[bed];"
             "[2:a]volume=0.55[s];"
             "[v]volume=1.0,highpass=f=70[vv];"
             "[vv][bed][s]amix=inputs=3:normalize=0[a]",
             "-map", "[a]", str(mixed)])
        norm = out / "mix-voiced-norm.wav"
        loudnorm(mixed, norm, -16)
        mux(picture, norm, out / "curre-demo.mp4")
    for tmp in ["mix-music.wav", "mix-voiced.wav"]:
        (out / tmp).unlink(missing_ok=True)
    print("wrote", out / "curre-demo.mp4", "and", out / "curre-demo-music-only.mp4")


if __name__ == "__main__":
    main()
