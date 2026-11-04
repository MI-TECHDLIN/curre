"""Writes the HyperFrames composition for the Curre demo film.

    python3 demo/tool/build_motion.py FILM_OUT

Reads the scene table (demo/motion/scenes.json), the phone shots and their
sidecars (FILM_OUT/clips/*.mp4|json, filmed by demo/film/shots_test.dart),
and the placed voice lines (FILM_OUT/voice/voice-timing.json), and writes
demo/motion/index.html plus FILM_OUT/sfx.json (where each sound effect
lands). Everything time-based in the film is derived from those three
sources, so a re-filmed shot or a new voice take only needs this step and a
render.

Style: the captain's motion-graphics guide, recoloured to Curre. A calm
"Liquid Glass" stage (frosted cards, slow colour blobs in Curre's pastels)
with kinetic type only for the hook and section titles; the real app screens
as filmed, with camera punch-ins on the part that matters and one short line
saying what it does. Named moves used: Rise, Pop, Count-up, Checklist tick,
Typewriter, Slide-in, Punch-in, Reframe, Bar fill.
"""

import html
import json
import os
import pathlib
import shutil
import sys

DEMO = pathlib.Path(__file__).resolve().parent.parent
MOTION = DEMO / "motion"
REPO = DEMO.parent
FPS = 30

# Phone placement on the 1920x1080 stage.
PHONE_W, PHONE_H = 392, 850  # logical points, as filmed
K = 860 / PHONE_H  # stage pixels per phone point
PX, PY = 1300 - PHONE_W * K / 2, 110  # screen's top-left on the stage
BEZEL = 12
FOCUS = (1300, 545)  # where a zoom target's centre lands
FOCUS_BOX = (860, 780)  # the most a zoom target may fill

# Curre's palette (lib/design/curre_colors.dart, light theme).
C = {
    "paper": "#F7F2EA", "raised": "#FFFDF9", "sunk": "#EEE7DC", "ink": "#1E1A16",
    "ink2": "#5A5048", "ink3": "#6E6257", "hairline": "#E2D9CC", "ember": "#E85F2E",
    "emberText": "#A8441A", "marigold": "#FCC35A", "rose": "#F7D3CC", "blue": "#CFE2F4",
    "green": "#DDE9CF", "sand": "#F3E2C4", "evening": "#2E3876", "open": "#CFE8C9",
}

TITLES = {
    "setup": ("01 · Set up", ["Pick a focus.", "Hide what pulls."]),
    "oneline": ("02 · Check-in", ["One sentence."]),
    "whynow": ("03 · Why now?", ["A hidden app", "asks why."]),
    "held": ("04 · Notifications", ["Held, then", "given back."]),
    "proof": ("05 · Proof", ["Proof,", "not ticks."]),
    "later": ("06 · Later", ["Saved for later,", "ranked to fit."]),
    "focusend": ("07 · The end", ["The focus ends.", "So does Curre’s job."]),
}

# Zooms: scene -> (clip, mark, in, out, label, line, extra). Times are clip
# seconds; marks are rectangles the shot recorded.
ZOOMS = {
    "setup": [
        ("setup", "focus-end", 7.3, 9.8, "Your focus", "Exams: pass my finals.", {"count": (14, "days, ends Mon 16 Nov")}),
        ("setup", "hidden-line", 13.4, 16.8, "Only what you pick", "Instagram and TikTok leave Home. Everything else opens as usual.", {"ticks": ["Instagram hidden", "TikTok hidden"]}),
    ],
    "oneline": [
        ("setup", "plan", 30.9, 36.7, "Fill + Extract", "Fill picks real apps. Extract copies your words: “G chord lesson”, “7”.", {"top": 680}),
        ("setup", "door", 38.9, 40.55, "A door, not an app", "YouTube → Search “G chord lesson”", {"punch": True}),
        ("setup", "search", 41.9, 46.6, "Straight to the task", "The search, not the feed.", {"note": "Drawn stand-in for the video app"}),
    ],
    "whynow": [
        ("whynow", "verdict-later", 6.0, 9.4, "Decide: just browsing", "It can wait. Save it for later, or wait 30 seconds.", {}),
        ("whynow", "ring", 10.4, 13.8, "No hard lock", "It still opens after 30 seconds.", {"bar": (10.4, 13.8, 0.0, 0.11, "30-second wait")}),
        ("whynow", "verdict-open", 19.0, 22.0, "Decide + Extract", "Someone’s waiting: Instagram opens at the chat with Ada, for 5 minutes.", {}),
        ("whynow", "verdict-flagged", 29.4, 31.9, "Guard", "An instruction, not a reason. Flagged, calmly.", {"punch": True}),
    ],
    "held": [
        ("held", "shade", 3.0, 5.85, "Held, not deleted", "A hidden app’s notification waits quietly on the phone.", {}),
        ("held", "held-row", 8.6, 9.95, "Missed notifications", "Held until the app comes back.", {}),
        ("rest", "rest-card", 2.9, 6.5, "Rest day", "One a week. Hidden apps open without asking.", {}),
        ("rest", "given-row", 8.4, 10.4, "Given back", "What was held goes back to the phone.", {}),
    ],
    "proof": [
        ("proof", "question", 4.1, 6.9, "One question", "What changed, finished, or became clear?", {}),
        ("proof", "proof-days", 9.3, 16.7, "Prooflight", "Decide, Extract and Verify back the note.", {"count": (7, "proof days in a row")}),
        ("proof", "sky", 18.4, 21.9, "Home", "Tasks done raise the evening’s water.", {"bar": (18.6, 20.4, 0.0, 0.5, "1 of 2 tasks done")}),
    ],
    "later": [
        ("later", "shelf", 6.1, 10.8, "Rerank", "What fits tonight’s plan comes first. The rest waits.", {}),
    ],
    "focusend": [
        ("focusend", "summary", 1.0, 6.7, "Two weeks, added up", "Then one tap back to the old home screen.", {"stats": "focusend"}),
    ],
}

