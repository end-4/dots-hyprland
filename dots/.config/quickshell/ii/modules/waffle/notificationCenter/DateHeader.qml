pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.waffle.looks

FooterRectangle {
    id: root

    implicitWidth: 0
    property bool collapsed
    color: ColorUtils.transparentize(Looks.colors.bgPanelBody, collapsed ? 0 : 1)
    Behavior on color {
        animation: Looks.transition.color.createObject(this)
    }

    RowLayout {
        anchors {
            fill: parent
            leftMargin: 16
            rightMargin: 16
            topMargin: 12
            bottomMargin: 12
        }

        WText {
            Layout.fillWidth: true
            font.pixelSize: Looks.font.pixelSize.large
            text: DateTime.collapsedCalendarFormat
        }

        WBorderedButton {
            implicitWidth: 24
            implicitHeight: 24
            padding: 0
            onClicked: root.collapsed = !root.collapsed
            contentItem: Item {
                FluentIcon {
                    anchors.centerIn: parent
                    implicitSize: 12
                    icon: "chevron-down"
                    rotation: root.collapsed ? 180 : 0
                    Behavior on rotation {
                        animation: Looks.transition.rotate.createObject(this)
                    }
                }
            }
        }
    }
}
