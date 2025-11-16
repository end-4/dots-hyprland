import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.waffle.looks

WBarAttachedPanelContent {
    id: root

    contentItem: ColumnLayout {
        anchors.centerIn: parent
        spacing: 0

        Rectangle {
            Layout.fillHeight: true
            Layout.fillWidth: true
            topLeftRadius: root.border.radius - root.border.border.width
            topRightRadius: topLeftRadius
            color: Looks.colors.bgPanelBody

            implicitWidth: 360
            implicitHeight: 380
        }

        Rectangle {
            Layout.fillHeight: false
            Layout.fillWidth: true
            color: Looks.colors.bgPanelSeparator
            implicitHeight: 1
        }

        Rectangle {
            Layout.fillHeight: false
            Layout.fillWidth: true
            bottomLeftRadius: root.border.radius - root.border.border.width
            bottomRightRadius: bottomLeftRadius
            color: Looks.colors.bgPanelFooter

            implicitWidth: 360
            implicitHeight: 47

            // Battery button
            WPanelFooterButton {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 12

                contentItem: Row {
                    spacing: 4

                    FluentIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        icon: WIcons.batteryIcon
                    }
                    WText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: `${Math.round(Battery.percentage * 100) || 0}%`
                    }
                }
            }

            // Settings button
            WPanelFooterButton {
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 12

                contentItem: FluentIcon {
                    icon: "settings"
                }
            }
        }
    }
}
