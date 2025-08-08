import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick

/**
 * A ListView with animations.
 */
ListView {
    id: root
    spacing: 5
    property real removeOvershoot: 20 // Account for gaps and bouncy animations
    property int dragIndex: -1
    property real dragDistance: 0
    property bool popin: true

    property real touchpadScrollFactor: Config?.options.interactions.scrolling.touchpadScrollFactor ?? 100
    property real mouseScrollFactor: Config?.options.interactions.scrolling.mouseScrollFactor ?? 50
    property real mouseScrollDeltaThreshold: Config?.options.interactions.scrolling.mouseScrollDeltaThreshold ?? 120

    function resetDrag() {
        root.dragIndex = -1
        root.dragDistance = 0
    }

    maximumFlickVelocity: 3500
    boundsBehavior: Flickable.DragOverBounds

    MouseArea {
        visible: Config?.options.interactions.scrolling.fasterTouchpadScroll
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: function(wheelEvent) {
            const delta = wheelEvent.angleDelta.y / root.mouseScrollDeltaThreshold;
            // The angleDelta.y of a touchpad is usually small and continuous, 
            // while that of a mouse wheel is typically in multiples of ±120.
            var scrollFactor = Math.abs(wheelEvent.angleDelta.y) >= root.mouseScrollDeltaThreshold ? root.mouseScrollFactor : root.touchpadScrollFactor;
            var targetY = root.contentY - delta * scrollFactor;
            targetY = Math.max(0, Math.min(targetY, root.contentHeight - root.height));
            root.contentY = targetY;
        }
    }

    Behavior on contentY {
        NumberAnimation {
            id: scrollAnim
            duration: Appearance.animation.scroll.duration
            easing.type: Appearance.animation.scroll.type
            easing.bezierCurve: Appearance.animation.scroll.bezierCurve
        }
    }

    add: Transition {
        animations: [
            Appearance?.animation.elementMove.numberAnimation.createObject(this, {
                properties: popin ? "opacity,scale" : "opacity",
                from: 0,
                to: 1,
            }),
        ]
    }

    addDisplaced: Transition {
        animations: [
            Appearance?.animation.elementMove.numberAnimation.createObject(this, {
                property: "y",
            }),
            Appearance?.animation.elementMove.numberAnimation.createObject(this, {
                properties: popin ? "opacity,scale" : "opacity",
                to: 1,
            }),
        ]
    }
    
    // displaced: Transition {
    //     animations: [
    //         Appearance?.animation.elementMove.numberAnimation.createObject(this, {
    //             property: "y",
    //         }),
    //         Appearance?.animation.elementMove.numberAnimation.createObject(this, {
    //             properties: "opacity,scale",
    //             to: 1,
    //         }),
    //     ]
    // }

    // move: Transition {
    //     animations: [
    //         Appearance?.animation.elementMove.numberAnimation.createObject(this, {
    //             property: "y",
    //         }),
    //         Appearance?.animation.elementMove.numberAnimation.createObject(this, {
    //             properties: "opacity,scale",
    //             to: 1,
    //         }),
    //     ]
    // }
    // moveDisplaced: Transition {
    //     animations: [
    //         Appearance?.animation.elementMove.numberAnimation.createObject(this, {
    //             property: "y",
    //         }),
    //         Appearance?.animation.elementMove.numberAnimation.createObject(this, {
    //             properties: "opacity,scale",
    //             to: 1,
    //         }),
    //     ]
    // }

    remove: Transition {
        animations: [
            Appearance?.animation.elementMove.numberAnimation.createObject(this, {
                property: "x",
                to: root.width + root.removeOvershoot,
            }),
            Appearance?.animation.elementMove.numberAnimation.createObject(this, {
                property: "opacity",
                to: 0,
            })
        ]
    }

    // This is movement when something is removed, not removing animation!
    removeDisplaced: Transition { 
        animations: [
            Appearance?.animation.elementMove.numberAnimation.createObject(this, {
                property: "y",
            }),
            Appearance?.animation.elementMove.numberAnimation.createObject(this, {
                properties: "opacity,scale",
                to: 1,
            }),
        ]
    }
}
