pragma ComponentBehavior: Bound

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick

Item {
    id: root
    readonly property string dialStyle: Config.options.background.clock.cookie.dialNumberStyle
    property string style: "rotating"
    property color colOnBackground: Appearance.colors.colOnSecondaryContainer
    property color colBackground: Appearance.colors.colOnSecondaryContainer
    property real dateSquareSize: 64

    // Rotating date
    Loader {
        anchors.fill: parent
        active: opacity > 0
        sourceComponent: RotatingDate {
            style: root.style
        }
    }

    // Rectangle date (only today's number) in right side of the clock
    Loader {
        id: rectLoader

        property real animIndex: root.style === "rect" ? 1.0 : 0.0
        Behavior on animIndex {
            animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
        }

        active: animIndex > 0

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter

        sourceComponent: RectangleDate {
            color: Appearance.colors.colSecondaryContainerHover
            radius: Appearance.rounding.small
            animIndex: rectLoader.animIndex
        }
    }

    // Date bubble / day
    Loader {
        id: dayBubbleLoader
        property real targetSize: root.style === "bubble" ? root.dateSquareSize : 0
        Behavior on targetSize {
            animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
        }

        active: targetSize > 0
        width: targetSize
        height: targetSize
        
        anchors {
            left: parent.left
            bottom: parent.bottom
            topMargin: 50
        }
        sourceComponent: BubbleDate {
            bubbleIndex: 0
            targetSize: dayBubbleLoader.targetSize
        }
    }

    // Date bubble / month
    Loader {
        id: monthBubbleLoader
        property real targetSize: root.style === "bubble" ? root.dateSquareSize : 0
        Behavior on targetSize {
            animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
        }

        width: targetSize
        height: targetSize
        active: targetSize > 0
        
        anchors {
            right: parent.right
            top: parent.top
            bottomMargin: 50
        }
        sourceComponent: BubbleDate {
            bubbleIndex: 1
            targetSize: monthBubbleLoader.targetSize
        }
    }
}
