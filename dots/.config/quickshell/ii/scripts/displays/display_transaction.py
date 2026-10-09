
#!/usr/bin/env python3
"""Vesta Shell display transactions for Hyprland Lua configuration."""

import fcntl
import json
import math
import os
import subprocess
import sys
import time
import uuid
from pathlib import Path

TIMEOUT = 15
VERIFY_TIMEOUT = 3.0

STATE_DIR = Path(
    os.environ.get(
        "XDG_RUNTIME_DIR",
        f"/tmp/vesta-{os.getuid()}"
    )
) / "vesta-shell"

STATE_FILE = STATE_DIR / "display-transaction.json"
LOCK_FILE = STATE_DIR / "display-transaction.lock"


def locked():
    STATE_DIR.mkdir(parents=True, exist_ok=True, mode=0o700)
    handle = open(LOCK_FILE, "a+")
    fcntl.flock(handle.fileno(), fcntl.LOCK_EX)
    return handle


def run(*arguments):
    process = subprocess.run(
        ["hyprctl", *arguments],
        capture_output=True,
        text=True,
        timeout=10
    )
    output = process.stdout.strip()

    if (
        process.returncode
        or output.lower().startswith("error:")
        or "keyword can't work" in output.lower()
    ):
        raise RuntimeError(
            process.stderr.strip()
            or output
            or "hyprctl failed"
        )

    return output


def monitors():
    result = json.loads(run("monitors", "-j"))

    if not isinstance(result, list) or not result:
        raise RuntimeError("No active monitors found")

    return result


def load():
    if not STATE_FILE.exists():
        return None

    return json.loads(
        STATE_FILE.read_text(encoding="utf-8")
    )


def save(data):
    STATE_DIR.mkdir(parents=True, exist_ok=True, mode=0o700)

    temporary = STATE_DIR / (
        f"display-transaction-{os.getpid()}.tmp"
    )

    with open(temporary, "w", encoding="utf-8") as file:
        json.dump(data, file)
        file.flush()
        os.fsync(file.fileno())

    os.replace(temporary, STATE_FILE)


def clear():
    STATE_FILE.unlink(missing_ok=True)


def mode_for(monitor):
    prefix = (
        f"{monitor['width']}x"
        f"{monitor['height']}@"
    )
    refresh = float(monitor["refreshRate"])
    candidates = []

    for entry in monitor.get("availableModes", []):
        if not entry.startswith(prefix):
            continue

        try:
            frequency = float(
                entry.split("@", 1)[1].removesuffix("Hz")
            )
            candidates.append((
                abs(frequency - refresh),
                entry.removesuffix("Hz")
            ))
        except ValueError:
            pass

    if candidates:
        distance, mode = min(candidates)
        if distance < 0.5:
            return mode

    return f"{prefix}{refresh:.5f}"


def normalize_position(value):
    number = float(value)

    if (
        not math.isfinite(number)
        or not -100000 <= number <= 100000
    ):
        raise ValueError("Invalid monitor position")

    return int(round(number))


def specification(monitor):
    entry = {
        "name": str(monitor["name"]),
        "mode": str(monitor["mode"]),
        "x": normalize_position(monitor["x"]),
        "y": normalize_position(monitor["y"]),
        "scale": float(monitor["scale"]),
        "transform": int(monitor["transform"]),
        "vrr": int(bool(monitor.get("vrr", False)))
    }

    if (
        not entry["name"]
        or not math.isfinite(entry["scale"])
        or entry["scale"] <= 0
    ):
        raise ValueError("Invalid monitor name or scale")

    if not 0 <= entry["transform"] <= 7:
        raise ValueError("Invalid monitor transform")

    return entry


def lua_monitor_command(monitor):
    entry = specification(monitor)

    output = json.dumps(
        entry["name"],
        ensure_ascii=True
    )
    mode = json.dumps(
        entry["mode"],
        ensure_ascii=True
    )
    position = json.dumps(
        f"{entry['x']}x{entry['y']}",
        ensure_ascii=True
    )

    return (
        "hl.monitor({"
        f"output={output},"
        f"mode={mode},"
        f"position={position},"
        f"scale={entry['scale']:.10g},"
        f"transform={entry['transform']},"
        f"vrr={entry['vrr']}"
        "})"
    )


def apply_monitor(monitor):
    result = run(
        "eval",
        lua_monitor_command(monitor)
    )

    if result.lower() != "ok":
        raise RuntimeError(
            "Unexpected Hyprland response: " + result
        )


def dimensions(target):
    resolution = target["mode"].split("@", 1)[0]
    width, height = map(
        int,
        resolution.split("x", 1)
    )

    if target["transform"] % 2:
        width, height = height, width

    return (
        math.ceil(width / target["scale"]),
        math.ceil(height / target["scale"])
    )


def overlaps(a, b):
    aw, ah = dimensions(a)
    bw, bh = dimensions(b)

    return (
        a["x"] < b["x"] + bw
        and a["x"] + aw > b["x"]
        and a["y"] < b["y"] + bh
        and a["y"] + ah > b["y"]
    )


