import "root:/modules/common"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

ColumnLayout {
    id: root
    spacing: 0
    required property var tabButtonList // Something like [{"icon": "notifications", "name": qsTr("Notifications")}, {"icon": "volume_up", "name": qsTr("Volume mixer")}]
    required property var externalTrackedTab
    property bool enableIndicatorAnimation: false
    signal currentIndexChanged(int index)

    TabBar {
        id: tabBar
        Layout.fillWidth: true
        currentIndex: root.externalTrackedTab
        onCurrentIndexChanged: {
            root.onCurrentIndexChanged(currentIndex)
        }

        background: Item {
            WheelHandler {
                onWheel: (event) => {
                    if (event.angleDelta.y < 0)
                        tabBar.currentIndex = Math.min(tabBar.currentIndex + 1, root.tabButtonList.length - 1)
                    else if (event.angleDelta.y > 0)
                        tabBar.currentIndex = Math.max(tabBar.currentIndex - 1, 0)
                }
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            }
        }

        Repeater {
            model: root.tabButtonList
            delegate: PrimaryTabButton {
                selected: (index == root.externalTrackedTab)
                buttonText: modelData.name
                buttonIcon: modelData.icon
            }
        }
    }

    Item { // Tab indicator
        id: tabIndicator
        Layout.fillWidth: true
        height: 3
        Connections {
            target: root
            function onExternalTrackedTabChanged() {
                root.enableIndicatorAnimation = true
            }
        }

        Rectangle {
            id: indicator
            property int tabCount: root.tabButtonList.length
            property real fullTabSize: root.width / tabCount;
            property real targetWidth: tabBar.contentItem.children[0].children[tabBar.currentIndex].tabContentWidth

            implicitWidth: targetWidth
            anchors {
                top: parent.top
                bottom: parent.bottom
            }

            x: tabBar.currentIndex * fullTabSize + (fullTabSize - targetWidth) / 2

            color: Appearance.m3colors.m3primary
            radius: Appearance.rounding.full

            Behavior on x {
                NumberAnimation {
                    duration: Appearance.animation.elementMove.duration
                    easing.type: Appearance.animation.elementMove.type
                    easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
                }
            }

            Behavior on implicitWidth {
                NumberAnimation {
                    duration: Appearance.animation.elementMove.duration
                    easing.type: Appearance.animation.elementMove.type
                    easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
                }
            }
        }
    }

    Rectangle { // Tabbar bottom border
        id: tabBarBottomBorder
        Layout.fillWidth: true
        height: 1
        color: Appearance.m3colors.m3outlineVariant
    }
}
