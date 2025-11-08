import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ComboBox {
    id: root

    property string buttonIcon: ""
    property real buttonRadius: height / 2
    property color buttonBackground: Appearance.colors.colSecondaryContainer
    property color buttonBackgroundHover: Appearance.colors.colSecondaryContainerHover
    property color buttonBackgroundActive: Appearance.colors.colSecondaryContainerActive

    implicitHeight: 40
    Layout.fillWidth: true

    background: Rectangle {
        radius: root.buttonRadius
        color: root.down ? root.buttonBackgroundActive : root.hovered ? root.buttonBackgroundHover : root.buttonBackground

        Behavior on color {
            ColorAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }
    }

    contentItem: Item {
        implicitWidth: buttonLayout.implicitWidth
        implicitHeight: buttonLayout.implicitHeight

        RowLayout {
            id: buttonLayout
            anchors.fill: parent
            spacing: 8
            anchors.leftMargin: 16
            anchors.rightMargin: 16

            Loader {
                Layout.alignment: Qt.AlignVCenter
                active: root.buttonIcon.length > 0
                visible: active
                sourceComponent: MaterialSymbol {
                    text: root.buttonIcon
                    iconSize: Appearance.font.pixelSize.larger
                    color: Appearance.colors.colOnSecondaryContainer
                }
            }

            StyledText {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                color: Appearance.colors.colOnSecondaryContainer
                text: root.displayText
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }
        }
    }

    delegate: ItemDelegate {
        id: itemDelegate
        width: root.width
        height: 40

        required property var model
        required property int index

        background: Rectangle {
            radius: Appearance.rounding.small
            color: root.currentIndex === itemDelegate.index ? Appearance.colors.colPrimary : itemDelegate.down ? Appearance.colors.colSecondaryContainerActive : itemDelegate.hovered ? Appearance.colors.colSecondaryContainerHover : "transparent"

            Behavior on color {
                ColorAnimation {
                    duration: 150
                    easing.type: Easing.OutCubic
                }
            }
        }

        contentItem: RowLayout {
            spacing: 8
            anchors.leftMargin: 12
            anchors.rightMargin: 12

            MaterialSymbol {
                Layout.alignment: Qt.AlignVCenter
                text: "check"
                iconSize: Appearance.font.pixelSize.normal
                color: root.currentIndex === itemDelegate.index ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSecondaryContainer
                opacity: root.currentIndex === itemDelegate.index ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.OutCubic
                    }
                }
            }

            StyledText {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                color: root.currentIndex === itemDelegate.index ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSecondaryContainer
                text: itemDelegate.model[root.textRole]
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }
        }
    }

    popup: Popup {
        y: root.height + 4
        width: root.width
        height: Math.min(listView.contentHeight + topPadding + bottomPadding, 300)
        padding: 8

        background: Rectangle {
            radius: Appearance.rounding.normal
            color: Appearance.colors.colSurfaceContainerHigh
        }

        contentItem: ListView {
            id: listView
            clip: true
            implicitHeight: contentHeight
            model: root.popup.visible ? root.delegateModel : null
            currentIndex: root.highlightedIndex

            ScrollIndicator.vertical: ScrollIndicator {}
        }
    }
}