TYPED = {  # the check-in sentence, typed in time with the app (clip seconds)
    "scene": "oneline", "clip": "setup", "start": 24.75, "cps": 21,
    "text": "Revise chapter 4 in Keep Notes and watch the G chord lesson on YouTube until 7",
    "marks": [("G chord lesson", C["blue"]), ("7", C["rose"])], "marked": 30.2,
}


def load():
    out = pathlib.Path(sys.argv[1])
    scenes = json.loads((MOTION / "scenes.json").read_text())["scenes"]
    t = 0.0
    for s in scenes:
        s["start"] = round(t, 3)
        t += s["duration"]
    total = round(t, 3)
    clips = {}
    for path in (out / "clips").glob("*.json"):
        clips[path.stem] = json.loads(path.read_text())
    timing_path = out / "voice" / "voice-timing.json"
    voice = json.loads(timing_path.read_text())["lines"] if timing_path.exists() else []
    return out, scenes, total, clips, {v["id"]: v for v in voice}


class Film:
    def __init__(self):
        self.css, self.html, self.js, self.sfx = [], [], [], []
        self.n = 0

    def id(self, prefix):
        self.n += 1
        return f"{prefix}{self.n}"

    def el(self, markup):
        self.html.append(markup)

    def tw(self, code):
        self.js.append(code)

    def sound(self, kind, at, **extra):
        self.sfx.append({"kind": kind, "at": round(at, 3), **extra})


def esc(text):
    return html.escape(text, quote=True)


def clip_at(scene, clip_name, clip_t):
    """Film time of a clip second inside a scene."""
    if scene.get("then") and clip_name == scene["then"]["clip"]:
        return scene["start"] + scene["then"]["at"] + clip_t
    return scene["start"] + clip_t - scene.get("from", 0)


def stage_rect(mark):
    return (PX + mark["x"] * K, PY + mark["y"] * K, mark["w"] * K, mark["h"] * K)


