pragma ComponentBehavior: Bound

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick

Item {
    id: root
    property string style: "rotating"
    property color colOnBackground: Appearance.colors.colOnSecondaryContainer
    property color colBackground: Appearance.colors.colOnSecondaryContainer
    property real dateSquareSize: 64

    // Rotating date
    Loader {
        opacity: root.style === "rotating" ? 1.0 : 0
        Behavior on opacity {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }

        anchors.fill: parent
        active: opacity > 0
        sourceComponent: RotatingDate {}
    }

    // Square date (only today's number) in right side of the clock
    Loader {
        width: root.style === "rect" ? 45 : 0
        height: root.style === "rect" ? 30 : 0

        Behavior on height {
            animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
        }
        Behavior on width {
            animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
        }

        active: height > 0
        sourceComponent: RectangleDate {}

        anchors {
            verticalCenter: parent.verticalCenter
            right: parent.right
            rightMargin: 10
        }
        
    }

    // Date bubble style day
    Loader {
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
        }
    }

    // Date bubble month
    Loader {
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
        }
    }
}
