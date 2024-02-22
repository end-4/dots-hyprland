#!/usr/bin/env python

import sys
from dataclasses import dataclass
from signal import SIGINT, SIGTERM, signal
from threading import Event
import setproctitle

from pywayland.client.display import Display
from pywayland.protocol.idle_inhibit_unstable_v1.zwp_idle_inhibit_manager_v1 import (
    ZwpIdleInhibitManagerV1,
)
from pywayland.protocol.wayland.wl_compositor import WlCompositor
from pywayland.protocol.wayland.wl_registry import WlRegistryProxy
from pywayland.protocol.wayland.wl_surface import WlSurface


@dataclass
class GlobalRegistry:
    surface: WlSurface | None = None
    inhibit_manager: ZwpIdleInhibitManagerV1 | None = None


def handle_registry_global(
    wl_registry: WlRegistryProxy, id_num: int, iface_name: str, version: int
) -> None:
    global_registry: GlobalRegistry = wl_registry.user_data or GlobalRegistry()

    if iface_name == "wl_compositor":
        compositor = wl_registry.bind(id_num, WlCompositor, version)
        global_registry.surface = compositor.create_surface()  # type: ignore
    elif iface_name == "zwp_idle_inhibit_manager_v1":
        global_registry.inhibit_manager = wl_registry.bind(
            id_num, ZwpIdleInhibitManagerV1, version
        )


def main() -> None:
    done = Event()
    signal(SIGINT, lambda _, __: done.set())
    signal(SIGTERM, lambda _, __: done.set())

    global_registry = GlobalRegistry()

    display = Display()
    display.connect()

    registry = display.get_registry()  # type: ignore
    registry.user_data = global_registry
    registry.dispatcher["global"] = handle_registry_global

    def shutdown() -> None:
        display.dispatch()
        display.roundtrip()
        display.disconnect()

    display.dispatch()
    display.roundtrip()

    if global_registry.surface is None or global_registry.inhibit_manager is None:
        print("Wayland seems not to support idle_inhibit_unstable_v1 protocol.")
        shutdown()
        sys.exit(1)

    inhibitor = global_registry.inhibit_manager.create_inhibitor(  # type: ignore
        global_registry.surface
    )

    display.dispatch()
    display.roundtrip()

    print("Inhibiting idle...")
    done.wait()
    print("Shutting down...")

    inhibitor.destroy()

    shutdown()


if __name__ == "__main__":
    setproctitle.setproctitle("wayland-idle-inhibitor.py")
    main()