def build():
    out, scenes, total, clips, voice = load()
    by_id = {s["id"]: s for s in scenes}
    f = Film()

    # ---- the stage: paper, three slow blobs --------------------------------
    f.el('<div id="bg"></div>')
    for i, (color, x, y, size) in enumerate([
        (C["marigold"], -200, -260, 1100), (C["rose"], 1100, 520, 1200), (C["blue"], 400, 700, 900)]):
        f.el(f'<div class="blob" id="blob{i}" style="left:{x}px;top:{y}px;width:{size}px;height:{size}px;background:radial-gradient(closest-side,{color} 0%,{color}99 45%,{color}00 100%)"></div>')
        dx, dy = [(160, 90), (-140, -70), (120, -110)][i]
        f.tw(f'tl.fromTo("#blob{i}",{{x:0,y:0}},{{x:{dx},y:{dy},duration:{total},ease:"none"}},0);')

    # ---- the phone: frame, screen with filmed clips, touches ----------------
    phone_from = by_id["setup"]["start"] - 0.9
    phone_to = by_id["arch"]["start"]
    sw, sh = PHONE_W * K, PHONE_H * K
    f.el('<div id="cam">')
    f.el(f'<div id="phone" style="left:{PX - BEZEL}px;top:{PY - BEZEL}px;width:{sw + 2 * BEZEL}px;height:{sh + 2 * BEZEL}px">')
    f.el(f'<div id="screen" style="left:{BEZEL}px;top:{BEZEL}px;width:{sw}px;height:{sh}px">')
    segments = []
    for s in scenes:
        if "clip" not in s:
            continue
        if s.get("then"):
            segments.append((s["clip"], s["start"], s["then"]["at"], s.get("from", 0)))
            segments.append((s["then"]["clip"], s["start"] + s["then"]["at"], s["duration"] - s["then"]["at"], 0))
        elif segments and segments[-1][0] == s["clip"] and abs(segments[-1][1] + segments[-1][2] - s["start"]) < 1e-6:
            c, st, du, fr = segments[-1]
            segments[-1] = (c, st, du + s["duration"], fr)
        else:
            segments.append((s["clip"], s["start"], s["duration"], s.get("from", 0)))
    # The first shot's opening frame shows while the phone rises.
    f.el(f'<img id="firstframe" class="clip shot" data-start="{phone_from:.3f}" data-duration="{segments[0][1] - phone_from:.3f}" src="assets/clips/{segments[0][0]}-first.png">')
    for name, start, dur, media in segments:
        vid = f.id("v")
        f.el(f'<video id="{vid}" class="clip shot" data-start="{start:.3f}" data-duration="{dur:.3f}" '
             f'data-media-start="{media:.3f}" src="assets/clips/{name}.mp4" muted playsinline></video>')
    # A held last frame of the final shot for the reframe into the pipeline card.
    last_name, last_start, last_dur, last_media = segments[-1]
    f.el(f'<img id="lastframe" class="clip shot" data-start="{last_start + last_dur:.3f}" data-duration="{total - last_start - last_dur:.3f}" src="assets/clips/{last_name}-last.png">')
    # Cut softeners between shots.
    for _, start, _, _ in segments[1:]:
        cut = f.id("cut")
        f.el(f'<div id="{cut}" class="clip layer" data-start="{start - 0.2:.3f}" data-duration="0.5"><div class="dipfill"></div></div>')
        f.tw(f'tl.fromTo("#{cut} .dipfill",{{opacity:0}},{{opacity:0.9,duration:0.2,ease:"power2.in"}},{start - 0.2:.3f})'
             f'.to("#{cut} .dipfill",{{opacity:0,duration:0.28,ease:"power2.out"}},{start:.3f});')
    f.el('</div>')  # screen
    # Touches: a soft dot where the finger lands, like Android's "show taps".
    for name, start, dur, media in segments:
        for tap in clips[name]["taps"]:
            at = start + tap["t"] - media
            if not (start <= at <= start + dur):
                continue
            dot = f.id("tap")
            x, y = BEZEL + tap["x"] * K, BEZEL + tap["y"] * K
            f.el(f'<div id="{dot}" class="clip layer" data-start="{at - 0.45:.3f}" data-duration="1.0"><div class="touch" style="left:{x - 22:.1f}px;top:{y - 22:.1f}px"><div class="dot"></div></div></div>')
            f.tw(f'tl.fromTo("#{dot} .dot",{{opacity:0,scale:1.25}},{{opacity:1,scale:1,duration:0.3,ease:"power3.out"}},{at - 0.42:.3f})'
                 f'.to("#{dot} .dot",{{scale:0.78,duration:0.08,ease:"power2.in"}},{at - 0.06:.3f})'
                 f'.to("#{dot} .dot",{{scale:1,duration:0.18,ease:"power2.out"}},{at + 0.02:.3f})'
                 f'.to("#{dot} .dot",{{opacity:0,duration:0.25,ease:"power2.in"}},{at + 0.25:.3f});')
            f.sound("tap", at)
    f.el('</div>')  # phone
    f.el('</div>')  # cam
    # Phone in at setup, Reframe into the pipeline card at the end.
    f.tw(f'tl.fromTo("#phone",{{opacity:0,y:120,scale:0.94}},{{opacity:1,y:0,scale:1,duration:0.9,ease:"power3.out"}},{phone_from:.3f});')

    # ---- per-scene titles and zooms -------------------------------------------
    for s in scenes:
        if s["id"] in TITLES:
            title_block(f, s)
        for zoom in ZOOMS.get(s["id"], []):
            zoom_block(f, s, clips, *zoom)

    typewriter(f, by_id[TYPED["scene"]])
    hook(f, by_id["hook"], voice)
    arch(f, by_id["arch"], voice, phone_to)
    end_card(f, by_id["end"])

    # ---- write -----------------------------------------------------------------
    page = PAGE.format(
        total=total, css=CSS.format(**C, pw=sw, ph=sh), body="\n".join(f.html), js="\n".join(f.js))
    (MOTION / "index.html").write_text(page)
    (out / "sfx.json").write_text(json.dumps({"seconds": total, "events": sorted(f.sfx, key=lambda e: e["at"])}, indent=1) + "\n")
    link_assets(out, last_name, segments[0][0])
    print(f"wrote {MOTION / 'index.html'} ({total:.1f} s, {len(f.sfx)} sounds)")


def title_block(f, s):
    label, lines = TITLES[s["id"]]
    t0 = s["start"]
    box = f"title-{s['id']}"
    words = []
    for li, line in enumerate(lines):
        words.append("<div class=\"tline\">" + " ".join(
            f'<span class="w" id="{box}-{li}-{wi}">{esc(w)}</span>' for wi, w in enumerate(line.split())) + "</div>")
    f.el(f'<div id="{box}" class="clip layer" data-start="{t0:.3f}" data-duration="{s["duration"]:.3f}"><div class="title">'
         f'<div class="label" id="{box}-label">{esc(label)}</div>{"".join(words)}</div></div>')
    f.tw(f'tl.fromTo("#{box}-label",{{opacity:0,x:-30}},{{opacity:1,x:0,duration:0.5,ease:"power3.out"}},{t0 + 0.1:.3f});')
    k = 0
    for li, line in enumerate(lines):
        for wi, _ in enumerate(line.split()):
            f.tw(f'tl.fromTo("#{box}-{li}-{wi}",{{opacity:0,y:46,scaleY:0.6}},{{opacity:1,y:0,scaleY:1,duration:0.38,ease:"power4.out"}},{t0 + 0.2 + k * 0.09:.3f});')
            k += 1
    f.tw(f'tl.to("#{box}",{{opacity:0,duration:0.25,ease:"power2.in"}},{t0 + s["duration"] - 0.3:.3f});')


