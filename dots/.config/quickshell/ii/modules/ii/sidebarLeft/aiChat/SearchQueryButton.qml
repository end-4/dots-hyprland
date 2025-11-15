import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland

RippleButton {
    id: root
    property string query

    implicitHeight: 30
    leftPadding: 6
    rightPadding: 10
    buttonRadius: Appearance.rounding.verysmall
    colBackground: Appearance.colors.colSurfaceContainerHighest
    colBackgroundHover: Appearance.colors.colSurfaceContainerHighestHover
    colRipple: Appearance.colors.colSurfaceContainerHighestActive

    PointingHandInteraction {}
    onClicked: {
        let url = Config.options.search.engineBaseUrl + root.query;
        for (let site of (Config?.options?.search.excludedSites ?? [])) {
            url += ` -site:${site}`;
        }
        Qt.openUrlExternally(url);
        GlobalStates.sidebarLeftOpen = false;
    }

    contentItem: Item {
        anchors.centerIn: parent
        implicitWidth: rowLayout.implicitWidth
        implicitHeight: rowLayout.implicitHeight
        RowLayout {
            id: rowLayout
            anchors.centerIn: parent
            spacing: 5
            MaterialSymbol {
                text: "search"
                iconSize: 20
                color: Appearance.m3colors.m3onSurface
            }
            StyledText {
                id: text
                horizontalAlignment: Text.AlignHCenter
                text: root.query
                color: Appearance.m3colors.m3onSurface
            }
        }
    }
}
