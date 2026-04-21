pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import qs.modules.common
import qs.modules.common.functions
import qs.modules.waffle.looks

Loader {
    id: root

    required property var contentItem
    property real padding: Looks.radius.large - Looks.radius.medium
    property bool noSmoothClosing: !Config.options.waffles.tweaks.smootherMenuAnimations
    property bool closeOnFocusLost: true
    signal focusCleared()
    
    property Item anchorItem: parent
    property real visualMargin: 12
    readonly property bool barAtBottom: Config.options.waffles.bar.bottom
    property real ambientShadowWidth: 1

    onFocusCleared: {
        if (!root.closeOnFocusLost) return;
        root.close()
    }

    function grabFocus() { // Doesn't work
        item.grabFocus();
    }

    function close() {
        item.close();
    }

    function updateAnchor() {
        item?.anchor.updateAnchor();
    }

    active: false
    visible: active
    sourceComponent: PopupWindow {
        id: popupWindow
        visible: true
        Component.onCompleted: {
            openAnim.start();
        }

        anchor {
            adjustment: PopupAdjustment.ResizeY | PopupAdjustment.SlideX
            item: root.anchorItem
            gravity: root.barAtBottom ? Edges.Top : Edges.Bottom
            edges: root.barAtBottom ? Edges.Top : Edges.Bottom
        }

        HyprlandFocusGrab {
            id: focusGrab
            active: true
            windows: [popupWindow]
            onCleared: root.focusCleared();
        }

        function close() {
            if (root.noSmoothClosing) root.active = false;
            else closeAnim.start();
        }

        function grabFocus() {
            focusGrab.active = true; // Doesn't work
        }

        implicitWidth: realContent.implicitWidth + (root.ambientShadowWidth * 2) + (root.visualMargin * 2)
        implicitHeight: realContent.implicitHeight + (root.ambientShadowWidth * 2) + (root.visualMargin * 2)

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
        WAmbientShadow {
            target: realContent
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
            color: Looks.colors.bg1Base
            radius: Looks.radius.large

            // test
            implicitWidth: root.contentItem.implicitWidth + (root.padding * 2)
            implicitHeight: root.contentItem.implicitHeight + (root.padding * 2)

            children: [root.contentItem]
        }
    }
}
