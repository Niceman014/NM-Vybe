"""Launch the NM VYBE Windows build, wait for its window and capture a PNG.

Usage: python tool/capture_window.py [--width 1280] [--width 820]
"""

from __future__ import annotations

import argparse
import ctypes
import ctypes.wintypes as wintypes
import os
import subprocess
import sys
import time

from PIL import ImageGrab

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
EXE = os.path.join(ROOT, "build", "windows", "x64", "runner", "Debug", "nm_vybe.exe")
OUT = os.path.join(ROOT, "docs", "screenshots")

user32 = ctypes.windll.user32


def find_window(title: str = "NM VYBE") -> int | None:
    handle = user32.FindWindowW(None, title)
    return int(handle) if handle else None


def window_rect(handle: int) -> tuple[int, int, int, int]:
    rect = wintypes.RECT()
    user32.GetWindowRect(handle, ctypes.byref(rect))
    return rect.left, rect.top, rect.right, rect.bottom


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--exe", default=EXE)
    parser.add_argument("--out", default=os.path.join(OUT, "windows"))
    parser.add_argument("--wait", type=float, default=30.0)
    parser.add_argument("--settle", type=float, default=6.0)
    parser.add_argument("--name", default="nm_vybe.png")
    args = parser.parse_args()

    os.makedirs(args.out, exist_ok=True)
    if not os.path.exists(args.exe):
        print(f"Missing executable: {args.exe}", file=sys.stderr)
        return 1

    process = subprocess.Popen([args.exe], cwd=os.path.dirname(args.exe))
    deadline = time.time() + args.wait
    handle = None
    while time.time() < deadline:
        handle = find_window()
        if handle:
            break
        time.sleep(0.5)
    if not handle:
        print("Window not found", file=sys.stderr)
        process.terminate()
        return 2

    user32.ShowWindow(handle, 9)  # SW_RESTORE
    user32.SetForegroundWindow(handle)
    time.sleep(args.settle)

    left, top, right, bottom = window_rect(handle)
    if right - left < 200:
        print(f"Unexpected window rect {left},{top},{right},{bottom}", file=sys.stderr)
        process.terminate()
        return 3

    image = ImageGrab.grab(bbox=(left, top, right, bottom))
    target = os.path.join(args.out, args.name)
    image.save(target, "PNG")
    print(f"Saved {target} ({image.width}x{image.height})")

    # Leave the app running; the caller may capture more states.
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
