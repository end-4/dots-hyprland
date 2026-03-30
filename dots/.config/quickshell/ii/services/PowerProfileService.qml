pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.UPower
import qs.modules.common
import qs.modules.common.functions

/**
 * Power Profile Service
 *
 * Provides:
 * - Cycle through power profiles (PowerSaver → Balanced → Performance → ...)
 * - GlobalShortcut for Fn+Q (registered as "powerProfileCycle")
 * - IPC handler for scripting: qs ipc call powerProfile cycle
 * - Desktop notification on profile change
 *
 * Uses Quickshell's built-in PowerProfiles / PowerProfile enums from UPower.
 */
Singleton {
    id: root

    readonly property string currentProfileName: {
        switch(PowerProfiles.profile) {
            case PowerProfile.PowerSaver:   return Translation.tr("Power Saver")
            case PowerProfile.Balanced:     return Translation.tr("Balanced")
            case PowerProfile.Performance:  return Translation.tr("Performance")
            default:                        return Translation.tr("Unknown")
        }
    }

    readonly property string currentProfileIcon: {
        switch(PowerProfiles.profile) {
            case PowerProfile.PowerSaver:   return "energy_savings_leaf"
            case PowerProfile.Balanced:     return "airwave"
            case PowerProfile.Performance:  return "local_fire_department"
            default:                        return "power_settings_new"
        }
    }

    readonly property int profileIndex: {
        switch(PowerProfiles.profile) {
            case PowerProfile.PowerSaver:   return 0
            case PowerProfile.Balanced:     return 1
            case PowerProfile.Performance:  return 2
            default:                        return 1
        }
    }

    signal profileChanged(string profileName)

    function cycle() {
        if (PowerProfiles.hasPerformanceProfile) {
            switch(PowerProfiles.profile) {
                case PowerProfile.PowerSaver:
                    PowerProfiles.profile = PowerProfile.Balanced
                    break;
                case PowerProfile.Balanced:
                    PowerProfiles.profile = PowerProfile.Performance
                    break;
                case PowerProfile.Performance:
                    PowerProfiles.profile = PowerProfile.PowerSaver
                    break;
            }
        } else {
            PowerProfiles.profile = PowerProfiles.profile === PowerProfile.Balanced
                ? PowerProfile.PowerSaver
                : PowerProfile.Balanced
        }
        root.profileChanged(root.currentProfileName)
        _showNotification()
    }

    function setProfile(name) {
        switch(name.toLowerCase()) {
            case "power-saver":
            case "powersaver":
                PowerProfiles.profile = PowerProfile.PowerSaver; break;
            case "balanced":
                PowerProfiles.profile = PowerProfile.Balanced; break;
            case "performance":
                PowerProfiles.profile = PowerProfile.Performance; break;
        }
        root.profileChanged(root.currentProfileName)
        _showNotification()
    }

    function _showNotification() {
        // Use notify-send for a desktop notification on profile change
        Quickshell.execDetached([
            "notify-send",
            "-i", "power-profile-" + (PowerProfiles.profile === PowerProfile.Performance
                ? "performance" : PowerProfiles.profile === PowerProfile.PowerSaver
                ? "power-saver" : "balanced") + "-symbolic",
            "-t", "2000",
            "-h", "string:x-canonical-private-synchronous:power-profile",
            Translation.tr("Power Profile"),
            root.currentProfileName
        ])
    }

    // ── Fn+Q keybind ──────────────────────────────────────────────────────
    GlobalShortcut {
        name: "powerProfileCycle"
        description: "Cycle power profile (Fn+Q)"
        onPressed: root.cycle()
    }

    // ── IPC: qs ipc call powerProfile cycle ───────────────────────────────
    IpcHandler {
        target: "powerProfile"

        function cycle(): void {
            root.cycle()
        }

        function set(profileName: string): void {
            root.setProfile(profileName)
        }
    }
}
