#!/usr/bin/env python3
import subprocess
import sys
import tempfile
import zlib
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from lib import log  # noqa: E402

SCRIPT = Path(__file__).resolve().parents[1] / "curseforge-information" / "convert-avatar.py"


fail = log.fail


def convert(source, target):
    subprocess.run([sys.executable, str(SCRIPT), str(source), str(target)], check=True, capture_output=True)


with tempfile.TemporaryDirectory() as tmp:
    icon = Path(tmp) / "icon.png"
    convert("src/LuaPad.tga", icon)
    if icon.read_bytes()[:8] != b"\x89PNG\r\n\x1a\n":
        fail("Output is not a PNG.")

    red_tga, red_png = Path(tmp) / "red.tga", Path(tmp) / "red.png"
    red_tga.write_bytes(bytes([0, 0, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 1, 0, 32, 8, 0x81, 0, 0, 0xFF, 0x80]))
    convert(red_tga, red_png)
    data = red_png.read_bytes()
    idat = data[data.index(b"IDAT") + 4:data.index(b"IEND") - 8]
    if zlib.decompress(idat) != b"\x00" + bytes((255, 0, 0, 128)) * 2:
        fail("RLE TGA did not decode to two red pixels.")

log.passed("src/LuaPad.tga and an RLE TGA convert to PNG.")
