"""Builds lib/design/art/fluent_props.dart from Microsoft's Fluent Emoji.

Curre's onboarding scenes use a small set of flat props (a ball of yarn,
a magnet, a door ...) drawn from Fluent Emoji's "Flat" style, which is
MIT-licensed (https://github.com/microsoft/fluentui-emoji). This script
fetches the chosen SVGs at a pinned commit and turns each one into SVG
path data plus a fill colour on its 32-unit grid, so the app draws them as
vectors (CurrePropArt) with Curre's own outline and no image assets.

Run from the repository root:

    python3 tool/build_fluent_props.py

Only <path>, <rect> and <ellipse> (with a rotate transform) appear in the
chosen files; anything else fails loudly rather than drawing wrongly.
"""

from __future__ import annotations

import math
import re
import sys
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET
from pathlib import Path

COMMIT = "1ffb34c752ecf5d402f04cfb4b392c77f57c54bc"
SOURCE = "https://raw.githubusercontent.com/microsoft/fluentui-emoji/{commit}/assets/{folder}/Flat/{slug}_flat.svg"
OUTPUT = Path("lib/design/art/fluent_props.dart")

# Dart enum name -> Fluent Emoji folder name. The file slug is the folder
# name in lower case with spaces as underscores.
PROPS = {
    "alarmClock": "Alarm clock",
    "bell": "Bell",
    "cloud": "Cloud",
    "crescentMoon": "Crescent moon",
    "door": "Door",
    "envelope": "Envelope",
    "guitar": "Guitar",
    "heart": "Red heart",
    "hotDrink": "Hot beverage",
    "hourglass": "Hourglass done",
    "house": "House",
    "magnet": "Magnet",
    "map": "World map",
    "memo": "Memo",
    "musicalNotes": "Musical notes",
    "openBook": "Open book",
    "pin": "Round pushpin",
    "popcorn": "Popcorn",
    "seedling": "Seedling",
    "shield": "Shield",
    "sparkles": "Sparkles",
    "speechBalloon": "Speech balloon",
    "star": "Star",
    "yarn": "Yarn",
    "zzz": "Zzz",
}

SVG_NS = "{http://www.w3.org/2000/svg}"
NAMED_COLOURS = {"white": "#FFFFFF", "black": "#000000"}


def fetch(folder: str) -> str:
    slug = folder.lower().replace(" ", "_")
    url = SOURCE.format(
        commit=COMMIT, folder=urllib.parse.quote(folder), slug=slug
    )
    with urllib.request.urlopen(url, timeout=30) as response:
        return response.read().decode("utf-8")


def num(value: float) -> str:
    text = f"{value:.4f}".rstrip("0").rstrip(".")
    return "0" if text in ("-0", "") else text


def rect_path(el: ET.Element) -> str:
    x = float(el.get("x", "0"))
    y = float(el.get("y", "0"))
    w = float(el.get("width"))
    h = float(el.get("height"))
    rx = float(el.get("rx", el.get("ry", "0")))
    ry = float(el.get("ry", el.get("rx", "0")))
    if rx == 0 and ry == 0:
        return f"M{num(x)} {num(y)}H{num(x + w)}V{num(y + h)}H{num(x)}Z"
    return (
        f"M{num(x + rx)} {num(y)}H{num(x + w - rx)}"
        f"A{num(rx)} {num(ry)} 0 0 1 {num(x + w)} {num(y + ry)}"
        f"V{num(y + h - ry)}"
        f"A{num(rx)} {num(ry)} 0 0 1 {num(x + w - rx)} {num(y + h)}"
        f"H{num(x + rx)}"
        f"A{num(rx)} {num(ry)} 0 0 1 {num(x)} {num(y + h - ry)}"
        f"V{num(y + ry)}"
        f"A{num(rx)} {num(ry)} 0 0 1 {num(x + rx)} {num(y)}Z"
    )


