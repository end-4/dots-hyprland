import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.widgets

/**
 * Quick Tools / Scripts settings page.
 * One-click system maintenance actions inspired by dots-fork quickscripts.
 */
ContentPage {
    forceWidth: true

    // ── Reusable script button ─────────────────────────────────────────────
    component ScriptButton: Item {
        id: scriptBtn
        required property string icon
        required property string label
        required property string command
        property string tooltip: ""
        property string runningLabel: Translation.tr("Running…")
        property string doneLabel:    Translation.tr("Done!")
        property bool   confirmFirst: false

        implicitHeight: 52
        Layout.fillWidth: true

        property bool running: false
        property bool done: false

        Process {
            id: proc
            onExited: (exitCode) => {
                scriptBtn.running = false
                scriptBtn.done = true
                doneTimer.restart()
            }
        }
        Timer { id: doneTimer; interval: 2500; onTriggered: scriptBtn.done = false }

        RippleButtonWithIcon {
            anchors.fill: parent
            materialIcon: scriptBtn.done ? "check" : scriptBtn.icon
            mainText: scriptBtn.running ? scriptBtn.runningLabel : (scriptBtn.done ? scriptBtn.doneLabel : scriptBtn.label)
            enabled: !scriptBtn.running
            buttonRadius: Appearance.rounding.small
            onClicked: {
                scriptBtn.running = true
                scriptBtn.done = false
                proc.command = ["bash", "-c", scriptBtn.command]
                proc.running = true
            }
            StyledToolTip { text: scriptBtn.tooltip.length > 0 ? scriptBtn.tooltip : scriptBtn.command }
        }
    }

    ContentSection {
        icon: "package_2"
        title: Translation.tr("Package Management (Arch)")

        ConfigRow {
            ScriptButton {
                icon: "system_update_alt"
                label: Translation.tr("Update all packages (pacman + AUR)")
                command: `${Config.options.apps.terminal} -e fish -c 'yay -Syu; read'`
                tooltip: Translation.tr("Runs yay -Syu to update all packages including AUR")
            }
        }
        ConfigRow {
            ScriptButton {
                icon: "cleaning_services"
                label: Translation.tr("Remove orphan packages")
                command: `${Config.options.apps.terminal} -e fish -c 'pacman -Qtdq | pkexec pacman -Rns -; read'`
                tooltip: Translation.tr("Removes packages that are no longer needed")
            }
            ScriptButton {
                icon: "delete_sweep"
                label: Translation.tr("Clear pacman cache")
                command: `${Config.options.apps.terminal} -e fish -c 'pkexec paccache -r; read'`
                tooltip: Translation.tr("Keeps only 3 most recent versions of each package")
            }
        }
    }

    ContentSection {
        icon: "terminal"
        title: Translation.tr("Shell")

        ConfigRow {
            ScriptButton {
                icon: "refresh"
                label: Translation.tr("Reload Quickshell")
                command: `qs reload || killall quickshell && sleep 0.5 && quickshell`
                tooltip: Translation.tr("Restarts the Quickshell desktop shell")
            }
            ScriptButton {
                icon: "refresh"
                label: Translation.tr("Restart Hyprland")
                command: `hyprctl reload`
                tooltip: Translation.tr("Reloads the Hyprland config")
            }
        }
        ScriptButton {
            icon: "edit"
            label: Translation.tr("Open shell config file")
            command: `${Config.options.apps.terminal} -e ${Config.options.apps.terminal} fish -c 'vim ${Directories.shellConfigPath}; read'`
            tooltip: Translation.tr("Opens the illogical-impulse config.json in your terminal editor")
        }
    }

    ContentSection {
        icon: "info"
        title: Translation.tr("System Info")

        ConfigRow {
            ScriptButton {
                icon: "monitor_heart"
                label: Translation.tr("System info (fastfetch)")
                command: `${Config.options.apps.terminal} -e fish -c 'fastfetch; read'`
                tooltip: Translation.tr("Shows system information in a terminal window")
            }
            ScriptButton {
                icon: "storage"
                label: Translation.tr("Disk usage (ncdu)")
                command: `${Config.options.apps.terminal} -e fish -c 'ncdu /; read'`
                tooltip: Translation.tr("Interactive disk usage analyzer")
            }
        }
        ScriptButton {
            icon: "bar_chart"
            label: Translation.tr("Resource monitor (btop)")
            command: `${Config.options.apps.terminal} -e fish -c 'btop; read'`
            tooltip: Translation.tr("Opens the btop resource monitor")
        }
    }

    ContentSection {
        icon: "download"
        title: Translation.tr("YouTube Downloader")

        StyledText {
            text: Translation.tr("Queued: %1 download(s)  |  Completed: %2").arg(
                YtDownloader.queue.filter(i => i.status === "downloading" || i.status === "queued").length
            ).arg(
                YtDownloader.queue.filter(i => i.status === "done").length
            )
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colSubtext
        }

        ConfigRow {
            ScriptButton {
                icon: "settings"
                label: Translation.tr("Open downloader settings")
                command: `quickshell -p ${Qt.resolvedUrl("../../../settings.qml")}`
                tooltip: Translation.tr("Opens the full settings app on the Downloader tab")
            }
        }
    }
}
