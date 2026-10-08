
#!/usr/bin/env python3

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
    STATE_DIR.mkdir(
        parents=True,
        exist_ok=True,
        mode=0o700
    )

    handle = open(LOCK_FILE, "a+")

    fcntl.flock(
        handle.fileno(),
        fcntl.LOCK_EX
    )

    return handle


def run(*arguments):
    process = subprocess.run(
        ["hyprctl", *arguments],
        capture_output=True,
        text=True,
        timeout=10
    )

    output = process.stdout.strip()
    error = process.stderr.strip()

    if process.returncode != 0:
        raise RuntimeError(
            error or output or "hyprctl failed"
        )

    if output.lower().startswith("error:"):
        raise RuntimeError(output)

    if "keyword can't work" in output.lower():
        raise RuntimeError(output)

    return output


def monitors():
    result = json.loads(
        run("monitors", "-j")
    )

    if not isinstance(result, list) or not result:
        raise RuntimeError(
            "No active monitors found"
        )

    return result


def load():
    if not STATE_FILE.exists():
        return None

    return json.loads(
        STATE_FILE.read_text(
            encoding="utf-8"
        )
    )


def save(data):
    STATE_DIR.mkdir(
        parents=True,
        exist_ok=True,
        mode=0o700
    )

    temporary = STATE_DIR / (
        f"display-transaction-{os.getpid()}.tmp"
    )

    with open(
        temporary,
        "w",
        encoding="utf-8"
    ) as file:
        json.dump(data, file)

        file.flush()
        os.fsync(file.fileno())

    os.replace(
        temporary,
        STATE_FILE
    )


def clear():
    STATE_FILE.unlink(
        missing_ok=True
    )


def mode_for(monitor):
    prefix = (
        f"{monitor['width']}x"
        f"{monitor['height']}@"
    )

    refresh_rate = float(
        monitor["refreshRate"]
    )

    candidates = []

    for entry in monitor.get(
        "availableModes", []
    ):
        if not entry.startswith(prefix):
            continue

        try:
            frequency = float(
                entry.split("@", 1)[1]
                .removesuffix("Hz")
            )

            candidates.append((
                abs(frequency - refresh_rate),
                entry.removesuffix("Hz")
            ))

        except ValueError:
            continue

    if candidates:
        distance, mode = min(candidates)

        if distance < 0.5:
            return mode

    return (
        f"{prefix}{refresh_rate:.5f}"
    )


def normalize_position(value):
    number = float(value)

    if not math.isfinite(number):
        raise ValueError(
            "Invalid monitor position"
        )

    if not -100000 <= number <= 100000:
        raise ValueError(
            "Monitor position out of range"
        )

    return int(round(number))


def specification(monitor):
    name = str(monitor["name"])
    mode = str(monitor["mode"])

    x = normalize_position(
        monitor["x"]
    )

    y = normalize_position(
        monitor["y"]
    )

    scale = float(
        monitor["scale"]
    )

    transform = int(
        monitor["transform"]
    )

    vrr = int(
        bool(monitor.get("vrr", False))
    )

    if not name:
        raise ValueError(
            "Invalid monitor name"
        )

    if not math.isfinite(scale) or scale <= 0:
        raise ValueError(
            "Invalid monitor scale"
        )

    if not 0 <= transform <= 7:
        raise ValueError(
            "Invalid monitor transform"
        )

    return {
        "name": name,
        "mode": mode,
        "x": x,
        "y": y,
        "scale": scale,
        "transform": transform,
        "vrr": vrr
    }


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

    scale = format(
        entry["scale"],
        ".10g"
    )

    transform = entry["transform"]
    vrr = entry["vrr"]

    return (
        "hl.monitor({"
        f"output={output},"
        f"mode={mode},"
        f"position={position},"
        f"scale={scale},"
        f"transform={transform},"
        f"vrr={vrr}"
        "})"
    )


def apply_monitor(monitor):
    command = lua_monitor_command(
        monitor
    )

    result = run(
        "eval",
        command
    )

    if result.lower() != "ok":
        raise RuntimeError(
            "Unexpected Hyprland response: "
            + result
        )


