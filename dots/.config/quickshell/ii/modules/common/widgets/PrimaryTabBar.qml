import qs.modules.common
import qs.services
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.synchronizer

ColumnLayout {
    id: root
    spacing: 0
    required property var tabButtonList // Something like [{"icon": "notifications", "name": Translation.tr("Notifications")}, {"icon": "volume_up", "name": Translation.tr("Volume mixer")}]
    property alias currentIndex: tabBar.currentIndex
    property bool enableIndicatorAnimation: false
    property color colIndicator: Appearance?.colors.colPrimary ?? "#65558F"
    property color colBorder: Appearance?.m3colors.m3outlineVariant ?? "#C6C6D0"

    onCurrentIndexChanged: {
        enableIndicatorAnimation = true
    }

    property bool centerTabBar: parent.width > 500
    Layout.fillWidth: !centerTabBar
    Layout.alignment: Qt.AlignHCenter
    implicitWidth: Math.max(tabBar.implicitWidth, 600)

    TabBar {
        id: tabBar
        Layout.fillWidth: true

        background: Item {
            WheelHandler {
                onWheel: (event) => {
                    if (event.angleDelta.y < 0)
                        tabBar.incrementCurrentIndex()
                    else if (event.angleDelta.y > 0)
                        tabBar.decrementCurrentIndex()
                }
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            }
        }

        Repeater {
            model: root.tabButtonList
            delegate: PrimaryTabButton {
                selected: (index == root.currentIndex)
                buttonText: modelData.name
                buttonIcon: modelData.icon
                minimumWidth: 160
                onClicked: tabBar.setCurrentIndex(index)
            }
        }
    }

    Item { // Tab indicator
        id: tabIndicator
        Layout.fillWidth: true
        height: 3

        Rectangle {
            id: indicator
            property int tabCount: root.tabButtonList.length
            property real fullTabSize: root.width / tabCount;
            property real targetWidth: tabBar.contentItem?.children[0]?.children[tabBar.currentIndex]?.tabContentWidth ?? 0

            implicitWidth: targetWidth
            anchors {
                top: parent.top
                bottom: parent.bottom
            }

            x: tabBar.currentIndex * fullTabSize + (fullTabSize - targetWidth) / 2

            color: root.colIndicator
            radius: Appearance?.rounding.full ?? 9999

            Behavior on x {
                animation: Appearance?.animation.elementMove.numberAnimation.createObject(this)
            }

            Behavior on implicitWidth {
                animation: Appearance?.animation.elementMove.numberAnimation.createObject(this)
            }
        }
    }

    Rectangle { // Tabbar bottom border
        id: tabBarBottomBorder
        Layout.fillWidth: true
        implicitHeight: 1
        color: root.colBorder
    }
}