def validate_no_overlap(targets):
    for index, first in enumerate(targets):
        for second in targets[index + 1:]:
            if overlaps(first, second):
                raise ValueError(
                    "Monitors overlap: "
                    f"{first['name']} and {second['name']}"
                )


def previous_specifications(previous):
    return [
        specification({
            "name": monitor["name"],
            "mode": mode_for(monitor),
            "x": monitor["x"],
            "y": monitor["y"],
            "scale": monitor["scale"],
            "transform": monitor["transform"],
            "vrr": monitor.get("vrr", False)
        })
        for monitor in previous
    ]


def validate(targets, current):
    if not isinstance(targets, list):
        raise ValueError("Expected a list of monitors")

    sources = {
        monitor["name"]: monitor
        for monitor in current
    }
    normalized = {}

    for target in targets:
        name = str(target["name"])

        if name not in sources or name in normalized:
            raise ValueError(
                f"Unknown or duplicated monitor: {name}"
            )

        available = [
            entry.removesuffix("Hz")
            for entry in sources[name].get(
                "availableModes", []
            )
        ]

        if str(target["mode"]) not in available:
            raise ValueError(
                f"Unsupported mode for {name}: "
                f"{target['mode']}"
            )

        normalized[name] = specification({
            **target,
            "vrr": sources[name].get("vrr", False)
        })

    if set(normalized) != set(sources):
        raise ValueError(
            "All active monitors must be included"
        )

    result = list(normalized.values())
    validate_no_overlap(result)
    return result


def verify(targets, timeout=VERIFY_TIMEOUT):
    deadline = time.monotonic() + timeout

    while True:
        current = {
            monitor["name"]: monitor
            for monitor in monitors()
        }
        failures = []

        for target in targets:
            actual = current.get(target["name"])

            if actual is None:
                failures.append(
                    f"{target['name']} missing"
                )
                continue

            resolution = (
                f"{actual['width']}x"
                f"{actual['height']}"
            )

            if resolution != target["mode"].split("@", 1)[0]:
                failures.append(
                    f"{target['name']}: resolution mismatch"
                )

            frequency = float(
                target["mode"].split("@", 1)[1]
            )

            if abs(
                float(actual["refreshRate"]) - frequency
            ) > 0.15:
                failures.append(
                    f"{target['name']}: refresh rate mismatch"
                )

            if abs(
                float(actual["scale"]) - target["scale"]
            ) > 0.01:
                failures.append(
                    f"{target['name']}: scale mismatch"
                )

            if (
                int(actual["transform"])
                != target["transform"]
            ):
                failures.append(
                    f"{target['name']}: transform mismatch"
                )

            if abs(
                int(actual["x"]) - target["x"]
            ) > 1:
                failures.append(
                    f"{target['name']}: X position mismatch"
                )

            if abs(
                int(actual["y"]) - target["y"]
            ) > 1:
                failures.append(
                    f"{target['name']}: Y position mismatch"
                )

        if not failures:
            return

        if time.monotonic() >= deadline:
            raise RuntimeError(
                "Display verification failed: "
                + "; ".join(failures)
            )

        time.sleep(0.15)


def apply_layout_safely(targets, current):
    """
    Move changed monitors to a free parking area first,
    then apply their final positions.

    This prevents temporary overlap between the old
    and new layouts during sequential Hyprland updates.
    """
    validate_no_overlap(targets)

    originals = {
        entry["name"]: entry
        for entry in previous_specifications(current)
    }

    changed = [
        target
        for target in targets
        if target != originals[target["name"]]
    ]

    if not changed:
        verify(targets)
        return

    all_entries = list(originals.values()) + targets

    right_edge = max(
        entry["x"] + dimensions(entry)[0]
        for entry in all_entries
    )

    parking_x = math.ceil(right_edge) + 128
    parking = []

    for target in changed:
        parked = dict(originals[target["name"]])

        parked["x"] = normalize_position(parking_x)
        parked["y"] = 0

        parking.append(parked)

        parking_x += (
            max(
                dimensions(parked)[0],
                dimensions(target)[0]
            ) + 128
        )

    # First free every old position.
    for parked in parking:
        apply_monitor(parked)

    # Then occupy the final positions.
    for target in changed:
        apply_monitor(target)

    verify(targets)


def restore(previous):
    targets = previous_specifications(previous)
    apply_layout_safely(targets, monitors())


def restore_transaction(state):
    restore(state["previous"])
    clear()


def watchdog():
    while True:
        handle = locked()

        try:
            state = load()

            if state is None:
                return

            remaining = (
                state["deadline"] - time.time()
            )

            if remaining <= 0:
                restore_transaction(state)
                return
        finally:
            handle.close()

        time.sleep(min(remaining, 0.2))