def validate(targets, current):
    if not isinstance(targets, list):
        raise ValueError(
            "Expected a list of monitors"
        )

    sources = {
        monitor["name"]: monitor
        for monitor in current
    }

    normalized = {}

    for target in targets:
        name = str(
            target["name"]
        )

        if name not in sources:
            raise ValueError(
                f"Unknown monitor: {name}"
            )

        if name in normalized:
            raise ValueError(
                f"Duplicated monitor: {name}"
            )

        source = sources[name]

        mode = str(
            target["mode"]
        )

        available = [
            entry.removesuffix("Hz")
            for entry in source.get(
                "availableModes", []
            )
        ]

        if mode not in available:
            raise ValueError(
                f"Unsupported mode for {name}: {mode}"
            )

        entry = {
            "name": name,
            "mode": mode,
            "x": target["x"],
            "y": target["y"],
            "scale": target["scale"],
            "transform": target["transform"],
            "vrr": source.get(
                "vrr", False
            )
        }

        normalized[name] = specification(
            entry
        )

    if set(normalized) != set(sources):
        raise ValueError(
            "All active monitors must be included"
        )

    return list(
        normalized.values()
    )


def previous_specifications(previous):
    result = []

    for monitor in previous:
        result.append(
            specification({
                "name": monitor["name"],
                "mode": mode_for(monitor),
                "x": monitor["x"],
                "y": monitor["y"],
                "scale": monitor["scale"],
                "transform": monitor["transform"],
                "vrr": monitor.get(
                    "vrr", False
                )
            })
        )

    return result


def expected_frequency(monitor):
    return float(
        monitor["mode"].split("@", 1)[1]
    )


def verify(targets, timeout=VERIFY_TIMEOUT):
    deadline = time.monotonic() + timeout

    while True:
        current = {
            monitor["name"]: monitor
            for monitor in monitors()
        }

        failures = []

        for target in targets:
            actual = current.get(
                target["name"]
            )

            if actual is None:
                failures.append(
                    f"{target['name']} missing"
                )
                continue

            expected_resolution = (
                target["mode"].split("@", 1)[0]
            )

            actual_resolution = (
                f"{actual['width']}x"
                f"{actual['height']}"
            )

            if actual_resolution != expected_resolution:
                failures.append(
                    f"{target['name']}: resolution mismatch"
                )

            if abs(
                float(actual["refreshRate"])
                - expected_frequency(target)
            ) > 0.15:
                failures.append(
                    f"{target['name']}: refresh rate mismatch"
                )

            if abs(
                float(actual["scale"])
                - float(target["scale"])
            ) > 0.01:
                failures.append(
                    f"{target['name']}: scale mismatch"
                )

            if int(actual["transform"]) != int(
                target["transform"]
            ):
                failures.append(
                    f"{target['name']}: transform mismatch"
                )

            if abs(
                int(actual["x"])
                - int(target["x"])
            ) > 1:
                failures.append(
                    f"{target['name']}: X position mismatch"
                )

            if abs(
                int(actual["y"])
                - int(target["y"])
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


def restore(previous):
    targets = previous_specifications(
        previous
    )

    errors = []

    for target in targets:
        try:
            apply_monitor(target)

        except Exception as error:
            errors.append(
                f"{target['name']}: {error}"
            )

    if errors:
        raise RuntimeError(
            "; ".join(errors)
        )

    verify(targets)


def restore_transaction(state):
    restore(
        state["previous"]
    )

    clear()


def watchdog():
    while True:
        handle = locked()

        try:
            state = load()

            if state is None:
                return

            remaining = (
                state["deadline"]
                - time.time()
            )

            if remaining <= 0:
                restore_transaction(
                    state
                )
                return

        finally:
            handle.close()

        time.sleep(
            min(remaining, 0.2)
        )


def apply(targets):
    handle = locked()

    try:
        if load() is not None:
            raise RuntimeError(
                "Another display transaction is active"
            )

        current = monitors()

        requested = validate(
            targets,
            current
        )

        state = {
            "id": str(uuid.uuid4()),
            "previous": current,
            "deadline": (
                time.time() + TIMEOUT
            )
        }

        save(state)

        try:
            process = subprocess.Popen(
                [
                    sys.executable,
                    str(
                        Path(__file__).resolve()
                    ),
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
            for target in requested:
                if time.time() >= state["deadline"]:
                    raise RuntimeError(
                        "Apply deadline reached"
                    )

                apply_monitor(
                    target
                )

            verify(
                requested
            )

        except Exception as error:
            try:
                restore_transaction(
                    state
                )

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


def confirm():
    handle = locked()

    try:
        state = load()

        if state is None:
            raise RuntimeError(
                "No active transaction"
            )

        if time.time() >= state["deadline"]:
            restore_transaction(
                state
            )

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

        restore_transaction(
            state
        )

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
        raise ValueError(
            "Missing command"
        )

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
