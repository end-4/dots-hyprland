#!/usr/bin/env python3
"""Browse live wallpapers from several sites in one list, download from MotionBGs and apply via switchwall.sh."""

import concurrent.futures
import html as _html
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


def fetch_html(url: str) -> tuple[str, str]:
    """Returns (html, final_url); the final URL tells whether a redirect (e.g. search -> tag page) happened."""
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=12) as resp:
        return resp.read().decode("utf-8", errors="ignore"), resp.geturl()


# ----------------------------------------------------------------------------- sources
# Every source returns (items, pages). Items share one shape so the store can show them in one grid:
#   id, slug, res, title, thumb, previewMp4, source, sourceName, pageUrl, browseOnly
# MotionBGs allows automated downloads (its robots.txt only blocks Yandex), so its items can be applied
# directly. MoeWalls and WallpaperWaifu hide their downloads behind scripts (MoeWalls' robots.txt even
# disallows /download*), so those items are browse-only: the store opens the wallpaper's page instead.

PER_PAGE_MOTIONBGS = 36
MOTIONBGS_THUMB = re.compile(r'/i/c/\d+x\d+/media/(\d+)/([a-z0-9-]+)\.(\d+x\d+)\.jpg')
TITLE_COUNT = re.compile(r"<title>\s*([\d,.]+)\+?")


def _motionbgs(page: int, query: str) -> tuple[list[dict], int]:
    q = query.strip()
    if not q:
        url = "https://motionbgs.com/" if page <= 1 else f"https://motionbgs.com/{page}/"
    elif page <= 1:
        url = f"https://motionbgs.com/search?q={urllib.parse.quote_plus(q)}"
    else:
        slug = urllib.parse.quote(re.sub(r"\s+", "-", q.lower()))
        url = f"https://motionbgs.com/tag:{slug}/{page}/"
    html, _final = fetch_html(url)
    seen: set[str] = set()
    items: list[dict] = []
    for m in MOTIONBGS_THUMB.finditer(html):
        wid, slug, res = m.group(1), m.group(2), m.group(3)
        if wid in seen:
            continue
        seen.add(wid)
        items.append({
            "id": wid,
            "slug": slug,
            "res": res,
            "title": slug.replace("-", " ").title(),
            "thumb": f"https://motionbgs.com/i/c/546x308/media/{wid}/{slug}.{res}.jpg",
            "previewMp4": f"https://motionbgs.com/media/{wid}/{slug}.960x540.mp4",
            "source": "motionbgs",
            "sourceName": "MotionBGs",
            "pageUrl": "",
            "browseOnly": False,
        })
    items = items[:PER_PAGE_MOTIONBGS]  # page 1 also lists extra "popular" entries below the grid
    pages = 1
    tc = TITLE_COUNT.search(html)
    if tc:
        try:
            pages = max(1, -(-int(re.sub(r"[,.]", "", tc.group(1))) // PER_PAGE_MOTIONBGS))
        except ValueError:
            pages = 1
    return items, pages


def _wordpress_grid(base: str, page: int, query: str, article_cls: str, source: str, name: str, img_attr: str) -> tuple[list[dict], int]:
    q = query.strip()
    if q:
        url = f"{base}/{'page/%d/' % page if page > 1 else ''}?s={urllib.parse.quote_plus(q)}"
    else:
        url = f"{base}/" if page <= 1 else f"{base}/page/{page}/"
    html, _final = fetch_html(url)
    items: list[dict] = []
    for art in re.findall(r"<article\b.*?</article>", html, re.S):
        if article_cls not in art:
            continue
        link = re.search(r'<a[^>]+href="(https?://[^"]+)"[^>]*>', art)
        title = re.search(r'title="([^"]+)"', art)
        img = re.search(rf'{img_attr}="(https?://[^"]+\.(?:jpg|jpeg|png|webp)[^"]*)"', art)
        if not (link and img):
            continue
        res = re.search(r"resolutions-(\d+x\d+)", art)
        pid = re.search(r"post-(\d+)", art)
        t = _html.unescape(title.group(1)) if title else link.group(1).rstrip("/").rsplit("/", 1)[-1].replace("-", " ").title()
        t = re.sub(r"\s+Live Wallpaper$", "", t)
        items.append({
            "id": f"{source}:{pid.group(1) if pid else link.group(1)}",
            "slug": link.group(1).rstrip("/").rsplit("/", 1)[-1],
            "res": res.group(1) if res else "",
            "title": t,
            "thumb": img.group(1),
            "previewMp4": "",
            "source": source,
            "sourceName": name,
            "pageUrl": link.group(1),
            "browseOnly": True,
        })
    pages = 1
    nums = [int(x) for x in re.findall(r"/page/(\d+)/", html)]
    if nums:
        pages = max(nums)
    return items, pages


def _moewalls(page: int, query: str) -> tuple[list[dict], int]:
    return _wordpress_grid("https://moewalls.com", page, query, "entry-tpl-grid", "moewalls", "MoeWalls", "src")


def _wallpaperwaifu(page: int, query: str) -> tuple[list[dict], int]:
    return _wordpress_grid("https://wallpaperwaifu.com", page, query, "wall-grid-item", "wallpaperwaifu", "WallpaperWaifu", "data-src")


SOURCES = {"motionbgs": _motionbgs, "moewalls": _moewalls, "wallpaperwaifu": _wallpaperwaifu}


def list_wallpapers(page: int = 1, query: str = "") -> dict:
    """One page from every source, interleaved: {"items": [...], "pages": N}."""
    results: dict[str, tuple[list[dict], int]] = {}
    with concurrent.futures.ThreadPoolExecutor(max_workers=len(SOURCES)) as pool:
        futures = {pool.submit(fn, page, query): name for name, fn in SOURCES.items()}
        for fut in concurrent.futures.as_completed(futures):
            try:
                results[futures[fut]] = fut.result()
            except Exception as e:  # one source being down must not break the store
                sys.stderr.write(f"WARN {futures[fut]}: {e}\n")
    # A source only has so many pages: past its last page it must not repeat or invent results
    lists = [results[n][0] if page <= results[n][1] else [] for n in SOURCES if n in results]
    merged: list[dict] = []
    for i in range(max((len(x) for x in lists), default=0)):
        for lst in lists:
            if i < len(lst):
                merged.append(lst[i])
    pages = max((r[1] for r in results.values()), default=1)
    return {"items": merged, "pages": pages}


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
            print('{"items": [], "pages": 1}')
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
