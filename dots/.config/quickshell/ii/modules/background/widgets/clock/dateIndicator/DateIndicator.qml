pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick

Item {
    id: root
    property string style: "bubble"
    property color color: Appearance.colors.colOnSecondaryContainer
    property real dateSquareSize: 64

    // Rotating date
    FadeLoader {
        anchors.fill: parent
        shown: Config.options.background.widgets.clock.cookie.dateStyle === "border"
        sourceComponent: RotatingDate {
            color: root.color
        }
    }

    // Rectangle date (only today's number) in right side of the clock
    FadeLoader {
        id: rectLoader
        shown: root.style === "rect"
        anchors {
            verticalCenter: parent.verticalCenter
            right: parent.right
            rightMargin: 40 - rectLoader.opacity * 30
        }

        sourceComponent: RectangleDate {
            color: ColorUtils.mix(root.color, Appearance.colors.colSecondaryContainerHover, 0.5)
            radius: Appearance.rounding.small
            implicitWidth: 45 * rectLoader.opacity
            implicitHeight: 30 * rectLoader.opacity
        }
    }

    // Bubble style: day of month
    FadeLoader {
        id: dayBubbleLoader
        shown: root.style === "bubble"
        property real targetSize: root.dateSquareSize * opacity
        anchors {
            left: parent.left
            top: parent.top
        }

        sourceComponent: BubbleDate {
            implicitWidth: dayBubbleLoader.targetSize
            implicitHeight: dayBubbleLoader.targetSize
            isMonth: false
            targetSize: dayBubbleLoader.targetSize
        }
    }

    // Bubble style: month
    FadeLoader {
        id: monthBubbleLoader
        shown: root.style === "bubble"
        property real targetSize: root.dateSquareSize * opacity
        anchors {
            right: parent.right
            bottom: parent.bottom
        }

        sourceComponent: BubbleDate {
            implicitWidth: monthBubbleLoader.targetSize
            implicitHeight: monthBubbleLoader.targetSize
            isMonth: true
            targetSize: monthBubbleLoader.targetSize
        }
    }
}