def zoom_block(f, s, clips, clip_name, mark_id, t_in, t_out, label, line, extra):
    marks = [m for m in clips[clip_name]["marks"] if m["id"] == mark_id]
    if not marks:
        raise SystemExit(f"shot {clip_name} has no mark {mark_id}")
    x, y, w, h = stage_rect(marks[0])
    scale = min(FOCUS_BOX[0] / w, FOCUS_BOX[1] / h, 2.55)
    cx, cy = x + w / 2, y + h / 2
    tx, ty = FOCUS[0] - scale * cx, FOCUS[1] - scale * cy
    a, b = clip_at(s, clip_name, t_in), clip_at(s, clip_name, t_out)
    span_in = 0.38 if extra.get("punch") else 0.75
    ease_in = "power3.out" if extra.get("punch") else "power2.inOut"
    f.tw(f'tl.to("#cam",{{x:{tx:.1f},y:{ty:.1f},scale:{scale:.3f},duration:{span_in},ease:"{ease_in}"}},{a:.3f})'
         f'.to("#cam",{{x:0,y:0,scale:1,duration:0.65,ease:"power2.inOut"}},{b:.3f});')
    if s["id"] in TITLES:  # the title steps back while the camera is in close
        f.tw(f'tl.to("#title-{s["id"]}",{{opacity:0,duration:0.3}},{a:.3f}).to("#title-{s["id"]}",{{opacity:1,duration:0.4}},{b + 0.3:.3f});')
    # The caption card: label, one line, and its move.
    card = f.id("cap")
    body = [f'<div class="label">{esc(label)}</div>']
    if "count" in extra:
        value, unit = extra["count"]
        body.append(f'<div class="count"><span class="num" id="{card}-n">0</span><span class="unit">{esc(unit)}</span></div>')
    body.append(f'<div class="line">{esc(line)}</div>')
    if "ticks" in extra:
        body.append('<div class="ticks">' + "".join(
            f'<div class="tick" id="{card}-t{i}"><span class="box">✓</span>{esc(t)}</div>' for i, t in enumerate(extra["ticks"])) + "</div>")
    if "bar" in extra:
        body.append(f'<div class="bar"><div class="fill" id="{card}-bar"></div></div><div class="barlabel">{esc(extra["bar"][4])}</div>')
    if "stats" in extra:
        body.append('<div class="stats">' + "".join(
            f'<div class="stat"><span class="num" id="{card}-s{i}">0</span><span>{esc(u)}</span></div>'
            for i, (_, u) in enumerate(FOCUS_STATS)) + "</div>")
    if "note" in extra:
        body.append(f'<div class="note">{esc(extra["note"])}</div>')
    top = extra.get("top", 520)
    f.el(f'<div id="{card}-clip" class="clip layer" data-start="{a:.3f}" data-duration="{b - a + 0.45:.3f}"><div id="{card}" class="glass cap" style="top:{top}px">{"".join(body)}</div></div>')
    f.tw(f'tl.fromTo("#{card}",{{opacity:0,y:30,scale:0.96}},{{opacity:1,y:0,scale:1,duration:0.6,ease:"power3.out"}},{a + 0.15:.3f})'
         f'.to("#{card}",{{opacity:0,y:-10,duration:0.3,ease:"power2.in"}},{b + 0.1:.3f});')
    if "count" in extra:
        value = extra["count"][0]
        count_up(f, f"#{card}-n", value, a + 0.45, 1.0)
    for i, _ in enumerate(extra.get("ticks", [])):
        at = a + 0.7 + i * 0.55
        f.tw(f'tl.fromTo("#{card}-t{i}",{{opacity:0,x:-16}},{{opacity:1,x:0,duration:0.35,ease:"power3.out"}},{at:.3f})'
             f'.fromTo("#{card}-t{i} .box",{{scale:0.4}},{{scale:1,duration:0.3,ease:"back.out(2)"}},{at:.3f});')
        f.sound("tick", at + 0.05)
    if "bar" in extra:
        b0, b1, v0, v1, _ = extra["bar"]
        s0, s1 = clip_at(s, clip_name, b0) + 0.3, clip_at(s, clip_name, b1)
        f.tw(f'tl.fromTo("#{card}-bar",{{scaleX:{max(v0, 0.001)}}},{{scaleX:{v1},duration:{s1 - s0:.2f},ease:"power2.out"}},{s0:.3f});')
    if "stats" in extra:
        for i, (value, _) in enumerate(FOCUS_STATS):
            count_up(f, f"#{card}-s{i}", value, a + 0.55 + i * 0.35, 0.9)


FOCUS_STATS = [(12, "days with proof"), (18, "tasks proved"), (35, "hidden apps left closed")]


def count_up(f, selector, value, at, dur):
    obj = f.id("cnt")
    f.tw(f'const {obj}={{v:0}};tl.fromTo({obj},{{v:0}},{{v:{value},duration:{dur},ease:"power2.out",'
         f'onUpdate:()=>{{document.querySelector("{selector}").textContent=Math.round({obj}.v)}}}},{at:.3f});')
    f.sound("counter", at, duration=dur)


def typewriter(f, s):
    t0 = clip_at(s, TYPED["clip"], TYPED["start"])
    text = TYPED["text"]
    box = "typed"
    spans = "".join(f'<span class="ch" id="{box}-{i}">{esc(ch)}</span>' for i, ch in enumerate(text))
    marked = clip_at(s, TYPED["clip"], TYPED["marked"])
    f.el(f'<div id="{box}-clip" class="clip layer" data-start="{t0 - 0.4:.3f}" data-duration="{s["start"] + 14.3 - t0 + 0.4:.3f}"><div id="{box}" class="glass typed">'
         f'<div class="label">Tobi types</div><div class="you">{spans}</div></div></div>')
    f.tw(f'tl.fromTo("#{box}",{{opacity:0,y:24}},{{opacity:1,y:0,duration:0.45,ease:"power3.out"}},{t0 - 0.4:.3f});')
    for i in range(len(text)):
        f.tw(f'tl.fromTo("#{box}-{i}",{{opacity:0}},{{opacity:1,duration:0.01}},{t0 + i / TYPED["cps"]:.3f});')
    for word, color in TYPED["marks"]:
        i = text.rfind(word) if word == "7" else text.find(word)
        for j in range(i, i + len(word)):
            f.tw(f'tl.to("#{box}-{j}",{{backgroundColor:"{color}",duration:0.35,ease:"power2.out"}},{marked + (j - i) * 0.02:.3f});')
    f.tw(f'tl.to("#{box}",{{opacity:0,y:-10,duration:0.3}},{s["start"] + 14.0:.3f});')


