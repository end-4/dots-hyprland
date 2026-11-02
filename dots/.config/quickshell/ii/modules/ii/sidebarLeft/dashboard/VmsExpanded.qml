import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import "Fmt.js" as Fmt

// Lista de VMs con estado, recursos y acciones (iniciar, pausar, apagar, forzar apagado...).
Item {
    id: root
    signal back()

    NumberAnimation on opacity { from: 0; to: 1; duration: 180 }

    LiveListModel {
        id: listModel
        key: "name"
        template: ({ name: "", state: "", vcpus: 1, cpu: 0, mem: 0, memMax: 0, ip: "" })
    }
    Connections {
        target: Vms
        function onVmsChanged() { listModel.sync(Vms.vms) }
    }
    Component.onCompleted: listModel.sync(Vms.vms)

    function busyLabel(a) {
        return a === "start" ? Translation.tr("Starting…")
            : a === "shutdown" ? Translation.tr("Shutting down…")
            : a === "reboot" ? Translation.tr("Rebooting…")
            : a === "destroy" ? Translation.tr("Forcing off…")
            : a === "suspend" ? Translation.tr("Pausing…") : Translation.tr("Resuming…");
    }

    function stateLabel(s) {
        return s === "running" ? Translation.tr("Running")
            : s === "paused" ? Translation.tr("Paused")
            : s === "shutoff" ? Translation.tr("Shut off")
            : Translation.tr("Crashed");
    }
    function stateColor(s) {
        return s === "running" ? Appearance.m3colors.m3primary
            : s === "paused" ? Appearance.m3colors.m3tertiary
            : s === "shutoff" ? Appearance.colors.colSubtext : Appearance.m3colors.m3error;
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Rectangle {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                radius: 18
                color: backArea.containsMouse ? Appearance.colors.colLayer1Hover : Appearance.colors.colLayer1
                scale: backArea.pressed ? 0.92 : 1
                Behavior on scale { NumberAnimation { duration: 80 } }
                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "arrow_back"
                    iconSize: 20
                    color: Appearance.colors.colOnLayer1
                }
                MouseArea {
                    id: backArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.back()
                }
            }
            MaterialSymbol { text: "dns"; iconSize: 22; color: Appearance.m3colors.m3primary }
            StyledText {
                Layout.fillWidth: true
                text: Translation.tr("Virtual machines")
                color: Appearance.colors.colOnLayer1
                font.pixelSize: Appearance.font.pixelSize.larger
            }
        }

        DashCard {
            Layout.fillWidth: true
            Layout.fillHeight: true
            hoverable: false

            StyledText {
                anchors.centerIn: parent
                visible: Vms.vms.length === 0
                width: parent.width - 40
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                text: Vms.ok ? Translation.tr("No virtual machines found") : Vms.errorText
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.small
            }

            ListView {
                anchors.fill: parent
                anchors.margins: 8
                clip: true
                spacing: 8
                model: listModel
                displaced: Transition { NumberAnimation { properties: "y"; duration: 300; easing.type: Easing.OutCubic } }
                move: Transition { NumberAnimation { properties: "y"; duration: 300; easing.type: Easing.OutCubic } }
                add: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 250 } }
                remove: Transition { NumberAnimation { property: "opacity"; to: 0; duration: 150 } }
                delegate: Rectangle {
                    id: card
                    required property var model
                    readonly property string st: model.state
                    readonly property string busyAction: Vms.pending[model.name] || ""
                    readonly property var result: Vms.results[model.name]
                    property bool confirming: false     // "Force off" pide una segunda pulsacion
                    width: ListView.view.width
                    height: col.implicitHeight + 20
                    radius: Appearance.rounding.small
                    color: Appearance.colors.colLayer2

                    Timer { id: confirmTimer; interval: 3000; onTriggered: card.confirming = false }

                    Column {
                        id: col
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                        spacing: 6

                        RowLayout {
                            width: parent.width
                            spacing: 8
                            Rectangle {
                                Layout.preferredWidth: 10
                                Layout.preferredHeight: 10
                                radius: 5
                                color: root.stateColor(card.st)
                            }
                            StyledText {
                                Layout.fillWidth: true
                                text: card.model.name
                                elide: Text.ElideRight
                                color: Appearance.colors.colOnLayer1
                                font.pixelSize: Appearance.font.pixelSize.normal
                            }
                            StyledText {
                                text: root.stateLabel(card.st)
                                color: root.stateColor(card.st)
                                font.pixelSize: Appearance.font.pixelSize.smaller
                            }
                        }

                        StyledText {
                            width: parent.width
                            elide: Text.ElideRight
                            color: Appearance.colors.colSubtext
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            text: card.st === "running"
                                ? (card.model.ip ? "IP " + card.model.ip + " · " : "")
                                    + "RAM " + Fmt.mem(card.model.mem) + " / " + Fmt.mem(card.model.memMax)
                                    + " · CPU " + Fmt.pct(card.model.cpu)
                                : Fmt.mem(card.model.memMax) + " · " + card.model.vcpus + " vCPU"
                        }

                        Row {   // accion en curso: sustituye a los botones hasta que cambie el estado
                            visible: card.busyAction !== ""
                            spacing: 8
                            MaterialSymbol {
                                id: spinner
                                text: "progress_activity"
                                iconSize: 18
                                color: Appearance.m3colors.m3primary
                                RotationAnimator on rotation {
                                    from: 0; to: 360; duration: 1000
                                    loops: Animation.Infinite
                                    running: spinner.visible
                                }
                            }
                            StyledText {
                                anchors.verticalCenter: spinner.verticalCenter
                                text: root.busyLabel(card.busyAction)
                                color: Appearance.colors.colSubtext
                                font.pixelSize: Appearance.font.pixelSize.small
                            }
                        }

                        StyledText {   // el ultimo error de virsh, si lo hubo
                            visible: card.result !== undefined && !card.result.ok
                            width: parent.width
                            wrapMode: Text.Wrap
                            color: Appearance.m3colors.m3error
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            text: card.result ? Vms.describeError(card.result.err) : ""
                        }

                        Flow {
                            visible: card.busyAction === ""
                            width: parent.width
                            spacing: 6
                            SmallButton {
                                visible: card.st === "shutoff"
                                icon: "play_arrow"; label: Translation.tr("Start")
                                onClicked: Vms.cmd("start:" + card.model.name)
                            }
                            SmallButton {
                                visible: card.st === "running"
                                icon: "pause"; label: Translation.tr("Pause")
                                onClicked: Vms.cmd("suspend:" + card.model.name)
                            }
                            SmallButton {
                                visible: card.st === "paused"
                                icon: "play_arrow"; label: Translation.tr("Resume")
                                onClicked: Vms.cmd("resume:" + card.model.name)
                            }
                            SmallButton {
                                visible: card.st === "running"
                                icon: "power_settings_new"; label: Translation.tr("Shut down")
                                onClicked: Vms.cmd("shutdown:" + card.model.name)
                            }
                            SmallButton {
                                visible: card.st === "running"
                                icon: "restart_alt"; label: Translation.tr("Reboot")
                                onClicked: Vms.cmd("reboot:" + card.model.name)
                            }
                            SmallButton {
                                visible: card.st === "running" && card.model.ip !== ""
                                icon: "content_copy"; label: Translation.tr("Copy IP")
                                onClicked: Quickshell.execDetached(["wl-copy", card.model.ip])
                            }
                            SmallButton {
                                visible: card.st !== "shutoff"
                                danger: true
                                icon: "power_off"
                                label: card.confirming ? Translation.tr("Confirm?") : Translation.tr("Force off")
                                onClicked: {
                                    if (card.confirming) {
                                        card.confirming = false;
                                        Vms.cmd("destroy:" + card.model.name);
                                    } else {
                                        card.confirming = true;
                                        confirmTimer.restart();
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
