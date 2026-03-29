pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.modules.common as C
import qs.modules.common.widgets as W

Item {
    id: root

    property bool vertical: C.Config.options.bar.vertical
    property real spacing: 4

    property list<var> leftWidgets: C.Config.options.hefty.bar.leftWidgets
    property list<var> centerLeftWidgets: C.Config.options.hefty.bar.centerLeftWidgets
    property list<var> centerWidgets: C.Config.options.hefty.bar.centerWidgets
    property list<var> centerRightWidgets: C.Config.options.hefty.bar.centerRightWidgets
    property list<var> rightWidgets: C.Config.options.hefty.bar.rightWidgets

    Side {
        id: leftSide
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.right: !root.vertical ? centerLeftSide.left : parent.right
        anchors.bottom: !root.vertical ? parent.bottom : centerLeftSide.top
        // For accessibility
        anchors.leftMargin: 0
        anchors.topMargin: 0

        HBarUserFallbackComponentRepeater {
            componentNames: root.leftWidgets
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }

    Side {
        id: centerLeftSide
        anchors.right: !root.vertical ? centerSide.left : parent.right
        anchors.bottom: !root.vertical ? parent.bottom : centerSide.top
        HBarUserFallbackComponentRepeater {
            componentNames: [...root.centerLeftWidgets, ...(root.centerLeftWidgets.length > 0 ? [invisibleItem] : []),]
        }
    }

    Side {
        id: centerSide
        anchors.verticalCenter: root.vertical ? parent.verticalCenter : undefined
        anchors.horizontalCenter: !root.vertical ? parent.horizontalCenter : undefined
        HBarUserFallbackComponentRepeater {
            componentNames: [...(root.centerLeftWidgets.length > 0 ? [invisibleItem] : []), ...root.centerWidgets, ...(root.centerRightWidgets.length > 0 ? [invisibleItem] : []),]
        }
    }

    Side {
        id: centerRightSide
        anchors.left: !root.vertical ? centerSide.right : parent.left
        anchors.top: !root.vertical ? parent.top : centerSide.bottom
        HBarUserFallbackComponentRepeater {
            componentNames: [...(root.centerLeftWidgets.length > 0 ? [invisibleItem] : []), ...root.centerRightWidgets,]
        }
    }

    Side {
        id: rightSide
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.left: !root.vertical ? centerRightSide.right : parent.left
        anchors.top: !root.vertical ? parent.top : centerRightSide.bottom
        // For accessibility
        anchors.rightMargin: 0
        anchors.bottomMargin: 0

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        HBarUserFallbackComponentRepeater {
            componentNames: root.rightWidgets
        }
    }

    component Side: W.BoxLayout {
        anchors {
            top: !root.vertical ? parent.top : undefined
            bottom: !root.vertical ? parent.bottom : undefined
            topMargin: root.spacing * root.vertical
            bottomMargin: root.spacing * root.vertical
            left: root.vertical ? parent.left : undefined
            right: root.vertical ? parent.right : undefined
            leftMargin: root.spacing * !root.vertical
            rightMargin: root.spacing * !root.vertical
        }

        vertical: C.Config.options.bar.vertical
        spacing: root.spacing
    }
}
