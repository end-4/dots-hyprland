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
    property real iconSize: Config.options?.dock.appFinder.iconSize ?? 40
    property color colText: Appearance.m3colors.m3onSurface

    buttonRadius: Appearance.rounding.normal

    colBackground: ColorUtils.transparentize(Appearance.colors.colLayer1Hover, 1)
    colBackgroundHover: Appearance.colors.colLayer1Hover
    colRipple: Appearance.colors.colLayer1Active

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
