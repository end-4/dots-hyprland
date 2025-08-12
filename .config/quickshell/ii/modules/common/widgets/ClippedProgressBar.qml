import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

/**
 * A progress bar with both ends rounded and text acts as clipping like OneUI 7's battery indicator.
 */
ProgressBar {
    id: root
    property real valueBarWidth: 30
    property real valueBarHeight: 18
    property color highlightColor: Appearance?.colors.colOnSecondaryContainer ?? "#685496"
    property color trackColor: ColorUtils.transparentize(highlightColor, 0.5) ?? "#F1D3F9"
    property alias radius: contentItem.radius
    property string text
    default property Item textMask: Item {
        width: valueBarWidth
        height: valueBarHeight
        StyledText {
            anchors.centerIn: parent
            font: root.font
            text: root.text
        }
    }

    text: Math.round(value * 100)
    font {
        pixelSize: 13
        weight: text.length > 2 ? Font.Medium : Font.DemiBold
    }

    background: Item {
        implicitHeight: valueBarHeight
        implicitWidth: valueBarWidth
    }

    contentItem: Rectangle {
        id: contentItem
        anchors.fill: parent
        radius: 9999
        color: root.trackColor
        visible: false

        Rectangle {
            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
            }
            radius: Appearance.rounding.unsharpen
            width: parent.width * root.visualPosition
            color: root.highlightColor
        }
    }

    OpacityMask {
        id: roundingMask
        visible: false
        anchors.fill: parent
        source: contentItem
        maskSource: Rectangle {
            width: contentItem.width
            height: contentItem.height
            radius: contentItem.radius
        }
    }

    OpacityMask {
        anchors.fill: parent
        source: roundingMask
        invert: true
        maskSource: root.textMask
    }
}
