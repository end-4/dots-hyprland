import "root:/modules/common"
import "root:/modules/common/widgets"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ToolTip {
    property string content
    property bool extraVisibleCondition: true
    property bool internalVisibleCondition: false
    padding: 7
    
    visible: (extraVisibleCondition && (parent.hovered === undefined || parent?.hovered) && internalVisibleCondition)

    Connections {
        target: parent
        onHoveredChanged: {
            if (parent.hovered) {
                tooltipShowDelay.restart()
            } else {
                internalVisibleCondition = false
            }
        }
    }

    Timer {
        id: tooltipShowDelay
        interval: 200
        repeat: false
        running: false
        onTriggered: {
            internalVisibleCondition = true
        }
    }

    background: Rectangle {
        color: Appearance.colors.colTooltip
        radius: Appearance.rounding.small
        width: tooltipTextObject.width + 2 * padding
        Behavior on opacity {
            OpacityAnimator {
                duration: Appearance.animation.elementDecel.duration
                easing.type: Appearance.animation.elementDecel.type
            }
        }
        opacity: visible ? 1 : 0
    }
    StyledText {
        id: tooltipTextObject
        text: content
        color: Appearance.colors.colOnTooltip
        wrapMode: Text.Wrap
    }
}