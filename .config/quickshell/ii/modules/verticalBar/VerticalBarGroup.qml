import qs.modules.common
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property real padding: 5
    implicitWidth: Appearance.sizes.baseVerticalBarWidth
    width: Appearance.sizes.verticalBarWidth
    implicitHeight: columnLayout.implicitHeight + padding * 2
    default property alias items: columnLayout.children

    Rectangle {
        id: background
        anchors {
            fill: parent
            leftMargin: 4
            rightMargin: 4
        }
        color: Config.options?.bar.borderless ? "transparent" : Appearance.colors.colLayer1
        radius: Appearance.rounding.small
    }

    ColumnLayout {
        id: columnLayout
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            bottom: parent.bottom
            topMargin: root.padding
            bottomMargin: root.padding
        }
        spacing: 12

        // Children defined by `items` prop
    }
}
