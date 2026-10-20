import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland

Item {
    id: root
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.QsWindow.window?.screen)
    readonly property var minimized: HyprlandData.windowList
        .filter(w => w.workspace?.name === "special:minimized")

    implicitWidth: row.implicitWidth

    // Absorbe el click izquierdo en toda el área: evita que llegue al
    // MouseArea de BarContent que abre el sidebar izquierdo.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
    }

    RowLayout {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        spacing: 6

        Repeater {
            model: root.minimized
            delegate: MouseArea {
                required property var modelData
                implicitWidth: 24
                implicitHeight: 24
                cursorShape: Qt.PointingHandCursor

                onClicked: {
                    const ws = HyprlandData.monitors[root.monitor?.id]?.activeWorkspace.id
                    if (ws === undefined) return
                    Quickshell.execDetached(["hyprctl", "dispatch",
                        `hl.dsp.window.move({ workspace = ${ws}, follow = true, window = "address:${modelData.address}" })`])
                }

                IconImage {
                    anchors.fill: parent
                    source: Quickshell.iconPath(AppSearch.guessIcon(modelData.class), "image-missing")
                }
            }
        }
    }
}
