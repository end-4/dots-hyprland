import QtQuick
import QtQuick.Layouts
import qs.modules.common as C

Item {
    id: root

    Side {
        id: leftSide
        anchors.left: parent.left
        width: (parent.width - centerSide.width) / 2
        HBarUserFallbackComponentRepeater {
            componentNames: C.Config.options.hefty.bar.leftWidgets
        }
    }

    Side {
        id: centerSide
        anchors.horizontalCenter: parent.horizontalCenter
        HBarUserFallbackComponentRepeater {
            componentNames: C.Config.options.hefty.bar.centerWidgets
        }
    }

    Side {
        id: rightSide
        anchors.right: parent.right
        width: (parent.width - centerSide.width) / 2
        HBarUserFallbackComponentRepeater {
            componentNames: C.Config.options.hefty.bar.rightWidgets
        }
    }

    component Side: RowLayout {
        anchors {
            top: parent.top
            bottom: parent.bottom
        }
    }
}