def voice_window(voice, line_id, frac=0.0, fallback=0.0):
    v = voice.get(line_id)
    if not v:
        return fallback
    return v["start"] + (v["end"] - v["start"]) * frac


def hook(f, s, voice):
    t0 = s["start"]
    f.el(f'<div id="hook" class="clip layer" data-start="{t0}" data-duration="{s["duration"] + 0.2}">')
    # Kinetic words.
    beats = [
        ("k1", ["Two weeks", "before exams."], 0.35, 3.9, [1]),
        ("k2", ["One quick look."], 4.55, 6.0, []),
        ("k3", ["An hour,", "gone."], 6.05, 7.45, [1]),
    ]
    for kid, lines, a, b, accent in beats:
        f.el(f'<div class="kinetic" id="{kid}">' + "".join(
            f'<div class="kl{" accent" if i in accent else ""}" id="{kid}-{i}">{esc(l)}</div>' for i, l in enumerate(lines)) + "</div>")
        for i, _ in enumerate(lines):
            f.tw(f'tl.fromTo("#{kid}-{i}",{{opacity:0,x:-90,scaleY:0.4}},{{opacity:1,x:0,scaleY:1,duration:0.36,ease:"power4.out"}},{t0 + a + i * 0.32:.3f});')
        f.tw(f'tl.to("#{kid}",{{opacity:0,x:60,duration:0.22,ease:"power3.in"}},{t0 + b:.3f});')
    # The phone that pulls: an outline and notification chips piling up.
    f.el('<div id="pull"><div id="pullphone"></div></div>')
    chips = [("12 new videos", "Y", 1.1, 1240, 210), ("Someone mentioned you", "I", 1.6, 1330, 330),
             ("Trending now", "T", 2.1, 1170, 450), ("3 new reels", "I", 2.6, 1360, 570),
             ("Your friends are watching", "T", 3.1, 1200, 690), ("Live now", "Y", 3.5, 1390, 810)]
    for i, (text, letter, at, x, y) in enumerate(chips):
        f.el(f'<div class="chip glass" id="chip{i}" style="left:{x}px;top:{y}px"><span class="tile">{letter}</span>{esc(text)}</div>')
        f.tw(f'tl.fromTo("#chip{i}",{{opacity:0,scale:0.5}},{{opacity:1,scale:1,duration:0.45,ease:"back.out(1.7)"}},{t0 + at:.3f});')
        f.sound("pop", t0 + at + 0.03)
        f.tw(f'tl.to("#chip{i}",{{y:"+=40",opacity:0,duration:0.35,ease:"power2.in"}},{t0 + 7.3 + i * 0.04:.3f});')
    f.tw(f'tl.fromTo("#pull",{{opacity:0,y:60}},{{opacity:1,y:0,duration:0.7,ease:"power3.out"}},{t0 + 0.7:.3f})'
         f'.to("#pull",{{opacity:0,duration:0.35}},{t0 + 7.4:.3f});')
    f.el('</div>')  # hook: Peek and the name sit outside it, so the Peek video is timed on its own.
    # Peek and the name.
    f.el(f'<div id="brand"><div class="disc"><video id="peek1" class="clip" data-start="{t0 + 7.6}" data-duration="{s["duration"] - 7.6 + 0.2:.2f}" src="assets/clips/peek.mp4" muted playsinline></video></div>'
         '<div class="wordmark">Curre</div><div class="tagline">A home screen for a focus period.</div>'
         '<div class="pills"><span class="pill" id="pill0">Exams</span><span class="pill" id="pill1">A deadline</span><span class="pill" id="pill2">A habit to break</span></div></div>')
    f.tw(f'tl.fromTo("#brand .disc",{{opacity:0,scale:0.4}},{{opacity:1,scale:1,duration:0.6,ease:"back.out(1.6)"}},{t0 + 7.6:.3f})'
         f'.fromTo("#brand .wordmark",{{opacity:0,y:40}},{{opacity:1,y:0,duration:0.6,ease:"power3.out"}},{t0 + 7.9:.3f})'
         f'.fromTo("#brand .tagline",{{opacity:0,y:30}},{{opacity:1,y:0,duration:0.6,ease:"power3.out"}},{t0 + 8.3:.3f});')
    for i in range(3):
        f.tw(f'tl.fromTo("#pill{i}",{{opacity:0,scale:0.6}},{{opacity:1,scale:1,duration:0.4,ease:"back.out(2)"}},{t0 + 9.4 + i * 0.3:.3f});')
    f.tw(f'tl.fromTo("#brand",{{opacity:1,x:0}},{{opacity:0,x:-80,duration:0.5,ease:"power3.in"}},{t0 + s["duration"] - 0.55:.3f});')


