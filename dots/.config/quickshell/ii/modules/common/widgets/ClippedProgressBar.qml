import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Effects

/**
 * A progress bar with both ends rounded and text acts as clipping like OneUI 7's battery indicator.
 */
ProgressBar {
    id: root
    property bool vertical: false
    property real valueBarWidth: 30
    property real valueBarHeight: 18
    property color highlightColor: Appearance?.colors.colOnSecondaryContainer ?? "#685496"
    property color trackColor: ColorUtils.transparentize(highlightColor, 0.5) ?? "#F1D3F9"
    property alias radius: contentItem.radius
    property alias progressRadius: progressFill.radius
    property string text
    default property Item textMask: Item {
        width: root.valueBarWidth
        height: root.valueBarHeight
        VisuallyCenteredStyledText {
            anchors.fill: parent
            font: root.font
            text: root.text
        }
        layer.enabled: true
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

    contentItem: Pill {
        id: contentItem
        anchors.fill: parent
        color: root.trackColor
        visible: false

        Rectangle {
            id: progressFill
            anchors {
                top: parent.top
                bottom: parent.bottom
                left: parent.left
                right: undefined
            }
            width: parent.width * root.visualPosition
            height: parent.height

            states: State {
                name: "vertical"
                when: root.vertical
                AnchorChanges {
                    target: progressFill
                    anchors {
                        top: undefined
                        bottom: parent.bottom
                        left: parent.left
                        right: parent.right
                    }
                }
                PropertyChanges {
                    target: progressFill
                    width: parent.width
                    height: parent.height * root.visualPosition
                }
            }

            radius: Appearance.rounding.unsharpen
            color: root.highlightColor
        }
    }

    Rectangle {
        id: contentMaskRect
        anchors.fill: contentItem
        width: contentItem.width
        height: contentItem.height
        radius: contentItem.radius
        layer.enabled: true
        visible: false
    }

    Item {
        // textMask has to be rendered somewhere so we put it in a practically invisible item
        anchors.centerIn: parent
        opacity: 0
        Component.onCompleted: root.textMask.layer.enabled = true // for multieffect masking
        children: [root.textMask]
    }

    MaskMultiEffect {
        id: boxClip
        anchors.fill: parent
        source: contentItem
        maskSource: contentMaskRect
        visible: false
    }

    MaskMultiEffect {
        id: textClip
        anchors.fill: parent
        implicitWidth: contentItem.implicitWidth
        implicitHeight: contentItem.implicitHeight
        source: boxClip
        maskSource: root.textMask
        maskInverted: true
    }

}
