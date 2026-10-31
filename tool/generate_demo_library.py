"""Generate a small, royalty-free demo library for NM VYBE.

Creates three "albums" of synthesized WAV tracks with LIST/INFO tags and matching
cover art in the user's Music folder, so the app has something to show on first
launch. Everything is generated from sine waves and gradients - no samples, no
copyrighted material.

Usage: python tool/generate_demo_library.py [--out "C:\\Users\\You\\Music\\NM VYBE Demo"]
"""

from __future__ import annotations

import argparse
import math
import os
import struct

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

SAMPLE_RATE = 22050


# --------------------------------------------------------------------------- audio
def note(freq: float, duration: float, amp: float = 0.2,
         harmonics: tuple[float, ...] = (0.0, 0.0), vibrato: float = 0.0,
         attack: float = 0.02, release: float = 0.12) -> np.ndarray:
    """One plucked/padded note as a float32 array."""
    n = int(duration * SAMPLE_RATE)
    t = np.arange(n) / SAMPLE_RATE
    phase = 2 * np.pi * freq * t
    if vibrato > 0:
        phase = phase + vibrato * np.sin(2 * np.pi * 5.2 * t)
    wave = np.sin(phase)
    for index, level in enumerate(harmonics, start=2):
        if level:
            wave = wave + level * np.sin(index * phase)
    envelope = np.ones(n)
    a = max(1, min(n, int(attack * SAMPLE_RATE)))
    r = max(1, min(n - 1, int(release * SAMPLE_RATE)))
    if a + r > n:
        scale = (n - 1) / (a + r)
        a = max(1, int(a * scale))
        r = max(1, min(n - a, int(r * scale)))
    envelope[:a] = np.linspace(0, 1, a)
    envelope[n - r:] = np.minimum(envelope[n - r:], np.linspace(1, 0, r))
    return (amp * wave * envelope).astype(np.float32)


def add(buffer: np.ndarray, sound: np.ndarray, start_seconds: float, gain: float = 1.0) -> None:
    start = int(start_seconds * SAMPLE_RATE)
    end = min(len(buffer), start + len(sound))
    if start >= len(buffer) or end <= start:
        return
    buffer[start:end] += sound[: end - start] * gain


def render_track(seed: int, duration: float, root: float, bpm: float,
                 bright: bool) -> np.ndarray:
    rng = np.random.default_rng(seed)
    total = int(duration * SAMPLE_RATE)
    buffer = np.zeros(total, dtype=np.float32)

    beat = 60.0 / bpm
    bar = beat * 4
    # i - VI - III - VII style progression in semitones
    progressions = [
        (0, -4, -9, -5),
        (0, 3, -5, -7),
        (0, -5, -8, -3),
    ]
    progression = progressions[seed % len(progressions)]

    t = 0.0
    bar_index = 0
    while t < duration:
        semis = progression[bar_index % len(progression)]
        chord_root = root * (2 ** (semis / 12.0))
        # Pad chord (root, minor/major third, fifth, octave)
        third = 3 if bar_index % 2 == 0 else 4
        chord = [
            chord_root,
            chord_root * (2 ** (third / 12.0)),
            chord_root * (2 ** (7 / 12.0)),
            chord_root * 2,
        ]
        for i, freq in enumerate(chord):
            pad = note(freq, bar * 1.05, amp=0.075 if i else 0.09,
                       harmonics=(0.22, 0.08), vibrato=0.004,
                       attack=0.35, release=0.6)
            add(buffer, pad, t, gain=1.0 - i * 0.12)
        # Sub bass on beats 1 and 3
        for beat_offset in (0.0, beat * 2):
            bass = note(chord_root / 2, beat * 1.4, amp=0.22,
                        harmonics=(0.35, 0.0), attack=0.01, release=0.35)
            add(buffer, bass, t + beat_offset)

        # Arpeggio: 8th notes cycling chord tones an octave up
        steps = int(bar / (beat / 2))
        for step in range(steps):
            freq = chord[step % len(chord)] * 2
            if bright:
                freq *= 2 ** (12 / 12.0) if step % 4 == 3 else 1.0
            pluck = note(freq, beat * 0.55, amp=0.055, harmonics=(0.15, 0.0),
                         attack=0.004, release=0.18)
            add(buffer, pluck, t + step * (beat / 2), gain=0.7 + 0.3 * rng.random())

        # Soft off-beat shimmer
        for step in range(2):
            shimmer = note(chord[2] * 4, beat * 0.4, amp=0.02,
                           attack=0.01, release=0.3)
            add(buffer, shimmer, t + beat * 1.0 + step * beat, gain=0.5)

        t += bar
        bar_index += 1

    # Gentle tape-style echo.
    delay = int(beat * 0.75 * SAMPLE_RATE)
    echo = np.zeros_like(buffer)
    echo[delay:] = buffer[:-delay] * 0.22
    buffer = buffer + echo

    # Fade in/out and normalise.
    fade_in = int(1.0 * SAMPLE_RATE)
    fade_out = int(2.5 * SAMPLE_RATE)
    buffer[:fade_in] *= np.linspace(0, 1, fade_in)
    buffer[-fade_out:] *= np.linspace(1, 0, fade_out)
    peak = float(np.max(np.abs(buffer))) or 1.0
    return (buffer / peak * 0.86).astype(np.float32)