def arch(f, s, voice, phone_to):
    t0 = s["start"]
    # Reframe: the phone shrinks into the card on the left.
    f.tw(f'tl.to("#phone",{{x:-940,y:20,scale:0.42,duration:0.9,ease:"power3.inOut"}},{t0 - 0.2:.3f})'
         f'.to("#phone",{{opacity:0,duration:0.4}},{t0 + s["duration"] - 0.5:.3f});')
    a2 = lambda frac, fb: voice_window(voice, "a2", frac, t0 + fb)  # noqa: E731
    rows = [
        ("/v1/plan", "Check-in", ["Fill", "Extract"], a2(0.0, 4.5)),
        ("/v1/unlock", "Why now?", ["Protect", "Guard", "Decide", "Extract"], a2(0.27, 6.5)),
        ("/v1/proof", "Proof", ["Protect", "Guard", "Decide", "Extract", "Verify"], a2(0.63, 9.4)),
        ("/v1/later", "Later shelf", ["Rerank"], a2(0.82, 10.8)),
    ]
    f.el(f'<div id="arch" class="clip layer" data-start="{t0}" data-duration="{s["duration"]}">')
    f.el('<div class="archhead"><div class="label">Under the hood</div><div class="atitle">One Clocked pipeline call per screen.</div></div>')
    f.el('<div class="glass phonecard"><div class="label">On the phone</div><div class="pline">Plans, history, proof days and saved items stay here.</div></div>')
    f.el('<div class="glass server" id="server"><div class="label">Curre server</div><div class="sline">Turns words into decisions, one Clocked pipeline call per route. Stores nothing.</div></div>')
    f.el('<div class="wire" id="wire1"></div>')
    for i, (route, screen, steps, at) in enumerate(rows):
        chips = '<span class="arrow">→</span>'.join(f'<span class="step">{esc(x)}</span>' for x in steps)
        f.el(f'<div class="glass route" id="route{i}"><span class="tickbox" id="route{i}-tick">✓</span><div class="rmeta"><div class="rname">{esc(screen)}</div><div class="rpath">{esc(route)}</div></div><div class="steps">{chips}</div></div>')
        f.tw(f'tl.fromTo("#route{i}",{{opacity:0,x:60}},{{opacity:1,x:0,duration:0.55,ease:"power3.out"}},{at:.3f})'
             f'.fromTo("#route{i}-tick",{{scale:0,opacity:0}},{{scale:1,opacity:1,duration:0.35,ease:"back.out(2)"}},{at + 0.35:.3f});')
        f.sound("tick", at + 0.4)
    a3 = voice_window(voice, "a3", 0.0, t0 + 12.9)
    f.el('<div class="privacy" id="privacy"><span class="pv" id="pv0"><b>✓</b> Server stores nothing</span><span class="pv" id="pv1"><b>✓</b> History stays on the phone</span><span class="pv" id="pv2"><b>✓</b> Protect keeps names out of the history copy</span></div>')
    for i in range(3):
        f.tw(f'tl.fromTo("#pv{i}",{{opacity:0,y:16}},{{opacity:1,y:0,duration:0.4,ease:"power3.out"}},{a3 + i * 0.45:.3f});')
        f.sound("tick", a3 + i * 0.45 + 0.1)
    f.tw(f'tl.fromTo(".archhead",{{opacity:0,y:30}},{{opacity:1,y:0,duration:0.6,ease:"power3.out"}},{t0 + 0.3:.3f})'
         f'.fromTo(".phonecard",{{opacity:0,y:20}},{{opacity:1,y:0,duration:0.5,ease:"power3.out"}},{t0 + 0.9:.3f})'
         f'.fromTo("#server",{{opacity:0,scale:0.9}},{{opacity:1,scale:1,duration:0.5,ease:"power3.out"}},{t0 + 1.8:.3f})'
         f'.fromTo("#wire1",{{scaleX:0}},{{scaleX:1,duration:0.5,ease:"power2.out"}},{t0 + 1.5:.3f})'
         f'.to("#arch",{{opacity:0,duration:0.4}},{t0 + s["duration"] - 0.45:.3f});')
    f.el('</div>')


def end_card(f, s):
    t0 = s["start"]
    f.el(f'<div id="end">'
         f'<div class="disc"><video id="peek2" class="clip" data-start="{t0}" data-duration="{s["duration"]}" src="assets/clips/peek.mp4" muted playsinline></video></div>'
         '<div class="wordmark">Curre</div><div class="tagline">Straight to what you came for.</div>'
         '<div class="cta">github.com/MI-TECHDLIN/curre</div><div class="built">Built with Clocked</div></div>')
    f.tw(f'tl.fromTo("#end .disc",{{opacity:0,scale:0.5}},{{opacity:1,scale:1,duration:0.6,ease:"back.out(1.6)"}},{t0 + 0.1:.3f})'
         f'.fromTo("#end .wordmark",{{opacity:0,y:40}},{{opacity:1,y:0,duration:0.6,ease:"power3.out"}},{t0 + 0.6:.3f})'
         f'.fromTo("#end .tagline",{{opacity:0,y:30}},{{opacity:1,y:0,duration:0.6,ease:"power3.out"}},{t0 + 1.0:.3f})'
         f'.fromTo("#end .cta",{{opacity:0,scale:0.8}},{{opacity:1,scale:1,duration:0.5,ease:"back.out(1.8)"}},{t0 + 1.8:.3f})'
         f'.fromTo("#end .built",{{opacity:0}},{{opacity:1,duration:0.5}},{t0 + 2.3:.3f});')
    f.sound("chime", t0 + 1.85)


