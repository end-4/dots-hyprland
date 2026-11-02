import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import "Fmt.js" as Fmt

// Vista completa de descargas: activas / en espera / terminadas, con controles.
Item {
    id: root
    signal back()
    property string tab: "active"    // active | waiting | stopped

    NumberAnimation on opacity { from: 0; to: 1; duration: 180 }

    LiveListModel {
        id: listModel
        key: "gid"
        template: ({ gid: "", name: "", status: "", total: 0, done: 0, speed: 0, up: 0, conns: 0, err: "" })
    }
    onCurrentListChanged: listModel.sync(root.currentList)
    Component.onCompleted: listModel.sync(root.currentList)

    readonly property var currentList: tab === "active" ? Aria2.activeList
        : tab === "waiting" ? Aria2.waitingList : Aria2.stoppedList

    function statusLabel(s) {
        return s === "complete" ? Translation.tr("Completed")
            : s === "error" ? Translation.tr("Error")
            : s === "removed" ? Translation.tr("Cancelled")
            : s === "paused" ? Translation.tr("Paused")
            : s === "waiting" ? Translation.tr("Waiting") : "";
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
            MaterialSymbol { text: "download"; iconSize: 22; color: Appearance.m3colors.m3primary }
            StyledText {
                Layout.fillWidth: true
                text: Translation.tr("Downloads")
                color: Appearance.colors.colOnLayer1
                font.pixelSize: Appearance.font.pixelSize.larger
            }
        }

        DashCard {
            Layout.fillWidth: true
            Layout.preferredHeight: 110
            hoverable: false
            Column {
                anchors { left: parent.left; top: parent.top; margins: 14 }
                StyledText {
                    text: Aria2.ok ? "↓ " + Fmt.rate(Aria2.dlSpeed) : Translation.tr("aria2 unavailable")
                    color: Appearance.colors.colOnLayer1
                    font.pixelSize: Appearance.font.pixelSize.huge
                }
                StyledText {
                    text: Aria2.ok ? "↑ " + Fmt.rate(Aria2.ulSpeed) : Aria2.errorText
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.small
                }
            }
            Sparkline {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height: 50
                values: Aria2.speedHist
                maxValue: Aria2.speedPeak
                lineColor: Appearance.m3colors.m3primary
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            ActionButton {
                Layout.fillWidth: true; Layout.preferredWidth: 1; implicitHeight: 48
                enabled: Aria2.ok
                icon: "pause_circle"; label: Translation.tr("Pause all")
                onClicked: Aria2.cmd("pauseAll")
            }
            ActionButton {
                Layout.fillWidth: true; Layout.preferredWidth: 1; implicitHeight: 48
                enabled: Aria2.ok
                icon: "play_circle"; label: Translation.tr("Resume all")
                onClicked: Aria2.cmd("resumeAll")
            }
            ActionButton {
                Layout.fillWidth: true; Layout.preferredWidth: 1; implicitHeight: 48
                enabled: Aria2.ok && Aria2.nStopped > 0
                icon: "delete_sweep"; label: Translation.tr("Clear list")
                onClicked: Aria2.cmd("purge")
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            Repeater {
                model: [
                    { id: "active", label: Translation.tr("Active"), n: Aria2.nActive },
                    { id: "waiting", label: Translation.tr("Waiting"), n: Aria2.nWaiting },
                    { id: "stopped", label: Translation.tr("Finished"), n: Aria2.nStopped }
                ]
                delegate: Rectangle {
                    id: tabBtn
                    required property var modelData
                    readonly property bool selected: root.tab === modelData.id
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: 32
                    radius: 16
                    color: selected ? Appearance.m3colors.m3primary
                        : tabArea.containsMouse ? Appearance.colors.colLayer1Hover : Appearance.colors.colLayer1
                    StyledText {
                        anchors.centerIn: parent
                        text: tabBtn.modelData.label + " (" + tabBtn.modelData.n + ")"
                        color: tabBtn.selected ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer1
                        font.pixelSize: Appearance.font.pixelSize.smaller
                    }
                    MouseArea {
                        id: tabArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.tab = tabBtn.modelData.id
                    }
                }
            }
        }

        DashCard {
            Layout.fillWidth: true
            Layout.fillHeight: true
            hoverable: false

            StyledText {
                anchors.centerIn: parent
                visible: root.currentList.length === 0
                text: Aria2.ok ? Translation.tr("Nothing here") : Aria2.errorText
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.small
            }

            ListView {
                anchors.fill: parent
                anchors.margins: 8
                clip: true
                spacing: 6
                model: listModel
                displaced: Transition { NumberAnimation { properties: "y"; duration: 300; easing.type: Easing.OutCubic } }
                move: Transition { NumberAnimation { properties: "y"; duration: 300; easing.type: Easing.OutCubic } }
                add: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 250 } }
                remove: Transition { NumberAnimation { property: "opacity"; to: 0; duration: 150 } }
                delegate: Rectangle {
                    id: row
                    required property var model
                    readonly property bool finished: model.status === "complete"
                        || model.status === "error" || model.status === "removed"
                    readonly property real frac: model.total > 0 ? Math.min(1, model.done / model.total) : 0
                    width: ListView.view.width
                    height: 66
                    radius: Appearance.rounding.small
                    color: Appearance.colors.colLayer2

                    RowLayout {
                        anchors { fill: parent; margins: 8 }
                        spacing: 8

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3
                            StyledText {
                                Layout.fillWidth: true
                                text: row.model.name
                                elide: Text.ElideMiddle
                                color: Appearance.colors.colOnLayer1
                                font.pixelSize: Appearance.font.pixelSize.small
                            }
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 4
                                radius: 2
                                visible: !row.finished
                                color: Appearance.colors.colLayer1
                                Rectangle {
                                    width: parent.width * row.frac
                                    Behavior on width { NumberAnimation { duration: 1000; easing.type: Easing.Linear } }
                                    height: parent.height
                                    radius: 2
                                    color: row.model.status === "paused" ? Appearance.colors.colSubtext : Appearance.m3colors.m3primary
                                }
                            }
                            StyledText {
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                color: row.model.status === "error" ? Appearance.m3colors.m3error : Appearance.colors.colSubtext
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                text: row.finished
                                    ? root.statusLabel(row.model.status)
                                        + (row.model.err ? ": " + row.model.err : "")
                                        + (row.model.total > 0 ? " · " + Fmt.size(row.model.total) : "")
                                    : Fmt.pct(row.frac * 100) + " · " + Fmt.size(row.model.done) + " / " + Fmt.size(row.model.total)
                                        + (row.model.speed > 0
                                            ? " · " + Fmt.rate(row.model.speed) + " · "
                                                + Translation.tr("ETA %1").arg(Fmt.eta((row.model.total - row.model.done) / row.model.speed))
                                            : (row.model.status === "paused" ? " · " + Translation.tr("Paused") : ""))
                            }
                        }

                        Rectangle {   // pausar / reanudar
                            visible: !row.finished
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            radius: 16
                            color: pauseArea.containsMouse ? Appearance.colors.colLayer1Hover : "transparent"
                            scale: pauseArea.pressed ? 0.88 : 1
                            Behavior on scale { NumberAnimation { duration: 80 } }
                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: row.model.status === "paused" ? "play_arrow" : "pause"
                                iconSize: 20
                                color: Appearance.colors.colOnLayer1
                            }
                            MouseArea {
                                id: pauseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Aria2.cmd((row.model.status === "paused" ? "resume:" : "pause:") + row.model.gid)
                            }
                        }
                        Rectangle {   // cancelar / quitar de la lista
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            radius: 16
                            color: rmArea.containsMouse ? Appearance.colors.colLayer1Hover : "transparent"
                            scale: rmArea.pressed ? 0.88 : 1
                            Behavior on scale { NumberAnimation { duration: 80 } }
                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: row.finished ? "delete" : "close"
                                iconSize: 20
                                color: Appearance.colors.colOnLayer1
                            }
                            MouseArea {
                                id: rmArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Aria2.cmd("remove:" + row.model.gid)
                            }
                        }
                    }
                }
            }
        }
    }
}
