"""Generate the NM VYBE app icon assets (Android mipmaps, Windows ICO, store PNG).

Usage: python tool/make_icons.py
"""

from __future__ import annotations

import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SIZE = 1024


def font(size: int, bold: bool = True):
    path = r"C:\Windows\Fonts\segoeuib.ttf" if bold else r"C:\Windows\Fonts\segoeui.ttf"
    try:
        return ImageFont.truetype(path, size)
    except OSError:
        return ImageFont.load_default()


def rounded_mask(size: int, radius: int) -> Image.Image:
    mask = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, size - 1, size - 1), radius=radius, fill=255)
    return mask


def gradient(size: int, start: tuple[int, int, int], end: tuple[int, int, int]) -> Image.Image:
    t = np.linspace(0, 1, size, dtype=np.float32)[:, None]
    start_arr = np.array(start, dtype=np.float32)[None, :]
    end_arr = np.array(end, dtype=np.float32)[None, :]
    rows = start_arr * (1 - t) + end_arr * t
    canvas = np.repeat(rows[:, None, :], size, axis=1)
    return Image.fromarray(canvas.astype(np.uint8), "RGB")


def build_icon() -> Image.Image:
    base = gradient(SIZE, (18, 8, 40), (60, 12, 90)).convert("RGBA")

    # Soft glow blobs.
    glow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(glow)
    draw.ellipse((120, 40, 900, 820), fill=(124, 77, 255, 90))
    draw.ellipse((380, 400, 1060, 1000), fill=(255, 64, 129, 80))
    glow = glow.filter(ImageFilter.GaussianBlur(110))
    base = Image.alpha_composite(base, glow)

    # Equalizer bars forming a "V" rhythm in the upper half.
    draw = ImageDraw.Draw(base)
    bar_width = 88
    gap = 36
    heights = [210, 350, 460, 350, 210]
    total = len(heights) * bar_width + (len(heights) - 1) * gap
    start_x = (SIZE - total) // 2
    center_y = 390
    for index, height in enumerate(heights):
        x = start_x + index * (bar_width + gap)
        top = center_y - height // 2
        bottom = center_y + height // 2
        colour = (
            255,
            255,
            255,
            240 if index == 2 else 205,
        )
        draw.rounded_rectangle((x, top, x + bar_width, bottom), radius=44, fill=colour)

    # Monogram + wordmark, deliberately below the waveform so nothing overlaps.
    mark_font = font(168, bold=True)
    mark = "NM"
    bbox = draw.textbbox((0, 0), mark, font=mark_font)
    draw.text(
        ((SIZE - (bbox[2] - bbox[0])) / 2 - bbox[0], 668),
        mark,
        font=mark_font,
        fill=(255, 255, 255, 248),
    )

    vibe_font = font(58, bold=True)
    vibe = "V Y B E"
    bbox = draw.textbbox((0, 0), vibe, font=vibe_font)
    draw.text(
        ((SIZE - (bbox[2] - bbox[0])) / 2 - bbox[0], 858),
        vibe,
        font=vibe_font,
        fill=(255, 255, 255, 205),
    )

    # Subtle top highlight and rounded corners.
    highlight = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    hdraw = ImageDraw.Draw(highlight)
    hdraw.ellipse((-300, -520, SIZE + 300, 360), fill=(255, 255, 255, 26))
    highlight = highlight.filter(ImageFilter.GaussianBlur(60))
    base = Image.alpha_composite(base, highlight)

    base.putalpha(rounded_mask(SIZE, 220))
    return base


def main() -> None:
    icon = build_icon()
    icons_dir = os.path.join(ROOT, "assets", "icons")
    os.makedirs(icons_dir, exist_ok=True)
    icon.save(os.path.join(icons_dir, "nm_vybe_icon.png"), "PNG")

    # Windows ICO (multi-resolution).
    ico_path = os.path.join(ROOT, "windows", "runner", "resources", "app_icon.ico")
    os.makedirs(os.path.dirname(ico_path), exist_ok=True)
    icon.save(ico_path, sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)])

    # Android mipmaps.
    densities = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
    for density, size in densities.items():
        target = os.path.join(
            ROOT, "android", "app", "src", "main", "res", f"mipmap-{density}", "ic_launcher.png"
        )
        if os.path.isdir(os.path.dirname(target)):
            icon.resize((size, size), Image.LANCZOS).save(target, "PNG")

    # Web/PWA placeholder icons that ship with the template.
    for size in (192, 512):
        web_icon = os.path.join(ROOT, "web", "icons", f"Icon-{size}.png")
        if os.path.isdir(os.path.dirname(web_icon)):
            icon.resize((size, size), Image.LANCZOS).save(web_icon, "PNG")

    print("Icon written to assets/icons, windows/runner/resources, android mipmaps and web icons.")


if __name__ == "__main__":
    main()