def link_assets(out, last_name, first_name):
    assets = MOTION / "assets"
    (assets / "fonts").mkdir(parents=True, exist_ok=True)
    for name in ["Geologica[CRSV,SHRP,slnt,wght].ttf", "Newsreader-Italic[opsz,wght].ttf", "AtkinsonHyperlegibleMono[wght].ttf"]:
        shutil.copyfile(REPO / "assets" / "fonts" / name, assets / "fonts" / (name.split("[")[0].lower() + ".ttf"))
    clips_dir = assets / "clips"
    if clips_dir.is_symlink() or clips_dir.is_file():
        clips_dir.unlink()
    elif clips_dir.is_dir():
        shutil.rmtree(clips_dir)
    os.symlink(out / "clips", clips_dir)
    last = out / "clips" / f"{last_name}-last.png"
    os.system(f'ffmpeg -v error -y -sseof -0.1 -i "{out}/clips/{last_name}.mp4" -frames:v 1 -update 1 "{last}"')
    os.system(f'ffmpeg -v error -y -i "{out}/clips/{first_name}.mp4" -frames:v 1 "{out}/clips/{first_name}-first.png"')


PAGE = """<!doctype html>
<!-- Generated by demo/tool/build_motion.py; edit that file, not this one. -->
<html><head><meta charset="utf-8">
<script src="https://cdn.jsdelivr.net/npm/gsap@3.12.5/dist/gsap.min.js"></script>
<style>{css}</style></head>
<body><div id="root" data-composition-id="main" data-start="0" data-duration="{total}" data-width="1920" data-height="1080">
{body}
</div>
<script>
const tl = gsap.timeline({{paused: true}});
{js}
window.__timelines = window.__timelines || {{}};
window.__timelines["main"] = tl;
</script></body></html>
"""