def write_wav(path: str, samples: np.ndarray, tags: dict[str, str]) -> None:
    pcm = np.clip(samples, -1.0, 1.0)
    data = (pcm * 32767.0).astype("<i2").tobytes()
    fmt = struct.pack("<HHIIHH", 1, 1, SAMPLE_RATE, SAMPLE_RATE * 2, 2, 16)

    chunks: list[tuple[bytes, bytes]] = [(b"fmt ", fmt), (b"data", data)]

    info = b"INFO"
    for key, value in tags.items():
        raw = value.encode("utf-8") + b"\x00"
        if len(raw) % 2:
            raw += b"\x00"
        info += key.encode("ascii") + struct.pack("<I", len(raw)) + raw
    chunks.append((b"LIST", info))

    body = b"WAVE"
    for chunk_id, payload in chunks:
        body += chunk_id + struct.pack("<I", len(payload)) + payload
        if len(payload) % 2:
            body += b"\x00"

    with open(path, "wb") as handle:
        handle.write(b"RIFF" + struct.pack("<I", len(body)) + body)


# --------------------------------------------------------------------------- art
def make_cover(path: str, palette: tuple[tuple[int, int, int], tuple[int, int, int]],
               title: str, artist: str, motif: int) -> None:
    size = 720
    top = np.array(palette[0], dtype=np.float32)
    bottom = np.array(palette[1], dtype=np.float32)
    ramp = np.linspace(0, 1, size, dtype=np.float32)[:, None, None]
    canvas = top[None, None, :] * (1 - ramp) + bottom[None, None, :] * ramp
    canvas = np.repeat(canvas, size, axis=1)
    image = Image.fromarray(canvas.astype(np.uint8), "RGB").convert("RGBA")

    overlay = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    rng = np.random.default_rng(motif)
    for _ in range(18):
        radius = int(rng.integers(40, 220))
        x = int(rng.integers(-60, size + 60))
        y = int(rng.integers(-60, size + 60))
        colour = (
            int(rng.integers(120, 255)),
            int(rng.integers(120, 255)),
            int(rng.integers(120, 255)),
            int(rng.integers(18, 60)),
        )
        draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=colour)
    overlay = overlay.filter(ImageFilter.GaussianBlur(38))
    image = Image.alpha_composite(image, overlay)

    grain = np.array(image, dtype=np.int16)
    noise = np.random.default_rng(motif + 1).integers(-10, 11, grain.shape[:2])[:, :, None]
    grain[:, :, :3] = np.clip(grain[:, :, :3] + noise, 0, 255)
    image = Image.fromarray(grain.astype(np.uint8), "RGBA")

    draw = ImageDraw.Draw(image)
    font_path = r"C:\Windows\Fonts\seguisb.ttf"
    bold_path = r"C:\Windows\Fonts\segoeuib.ttf"
    title_font = _font(bold_path, 74)
    artist_font = _font(font_path, 34)
    mark_font = _font(bold_path, 26)

    draw.text((56, size - 190), title, font=title_font, fill=(255, 255, 255, 236))
    draw.text((58, size - 104), artist, font=artist_font, fill=(255, 255, 255, 190))
    draw.text((58, 52), "NM VYBE", font=mark_font, fill=(255, 255, 255, 130))

    image.convert("RGB").save(path, "JPEG", quality=92)


