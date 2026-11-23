#!/usr/bin/env python3
"""Fast Everything-style query, filter, and sort helper for Quickshell FileSearch."""

from datetime import datetime
import json
import os
import subprocess
import sys

EXT_GROUPS = {
    "image": {"png", "jpg", "jpeg", "webp", "gif", "svg", "bmp", "avif", "heic", "ico", "tiff", "tif", "raw"},
    "video": {"mp4", "mkv", "webm", "avi", "mov", "flv", "wmv", "m4v", "ts"},
    "audio": {"mp3", "flac", "wav", "ogg", "opus", "m4a", "aac", "wma"},
    "doc": {"pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx", "odt", "ods", "odp", "txt", "md", "rtf", "csv", "epub"},
    "archive": {"zip", "tar", "gz", "tgz", "bz2", "xz", "zst", "7z", "rar"},
    "exec": {"appimage", "exe", "msi", "sh", "bat", "cmd", "desktop", "bin", "run"},
    "code": {"py", "js", "ts", "tsx", "jsx", "qml", "lua", "rs", "go", "c", "cpp", "h", "hpp", "json", "yml", "yaml", "toml", "conf", "css", "html", "sql"},
}


def icon_for(path: str, ext: str, is_dir: bool) -> tuple[str, str]:
    """Return (material_icon_name, type_label) for a file/directory."""
    if is_dir:
        return ("folder", "Folder")
    if ext in EXT_GROUPS["image"]:
        return ("image", ext.upper())
    if ext in EXT_GROUPS["video"]:
        return ("movie", ext.upper())
    if ext in EXT_GROUPS["audio"]:
        return ("music_note", ext.upper())
    if ext == "pdf":
        return ("picture_as_pdf", "PDF")
    if ext in EXT_GROUPS["doc"]:
        return ("article", ext.upper() if ext else "Document")
    if ext in EXT_GROUPS["archive"]:
        return ("folder_zip", ext.upper())
    if ext in ("exe", "msi"):
        return ("sports_esports", ext.upper())
    if ext in ("appimage", "desktop"):
        return ("apps", "AppImage" if ext == "appimage" else "App")
    if ext in ("sh", "bat", "cmd", "bin", "run"):
        return ("terminal", ext.upper())
    if ext in EXT_GROUPS["code"]:
        return ("code", ext.upper())
    if os.access(path, os.X_OK):
        return ("terminal", "Executable")
    return ("description", ext.upper() if ext else "File")


def human_size(num: int) -> str:
    for unit in ("B", "KB", "MB", "GB", "TB"):
        if num < 1024 or unit == "TB":
            return f"{num} B" if unit == "B" else f"{num:.1f} {unit}"
        num /= 1024
    return ""


def display_dir(path: str, home: str, max_len: int = 46) -> str:
    parent = os.path.dirname(path) or "/"
    if parent == home:
        shown = "~"
    elif parent.startswith(home + "/"):
        shown = "~" + parent[len(home):]
    else:
        shown = parent
    if len(shown) <= max_len:
        return shown
    keep = (max_len - 1) // 2
    return shown[:keep] + "…" + shown[-keep:]


def run_locate(db_path: str, update_script: str, terms: list[str], home: str) -> list[str]:
    if os.path.exists(db_path) and os.path.getsize(db_path) > 0:
        cmd = ["plocate", "-d", db_path, "-i", "-l", "1500", "--", *terms]
        res = subprocess.run(cmd, capture_output=True, text=True, check=False)
        return [line for line in res.stdout.splitlines() if line]
    if os.path.isfile(update_script) and os.access(update_script, os.X_OK):
        subprocess.Popen([update_script], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    res = subprocess.run(["fd", "-i", "-L", "--max-results", "500", "--", terms[0], home],
                         capture_output=True, text=True, check=False)
    return [line.rstrip("/") for line in res.stdout.splitlines() if line]


def matches_filter(path: str, ftype: str, ext: str, is_dir: bool) -> bool:
    if ftype == "all":
        return True
    if ftype == "dir":
        return is_dir
    if ftype == "file":
        return not is_dir
    if is_dir:
        return False
    if ftype in EXT_GROUPS:
        if ext in EXT_GROUPS[ftype]:
            return True
        if ftype == "exec":
            return os.access(path, os.X_OK)
        return False
    return True


def main() -> int:
    if len(sys.argv) < 7:
        return 2
    db_path, update_script, sort_by, sort_order, filter_type = sys.argv[1:6]
    terms = [t for t in sys.argv[6:] if t]
    if not terms:
        return 0

    home = os.path.expanduser("~").rstrip("/")
    home_prefix = home + "/"
    primary = terms[0].lower()
    raw_paths = run_locate(db_path, update_script, terms, home)

    entries = []
    need_stat = (filter_type in ("dir", "file", "exec")) or (sort_by in ("size", "mtime", "type"))

    for p in raw_paths:
        base = os.path.basename(p)
        _, raw_ext = os.path.splitext(base)
        ext = raw_ext.lstrip(".").lower()

        if filter_type != "all" and filter_type not in ("dir", "file", "exec"):
            if ext not in EXT_GROUPS.get(filter_type, ()):
                continue

        is_dir = False
        size = 0
        mtime = 0.0
        try:
            st = os.lstat(p)
            import stat as stat_mod
            is_dir = stat_mod.S_ISDIR(st.st_mode)
            size = 0 if is_dir else st.st_size
            mtime = st.st_mtime
        except OSError:
            if need_stat:
                continue

        if not matches_filter(p, filter_type, ext, is_dir):
            continue

        rel = 0.0
        if p.startswith(home_prefix) or p == home:
            rel += 1000.0
        b_low = base.lower()
        if b_low == primary:
            rel += 500.0
        elif b_low.startswith(primary):
            rel += 300.0
        elif primary in b_low:
            rel += 200.0
        rel -= len(p) * 0.1

        entries.append({
            "path": p,
            "name": base,
            "dir": display_dir(p, home),
            "ext": ext,
            "isDir": is_dir,
            "sizeBytes": size,
            "mtimeTs": mtime,
            "rel": rel,
        })

    reverse = sort_order == "desc"
    if sort_by == "name":
        entries.sort(key=lambda e: e["name"].lower(), reverse=reverse)
    elif sort_by == "size":
        entries.sort(key=lambda e: (e["sizeBytes"], e["rel"]), reverse=reverse)
    elif sort_by == "type":
        entries.sort(key=lambda e: (0 if e["isDir"] else 1, e["ext"], e["name"].lower()), reverse=reverse)
    elif sort_by == "mtime":
        entries.sort(key=lambda e: (e["mtimeTs"], e["rel"]), reverse=reverse)
    else:
        entries.sort(key=lambda e: e["rel"], reverse=reverse)

    for e in entries[:50]:
        mtime_str = datetime.fromtimestamp(e["mtimeTs"]).strftime("%d.%m.%Y %H:%M") if e["mtimeTs"] > 0 else ""
        size_str = "" if e["isDir"] else human_size(e["sizeBytes"])
        icon_name, kind_label = icon_for(e["path"], e["ext"], e["isDir"])
        print(json.dumps({
            "path": e["path"],
            "name": e["name"],
            "dir": e["dir"],
            "size": size_str,
            "mtime": mtime_str,
            "isDir": e["isDir"],
            "icon": icon_name,
            "kind": kind_label,
        }, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
