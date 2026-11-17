#!/usr/bin/env python3
"""Convert a 24/32-bit TGA (the addon icon) to PNG, for the CurseForge avatar. Standard library only."""
import struct
import sys
import zlib
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from lib import log  # noqa: E402


def read_tga(data):
    id_len, cmap_type, kind = data[0], data[1], data[2]
    width, height, depth, desc = struct.unpack("<HHBB", data[12:18])
    if cmap_type or kind not in (2, 10) or depth not in (24, 32):
        log.fail(f"Only true-color 24/32-bit TGA is supported (type {kind}, {depth}-bit).")
    size = depth // 8
    pos, need, pixels = 18 + id_len, width * height * size, bytearray()
    if kind == 2:
        pixels = data[pos:pos + need]
    else:
        while len(pixels) < need:
            head = data[pos]
            pos += 1
            count = (head & 0x7F) + 1
            if head & 0x80:
                pixels += data[pos:pos + size] * count
                pos += size
            else:
                pixels += data[pos:pos + size * count]
                pos += size * count
    if len(pixels) < need:
        log.fail("The TGA file is truncated.")
    rows = [pixels[y * width * size:(y + 1) * width * size] for y in range(height)]
    if not desc & 0x20:
        rows.reverse()
    out = []
    for row in rows:
        line = bytearray()
        for x in range(0, len(row), size):
            b, g, r = row[x], row[x + 1], row[x + 2]
            line += bytes((r, g, b, row[x + 3] if size == 4 else 255))
        out.append(bytes(line))
    return width, height, out


def png(width, height, rows):
    def chunk(tag, body):
        return struct.pack(">I", len(body)) + tag + body + struct.pack(">I", zlib.crc32(tag + body))

    raw = b"".join(b"\x00" + row for row in rows)
    return (
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))
        + chunk(b"IDAT", zlib.compress(raw, 9))
        + chunk(b"IEND", b"")
    )


def main():
    if len(sys.argv) != 3:
        log.fail("Usage: convert-avatar.py <input.tga> <output.png>")
    with open(sys.argv[1], "rb") as f:
        width, height, rows = read_tga(f.read())
    with open(sys.argv[2], "wb") as f:
        f.write(png(width, height, rows))
    log.info(f"Wrote '{sys.argv[2]}' ({width}x{height}).")


if __name__ == "__main__":
    main()
