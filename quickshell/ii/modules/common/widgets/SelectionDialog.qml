import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs
import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    id: root
    property real dialogPadding: 15
    property real dialogMargin: 30
    property string titleText: "Selection Dialog"
    property alias items: choiceModel.values
    property int selectedId: choiceListView.currentIndex
    property var defaultChoice

    signal canceled();
    signal selected(var result);

    Rectangle { // Scrim
        id: scrimOverlay
        anchors.fill: parent
        radius: Appearance.rounding.small
        color: Appearance.colors.colScrim
        MouseArea {
            hoverEnabled: true
            anchors.fill: parent
            preventStealing: true
            propagateComposedEvents: false
        }
    }

    Rectangle { // The dialog
        id: dialog
        color: Appearance.colors.colSurfaceContainerHigh
        radius: Appearance.rounding.normal
        anchors.fill: parent
        anchors.margins: dialogMargin
        implicitHeight: dialogColumnLayout.implicitHeight
        
        ColumnLayout {
            id: dialogColumnLayout
            anchors.fill: parent
            spacing: 16

            StyledText {
                id: dialogTitle
                Layout.topMargin: dialogPadding
                Layout.leftMargin: dialogPadding
                Layout.rightMargin: dialogPadding
                Layout.alignment: Qt.AlignLeft
                color: Appearance.m3colors.m3onSurface
                font.pixelSize: Appearance.font.pixelSize.larger
                text: root.titleText
            }

            Rectangle {
                color: Appearance.m3colors.m3outline
                implicitHeight: 1
                Layout.fillWidth: true
                Layout.leftMargin: dialogPadding
                Layout.rightMargin: dialogPadding
            }

            StyledListView {
                id: choiceListView
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                currentIndex: root.defaultChoice !== undefined ? root.items.indexOf(root.defaultChoice) : -1
                spacing: 6

                model: ScriptModel {
                    id: choiceModel
                }

                delegate: StyledRadioButton {
                    id: radioButton
                    required property var modelData
                    required property int index
                    anchors {
                        left: parent?.left
                        right: parent?.right
                        leftMargin: root.dialogPadding
                        rightMargin: root.dialogPadding
                    }

                    description: modelData.toString()
                    checked: index === choiceListView.currentIndex

                    onCheckedChanged: {
                        if (checked) {
                            choiceListView.currentIndex = index;
                        }
                    }
                }
            }

            Rectangle {
                color: Appearance.m3colors.m3outline
                implicitHeight: 1
                Layout.fillWidth: true
                Layout.leftMargin: dialogPadding
                Layout.rightMargin: dialogPadding
            }

            RowLayout {
                id: dialogButtonsRowLayout
                Layout.bottomMargin: dialogPadding
                Layout.leftMargin: dialogPadding
                Layout.rightMargin: dialogPadding
                Layout.alignment: Qt.AlignRight

                DialogButton {
                    buttonText: Translation.tr("Cancel")
                    onClicked: root.canceled()
                }
                DialogButton {
                    buttonText: Translation.tr("OK")
                    onClicked: root.selected(
                        root.selectedId === -1 ? null :
                        root.items[root.selectedId]
                    )
                }
            }
        }
    }
}
