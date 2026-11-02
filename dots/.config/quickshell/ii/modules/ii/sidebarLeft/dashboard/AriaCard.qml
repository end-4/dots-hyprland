import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import "Fmt.js" as Fmt

// Resumen de descargas: velocidad global + hasta 3 descargas con barra de progreso.
DashCard {
    id: root
    readonly property var shown: !Aria2.ok ? [] : Aria2.activeList.length > 0
        ? Aria2.activeList.slice(0, 3) : Aria2.waitingList.slice(0, 3)

    // Modelo en sitio: las barras se conservan entre actualizaciones (y por eso pueden animarse)
    LiveListModel {
        id: shownModel
        key: "gid"
        template: ({ gid: "", name: "", status: "", total: 0, done: 0, speed: 0, up: 0, conns: 0, err: "" })
    }
    onShownChanged: shownModel.sync(root.shown)
    Component.onCompleted: shownModel.sync(root.shown)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            MaterialSymbol {
                text: Aria2.ok ? "download" : "cloud_off"
                iconSize: 18
                color: Aria2.ok ? Appearance.m3colors.m3primary : Appearance.colors.colSubtext
            }
            StyledText {
                Layout.fillWidth: true
                text: Translation.tr("DOWNLOADS")
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.smaller
            }
            StyledText {
                visible: Aria2.ok
                text: "↓ " + Fmt.rate(Aria2.dlSpeed)
                color: Appearance.colors.colOnLayer1
                font.pixelSize: Appearance.font.pixelSize.small
            }
        }

        StyledText {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !Aria2.ok || root.shown.length === 0
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.Wrap
            text: !Aria2.ok ? Aria2.errorText
                : Translation.tr("No active downloads · %1 waiting · %2 finished").arg(Aria2.nWaiting).arg(Aria2.nStopped)
            color: Appearance.colors.colSubtext
            font.pixelSize: Appearance.font.pixelSize.small
        }

        Repeater {
            model: shownModel
            delegate: ColumnLayout {
                id: item
                required property var model
                readonly property real frac: model.total > 0 ? Math.min(1, model.done / model.total) : 0
                Layout.fillWidth: true
                spacing: 3

                RowLayout {
                    Layout.fillWidth: true
                    StyledText {
                        Layout.fillWidth: true
                        text: item.model.name
                        elide: Text.ElideMiddle
                        color: Appearance.colors.colOnLayer1
                        font.pixelSize: Appearance.font.pixelSize.small
                    }
                    StyledText {
                        text: item.model.status === "paused" ? Translation.tr("Paused") : Fmt.pct(item.frac * 100)
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.smaller
                    }
                }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 5
                    radius: 3
                    color: Appearance.colors.colLayer2
                    Rectangle {
                        width: parent.width * item.frac
                        Behavior on width { NumberAnimation { duration: 1000; easing.type: Easing.Linear } }
                        height: parent.height
                        radius: 3
                        color: Appearance.m3colors.m3primary
                    }
                }
            }
        }
        Item { Layout.fillHeight: true; visible: Aria2.ok && root.shown.length > 0 }
    }
}
