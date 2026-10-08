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
    property bool showLabel: Config.options.regionSelector.targetRegions.showLabel
    property bool showIcon: Config.options.regionSelector.targetRegions.showIcon
    property bool showTitle: Config.options.regionSelector.targetRegions.showTitle
    property bool showCoordinates: Config.options.regionSelector.targetRegions.showCoordinates
    property bool targeted: false
    property real regionAlpha: 0.3
    readonly property real labelAlpha: 0.7 + 0.3 * regionAlpha
    property color borderColor: "#ddffffff"
    property color fillColor: "transparent"
    property string text: ""
    property string title: ""
    readonly property string labelText: (showTitle && title) ? `${text} — ${title}` : text
    property real textPadding: 10
    z: 2
    color: Qt.rgba(fillColor.r, fillColor.g, fillColor.b, fillColor.a * regionAlpha)
    border.color: Qt.rgba(borderColor.r, borderColor.g, borderColor.b, borderColor.a * regionAlpha)
    border.width: targeted ? 4 : 2
    radius: 4

    Behavior on color {
        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
    }

    visible: opacity > 0
    Behavior on opacity {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }
    x: clientDimensions.at[0]
    y: clientDimensions.at[1]
    width: clientDimensions.size[0]
    height: clientDimensions.size[1]

    function hasWindowIcon() {
        const cls = clientDimensions.class;
        if (!cls) return false;
        const guessed = AppSearch.guessIcon(cls);
        return guessed !== "image-missing" && AppSearch.iconExists(guessed);
    }

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
            color: Qt.rgba(root.colBackground.r, root.colBackground.g, root.colBackground.b, root.colBackground.a * root.labelAlpha)
            border.width: 1
            border.color: Qt.rgba(Appearance.m3colors.m3outlineVariant.r, Appearance.m3colors.m3outlineVariant.g, Appearance.m3colors.m3outlineVariant.b, Appearance.m3colors.m3outlineVariant.a * root.labelAlpha)
            implicitWidth: regionInfo.implicitWidth + horizontalPadding * 2
            implicitHeight: regionInfo.implicitHeight + verticalPadding * 2

            Component {
                id: windowIconComponent
                IconImage {
                    implicitSize: Appearance.font.pixelSize.larger
                    source: Quickshell.iconPath(AppSearch.guessIcon(root.clientDimensions.class), "image-missing")
                }
            }

            Component {
                id: genericIconComponent
                MaterialSymbol {
                    iconSize: Appearance.font.pixelSize.larger
                    text: root.clientDimensions.namespace ? "layers" : root.clientDimensions.class !== undefined ? "select_window" : "image"
                    color: root.colForeground
                }
            }

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
                        sourceComponent: root.hasWindowIcon() ? windowIconComponent : genericIconComponent
                    }

                    StyledText {
                        id: regionText
                        text: root.labelText
                        color: root.colForeground
                    }
                }

                Row {
                    id: regionInfoPositionsRow
                    spacing: 4
                    visible: root.showCoordinates

                    StyledText {
                        text: `${root.x},${root.y} ${root.width}x${root.height}`
                        color: root.colForeground
                    }
                }
            }
        }
    }
}