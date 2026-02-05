pragma ComponentBehavior: Bound
import QtQuick

Rectangle {
    id: root

    property bool hover: false
    property bool press: false
    property bool drag: false
    property color contentColor: Appearance.m3colors.m3onBackground
    color: "transparent"

    FadeLoader {
        id: hoverLoader
        anchors.fill: parent
        shown: root.hover
        sourceComponent: StateLayer {
            radius: root.radius
            state: StateLayer.State.Hover
            color: root.contentColor
        }
    }
    FadeLoader {
        id: focusLoader
        anchors.fill: parent
        shown: root.focus
        sourceComponent: StateLayer {
            radius: root.radius
            state: StateLayer.State.Focus
            color: root.contentColor
        }
    }
    FadeLoader {
        id: pressLoader
        anchors.fill: parent
        shown: root.press
        sourceComponent: StateLayer {
            radius: root.radius
            state: StateLayer.State.Press
            color: root.contentColor
        }
    }
    FadeLoader {
        id: dragLoader
        anchors.fill: parent
        shown: root.drag
        sourceComponent: StateLayer {
            radius: root.radius
            state: StateLayer.State.Drag
            color: root.contentColor
        }
    }
}
