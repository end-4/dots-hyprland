pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Services.UPower
import qs.modules.common
import qs.services
import qs.modules.ii.island

// Batteries of wireless peripherals (mouse, headset, keyboard) reported by UPower.
// Below 15% a card drops once per device; below 30% the idle pill shows a glance item for it.
Item {
    id: root

    readonly property real lowPct: 0.15
    // Re-arms the low card, and the glance item shows only below this level.
    readonly property real recoverPct: 0.30

    // nativePath -> last percentage (0..1). Kept across delegate recreation, so a device list change
    // does not reset the crossing check.
    property var last: ({})
    // nativePath -> true once the low card was pushed; cleared above recoverPct.
    property var warned: ({})
    // nativePath -> true while a glance item is shown.
    property var glanced: ({})

    // The laptop's own battery (and its DisplayDevice) is shown by end-4's bar, not here.
    function isPeripheral(dev) {
        return !dev.isLaptopBattery && dev.nativePath !== "DisplayDevice" && dev.type !== UPowerDeviceType.LinePower;
    }

    function label(dev) {
        return dev.model && dev.model.length > 0 ? dev.model : Translation.tr("Device");
    }

    // Runs on every change, and once when a device first appears (initial = true): that first value
    // is only a baseline, so a device that is already low at startup gets no card.
    function update(dev, initial) {
        if (!dev.ready)
            return;
        const key = dev.nativePath;
        const p = dev.percentage;
        const prev = root.last[key];
        root.last[key] = p;

        if (!initial && prev !== undefined && prev >= root.lowPct && p < root.lowPct && !root.warned[key]) {
            root.warned[key] = true;
            IslandState.pushCard("bat-" + key, {
                icon: "battery_alert",
                title: Translation.tr("%1 battery low").arg(root.label(dev)),
                body: Translation.tr("%1% left").arg(Math.round(p * 100)),
                accent: String(Appearance.colors.colError),
                ttl: 8000
            });
        }
        if (p > root.recoverPct)
            root.warned[key] = false;

        if (p < root.recoverPct) {
            IslandState.setGlance("bat-" + key, {
                icon: "battery_3_bar",
                text: Translation.tr("%1 %2%").arg(root.label(dev)).arg(Math.round(p * 100))
            });
            root.glanced[key] = true;
        } else if (root.glanced[key]) {
            IslandState.clearGlance("bat-" + key);
            root.glanced[key] = false;
        }
    }

    // Drops glance items of devices that were unplugged or turned off.
    function prune() {
        const present = {};
        for (const d of UPower.devices.values) {
            if (root.isPeripheral(d))
                present[d.nativePath] = true;
        }
        for (const key in root.glanced) {
            if (!present[key] && root.glanced[key]) {
                IslandState.clearGlance("bat-" + key);
                root.glanced[key] = false;
            }
        }
    }

    Connections {
        target: UPower.devices
        function onValuesChanged() { root.prune(); }
    }

    Instantiator {
        model: UPower.devices.values.filter(d => root.isPeripheral(d))

        delegate: Connections {
            id: link
            required property var modelData
            target: modelData

            function onPercentageChanged() { root.update(link.modelData, false); }
            function onReadyChanged() { root.update(link.modelData, false); }

            Component.onCompleted: root.update(link.modelData, true)
        }
    }
}
