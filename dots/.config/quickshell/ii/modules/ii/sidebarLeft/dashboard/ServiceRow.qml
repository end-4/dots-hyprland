import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import "Fmt.js" as Fmt

// Fila de un servicio de systemd; al pulsarla se despliegan estado y acciones.
Rectangle {
    id: row
    required property var model
    property bool open: false
    signal toggle()

    readonly property string busy: PortsServices.pending[model.key] || ""
    readonly property var result: PortsServices.results[model.key]
    readonly property bool isActive: model.active === "active" || model.active === "activating"
    property string confirming: ""
    readonly property color stateColor: model.active === "failed" ? Appearance.m3colors.m3error
        : model.active === "active" ? Appearance.m3colors.m3primary
        : model.active === "activating" ? Appearance.m3colors.m3tertiary : Appearance.colors.colSubtext

    function busyLabel(a) {
        return a === "start" ? Translation.tr("Starting…")
            : a === "stop" ? Translation.tr("Stopping…")
            : a === "restart" ? Translation.tr("Restarting…")
            : a === "enable" ? Translation.tr("Enabling…")
            : a === "disable" ? Translation.tr("Disabling…")
            : a === "freeze" ? Translation.tr("Pausing…") : Translation.tr("Resuming…");
    }
    function svc(action) {
        PortsServices.act(model.key, { cmd: "svc", scope: model.scope, action: action, unit: model.unit, key: model.key }, action);
    }
    // Los servicios criticos piden una segunda pulsacion (3 s) antes de parar/reiniciar/deshabilitar/pausar.
    function request(id, action) {
        if (model.critical && confirming !== id) { confirming = id; confirmTimer.restart(); }
        else { confirming = ""; svc(action); }
    }

    width: ListView.view.width
    height: col.implicitHeight + 16
    radius: Appearance.rounding.small
    clip: true
    color: open ? Appearance.colors.colLayer2 : headerArea.containsMouse ? Appearance.colors.colLayer1Hover : "transparent"
    Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

    Timer { id: confirmTimer; interval: 3000; onTriggered: row.confirming = "" }

    Column {
        id: col
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 8 }
        spacing: 4

        RowLayout {
            width: parent.width
            spacing: 8
            Rectangle {
                Layout.preferredWidth: 10
                Layout.preferredHeight: 10
                radius: 5
                color: row.stateColor
            }
            StyledText {
                Layout.fillWidth: true
                text: row.model.name
                elide: Text.ElideRight
                color: Appearance.colors.colOnLayer1
                font.pixelSize: Appearance.font.pixelSize.small
            }
            MaterialSymbol {
                visible: row.model.critical
                text: "shield"
                iconSize: 15
                color: Appearance.m3colors.m3error
            }
            StyledText {
                visible: row.model.scope === "user"
                text: Translation.tr("user")
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.smaller
            }
            StyledText {
                visible: row.model.frozen
                text: Translation.tr("Paused")
                color: Appearance.m3colors.m3tertiary
                font.pixelSize: Appearance.font.pixelSize.smaller
            }
            StyledText {
                visible: row.model.mem > 0
                text: Fmt.mem(row.model.mem / 1024)
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.smaller
            }
        }
        StyledText {
            width: parent.width
            text: row.model.desc
            elide: Text.ElideRight
            color: Appearance.colors.colSubtext
            font.pixelSize: Appearance.font.pixelSize.smaller
        }

        Column {
            visible: row.open
            width: parent.width
            spacing: 6

            StyledText {
                width: parent.width
                wrapMode: Text.Wrap
                text: row.model.active + " (" + row.model.sub + ") · " + (row.model.enabled !== "" ? row.model.enabled : "—")
                    + " · " + row.model.unit
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.smaller
            }
            StyledText {
                visible: row.model.critical
                width: parent.width
                wrapMode: Text.Wrap
                text: Translation.tr("Critical system service: stopping it can break your session")
                color: Appearance.m3colors.m3error
                font.pixelSize: Appearance.font.pixelSize.smaller
            }

            BusyRow { visible: row.busy !== ""; label: row.busyLabel(row.busy) }

            StyledText {
                visible: row.result !== undefined && !row.result.ok
                width: parent.width
                wrapMode: Text.Wrap
                text: row.result ? PortsServices.describeError(row.result.err) : ""
                color: Appearance.m3colors.m3error
                font.pixelSize: Appearance.font.pixelSize.smaller
            }

            Flow {
                visible: row.busy === ""
                width: parent.width
                spacing: 6
                SmallButton {
                    visible: !row.isActive
                    icon: "play_arrow"; label: Translation.tr("Start")
                    onClicked: row.svc("start")
                }
                SmallButton {
                    visible: row.isActive
                    danger: row.model.critical
                    icon: "stop"
                    label: row.confirming === "stop" ? Translation.tr("Confirm?") : Translation.tr("Stop")
                    onClicked: row.request("stop", "stop")
                }
                SmallButton {
                    visible: row.isActive
                    danger: row.model.critical
                    icon: "restart_alt"
                    label: row.confirming === "restart" ? Translation.tr("Confirm?") : Translation.tr("Restart")
                    onClicked: row.request("restart", "restart")
                }
                SmallButton {
                    visible: row.isActive && !row.model.frozen
                    danger: row.model.critical
                    icon: "pause"
                    label: row.confirming === "freeze" ? Translation.tr("Confirm?") : Translation.tr("Pause")
                    onClicked: row.request("freeze", "freeze")
                }
                SmallButton {
                    visible: row.model.frozen
                    icon: "play_arrow"; label: Translation.tr("Resume")
                    onClicked: row.svc("thaw")
                }
                SmallButton {
                    visible: row.model.enabled === "disabled"
                    icon: "toggle_off"; label: Translation.tr("Enable")
                    onClicked: row.svc("enable")
                }
                SmallButton {
                    visible: row.model.enabled === "enabled"
                    danger: row.model.critical
                    icon: "toggle_on"
                    label: row.confirming === "disable" ? Translation.tr("Confirm?") : Translation.tr("Disable")
                    onClicked: row.request("disable", "disable")
                }
            }
        }
    }

    MouseArea {
        id: headerArea
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: 44
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: row.toggle()
    }
}
