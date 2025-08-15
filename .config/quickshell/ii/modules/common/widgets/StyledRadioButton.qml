import qs.modules.common
import qs.modules.common.widgets
import qs.services
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell.Services.Pipewire

RadioButton {
    id: root
    implicitHeight: contentItem.implicitHeight + 4 * 2
    property string description
    property color activeColor: Appearance?.colors.colPrimary ?? "#685496"
    property color inactiveColor: Appearance?.m3colors.m3onSurfaceVariant ?? "#45464F"

    PointingHandInteraction {}

    indicator: Item{}
    
    contentItem: RowLayout {
        id: contentItem
        Layout.fillWidth: true
        spacing: 12
        Rectangle {
            id: radio
            Layout.fillWidth: false
            Layout.alignment: Qt.AlignVCenter
            width: 20
            height: 20
            radius: Appearance?.rounding.full
            border.color: checked ? root.activeColor : root.inactiveColor
            border.width: 2
            color: "transparent"

            // Checked indicator
            Rectangle {
                anchors.centerIn: parent
                width: checked ? 10 : 4
                height: checked ? 10 : 4
                radius: Appearance?.rounding.full
                color: Appearance?.colors.colPrimary
                opacity: checked ? 1 : 0

                Behavior on opacity {
                    animation: Appearance?.animation.elementMoveFast.numberAnimation.createObject(this)
                }
                Behavior on width {
                    animation: Appearance?.animation.elementMove.numberAnimation.createObject(this)
                }
                Behavior on height {
                    animation: Appearance?.animation.elementMove.numberAnimation.createObject(this)
                }

            }

            // Hover
            Rectangle {
                anchors.centerIn: parent
                width: root.hovered ? 40 : 20
                height: root.hovered ? 40 : 20
                radius: Appearance?.rounding.full
                color: Appearance?.m3colors.m3onSurface
                opacity: root.hovered ? 0.1 : 0

                Behavior on opacity {
                    animation: Appearance?.animation.elementMoveFast.numberAnimation.createObject(this)
                }
                Behavior on width {
                    animation: Appearance?.animation.elementMove.numberAnimation.createObject(this)
                }
                Behavior on height {
                    animation: Appearance?.animation.elementMove.numberAnimation.createObject(this)
                }
            }
        }

        StyledText {
            text: root.description
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            color: Appearance?.m3colors.m3onSurface
        }
    }
}