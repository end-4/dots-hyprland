pragma ComponentBehavior: Bound
import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import Quickshell

StyledFlickable {
    id: root
    required property int length
    contentWidth: dotsRow.implicitWidth
    contentX: (Math.max(contentWidth - width, 0))
    Behavior on contentX {
        animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
    }
    Row {
        id: dotsRow
        anchors {
            left: parent.left
            verticalCenter: parent.verticalCenter
            leftMargin: 4
        }
        spacing: 10
        Repeater {
            model: ScriptModel {
                values: Array(root.length)
            }
            delegate: Item {
                id: charItem
                required property int index
                implicitWidth: 10
                implicitHeight: 10
                MaterialShape {
                    id: materialShape
                    anchors.centerIn: parent
                    property list<var> charShapes: [
                        MaterialShape.Shape.Clover4Leaf,
                        MaterialShape.Shape.Arrow,
                        MaterialShape.Shape.Pill,
                        MaterialShape.Shape.SoftBurst,
                        MaterialShape.Shape.Diamond,
                        MaterialShape.Shape.ClamShell,
                        MaterialShape.Shape.Pentagon,
                    ]
                    shape: charShapes[charItem.index % charShapes.length]
                    // Animate on appearance
                    color: Appearance.colors.colPrimary
                    implicitSize: 0
                    opacity: 0
                    scale: 0.5
                    Component.onCompleted: {
                        appearAnim.start();
                    }
                    ParallelAnimation {
                        id: appearAnim
                        NumberAnimation {
                            target: materialShape
                            properties: "opacity"
                            to: 1
                            duration: 50
                            easing.type: Appearance.animation.elementMoveFast.type
                            easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                        }
                        NumberAnimation {
                            target: materialShape
                            properties: "scale"
                            to: 1
                            duration: 200
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Appearance.animationCurves.expressiveFastSpatial
                        }
                        NumberAnimation {
                            target: materialShape
                            properties: "implicitSize"
                            to: 18
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Appearance.animationCurves.expressiveFastSpatial
                        }
                        ColorAnimation {
                            target: materialShape
                            properties: "color"
                            from: Appearance.colors.colPrimary
                            to: Appearance.colors.colOnLayer1
                            duration: 1000
                            easing.type: Appearance.animation.elementMoveFast.type
                            easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                        }
                    }
                }
            }
        }
    }
}
