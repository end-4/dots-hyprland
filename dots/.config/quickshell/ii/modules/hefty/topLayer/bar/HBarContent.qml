pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.modules.common as C

Item {
    id: root

    property bool vertical: C.Config.options.bar.vertical
    property real spacing: 4

    Side {
        id: leftSide
        anchors.left: parent.left
        anchors.top: parent.top

        HBarUserFallbackComponentRepeater {
            componentNames: C.Config.options.hefty.bar.leftWidgets
        }
    }

    Side {
        id: centerLeftSide
        anchors.right: !root.vertical ? centerSide.left : parent.right
        anchors.bottom: root.vertical ? parent.bottom : undefined
        HBarUserFallbackComponentRepeater {
            componentNames: C.Config.options.hefty.bar.centerLeftWidgets
        }
    }

    Side {
        id: centerSide
        anchors.verticalCenter: root.vertical ? parent.verticalCenter : undefined
        anchors.horizontalCenter: !root.vertical ? parent.horizontalCenter : undefined
        HBarUserFallbackComponentRepeater {
            componentNames: C.Config.options.hefty.bar.centerWidgets
        }
    }

    Side {
        id: centerRightSide
        anchors.left: !root.vertical ? centerSide.right : parent.left
        anchors.top: root.vertical ? parent.top : undefined
        HBarUserFallbackComponentRepeater {
            componentNames: C.Config.options.hefty.bar.centerRightWidgets
        }
    }

    Side {
        id: rightSide
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        HBarUserFallbackComponentRepeater {
            componentNames: C.Config.options.hefty.bar.rightWidgets
        }
    }

    component Side: GridLayout {
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

        columns: C.Config.options.bar.vertical ? 1 : -1
        property real spacing: root.spacing
        columnSpacing: spacing
        rowSpacing: spacing
    }
}
