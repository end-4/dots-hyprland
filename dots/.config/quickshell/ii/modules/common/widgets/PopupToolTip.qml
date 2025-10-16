import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

Item {
    id: root
    property string text: ""
    property bool extraVisibleCondition: true
    property bool alternativeVisibleCondition: false
    property real horizontalPadding: 10
    property real verticalPadding: 5

    property var anchorEdges: Edges.Top
    property var anchorGravity: anchorEdges

    readonly property bool internalVisibleCondition: (extraVisibleCondition && (parent.hovered === undefined || parent?.hovered)) || alternativeVisibleCondition

    Loader {
        id: tooltipLoader
        anchors.fill: parent
        active: internalVisibleCondition
        sourceComponent: PopupWindow {
            visible: true
            anchor {
                window: root.QsWindow.window
                item: root.parent
                edges: root.anchorEdges
                gravity: root.anchorGravity
            }
            mask: Region {
                item: null
            }

            color: "transparent"
            implicitWidth: contentItem.implicitWidth + root.horizontalPadding * 2
            implicitHeight: contentItem.implicitHeight + root.verticalPadding * 2

            StyledToolTipContent {
                id: contentItem
                anchors.centerIn: parent
                text: root.text
                shown: false
                Component.onCompleted: shown = true
                horizontalPadding: root.horizontalPadding
                verticalPadding: root.verticalPadding
            }
        }
    }
}
