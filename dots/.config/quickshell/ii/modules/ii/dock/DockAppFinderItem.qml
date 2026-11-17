pragma ComponentBehavior: Bound
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

RippleButton {
    id: root
    required property var entry // DesktopEntry
    // Icon size adapts to the cell size so it scales with panel width/columns
    property real iconSize: Math.min(root.width * 0.45, root.height * 0.4)
    property color colText: Appearance.m3colors.m3onSurface
    property bool selected: false // Keyboard navigation highlight

    buttonRadius: Appearance.rounding.normal

    // M3 theme colors — hover is clearly visible in both dark and light mode;
    // pressing deepens the background (Button.down is a built-in read-only prop)
    readonly property color baseHover: Appearance.m3colors.m3secondaryContainer
    readonly property color pressedColor: ColorUtils.mix(Appearance.m3colors.m3secondaryContainer, Appearance.m3colors.m3onSecondaryContainer, 0.25)
    colBackground: "transparent"
    colBackgroundHover: root.down ? root.pressedColor : root.baseHover
    colRipple: root.baseHover
    toggled: root.selected
    colBackgroundToggled: root.down ? root.pressedColor : root.baseHover
    colBackgroundToggledHover: root.pressedColor

    PointingHandInteraction {}

    onClicked: {
        root.entry?.execute();
    }

    contentItem: ColumnLayout {
        anchors.centerIn: parent
        spacing: 4

        IconImage {
            Layout.alignment: Qt.AlignHCenter
            source: Quickshell.iconPath(root.entry?.icon ?? "", "image-missing")
            implicitSize: root.iconSize
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            Layout.maximumWidth: root.width - 8
            text: root.entry?.name ?? ""
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: root.colText
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
            maximumLineCount: 2
            wrapMode: Text.WordWrap
        }
    }
}
