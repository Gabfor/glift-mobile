import argparse
import base64
import struct
import zlib
from pathlib import Path
from typing import Dict, List, Tuple

Color = Tuple[int, int, int, int]

BASE_ICON_PNG = Path("assets/images/app_icon.png")
BASE_ICON_B64 = Path("assets/images/app_icon.b64.txt")

PNG_TARGETS: Dict[str, int] = {
    # Android
    "android/app/src/main/res/mipmap-mdpi/ic_launcher.png": 48,
    "android/app/src/main/res/mipmap-hdpi/ic_launcher.png": 72,
    "android/app/src/main/res/mipmap-xhdpi/ic_launcher.png": 96,
    "android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png": 144,
    "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png": 192,
    # iOS
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png": 20,
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png": 40,
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png": 60,
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png": 29,
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png": 58,
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png": 87,
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png": 40,
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png": 80,
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png": 120,
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png": 120,
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png": 180,
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png": 76,
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png": 152,
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png": 167,
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png": 1024,
    # macOS
    "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_16.png": 16,
    "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_32.png": 32,
    "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_64.png": 64,
    "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_128.png": 128,
    "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_256.png": 256,
    "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png": 512,
    "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png": 1024,
    # Web
    "web/icons/Icon-192.png": 192,
    "web/icons/Icon-512.png": 512,
    "web/icons/Icon-maskable-192.png": 192,
    "web/icons/Icon-maskable-512.png": 512,
    "web/favicon.png": 48,
}

WINDOWS_ICO = "windows/runner/resources/app_icon.ico"
WINDOWS_SIZES = [16, 24, 32, 48, 64, 128, 256]


def _paeth(a: int, b: int, c: int) -> int:
    p = a + b - c
    pa = abs(p - a)
    pb = abs(p - b)
    pc = abs(p - c)
    if pa <= pb and pa <= pc:
        return a
    if pb <= pc:
        return b
    return c


