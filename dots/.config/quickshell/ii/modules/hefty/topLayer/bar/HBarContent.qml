import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common.widgets

Item {
    id: root

    Side {
        id: leftSide
        anchors.left: parent.left
        width: (parent.width - centerSide.width) / 2
    }

    Side {
        id: centerSide
        anchors.horizontalCenter: parent.horizontalCenter
        HBarUserFallbackComponentRepeater {
            componentNames: [["Workspaces"]]
        }
    }

    Side {
        id: rightSide
        anchors.right: parent.right
        width: (parent.width - centerSide.width) / 2
    }

    component Side: RowLayout {
        anchors {
            top: parent.top
            bottom: parent.bottom
        }
    }
}
