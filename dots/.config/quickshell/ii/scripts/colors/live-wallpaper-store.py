#!/usr/bin/env python3
"""Fetch, search, and download live wallpapers from motionbgs.com and apply via switchwall.sh."""

import json
import os
import re
import shutil
import subprocess
import sys
import urllib.parse
import urllib.request
from pathlib import Path

UA = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0 Safari/537.36"
LIVE_DIR = Path.home() / "Pictures/Wallpapers/Live"
SWITCHWALL = Path.home() / ".config/quickshell/ii/scripts/colors/switchwall.sh"


def fetch_html(url: str) -> str:
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=12) as resp:
        return resp.read().decode("utf-8", errors="ignore")


def list_wallpapers(page: int = 1, query: str = "") -> list[dict]:
    q = query.strip()
    if q:
        url = f"https://motionbgs.com/search?q={urllib.parse.quote_plus(q)}&page={page}"
    else:
        url = f"https://motionbgs.com/?page={page}"
    html = fetch_html(url)

    # Match thumbnail URLs: /i/c/<size>/media/<id>/<slug>.<res>.jpg
    pattern = re.compile(r'/i/c/\d+x\d+/media/(\d+)/([a-z0-9-]+)\.(\d+x\d+)\.jpg')
    seen: set[str] = set()
    items: list[dict] = []
    for m in pattern.finditer(html):
        wid, slug, res = m.group(1), m.group(2), m.group(3)
        if wid in seen:
            continue
        seen.add(wid)
        title = slug.replace("-", " ").title()
        items.append({
            "id": wid,
            "slug": slug,
            "res": res,
            "title": title,
            "thumb": f"https://motionbgs.com/i/c/546x308/media/{wid}/{slug}.{res}.jpg",
            "previewMp4": f"https://motionbgs.com/media/{wid}/{slug}.960x540.mp4",
        })
    return items


def is_valid_video(path: Path) -> bool:
    """True when ffprobe can read a video stream from the file (rejects truncated/HTML downloads).

    Without ffprobe installed the check is skipped (download_file still verifies Content-Length)."""
    if shutil.which("ffprobe") is None:
        return True
    try:
        out = subprocess.check_output(
            ["ffprobe", "-v", "error", "-select_streams", "v:0", "-show_entries", "stream=codec_name", "-of", "csv=p=0", str(path)],
            stderr=subprocess.DEVNULL, text=True, timeout=10,
        ).strip()
        return bool(out)
    except Exception:
        return False


def download_file(url: str, dest: Path) -> bool:
    """Stream url to dest atomically (via .part + rename). Returns True on a valid video."""
    part = dest.with_name(dest.name + ".part")
    try:
        req = urllib.request.Request(url, headers={"User-Agent": UA})
        with urllib.request.urlopen(req, timeout=20) as resp, open(part, "wb") as fh:
            head = resp.read(512)
            if b"<html" in head.lower() or not head:
                return False
            fh.write(head)
            while True:
                chunk = resp.read(1 << 16)
                if not chunk:
                    break
                fh.write(chunk)
            expected = int(resp.headers.get("Content-Length") or 0)
        # Reject truncated transfers (ffprobe alone accepts a cut-off mp4 with an intact header)
        if expected and part.stat().st_size < expected:
            return False
        if part.stat().st_size > 10000 and is_valid_video(part):
            os.replace(part, dest)
            return True
        return False
    except Exception:
        return False
    finally:
        try:
            part.unlink()
        except FileNotFoundError:
            pass


