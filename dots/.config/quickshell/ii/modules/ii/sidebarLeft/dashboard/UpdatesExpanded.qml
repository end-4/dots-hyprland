import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.widgets
import qs.services

// Lista de paquetes pendientes + botones para buscar y actualizar.
Item {
    id: root
    signal back()

    // Terminal usada para "Update now" (se le añade el comando, p. ej. `paru -Syu`).
    // Cambia esta lista si usas otra terminal.
    property var terminal: ["kitty", "--hold"]

    NumberAnimation on opacity { from: 0; to: 1; duration: 180 }

    readonly property var items: Updates.repo.map(p => ({ n: p.n, oldV: p.old, newV: p.new, reboot: p.reboot, src: "repo" }))
        .concat(Updates.aur.map(p => ({ n: p.n, oldV: p.old, newV: p.new, reboot: p.reboot, src: "AUR" })))

    LiveListModel {
        id: listModel
        key: "n"
        template: ({ n: "", oldV: "", newV: "", reboot: false, src: "" })
    }
    onItemsChanged: listModel.sync(root.items)
    Component.onCompleted: listModel.sync(root.items)

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
            MaterialSymbol { text: "system_update_alt"; iconSize: 22; color: Appearance.m3colors.m3primary }
            StyledText {
                Layout.fillWidth: true
                text: Translation.tr("Updates")
                color: Appearance.colors.colOnLayer1
                font.pixelSize: Appearance.font.pixelSize.larger
            }
        }

        DashCard {
            Layout.fillWidth: true
            Layout.preferredHeight: 92
            hoverable: false
            Column {
                anchors { left: parent.left; top: parent.top; margins: 14 }
                spacing: 2
                StyledText {
                    text: !Updates.ok ? Translation.tr("Could not check")
                        : Updates.count === 0 ? Translation.tr("System up to date")
                        : Translation.tr("%1 pending").arg(Updates.count)
                    color: Appearance.colors.colOnLayer1
                    font.pixelSize: Appearance.font.pixelSize.huge
                }
                StyledText {
                    text: !Updates.ok ? Updates.errorText
                        : Translation.tr("%1 repositories · %2 AUR").arg(Updates.repo.length).arg(Updates.aur.length)
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.small
                }
                StyledText {
                    text: Translation.tr("Updated %1 · checked %2").arg(Updates.ago(Updates.lastUpgrade)).arg(Updates.ago(Updates.ts))
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.smaller
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            ActionButton {
                Layout.fillWidth: true; Layout.preferredWidth: 1; implicitHeight: 48
                enabled: !Updates.busy
                icon: "refresh"; label: Updates.busy ? Translation.tr("Searching…") : Translation.tr("Search now")
                onClicked: Updates.refresh()
            }
            ActionButton {
                Layout.fillWidth: true; Layout.preferredWidth: 1; implicitHeight: 48
                enabled: Updates.count > 0 && Updates.updateCmd.length > 0
                icon: "terminal"; label: Translation.tr("Update now")
                onClicked: Quickshell.execDetached(root.terminal.concat(Updates.updateCmd))
            }
        }

        DashCard {
            Layout.fillWidth: true
            Layout.fillHeight: true
            hoverable: false

            StyledText {
                anchors.centerIn: parent
                visible: root.items.length === 0
                text: Updates.ok ? Translation.tr("Nothing pending") : Updates.errorText
                width: parent.width - 40
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.small
            }

            ListView {
                anchors.fill: parent
                anchors.margins: 8
                clip: true
                spacing: 2
                model: listModel
                displaced: Transition { NumberAnimation { properties: "y"; duration: 300; easing.type: Easing.OutCubic } }
                move: Transition { NumberAnimation { properties: "y"; duration: 300; easing.type: Easing.OutCubic } }
                add: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 250 } }
                remove: Transition { NumberAnimation { property: "opacity"; to: 0; duration: 150 } }
                delegate: Rectangle {
                    id: row
                    required property var model
                    width: ListView.view.width
                    height: 40
                    radius: Appearance.rounding.small
                    color: "transparent"

                    RowLayout {
                        anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                        spacing: 8
                        StyledText {
                            Layout.fillWidth: true
                            text: row.model.n
                            elide: Text.ElideRight
                            color: Appearance.colors.colOnLayer1
                            font.pixelSize: Appearance.font.pixelSize.small
                        }
                        Rectangle {
                            visible: row.model.src === "AUR" || row.model.reboot
                            Layout.preferredHeight: 18
                            Layout.preferredWidth: tag.implicitWidth + 12
                            radius: 9
                            color: Appearance.colors.colLayer2
                            StyledText {
                                id: tag
                                anchors.centerIn: parent
                                text: row.model.reboot ? Translation.tr("reboot") : "AUR"
                                color: row.model.reboot ? Appearance.m3colors.m3error : Appearance.colors.colSubtext
                                font.pixelSize: Appearance.font.pixelSize.smaller
                            }
                        }
                        StyledText {
                            text: row.model.oldV + " → " + row.model.newV
                            elide: Text.ElideLeft
                            Layout.maximumWidth: 190
                            color: Appearance.colors.colSubtext
                            font.pixelSize: Appearance.font.pixelSize.smaller
                        }
                    }
                }
            }
        }
    }
}
