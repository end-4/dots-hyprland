import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import qs.modules.common
import qs.modules.common.functions
import qs.modules.waffle.looks

Loader {
    id: root

    property Item anchorItem: parent
    property real visualMargin: 12
    readonly property bool barAtBottom: Config.options.waffles.bar.bottom
    property real ambientShadowWidth: 1

    active: false
    visible: active
    sourceComponent: PopupWindow {
        id: popupWindow
        visible: true
        Component.onCompleted: {
            openAnim.start();
        }

        anchor {
            adjustment: PopupAdjustment.Slide
            item: root.anchorItem
            gravity: root.barAtBottom ? Edges.Top : Edges.Bottom
            edges: root.barAtBottom ? Edges.Top : Edges.Bottom
        }

        HyprlandFocusGrab {
            id: focusGrab
            active: true
            windows: [popupWindow]
            onCleared: {
                closeAnim.start();
            }
        }

        implicitWidth: realContent.implicitWidth + (ambientShadow.border.width * 2) + (root.visualMargin * 2)
        implicitHeight: realContent.implicitHeight + (ambientShadow.border.width * 2) + (root.visualMargin * 2)

        property real sourceEdgeMargin: -implicitHeight
        PropertyAnimation {
            id: openAnim
            target: popupWindow
            property: "sourceEdgeMargin"
            to: (root.ambientShadowWidth + root.visualMargin)
            duration: 200
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Looks.transition.easing.bezierCurve.easeIn
        }
        SequentialAnimation {
            id: closeAnim
            PropertyAnimation {
                target: popupWindow
                property: "sourceEdgeMargin"
                to: -implicitHeight
                duration: 150
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Looks.transition.easing.bezierCurve.easeOut
            }
            ScriptAction {
                script: {
                    root.active = false;
                }
            }
        }

        color: "transparent"
        Rectangle {
            id: ambientShadow
            z: 0
            anchors {
                fill: realContent
                margins: -border.width
            }
            border.color: ColorUtils.transparentize(Looks.colors.bg0Border, Looks.shadowTransparency)
            border.width: root.ambientShadowWidth
            color: "transparent"
            radius: realContent.radius + border.width
        }
        
        Rectangle {
            id: realContent
            z: 1
            anchors {
                left: parent.left
                right: parent.right
                top: root.barAtBottom ? undefined : parent.top
                bottom: root.barAtBottom ? parent.bottom : undefined
                margins: root.ambientShadowWidth + root.visualMargin
                // Opening anim
                bottomMargin: root.barAtBottom ? popupWindow.sourceEdgeMargin : (root.ambientShadowWidth + root.visualMargin)
                topMargin: root.barAtBottom ? (root.ambientShadowWidth + root.visualMargin) : popupWindow.sourceEdgeMargin
            }
            color: Looks.colors.bg1
            radius: Looks.radius.large

            // test
            implicitWidth: 300
            implicitHeight: 400

            Menu {
                id: menu
            }
        }
    }
}