CSS = """
@font-face {{ font-family: 'Geologica'; src: url('assets/fonts/geologica.ttf'); font-weight: 100 900; }}
@font-face {{ font-family: 'Newsreader'; src: url('assets/fonts/newsreader-italic.ttf'); font-style: italic; font-weight: 200 800; }}
@font-face {{ font-family: 'AtkinsonHyperlegibleMono'; src: url('assets/fonts/atkinsonhyperlegiblemono.ttf'); font-weight: 200 800; }}
* {{ box-sizing: border-box; }}
body {{ margin: 0; }}
#root {{ position: relative; width: 1920px; height: 1080px; overflow: hidden; font-family: 'Geologica', sans-serif; color: {ink}; }}
#bg {{ position: absolute; inset: 0; background: {paper}; }}
.blob {{ position: absolute; opacity: 0.55; }}
#cam {{ position: absolute; left: 0; top: 0; width: 1920px; height: 1080px; transform-origin: 0 0; }}
#phone {{ position: absolute; border-radius: 58px; background: {ink}; box-shadow: 0 40px 90px rgba(30,26,22,0.28), 0 0 0 1.5px rgba(255,255,255,0.4) inset; }}
#screen {{ position: absolute; border-radius: 46px; overflow: hidden; background: {paper}; }}
#screen .shot {{ position: absolute; left: 0; top: 0; width: {pw}px; height: {ph}px; object-fit: cover; }}
.layer {{ position: absolute; inset: 0; pointer-events: none; }}
.layer .dipfill {{ position: absolute; inset: 0; background: {paper}; opacity: 0; }}
.touch {{ position: absolute; width: 44px; height: 44px; }}
.touch .dot {{ width: 44px; height: 44px; border-radius: 50%; background: rgba(30,26,22,0.30); border: 2.5px solid rgba(255,255,255,0.95); box-shadow: 0 4px 14px rgba(30,26,22,0.25); opacity: 0; }}
.glass {{ background: rgba(255,253,249,0.9); border: 1.5px solid rgba(255,255,255,0.95); border-radius: 32px; box-shadow: 0 24px 60px rgba(30,26,22,0.12); }}
.label {{ font-weight: 600; font-size: 22px; letter-spacing: 3px; text-transform: uppercase; color: {emberText}; }}
.title {{ position: absolute; left: 150px; top: 150px; width: 760px; }}
.title .label {{ margin-bottom: 18px; }}
.tline {{ font-weight: 800; font-size: 76px; line-height: 1.04; letter-spacing: -1.5px; }}
.tline .w {{ display: inline-block; transform-origin: 50% 100%; }}
.cap {{ position: absolute; left: 150px; top: 520px; width: 640px; padding: 30px 36px; }}
.cap .line {{ font-weight: 500; font-size: 34px; line-height: 1.25; margin-top: 12px; }}
.cap .count {{ display: flex; align-items: baseline; gap: 16px; margin-top: 8px; }}
.cap .count .num {{ font-weight: 800; font-size: 120px; line-height: 1; color: {ember}; }}
.cap .count .unit {{ font-weight: 600; font-size: 30px; color: {ink2}; }}
.cap .ticks {{ margin-top: 18px; display: flex; gap: 14px; }}
.cap .tick {{ display: flex; align-items: center; gap: 10px; font-weight: 600; font-size: 26px; background: {sunk}; border-radius: 999px; padding: 8px 18px 8px 8px; }}
.box {{ display: inline-flex; width: 34px; height: 34px; border-radius: 50%; background: {ink}; color: {raised}; align-items: center; justify-content: center; font-size: 20px; font-weight: 800; }}
.cap .bar {{ margin-top: 20px; height: 18px; border-radius: 9px; background: {sunk}; overflow: hidden; }}
.cap .bar .fill {{ height: 100%; background: {ember}; transform-origin: 0 50%; transform: scaleX(0); border-radius: 9px; }}
.cap .barlabel {{ margin-top: 8px; font-family: 'AtkinsonHyperlegibleMono', monospace; font-size: 22px; color: {ink3}; }}
.cap .stats {{ display: flex; gap: 14px; margin-top: 18px; }}
.cap .stat {{ flex: 1; background: {sunk}; border-radius: 22px; padding: 14px 16px; font-size: 20px; font-weight: 600; color: {ink2}; line-height: 1.2; }}
.cap .stat .num {{ display: block; font-size: 58px; font-weight: 800; color: {ink}; }}
.cap .note {{ margin-top: 14px; font-family: 'AtkinsonHyperlegibleMono', monospace; font-size: 18px; color: {ink3}; }}
.typed {{ position: absolute; left: 150px; top: 290px; width: 680px; padding: 28px 34px; }}
.typed .you {{ font-family: 'Newsreader', serif; font-style: italic; font-size: 44px; line-height: 1.3; margin-top: 10px; }}
.typed .ch {{ border-radius: 6px; }}
.typed .caret {{ color: {ember}; font-style: normal; }}
#hook {{ position: absolute; inset: 0; }}
.kinetic {{ position: absolute; left: 150px; top: 330px; width: 1000px; }}
.kl {{ font-weight: 900; font-size: 150px; line-height: 0.98; letter-spacing: -4px; text-transform: uppercase; transform-origin: 0 100%; }}
.kl.accent {{ color: {ember}; }}
#pull {{ position: absolute; left: 0; top: 0; width: 1920px; height: 1080px; }}
#pullphone {{ position: absolute; left: 1215px; top: 150px; width: 330px; height: 760px; border-radius: 56px; border: 10px solid {ink}; background: rgba(255,253,249,0.5); }}
.chip {{ position: absolute; display: flex; align-items: center; gap: 14px; padding: 14px 24px 14px 14px; border-radius: 26px; font-weight: 600; font-size: 28px; white-space: nowrap; }}
.chip .tile {{ display: inline-flex; width: 46px; height: 46px; border-radius: 14px; background: {blue}; align-items: center; justify-content: center; font-weight: 800; font-size: 24px; }}
#brand {{ position: absolute; left: 150px; top: 230px; }}
#brand .disc, #end .disc {{ width: 260px; height: 260px; border-radius: 50%; overflow: hidden; box-shadow: 0 30px 70px rgba(232,95,46,0.25); }}
.disc video {{ width: 100%; height: 100%; object-fit: cover; }}
.wordmark {{ font-weight: 800; font-size: 170px; letter-spacing: -6px; line-height: 1; margin-top: 24px; }}
.tagline {{ font-weight: 500; font-size: 46px; color: {ink2}; margin-top: 10px; }}
.pills {{ display: flex; gap: 14px; margin-top: 28px; }}
.pill {{ display: inline-block; padding: 12px 26px; border-radius: 999px; background: {marigold}; font-weight: 700; font-size: 30px; }}
#arch {{ position: absolute; inset: 0; }}
.archhead {{ position: absolute; left: 150px; top: 110px; }}
.atitle {{ font-weight: 800; font-size: 64px; letter-spacing: -1.5px; margin-top: 10px; }}
.phonecard {{ position: absolute; left: 150px; top: 770px; width: 420px; padding: 20px 26px; }}
.pline, .sline {{ font-size: 25px; font-weight: 500; line-height: 1.25; margin-top: 6px; color: {ink2}; }}
.server {{ position: absolute; left: 820px; top: 250px; width: 960px; padding: 20px 28px; }}
.wire {{ position: absolute; background: {ink}; border-radius: 3px; }}
#wire1 {{ left: 470px; top: 558px; width: 350px; height: 5px; transform-origin: 0 50%; }}
.route {{ position: absolute; left: 820px; width: 960px; padding: 16px 24px; display: flex; align-items: center; gap: 20px; border-radius: 26px; }}
#route0 {{ top: 392px; }} #route1 {{ top: 488px; }} #route2 {{ top: 584px; }} #route3 {{ top: 680px; }}
.tickbox {{ display: inline-flex; width: 40px; height: 40px; border-radius: 50%; background: {ink}; color: {raised}; align-items: center; justify-content: center; font-weight: 800; font-size: 22px; flex: none; }}
.rmeta {{ width: 180px; flex: none; }}
.rname {{ font-weight: 700; font-size: 27px; }}
.rpath {{ font-family: 'AtkinsonHyperlegibleMono', monospace; font-size: 20px; color: {ink3}; }}
.steps {{ display: flex; align-items: center; gap: 9px; flex-wrap: nowrap; }}
.step {{ padding: 7px 14px; border-radius: 999px; background: {sunk}; font-weight: 600; font-size: 23px; white-space: nowrap; }}
.step:last-child {{ background: {marigold}; }}
.arrow {{ color: {ink3}; font-size: 22px; }}
.privacy {{ position: absolute; left: 820px; top: 800px; width: 960px; display: flex; flex-wrap: wrap; gap: 12px; }}
.pv {{ padding: 10px 20px; border-radius: 999px; background: {green}; font-weight: 600; font-size: 24px; white-space: nowrap; }}
#end {{ position: absolute; inset: 0; display: flex; flex-direction: column; align-items: center; justify-content: center; }}
#end .disc {{ width: 240px; height: 240px; }}
#end .wordmark {{ font-size: 150px; margin-top: 18px; }}
#end .tagline {{ margin-top: 4px; }}
.cta {{ margin-top: 34px; padding: 18px 36px; border-radius: 999px; background: {ink}; color: {raised}; font-weight: 700; font-size: 36px; }}
.built {{ margin-top: 22px; font-family: 'AtkinsonHyperlegibleMono', monospace; font-size: 26px; color: {ink3}; letter-spacing: 1px; }}
"""


if __name__ == "__main__":
    build()
