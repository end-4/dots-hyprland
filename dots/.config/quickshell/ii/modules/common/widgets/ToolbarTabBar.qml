pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.models
import qs.services
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    property alias currentIndex: tabBar.currentIndex
    required property var tabButtonList

    function incrementCurrentIndex() {
        tabBar.incrementCurrentIndex()
    }
    function decrementCurrentIndex() {
        tabBar.decrementCurrentIndex()
    }
    function setCurrentIndex(index) {
        tabBar.setCurrentIndex(index)
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

    // TabBar doesn't allow tabs to be of different sizes. Literally unusable. 
    // We use it only for the logic and draw stuff manually
    TabBar {
        id: tabBar
        z: -1
        background: null
        Repeater { // This is to fool the TabBar that it has tabs so it does the indices properly
            model: root.tabButtonList.length
            delegate: TabButton {
                background: null
            }
        }
    }
}