def _font(path: str, size: int):
    try:
        return ImageFont.truetype(path, size)
    except OSError:
        return ImageFont.load_default()


# --------------------------------------------------------------------------- main
ALBUMS = [
    {
        "title": "Neon Drive",
        "artist": "Nova Kane",
        "year": "2026",
        "genre": "Synthwave",
        "palette": ((32, 8, 62), (150, 26, 120)),
        "root": 220.0,
        "bpm": 104,
        "bright": True,
        "tracks": [
            ("Chrome Sunset", 38, 0),
            ("Velvet Circuit", 44, 1),
            ("Night Bloom", 41, 2),
            ("Afterglow Drive", 47, 3),
        ],
    },
    {
        "title": "Midnight Rain",
        "artist": "Echo Vale",
        "year": "2026",
        "genre": "Ambient",
        "palette": ((6, 24, 46), (26, 104, 122)),
        "root": 174.6,
        "bpm": 82,
        "bright": False,
        "tracks": [
            ("Glass Harbour", 46, 4),
            ("Low Tide", 39, 5),
            ("Streetlight Lullaby", 42, 6),
        ],
    },
    {
        "title": "Golden Hour",
        "artist": "Sol & The Days",
        "year": "2026",
        "genre": "Downtempo",
        "palette": ((72, 18, 8), (222, 132, 32)),
        "root": 261.6,
        "bpm": 92,
        "bright": True,
        "tracks": [
            ("Amber Skies", 40, 7),
            ("Slow Motion Summer", 45, 8),
            ("Honey Light", 36, 9),
        ],
    },
]


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--out",
        default=os.path.join(os.path.expanduser("~"), "Music", "NM VYBE Demo"),
    )
    args = parser.parse_args()
    root = os.path.abspath(args.out)
    os.makedirs(root, exist_ok=True)

    print(f"Writing demo library to {root}")
    for album_index, album in enumerate(ALBUMS):
        album_dir = os.path.join(root, f"{album_index + 1:02d} - {album['title']}")
        os.makedirs(album_dir, exist_ok=True)
        make_cover(
            os.path.join(album_dir, "cover.jpg"),
            album["palette"],
            album["title"],
            album["artist"],
            album_index + 11,
        )
        for track_index, (title, duration, seed) in enumerate(album["tracks"]):
            filename = f"{album['artist']} - {title}.wav"
            path = os.path.join(album_dir, filename)
            if os.path.exists(path):
                print(f"  skipping {filename}")
                continue
            samples = render_track(
                seed=seed,
                duration=float(duration),
                root=album["root"] * (2 ** ((track_index % 4) * 2 / 12.0)),
                bpm=album["bpm"],
                bright=album["bright"],
            )
            write_wav(
                path,
                samples,
                {
                    "INAM": title,
                    "IART": album["artist"],
                    "IPRD": album["title"],
                    "ICRD": album["year"],
                    "IGNR": album["genre"],
                    "ITRK": str(track_index + 1),
                },
            )
            print(f"  wrote {filename} ({duration}s)")
    print("Done.")


if __name__ == "__main__":
    main()
