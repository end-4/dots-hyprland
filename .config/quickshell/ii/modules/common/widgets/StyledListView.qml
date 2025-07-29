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

    function resetDrag() {
        root.dragIndex = -1
        root.dragDistance = 0
    }

    maximumFlickVelocity: 3500
    boundsBehavior: Flickable.DragOverBounds

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
