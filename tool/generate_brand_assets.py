"""Render Curre's code-drawn Android bitmap assets.

The adaptive, monochrome and splash masters stay as Android vectors. This
script produces the legacy launcher density fallbacks and the big-picture
notification art from the same Peek/horizon geometry, with no external art.
"""

from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
RES = ROOT / "android" / "app" / "src" / "main" / "res"

WARM = "#FBDCC4"
PAPER = "#F7F2EA"
EMBER = "#E85F2E"
INK = "#1E1A16"


def _scaled(value: float, scale: int) -> int:
    return round(value * scale)


def _peek_icon(size: int) -> Image.Image:
    scale = 8
    canvas = Image.new("RGB", (108 * scale, 108 * scale), WARM)
    draw = ImageDraw.Draw(canvas)

    def line(points: list[tuple[float, float]], color: str, width: float) -> None:
        draw.line(
            [(_scaled(x, scale), _scaled(y, scale)) for x, y in points],
            fill=color,
            width=_scaled(width, scale),
        )
        radius = _scaled(width / 2, scale)
        for x, y in (points[0], points[-1]):
            cx, cy = _scaled(x, scale), _scaled(y, scale)
            draw.ellipse((cx - radius, cy - radius, cx + radius, cy + radius), fill=color)

    line([(54, 40), (54, 25)], EMBER, 8)
    line([(40, 43), (34, 35)], EMBER, 8)
    line([(68, 43), (74, 35)], EMBER, 8)

    draw.ellipse(
        tuple(_scaled(v, scale) for v in (28, 44, 80, 96)),
        fill=EMBER,
    )
    draw.rectangle((0, _scaled(73, scale), 108 * scale, 108 * scale), fill=WARM)
    line([(44, 55), (44, 62)], INK, 8)
    line([(64, 55), (64, 62)], INK, 8)
    line([(47, 67), (50.5, 69.5), (54, 71), (57.5, 69.5), (61, 67)], INK, 3)
    line([(30, 73), (78, 73)], INK, 4)
    return canvas.resize((size, size), Image.Resampling.LANCZOS)


def _notification_art() -> Image.Image:
    scale = 2
    width, height = 1024 * scale, 512 * scale
    canvas = Image.new("RGB", (width, height), WARM)
    draw = ImageDraw.Draw(canvas)
    horizon = round(height * 0.72)
    draw.rectangle((0, horizon, width, height), fill=PAPER)

    sun_x, sun_y, radius = round(width * 0.76), horizon, 150 * scale
    draw.ellipse(
        (sun_x - radius, sun_y - radius, sun_x + radius, sun_y + radius),
        fill=EMBER,
    )
    draw.rectangle((0, horizon, width, height), fill=PAPER)
    draw.line((0, horizon, width, horizon), fill=INK, width=8 * scale)

    ray_width = 22 * scale
    for x1, y1, x2, y2 in (
        (sun_x, sun_y - radius - 42 * scale, sun_x, sun_y - radius - 86 * scale),
        (sun_x - 112 * scale, sun_y - radius + 20 * scale, sun_x - 145 * scale, sun_y - radius - 10 * scale),
        (sun_x + 112 * scale, sun_y - radius + 20 * scale, sun_x + 145 * scale, sun_y - radius - 10 * scale),
    ):
        draw.line((x1, y1, x2, y2), fill=EMBER, width=ray_width)
        r = ray_width // 2
        draw.ellipse((x2 - r, y2 - r, x2 + r, y2 + r), fill=EMBER)

    cloud = "#4A1E0B"
    for offset in (0, 210 * scale):
        x = 90 * scale + offset
        y = 132 * scale + (offset // 5)
        draw.line(
            (x, y, x + 120 * scale, y),
            fill=cloud,
            width=7 * scale,
        )
        draw.ellipse((x - 4 * scale, y - 4 * scale, x + 4 * scale, y + 4 * scale), fill=cloud)
        draw.ellipse((x + 116 * scale, y - 4 * scale, x + 124 * scale, y + 4 * scale), fill=cloud)

    return canvas.resize((1024, 512), Image.Resampling.LANCZOS)


def main() -> None:
    densities = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    for directory, size in densities.items():
        target = RES / directory / "ic_launcher.png"
        target.parent.mkdir(parents=True, exist_ok=True)
        _peek_icon(size).save(target, optimize=True)

    art = RES / "drawable-nodpi" / "curre_notification_art.png"
    art.parent.mkdir(parents=True, exist_ok=True)
    _notification_art().save(art, optimize=True)


if __name__ == "__main__":
    main()
