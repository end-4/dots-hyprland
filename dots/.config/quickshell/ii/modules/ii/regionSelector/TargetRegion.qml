pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import Quickshell
import Quickshell.Widgets

Rectangle {
    id: root
    required property var clientDimensions

    property color colBackground: Qt.alpha("#88111111", 0.9)
    property color colForeground: "#ddffffff"
    property real regionAlpha: 0.3
    property bool showLabel: Config.options.regionSelector.targetRegions.showLabel
    property bool showIcon: false
    property bool targeted: false
    property color borderColor: "#ddffffff"
    property color fillColor: "transparent"
    property string text: ""
    property real textPadding: 10
    z: 2
    color: Qt.alpha(fillColor, regionAlpha)
    border.color: Qt.alpha(borderColor, regionAlpha)
    border.width: targeted ? 4 : 2
    radius: 4

    Behavior on color {
        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
    }

    visible: regionAlpha > 0
    Behavior on regionAlpha {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }
    x: clientDimensions.at[0]
    y: clientDimensions.at[1]
    width: clientDimensions.size[0]
    height: clientDimensions.size[1]

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
            color: Qt.alpha(root.colBackground, regionAlpha)
            border.width: 1
            border.color: Qt.alpha(Appearance.m3colors.m3outlineVariant, regionAlpha)
            implicitWidth: regionInfo.implicitWidth + horizontalPadding * 2
            implicitHeight: regionInfo.implicitHeight + verticalPadding * 2

            Column {
                id: regionInfo
                anchors.centerIn: parent
                spacing: 4

                Row {
                    id: regionInfoRow
                    spacing: 4

                    Loader {
                        id: regionIconLoader
                        active: root.showIcon
                        visible: active
                        sourceComponent: IconImage {
                            implicitSize: Appearance.font.pixelSize.larger
                            source: Quickshell.iconPath(AppSearch.guessIcon(root.clientDimensions.class), "image-missing")
                        }
                    }

                    StyledText {
                        id: regionText
                        text: root.text
                        color: root.colForeground
                    }
                }

                Row {
                    id: regionInfoPositionsRow
                    spacing: 4

                    StyledText {
                        text: `${root.x},${root.y} ${root.width}x${root.height}`
                        color: root.colForeground
                    }
                }
            }
        }
    }
}
