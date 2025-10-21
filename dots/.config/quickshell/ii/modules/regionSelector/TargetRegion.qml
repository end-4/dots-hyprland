pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import Quickshell
import Quickshell.Widgets

Rectangle {
    id: root
    required property color colBackground
    required property color colForeground
    property bool showLabel: Config.options.regionSelector.targetRegions.showLabel
    property bool showIcon: false
    property bool targeted: false
    property color borderColor
    property color fillColor: "transparent"
    property string text: ""
    property real textPadding: 10
    z: 2
    color: fillColor
    border.color: borderColor
    border.width: targeted ? 3 : 1
    radius: 4

    Loader {
        anchors {
            top: parent.top
            left: parent.left
            topMargin: root.textPadding
            leftMargin: root.textPadding
        }
        
        active: root.showLabel
        sourceComponent: Rectangle {
            property real verticalPadding: 5
            property real horizontalPadding: 10
            radius: 10
            color: root.colBackground
            border.width: 1
            border.color: Appearance.m3colors.m3outlineVariant
            implicitWidth: regionInfoRow.implicitWidth + horizontalPadding * 2
            implicitHeight: regionInfoRow.implicitHeight + verticalPadding * 2

            Row {
                id: regionInfoRow
                anchors.centerIn: parent
                spacing: 4

                Loader {
                    id: regionIconLoader
                    active: root.showIcon
                    visible: active
                    sourceComponent: IconImage {
                        implicitSize: Appearance.font.pixelSize.larger
                        source: Quickshell.iconPath(AppSearch.guessIcon(root.text), "image-missing")
                    }
                }

                StyledText {
                    id: regionText
                    text: root.text
                    color: root.colForeground
                }
            }
        }
    }
}