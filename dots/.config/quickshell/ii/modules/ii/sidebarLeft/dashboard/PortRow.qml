import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

// Fila de un puerto en escucha; al pulsarla se despliegan detalles y acciones.
Rectangle {
    id: row
    required property var model
    property bool open: false
    signal toggle()

    readonly property string busy: PortsServices.pending[model.key] || ""
    readonly property var result: PortsServices.results[model.key]
    property string confirming: ""
    readonly property color expoColor: model.exposure === "all" ? Appearance.m3colors.m3error
        : model.exposure === "lan" ? Appearance.m3colors.m3tertiary : Appearance.colors.colSubtext
    readonly property string expoLabel: model.exposure === "all" ? Translation.tr("all interfaces")
        : model.exposure === "lan" ? Translation.tr("LAN") : Translation.tr("local only")

    function busyLabel(a) {
        return a === "stop" ? Translation.tr("Stopping…")
            : a === "reveal" ? Translation.tr("Identifying…") : Translation.tr("Terminating…");
    }
    // Primera pulsacion: pide confirmacion (3 s). Segunda: ejecuta.
    function request(id, run) {
        if (confirming === id) { confirming = ""; run(); }
        else { confirming = id; confirmTimer.restart(); }
    }
    function kill(sig) {
        PortsServices.act(model.key, { cmd: "kill", pid: model.pid, sig: sig, comm: model.comm, key: model.key }, sig);
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
        spacing: 6

        RowLayout {
            width: parent.width
            height: 30
            spacing: 8
            Rectangle {
                Layout.preferredWidth: 10
                Layout.preferredHeight: 10
                radius: 5
                color: row.expoColor
            }
            StyledText {
                text: row.model.proto + " " + row.model.port
                color: Appearance.colors.colOnLayer1
                font.pixelSize: Appearance.font.pixelSize.small
            }
            StyledText {
                Layout.fillWidth: true
                text: row.expoLabel
                elide: Text.ElideRight
                color: row.expoColor
                font.pixelSize: Appearance.font.pixelSize.smaller
            }
            StyledText {
                Layout.maximumWidth: 150
                text: row.model.proc !== "" ? row.model.proc : "—"
                elide: Text.ElideRight
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.small
            }
        }

        Column {
            visible: row.open
            width: parent.width
            spacing: 6

            StyledText {
                width: parent.width
                wrapMode: Text.Wrap
                text: Translation.tr("Address %1").arg(row.model.addrs)
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.smaller
            }
            StyledText {
                width: parent.width
                wrapMode: Text.Wrap
                text: row.model.pid > 0
                    ? Translation.tr("Process %1 (PID %2)").arg(row.model.proc).arg(row.model.pid)
                    : Translation.tr("Owner unknown (system process)")
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.smaller
            }
            StyledText {
                visible: row.model.unit !== ""
                width: parent.width
                wrapMode: Text.Wrap
                text: Translation.tr("Unit %1 (%2)").arg(row.model.unit).arg(row.model.uscope)
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
                    visible: row.model.own && row.model.pid > 0
                    icon: "close"
                    label: row.confirming === "term" ? Translation.tr("Confirm?") : Translation.tr("Terminate")
                    onClicked: row.request("term", () => row.kill("TERM"))
                }
                SmallButton {
                    visible: row.model.own && row.model.pid > 0
                    danger: true
                    icon: "dangerous"
                    label: row.confirming === "kill" ? Translation.tr("Confirm?") : Translation.tr("Force kill")
                    onClicked: row.request("kill", () => row.kill("KILL"))
                }
                SmallButton {
                    visible: row.model.unit !== ""
                    danger: row.model.critical
                    icon: "stop"
                    label: row.confirming === "stop" ? Translation.tr("Confirm?") : Translation.tr("Stop service")
                    onClicked: row.request("stop", () => PortsServices.act(row.model.key,
                        { cmd: "svc", scope: row.model.uscope, action: "stop", unit: row.model.unit, key: row.model.key }, "stop"))
                }
                SmallButton {
                    visible: row.model.pid === 0
                    icon: "admin_panel_settings"
                    label: Translation.tr("Identify owners")
                    onClicked: PortsServices.act(row.model.key, { cmd: "reveal", key: row.model.key }, "reveal")
                }
            }
        }
    }

    MouseArea {
        id: headerArea
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: 38
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: row.toggle()
    }
}