def download_and_apply(wid: str, slug: str, monitor: str = "") -> int:
    LIVE_DIR.mkdir(parents=True, exist_ok=True)
    safe_slug = re.sub(r"[^A-Za-z0-9._-]", "_", slug) or wid
    out_path = LIVE_DIR / f"{safe_slug}-{wid}.mp4"

    # A previous (pre-atomic) download may have left a truncated file behind
    if out_path.exists() and not is_valid_video(out_path):
        out_path.unlink()

    if not out_path.exists():
        for url in (
            f"https://motionbgs.com/dl/hd/{wid}",
            f"https://motionbgs.com/media/{wid}/{slug}.960x540.mp4",
        ):
            if download_file(url, out_path):
                break

    if not out_path.exists():
        return 1

    cmd = ["bash", str(SWITCHWALL), "--image", str(out_path)]
    if monitor:
        cmd += ["--monitor", monitor]
    subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
    print(str(out_path))
    return 0


def list_history() -> list[dict]:
    dirs = [LIVE_DIR, Path.home() / "Pictures/Wallpapers"]
    seen: set[str] = set()
    files: list[Path] = []
    for d in dirs:
        if not d.is_dir():
            continue
        for ext in ("*.mp4", "*.webm", "*.mkv", "*.avi", "*.mov", "*.gif"):
            for p in d.glob(ext):
                rp = str(p.resolve())
                if rp not in seen:
                    seen.add(rp)
                    files.append(p)
    files.sort(key=lambda p: p.stat().st_mtime, reverse=True)
    thumb_dir = Path.home() / ".config/hypr/custom/scripts/mpvpaper_thumbnails"
    thumb_dir.mkdir(parents=True, exist_ok=True)
    out: list[dict] = []
    for p in files[:40]:
        stem = p.stem
        title = re.sub(r"-\d+$", "", stem).replace("-", " ").replace("_", " ").title()
        cand_thumb = thumb_dir / f"{p.name}.jpg"
        if cand_thumb.exists() and cand_thumb.stat().st_size == 0:
            cand_thumb.unlink()
        if not cand_thumb.exists() and p.suffix.lower() != ".gif":
            try:
                subprocess.run(
                    ["ffmpeg", "-y", "-i", str(p), "-vframes", "1", "-vf", "scale=546:-1", str(cand_thumb)],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                    timeout=15,
                )
            except Exception:
                pass
            if cand_thumb.exists() and cand_thumb.stat().st_size == 0:
                cand_thumb.unlink()
        thumb = ("file://" + str(cand_thumb)) if cand_thumb.exists() else ("file://" + str(p) if p.suffix.lower() == ".gif" else "")
        res = ""
        try:
            r_out = subprocess.check_output(
                ["ffprobe", "-v", "error", "-select_streams", "v:0", "-show_entries", "stream=width,height", "-of", "csv=s=x:p=0", str(p)],
                stderr=subprocess.DEVNULL,
                text=True,
                timeout=1.5,
            ).strip()
            if "x" in r_out:
                res = r_out.splitlines()[0]
        except Exception:
            pass
        out.append({
            "id": str(p),
            "slug": stem,
            "res": res,
            "title": title,
            "thumb": thumb,
            "previewMp4": "file://" + str(p),
            "localPath": str(p),
        })
    return out


def main() -> int:
    if len(sys.argv) < 2 or sys.argv[1] == "list":
        page = int(sys.argv[2]) if len(sys.argv) >= 3 else 1
        query = sys.argv[3] if len(sys.argv) >= 4 else ""
        try:
            print(json.dumps(list_wallpapers(page, query), ensure_ascii=False))
            return 0
        except Exception as e:
            sys.stderr.write(f"ERR: {e}\n")
            print("[]")
            return 1
    if sys.argv[1] == "history":
        print(json.dumps(list_history(), ensure_ascii=False))
        return 0
    if sys.argv[1] == "apply-local" and len(sys.argv) >= 3:
        path = sys.argv[2]
        mon = sys.argv[3] if len(sys.argv) >= 4 else ""
        cmd = ["bash", str(SWITCHWALL), "--image", path]
        if mon:
            cmd += ["--monitor", mon]
        subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
        return 0
    if sys.argv[1] == "download" and len(sys.argv) >= 4:
        mon = sys.argv[4] if len(sys.argv) >= 5 else ""
        return download_and_apply(sys.argv[2], sys.argv[3], mon)
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