def apply(targets):
    handle = locked()

    try:
        if load() is not None:
            raise RuntimeError(
                "Another display transaction is active"
            )

        current = monitors()
        requested = validate(targets, current)

        state = {
            "id": str(uuid.uuid4()),
            "previous": current,
            "deadline": time.time() + TIMEOUT
        }

        save(state)

        try:
            process = subprocess.Popen(
                [
                    sys.executable,
                    str(Path(__file__).resolve()),
                    "watchdog"
                ],
                stdin=subprocess.DEVNULL,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                start_new_session=True,
                close_fds=True
            )

            if process.pid <= 0:
                raise RuntimeError(
                    "Failed to start watchdog"
                )
        except Exception:
            clear()
            raise

        try:
            apply_layout_safely(
                requested,
                current
            )
        except Exception as error:
            try:
                restore_transaction(state)
            except Exception as recovery_error:
                raise RuntimeError(
                    f"Apply failed: {error}; "
                    f"recovery failed: {recovery_error}"
                )

            raise RuntimeError(
                f"Apply failed and reverted: {error}"
            )

        return {
            "ok": True,
            "active": True,
            "deadline": state["deadline"],
            "timeout": TIMEOUT
        }
    finally:
        handle.close()


def normalize_layout(targets):
    if not targets:
        return targets

    offset_x = min(
        target["x"] for target in targets
    )
    offset_y = min(
        target["y"] for target in targets
    )

    return [
        {
            **target,
            "x": normalize_position(
                target["x"] - offset_x
            ),
            "y": normalize_position(
                target["y"] - offset_y
            )
        }
        for target in targets
    ]


def apply_positions(requested):
    handle = locked()

    try:
        if load() is not None:
            raise RuntimeError(
                "Another display transaction is active"
            )

        if (
            not isinstance(requested, dict)
            or not requested
        ):
            raise ValueError(
                "Expected a non-empty map of monitor positions"
            )

        current = monitors()

        sources = {
            monitor["name"]
            for monitor in current
        }

        if any(
            name not in sources
            for name in requested
        ):
            raise ValueError(
                "Unknown monitor in position request"
            )

        targets = previous_specifications(current)

        for target in targets:
            if target["name"] not in requested:
                continue

            position = requested[target["name"]]

            if not isinstance(position, dict):
                raise ValueError(
                    "Invalid monitor position"
                )

            target["x"] = normalize_position(
                position["x"]
            )
            target["y"] = normalize_position(
                position["y"]
            )

        targets = normalize_layout(targets)
        validate_no_overlap(targets)

        try:
            apply_layout_safely(
                targets,
                current
            )
        except Exception as error:
            try:
                restore(current)
            except Exception as recovery_error:
                raise RuntimeError(
                    f"Position change failed: {error}; "
                    f"recovery failed: {recovery_error}"
                )

            raise RuntimeError(
                "Position change failed and reverted: "
                + str(error)
            )

        return {
            "ok": True,
            "positionsApplied": True,
            "positions": {
                target["name"]: {
                    "x": target["x"],
                    "y": target["y"]
                }
                for target in targets
            }
        }
    finally:
        handle.close()


def confirm():
    handle = locked()

    try:
        state = load()

        if state is None:
            raise RuntimeError(
                "No active transaction"
            )

        if time.time() >= state["deadline"]:
            restore_transaction(state)
            raise RuntimeError(
                "Confirmation expired; changes reverted"
            )

        clear()

        return {
            "ok": True,
            "confirmed": True
        }
    finally:
        handle.close()


def revert():
    handle = locked()

    try:
        state = load()

        if state is None:
            return {
                "ok": True,
                "reverted": False
            }

        restore_transaction(state)

        return {
            "ok": True,
            "reverted": True
        }
    finally:
        handle.close()


def status():
    handle = locked()

    try:
        state = load()

        if state is None:
            return {
                "ok": True,
                "active": False
            }

        return {
            "ok": True,
            "active": True,
            "deadline": state["deadline"],
            "remaining": max(
                0,
                state["deadline"] - time.time()
            )
        }
    finally:
        handle.close()


def main():
    if len(sys.argv) < 2:
        raise ValueError("Missing command")

    command = sys.argv[1]

    if command == "snapshot":
        result = {
            "ok": True,
            "monitors": monitors()
        }

    elif command == "status":
        result = status()

    elif command == "apply":
        if len(sys.argv) != 3:
            raise ValueError(
                "Expected JSON monitor configuration"
            )

        result = apply(
            json.loads(sys.argv[2])
        )

    elif command == "positions":
        if len(sys.argv) != 3:
            raise ValueError(
                "Expected JSON monitor positions"
            )

        result = apply_positions(
            json.loads(sys.argv[2])
        )

    elif command == "confirm":
        result = confirm()

    elif command == "revert":
        result = revert()

    elif command == "watchdog":
        watchdog()
        return

    else:
        raise ValueError(
            f"Unknown command: {command}"
        )

    print(
        json.dumps(result),
        flush=True
    )


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print(
            json.dumps({
                "ok": False,
                "error": str(error)
            }),
            flush=True
        )
        sys.exit(1)