def ellipse_path(el: ET.Element) -> str:
    cx = float(el.get("cx"))
    cy = float(el.get("cy"))
    rx = float(el.get("rx"))
    ry = float(el.get("ry"))
    angle = 0.0
    transform = el.get("transform")
    if transform:
        match = re.fullmatch(
            r"rotate\(([-\d.]+)(?:[ ,]+([-\d.]+)[ ,]+([-\d.]+))?\)", transform.strip()
        )
        if not match:
            raise ValueError(f"unsupported transform {transform!r}")
        angle = float(match.group(1))
        if match.group(2) is not None and (
            float(match.group(2)) != cx or float(match.group(3)) != cy
        ):
            raise ValueError("ellipse rotation must be about its own centre")
    t = math.radians(angle)
    dx, dy = rx * math.cos(t), rx * math.sin(t)
    a = (cx - dx, cy - dy)
    b = (cx + dx, cy + dy)
    arc = f"A{num(rx)} {num(ry)} {num(angle)} 1 0"
    return (
        f"M{num(a[0])} {num(a[1])}{arc} {num(b[0])} {num(b[1])}"
        f"{arc} {num(a[0])} {num(a[1])}Z"
    )


def shapes(svg: str, name: str) -> list[tuple[str, str, bool]]:
    root = ET.fromstring(svg)
    if root.get("viewBox") != "0 0 32 32":
        raise ValueError(f"{name}: unexpected viewBox {root.get('viewBox')}")
    out: list[tuple[str, str, bool]] = []
    for el in root.iter():
        tag = el.tag.replace(SVG_NS, "")
        if tag in ("svg", "g", "defs"):
            if el.get("transform"):
                raise ValueError(f"{name}: transformed <{tag}> is unsupported")
            continue
        if tag in ("clipPath",):
            raise ValueError(f"{name}: clip paths are unsupported")
        fill = el.get("fill")
        if fill is None or fill == "none":
            raise ValueError(f"{name}: <{tag}> without a fill")
        if tag == "path":
            if el.get("transform"):
                raise ValueError(f"{name}: transformed path is unsupported")
            data = re.sub(r"\s+", " ", el.get("d").strip())
        elif tag == "rect":
            data = rect_path(el)
        elif tag == "ellipse":
            data = ellipse_path(el)
        else:
            raise ValueError(f"{name}: unsupported element <{tag}>")
        fill = NAMED_COLOURS.get(fill, fill)
        if not re.fullmatch(r"#[0-9A-Fa-f]{6}", fill):
            raise ValueError(f"{name}: unsupported fill {fill!r}")
        even_odd = el.get("fill-rule") == "evenodd"
        out.append((data, fill[1:].upper(), even_odd))
    return out


def main() -> int:
    lines = [
        "// GENERATED by tool/build_fluent_props.py. Do not edit by hand.",
        "//",
        "// Flat props from Microsoft's Fluent Emoji (\"Flat\" style),",
        f"// https://github.com/microsoft/fluentui-emoji at {COMMIT[:12]},",
        "// MIT License, Copyright (c) Microsoft Corporation. The licence is",
        "// registered on Curre's licences page (registerCurreLicenses).",
        "",
        "part of '../widgets/curre_prop.dart';",
        "",
        "const Map<CurreProp, List<PropShape>> _fluentPropShapes = {",
    ]
    for enum_name, folder in sorted(PROPS.items()):
        svg = fetch(folder)
        lines.append(f"  CurreProp.{enum_name}: [")
        for data, colour, even_odd in shapes(svg, folder):
            rule = ", evenOdd: true" if even_odd else ""
            lines.append(f"    PropShape(")
            lines.append(f"      '{data}',")
            lines.append(f"      0xFF{colour}{rule},")
            lines.append("    ),")
        lines.append("  ],")
    lines.append("};")
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"wrote {OUTPUT} ({len(PROPS)} props)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
