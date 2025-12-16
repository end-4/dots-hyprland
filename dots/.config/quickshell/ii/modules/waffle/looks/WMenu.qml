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

    property color color: Looks.colors.bg1Base
    property alias backgroundPane: bgPane

    implicitWidth: background.implicitWidth + margins * 2
    implicitHeight: background.implicitHeight + margins * 2
    margins: 10
    padding: 3
    property real sourceEdgeMargin: -implicitHeight
    clip: true

    enter: Transition {
        NumberAnimation {
            property: "sourceEdgeMargin"
            from: -root.implicitHeight
            to: root.margins
            duration: 200
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Looks.transition.easing.bezierCurve.easeIn
        }
    }
    exit: Transition {
        NumberAnimation {
            property: "sourceEdgeMargin"
            from: root.margins
            to: -root.implicitHeight
            duration: 150
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Looks.transition.easing.bezierCurve.easeOut
        }
    }

    background: Item {
        id: bgItem
        implicitWidth: bgPane.implicitWidth
        implicitHeight: bgPane.implicitHeight
        WPane {
            id: bgPane
            anchors {
                left: parent.left
                right: parent.right
                top: root.downDirection ? parent.top : undefined
                bottom: root.downDirection ? undefined : parent.bottom
                margins: root.margins
                topMargin: root.downDirection ? root.sourceEdgeMargin : root.margins
                bottomMargin: root.downDirection ? root.margins : root.sourceEdgeMargin
            }
            contentItem: Rectangle {
                color: root.color
                implicitWidth: menuListView.implicitWidth + root.padding * 2
                implicitHeight: root.contentItem.implicitHeight + root.padding * 2
            }

        }
    }

    Component.onCompleted: {
        menuListView.itemAtIndex(0)?.forceActiveFocus();
    }

    contentItem: Item {
        implicitWidth: menuListView.implicitWidth
        implicitHeight: menuListView.implicitHeight
        ListView {
            id: menuListView
            anchors {
                left: parent.left
                right: parent.right
                top: root.downDirection ? parent.top : undefined
                bottom: root.downDirection ? undefined : parent.bottom
                margins: root.margins // ????
                topMargin: root.downDirection ? root.sourceEdgeMargin : root.margins
                bottomMargin: root.downDirection ? root.margins : root.sourceEdgeMargin
            }
            implicitHeight: contentHeight
            implicitWidth: Array.from({
                length: count
            }, (_, i) => itemAtIndex(i)?.implicitWidth ?? 0).reduce((a, b) => a > b ? a : b)

            model: root.contentModel
        }
    }

    delegate: WMenuItem {
        id: menuItemDelegate
    }
}
