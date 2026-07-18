pragma ComponentBehavior: Bound
import QtQuick
import qs.modules.common as C

Rectangle {
    id: root

    property bool hover: false
    property bool press: false
    property bool drag: false
    property color contentColor: C.Appearance.m3colors.m3onBackground
    color: "transparent"

    FadeLoader {
        id: hoverLoader
        anchors.fill: parent
        shown: root.hover
        sourceComponent: StateLayer {
            state: StateLayer.State.Hover
            color: root.contentColor
            topLeftRadius: root.topLeftRadius
            topRightRadius: root.topRightRadius
            bottomLeftRadius: root.bottomLeftRadius
            bottomRightRadius: root.bottomRightRadius
        }
    }
    FadeLoader {
        id: focusLoader
        anchors.fill: parent
        shown: root.focus
        sourceComponent: StateLayer {
            state: StateLayer.State.Focus
            color: root.contentColor
            topLeftRadius: root.topLeftRadius
            topRightRadius: root.topRightRadius
            bottomLeftRadius: root.bottomLeftRadius
            bottomRightRadius: root.bottomRightRadius
        }
    }
    FadeLoader {
        id: pressLoader
        anchors.fill: parent
        shown: root.press
        sourceComponent: StateLayer {
            state: StateLayer.State.Press
            color: root.contentColor
            topLeftRadius: root.topLeftRadius
            topRightRadius: root.topRightRadius
            bottomLeftRadius: root.bottomLeftRadius
            bottomRightRadius: root.bottomRightRadius
        }
    }
    FadeLoader {
        id: dragLoader
        anchors.fill: parent
        shown: root.drag
        sourceComponent: StateLayer {
            state: StateLayer.State.Drag
            color: root.contentColor
            topLeftRadius: root.topLeftRadius
            topRightRadius: root.topRightRadius
            bottomLeftRadius: root.bottomLeftRadius
            bottomRightRadius: root.bottomRightRadius
        }
    }
}