def _reconstruct_scanlines(raw: bytes, width: int, height: int, bpp: int) -> List[List[int]]:
    stride = width * bpp
    recon: List[List[int]] = []
    i = 0
    prev_row = [0] * stride
    for _ in range(height):
        filter_type = raw[i]
        i += 1
        row_data = list(raw[i : i + stride])
        i += stride

        row: List[int] = [0] * stride
        if filter_type == 0:  # None
            row = row_data
        elif filter_type == 1:  # Sub
            for x in range(stride):
                left = row[x - bpp] if x >= bpp else 0
                row[x] = (row_data[x] + left) & 0xFF
        elif filter_type == 2:  # Up
            for x in range(stride):
                row[x] = (row_data[x] + prev_row[x]) & 0xFF
        elif filter_type == 3:  # Average
            for x in range(stride):
                left = row[x - bpp] if x >= bpp else 0
                up = prev_row[x]
                row[x] = (row_data[x] + ((left + up) // 2)) & 0xFF
        elif filter_type == 4:  # Paeth
            for x in range(stride):
                left = row[x - bpp] if x >= bpp else 0
                up = prev_row[x]
                up_left = prev_row[x - bpp] if x >= bpp else 0
                row[x] = (row_data[x] + _paeth(left, up, up_left)) & 0xFF
        else:
            raise ValueError(f"Unsupported PNG filter type: {filter_type}")

        recon.append(row)
        prev_row = row
    return recon


def _parse_png(data: bytes) -> List[List[Color]]:
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError("Not a PNG file")

    offset = 8
    width = height = bit_depth = color_type = None
    idat_chunks = []

    while offset < len(data):
        length = struct.unpack(">I", data[offset : offset + 4])[0]
        offset += 4
        chunk_type = data[offset : offset + 4]
        offset += 4
        chunk_data = data[offset : offset + length]
        offset += length
        offset += 4  # skip CRC

        if chunk_type == b"IHDR":
            width, height, bit_depth, color_type = struct.unpack(">IIBBBBB", chunk_data)[0:4]
        elif chunk_type == b"IDAT":
            idat_chunks.append(chunk_data)
        elif chunk_type == b"IEND":
            break

    if width is None or height is None or bit_depth is None or color_type is None:
        raise ValueError("Malformed PNG: missing IHDR metadata")
    if bit_depth != 8 or color_type not in (2, 6):
        raise ValueError("Only 8-bit RGB/RGBA PNGs are supported")

    bpp = 4 if color_type == 6 else 3
    raw = zlib.decompress(b"".join(idat_chunks))
    rows = _reconstruct_scanlines(raw, width, height, bpp)

    pixels: List[List[Color]] = []
    for row in rows:
        row_pixels: List[Color] = []
        for x in range(0, len(row), bpp):
            r, g, b = row[x : x + 3]
            a = row[x + 3] if color_type == 6 else 255
            row_pixels.append((r, g, b, a))
        pixels.append(row_pixels)
    return pixels


def read_png(path: Path) -> List[List[Color]]:
    return _parse_png(path.read_bytes())


def scale_icon(pixels: List[List[Color]], target_size: int) -> List[List[Color]]:
    source_size = len(pixels)
    if source_size == target_size:
        return [row[:] for row in pixels]
    result = []
    for y in range(target_size):
        src_y = int(y * source_size / target_size)
        row: List[Color] = []
        for x in range(target_size):
            src_x = int(x * source_size / target_size)
            row.append(pixels[src_y][src_x])
        result.append(row)
    return result


def chunk(tag: bytes, data: bytes) -> bytes:
    return (
        struct.pack(">I", len(data))
        + tag
        + data
        + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
    )


def write_png(path: Path, pixels: List[List[Color]]) -> bytes:
    height = len(pixels)
    width = len(pixels[0])
    raw_rows = [b"\x00" + bytes([c for pixel in row for c in pixel]) for row in pixels]
    raw = b"".join(raw_rows)
    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(raw, 9))
    png += chunk(b"IEND", b"")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(png)
    return png


def write_ico(path: Path, png_bytes: bytes) -> None:
    entry = struct.pack(
        "<BBBBHHII",
        0,
        0,
        0,
        0,
        1,
        32,
        len(png_bytes),
        6 + 16,
    )
    header = struct.pack("<HHH", 0, 1, 1)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(header + entry + png_bytes)


def generate_png_targets(base_pixels: List[List[Color]], base_dir: Path) -> Dict[int, bytes]:
    cache: Dict[int, bytes] = {}
    for relative_target, size in PNG_TARGETS.items():
        target = base_dir / Path(relative_target)
        scaled = scale_icon(base_pixels, size)
        png_bytes = write_png(target, scaled)
        cache[size] = png_bytes
    return cache


def generate_windows_icon(base_pixels: List[List[Color]], cache: Dict[int, bytes], base_dir: Path) -> None:
    png_bytes = cache.get(256)
    if png_bytes is None:
        png_bytes = write_png(base_dir / Path("windows/runner/resources/app_icon_256_tmp.png"), scale_icon(base_pixels, 256))
    write_ico(base_dir / Path(WINDOWS_ICO), png_bytes)
    tmp = base_dir / Path("windows/runner/resources/app_icon_256_tmp.png")
    if tmp.exists():
        tmp.unlink()


def load_base_icon_pixels() -> List[List[Color]]:
    if BASE_ICON_PNG.exists():
        return read_png(BASE_ICON_PNG)
    if BASE_ICON_B64.exists():
        data = base64.b64decode(BASE_ICON_B64.read_text())
        return _parse_png(data)
    raise FileNotFoundError(
        f"Missing base icon. Provide {BASE_ICON_PNG} or a base64 source at {BASE_ICON_B64}"
    )


def main() -> None:
    parser = argparse.ArgumentParser(
        description=(
            "Generate launcher icons for every platform using the base icon at assets/images/app_icon.png "
            "or its base64 twin assets/images/app_icon.b64.txt. "
            "If your PR workflow refuses binary diffs, pass --export-dir to write icons outside the tracked tree."
        )
    )
    parser.add_argument(
        "--export-dir",
        type=Path,
        help=(
            "Directory where generated icons should be written. When omitted, platform assets are overwritten in-place. "
            "Use this to avoid adding binary changes to your commits while still producing the icons locally."
        ),
    )
    args = parser.parse_args()

    base_dir = args.export_dir or Path(".")
    base_pixels = load_base_icon_pixels()
    cache = generate_png_targets(base_pixels, base_dir)
    generate_windows_icon(base_pixels, cache, base_dir)


if __name__ == "__main__":
    main()
