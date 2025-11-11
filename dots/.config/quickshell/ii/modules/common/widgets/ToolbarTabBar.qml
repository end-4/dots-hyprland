pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.models
import qs.services
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.synchronizer

Item {
    id: root
    property int currentIndex: 0
    required property var tabButtonList

    function incrementCurrentIndex() {
        root.currentIndex = (root.currentIndex + 1) % root.tabButtonList.length
    }
    function decrementCurrentIndex() {
        root.currentIndex = (root.currentIndex - 1 + root.tabButtonList.length) % root.tabButtonList.length
    }
    function setCurrentIndex(index) {
        root.currentIndex = Math.max(0, Math.min(index, root.tabButtonList.length - 1))
    }

    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
    implicitWidth: contentItem.implicitWidth
    implicitHeight: 40

    Row {
        id: contentItem
        z: 1
        anchors.centerIn: parent
        spacing: 4

        Repeater {
            model: root.tabButtonList
            delegate: ToolbarTabButton {
                required property int index
                required property var modelData
                current: index == root.currentIndex
                text: modelData.name
                materialSymbol: modelData.icon
                onClicked: {
                    root.setCurrentIndex(index)
                }
            }
        }
    }

    Rectangle {
        id: activeIndicator
        z: 0
        color: Appearance.colors.colSecondaryContainer
        implicitWidth: contentItem.children[root.currentIndex]?.implicitWidth ?? 0
        implicitHeight: contentItem.children[root.currentIndex]?.implicitHeight ?? 0
        radius: height / 2
        // Animation
        property Item targetItem: contentItem.children[root.currentIndex]
        AnimatedTabIndexPair {
            id: leftBound
            idx1Duration: 50
            idx2Duration: 200
            index: activeIndicator.targetItem.x
        }
        AnimatedTabIndexPair {
            id: rightBound
            idx1Duration: 50
            idx2Duration: 200
            index: activeIndicator.targetItem.x + activeIndicator.targetItem.width
        }
        x: Math.min(leftBound.idx1, leftBound.idx2)
        width: Math.max(rightBound.idx1, rightBound.idx2) - x
    }

    MouseArea {
        anchors.fill: parent
        z: 2
        acceptedButtons: Qt.NoButton
        cursorShape: Qt.PointingHandCursor
        onWheel: (event) => {
            if (event.angleDelta.y < 0) {
                root.incrementCurrentIndex();
            }
            else {
                root.decrementCurrentIndex();
            }
        }
    }
}
