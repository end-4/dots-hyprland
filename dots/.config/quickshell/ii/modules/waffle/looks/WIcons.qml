pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.UPower
import qs.services

Singleton {
    id: root

    property string internetIcon: {
        if (Network.ethernet) return "ethernet";
        if (Network.wifiEnabled) {
            const strength = Network.networkStrength;
            if (strength > 75) return "wifi-1";
            if (strength > 50) return "wifi-2";
            if (strength > 25) return "wifi-3";
            return "wifi-4";
        }
        if (Network.wifiStatus === "connecting") return "wifi-4";
        if (Network.wifiStatus === "disconnected") return "wifi-off";
        if (Network.wifiStatus === "disabled") return "wifi-off";
        return "wifi-warning";
    }

    property string batteryIcon: {
        if (Battery.isCharging) return "battery-charge";
        if (Battery.isCriticalAndNotCharging) return "battery-warning";
        if (Battery.percentage >= 0.9) return "battery-full";
        return `battery-${Math.ceil(Battery.percentage * 10)}`;
    }

    property string volumeIcon: {
        const muted = Audio.sink?.audio.muted ?? false;
        const volume = Audio.sink?.audio.volume ?? 0;
        if (muted)
            return volume > 0 ? "speaker-off" : "speaker-none";
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
        switch(PowerProfiles.profile) {
            case PowerProfile.PowerSaver: return "leaf-two";
            case PowerProfile.Balanced: return "flash-on";
            case PowerProfile.Performance: return "fire";
        }
    }
}
