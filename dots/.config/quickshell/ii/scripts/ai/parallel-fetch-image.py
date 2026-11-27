#!/usr/bin/env python3
"""Parallel HTTP Range image downloader (zero-HEAD first-chunk + parallel tail)."""

import concurrent.futures
import hashlib
import os
import sys
import urllib.parse
import urllib.request

CACHE_DIR = "/tmp/qs-anime-cache"
USER_AGENT = (
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
    "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36"
)
FIRST_CHUNK = 512 * 1024  # 512 KiB in the initial GET (0 extra HEAD RTT)
DEFAULT_WORKERS = 8


def guess_ext(url: str) -> str:
    path = urllib.parse.urlparse(url).path
    _, ext = os.path.splitext(path)
    ext = ext.lower()
    if ext in {".jpg", ".jpeg", ".png", ".webp", ".gif", ".avif", ".bmp"}:
        return ext
    return ".img"


def download_range(url: str, fd: int, start: int, end: int) -> None:
    req = urllib.request.Request(
        url,
        headers={
            "User-Agent": USER_AGENT,
            "Range": f"bytes={start}-{end}",
        },
    )
    with urllib.request.urlopen(req, timeout=30) as resp:
        offset = start
        while True:
            buf = resp.read(65536)
            if not buf:
                break
            written = 0
            while written < len(buf):
                n = os.pwrite(fd, buf[written:], offset + written)
                written += n
            offset += len(buf)


def main() -> int:
    if len(sys.argv) < 2 or not sys.argv[1]:
        return 1
    url = sys.argv[1]
    workers = int(sys.argv[2]) if len(sys.argv) > 2 else DEFAULT_WORKERS

    os.makedirs(CACHE_DIR, exist_ok=True)
    digest = hashlib.sha256(url.encode("utf-8")).hexdigest()[:24]
    dest = os.path.join(CACHE_DIR, f"{digest}{guess_ext(url)}")

    if os.path.isfile(dest) and os.path.getsize(dest) > 0:
        print(f"file://{dest}", flush=True)
        return 0

    part = f"{dest}.{os.getpid()}.part"
    try:
        req = urllib.request.Request(
            url,
            headers={
                "User-Agent": USER_AGENT,
                "Range": f"bytes=0-{FIRST_CHUNK - 1}",
            },
        )
        with urllib.request.urlopen(req, timeout=30) as resp:
            status = getattr(resp, "status", 200)
            content_range = resp.headers.get("Content-Range", "")
            first_data = resp.read()

            total = None
            if status == 206 and "/" in content_range:
                tail = content_range.rsplit("/", 1)[-1].strip()
                if tail.isdigit():
                    total = int(tail)

            fd = os.open(part, os.O_CREAT | os.O_RDWR | os.O_TRUNC, 0o644)
            try:
                written = 0
                while written < len(first_data):
                    written += os.pwrite(fd, first_data[written:], written)

                if status == 206 and total and total > len(first_data):
                    os.ftruncate(fd, total)
                    rem_start = len(first_data)
                    rem_len = total - rem_start
                    step = max(256 * 1024, (rem_len + workers - 1) // workers)
                    ranges = []
                    pos = rem_start
                    while pos < total:
                        end = min(total - 1, pos + step - 1)
                        ranges.append((pos, end))
                        pos = end + 1

                    with concurrent.futures.ThreadPoolExecutor(max_workers=len(ranges)) as ex:
                        futs = [ex.submit(download_range, url, fd, s, e) for s, e in ranges]
                        for fut in concurrent.futures.as_completed(futs):
                            fut.result()
                elif status == 200:
                    # Server ignored Range and sent full body; first_data already has it all.
                    pass
            finally:
                os.close(fd)

        os.replace(part, dest)
        print(f"file://{dest}", flush=True)
        return 0
    except Exception as exc:
        print(f"ERR:{exc}", file=sys.stderr)
        try:
            if os.path.exists(part):
                os.unlink(part)
        except OSError:
            pass
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
