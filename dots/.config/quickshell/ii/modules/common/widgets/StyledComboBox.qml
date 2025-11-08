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
                active: root.buttonIcon.length > 0 || (root.currentIndex >= 0 && root.model[root.currentIndex]?.icon)
                visible: active
                sourceComponent: MaterialSymbol {
                    text: {
                        if (root.currentIndex >= 0 && root.model[root.currentIndex]?.icon) {
                            return root.model[root.currentIndex].icon;
                        }
                        return root.buttonIcon;
                    }
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
        width: ListView.view ? ListView.view.width : root.width
        height: 40

        required property var model
        required property int index

        background: Rectangle {
            anchors.fill: parent
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

            Loader {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredHeight: Appearance.font.pixelSize.larger
                active: itemDelegate.model.icon && itemDelegate.model.icon.length > 0
                visible: active
                sourceComponent: Item {
                    implicitWidth: icon.implicitWidth
                    implicitHeight: Appearance.font.pixelSize.larger
                    MaterialSymbol {
                        id: icon
                        anchors.centerIn: parent
                        text: itemDelegate.model.icon
                        iconSize: Appearance.font.pixelSize.larger
                        color: root.currentIndex === itemDelegate.index ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSecondaryContainer
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: Appearance.font.pixelSize.larger

                StyledText {
                    anchors.centerIn: parent
                    width: parent.width
                    color: root.currentIndex === itemDelegate.index ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSecondaryContainer
                    text: itemDelegate.model[root.textRole]
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }

    popup: Popup {
        y: root.height + 4
        width: root.width
        height: Math.min(listView.contentHeight + topPadding + bottomPadding, 300)
        padding: 8

        enter: Transition {
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: 150
                easing.type: Easing.OutCubic
            }
        }

        exit: Transition {
            NumberAnimation {
                property: "opacity"
                from: 1
                to: 0
                duration: 100
                easing.type: Easing.InCubic
            }
        }

        background: Rectangle {
            radius: Appearance.rounding.normal
            color: Appearance.colors.colSurfaceContainerHigh
        }

        contentItem: ListView {
            id: listView
            clip: true
            implicitHeight: contentHeight
            spacing: 2
            model: root.popup.visible ? root.delegateModel : null
            currentIndex: root.highlightedIndex

            ScrollIndicator.vertical: ScrollIndicator {}
        }
    }
}
