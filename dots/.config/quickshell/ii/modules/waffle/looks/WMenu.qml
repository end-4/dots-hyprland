pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.modules.common
import qs.modules.common.functions
import qs.modules.waffle.looks

Menu {
    id: root

    property bool downDirection: false
    property bool hasIcons: false // TODO: implement

    implicitWidth: background.implicitWidth + root.padding * 2
    implicitHeight: background.implicitHeight + root.padding * 2
    padding: 3
    property real sourceEdgeMargin: -implicitHeight
    clip: true
    
    enter: Transition {
        NumberAnimation {
            property: "sourceEdgeMargin"
            from: -root.implicitHeight
            to: root.padding
            duration: 200
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Looks.transition.easing.bezierCurve.easeIn
        }
    }
    exit: Transition {
        NumberAnimation {
            property: "sourceEdgeMargin"
            from: root.padding
            to: -root.implicitHeight
            duration: 150
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Looks.transition.easing.bezierCurve.easeOut
        }
    }

    background: WPane {
        anchors {
            left: parent.left
            right: parent.right
            top: root.downDirection ? parent.top : undefined
            bottom: root.downDirection ? undefined : parent.bottom
            margins: root.padding
            topMargin: root.downDirection ? root.sourceEdgeMargin : root.padding
            bottomMargin: root.downDirection ? root.padding : root.sourceEdgeMargin
        }
        contentItem: Rectangle {
            color: Looks.colors.bg1Base
            implicitWidth: menuListView.implicitWidth + root.padding * 2
            implicitHeight: root.contentItem.implicitHeight + root.padding * 2
        }
    }

    contentItem: ListView {
        id: menuListView
        anchors {
            left: parent.left
            right: parent.right
            top: root.downDirection ? parent.top : undefined
            bottom: root.downDirection ? undefined : parent.bottom
            margins: root.padding * 2
            topMargin: root.downDirection ? root.sourceEdgeMargin : root.padding
            bottomMargin: root.downDirection ? root.padding : root.sourceEdgeMargin
        }
        implicitHeight: contentHeight
        implicitWidth: Array.from({
            length: count
        }, (_, i) => itemAtIndex(i)?.implicitWidth ?? 0).reduce((a, b) => a > b ? a : b)

        model: root.contentModel
    }

    delegate: WMenuItem {
        id: menuItemDelegate
    }
}
