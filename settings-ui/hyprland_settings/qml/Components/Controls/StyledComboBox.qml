// hyprland-settings/qml/Components/Controls/StyledComboBox.qml
import QtQuick
import QtQuick.Controls
import App 1.0
import Components 1.0

ComboBox {
    id: root
    implicitHeight: 40
    property int popupY: root.height

    font.family: Theme.mainFont.family
    font.pixelSize: Theme.mainFont.pixelSize

    indicator: MaterialSymbol {
        text: "arrow_drop_down"
        color: Theme.text
        x: root.width - width - root.rightPadding
        y: root.topPadding + (root.availableHeight - height) / 2
        font.pixelSize: 24
    }

    contentItem: Text {
        text: root.displayText
        font: root.font
        color: Theme.text
        verticalAlignment: Text.AlignVCenter
        leftPadding: 8
        elide: Text.ElideRight
    }

    background: Rectangle {
        radius: Theme.radius
        color: Theme.surfaceContainer
        border.color: root.activeFocus ? Theme.primary : Theme.outline
        border.width: root.activeFocus ? 2 : 1
    }

    popup: Popup {
        id: popup
        y: root.popupY
        width: root.width
        implicitHeight: contentItem.implicitHeight
        padding: 8

        property int savedIndex: -1

        onOpened: {
            savedIndex = root.currentIndex
            // FIX: Use the correct delegate model provided by ComboBox
            if (!listView.model) {
                listView.model = root.delegateModel
            }
        }

        onClosed: {
            // FIX: Ensure currentIndex is valid before assigning
            if (root.currentIndex === -1 && savedIndex !== -1 && savedIndex < root.count) {
                root.currentIndex = savedIndex
            }
        }

        contentItem: ListView {
            id: listView
            clip: true
            implicitHeight: Math.min(contentHeight, 40 * 5.5) // Limit max height

            delegate: Rectangle {
                width: listView.width
                height: 40
                color: mouseArea.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.2) : "transparent"
                radius: Theme.radius

                Text {
                    // FIX: Check if textRole is defined and if model contains it.
                    // Fallback to modelData for simple string lists.
                    text: (root.textRole && model && model.hasOwnProperty(root.textRole)) ? model[root.textRole] : modelData
                    font: root.font
                    color: Theme.text
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 8
                    elide: Text.ElideRight
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        root.currentIndex = index
                        root.popup.close()
                    }
                }
            }
        }

        background: Rectangle {
            color: Theme.surfaceContainerHigh
            border.color: Theme.outline
            border.width: 1
            radius: Theme.radius
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.popup.visible ? root.popup.close() : root.popup.open()
    }
}