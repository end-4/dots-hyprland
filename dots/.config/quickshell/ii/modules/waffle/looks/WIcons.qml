pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.UPower
import qs.services

Singleton {
    id: root

    function pathForName(iconName) {
        return Quickshell.shellPath(`assets/icons/fluent/${iconName}.svg`);
    }

    function wifiIconForStrength(strength) {
        if (strength > 75)
            return "wifi-1";
        if (strength > 50)
            return "wifi-2";
        if (strength > 25)
            return "wifi-3";
        return "wifi-4";
    }

    property string internetIcon: {
        if (Network.ethernet)
            return "ethernet";
        if (Network.wifiEnabled) {
            const strength = Network.networkStrength;
            return wifiIconForStrength(strength);
        }
        if (Network.wifiStatus === "connecting")
            return "wifi-4";
        if (Network.wifiStatus === "disconnected")
            return "wifi-off";
        if (Network.wifiStatus === "disabled")
            return "wifi-off";
        return "wifi-warning";
    }

    property string batteryIcon: {
        if (Battery.isCharging)
            return "battery-charge";
        if (Battery.isCriticalAndNotCharging)
            return "battery-warning";
        if (Battery.percentage >= 0.9)
            return "battery-full";
        return `battery-0`;
    }

    property string batteryLevelIcon: {
        const discreteLevel = Math.ceil(Battery.percentage * 10);
        return `battery-${discreteLevel > 9 ? "full" : discreteLevel}`;
    }

    property string volumeIcon: {
        const muted = Audio.sink?.audio.muted ?? false;
        const volume = Audio.sink?.audio.volume ?? 0;
        if (muted)
            return "speaker-mute";
        if (volume == 0)
            return "speaker-none";
        if (volume < 0.5)
            return "speaker-1";
        return "speaker";
    }

    property string micIcon: {
        const muted = Audio.source?.audio.muted ?? false;
        return muted ? "mic-off" : "mic";
    }

    property string bluetoothIcon: BluetoothStatus.connected ? "bluetooth-connected" : BluetoothStatus.enabled ? "bluetooth" : "bluetooth-disabled"

    property string nightLightIcon: Hyprsunset.active ? "weather-moon" : "weather-moon-off"

    property string notificationsIcon: Notifications.silent ? "alert-snooze" : "alert"

    property string powerProfileIcon: {
        switch (PowerProfiles.profile) {
        case PowerProfile.PowerSaver:
            return "leaf-two";
        case PowerProfile.Balanced:
            return "flash-on";
        case PowerProfile.Performance:
            return "fire";
        }
    }

    function audioDeviceIcon(node) {
        if (!node.isSink)
            return "mic-on";
        const monitor = /monitor|hdmi/i;
        const headphones = /headset|headphone|bluez|wireless/i;
        const speakers = /speaker|output/i;
        if (monitor.test(node.nickname) || monitor.test(node.description) || monitor.test(node.name)) {
            return "desktop-speaker";
        }
        if (headphones.test(node.nickname) || headphones.test(node.description) || headphones.test(node.name)) {
            return "headphones";
        }
        if (speakers.test(node.nickname) || speakers.test(node.description) || speakers.test(node.name)) {
            return "speaker";
        }
        return "speaker";
    }

    function audioAppIcon(node) {
        let icon;
        icon = AppSearch.guessIcon(node?.properties["application.icon-name"] ?? "");
        if (AppSearch.iconExists(icon))
            return icon;
        icon = AppSearch.guessIcon(node?.properties["node.name"] ?? "");
        return icon;
    }

    function bluetoothDeviceIcon(device) {
        const systemIconName = device?.icon || "";
        if (systemIconName.includes("headset") || systemIconName.includes("headphones"))
            return "headphones";
        if (systemIconName.includes("audio"))
            return "speaker";
        if (systemIconName.includes("phone"))
            return "phone";
        if (systemIconName.includes("mouse"))
            return "bluetooth";
        if (systemIconName.includes("keyboard"))
            return "keyboard";
        return "bluetooth";
    }

    function fluentFromMaterial(icon) {
        switch (icon) {
        case "calculate":
            return "calculator";
        case "keyboard_return":
            return "arrow-enter-left";
        case "open_in_new":
            return "open";
        case "settings_suggest":
            return "wand";
        case "terminal":
            return "app-generic";
        case "travel_explore":
            return "globe-search";
        case "keep":
            return "pin";
        case "keep_off":
            return "pin-off";
        default:
            return "apps";
        }
    }

    function guessIconForName(name) {
        const lowerName = name.toLowerCase();
        if (lowerName.includes("app") || lowerName.includes("desktop"))
            return "apps";
        if (lowerName.includes("news"))
            return "news";
        if (lowerName.includes("new") || lowerName.includes("create") || lowerName.includes("add"))
            return "add";
        if (lowerName.includes("open"))
            return "open";
        if (lowerName.includes("friends") || lowerName.includes("contact") || lowerName.includes("family"))
            return "people";
        if (lowerName.includes("community"))
            return "people-team";
        if (lowerName.includes("library"))
            return "library";
        if (lowerName.includes("setting"))
            return "settings";
        if (lowerName.includes("gallery"))
            return "image-copy";
        if (lowerName.includes("server"))
            return "server";
        if (lowerName.includes("picture") || lowerName.includes("photo") || lowerName.includes("image"))
            return "image";
        if (lowerName.includes("store") || lowerName.includes("shop"))
            return "store-microsoft";
        if (lowerName.includes("record") || lowerName.includes("capture"))
            return "record";
        if (lowerName.includes("screen") || lowerName.includes("display") || lowerName.includes("monitor") || lowerName.includes("desktop"))
            return "desktop";

        return "apps";
    }
}
