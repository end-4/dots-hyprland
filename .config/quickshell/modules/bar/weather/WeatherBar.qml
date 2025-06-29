pragma ComponentBehavior: Bound
import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/constants"
import "root:/services"
import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property real margin: 5
    implicitHeight: 32
    implicitWidth: mouseArea.implicitWidth + margin * 2

    MouseArea {
        id: mouseArea
        property bool hovered: false
        implicitWidth: rowLayout.implicitWidth
        implicitHeight: rowLayout.implicitHeight
        anchors.centerIn: root

        hoverEnabled: true
        onEntered: {
            popupLoader.item.visible = true;
        }
        onExited: {
            popupLoader.item.visible = false;
        }

        RowLayout {
            id: rowLayout

            MaterialSymbol {
                fill: 0
                text: WeatherIcons.codeToName[WeatherService.data.wCode]
                iconSize: Appearance.font.pixelSize.large
                color: Appearance.colors.colOnLayer1
            }

            StyledText {
                visible: true
                font.pixelSize: Appearance.font.pixelSize.large
                color: Appearance.colors.colOnLayer1
                text: WeatherService.data.temp
            }
        }
    }

    LazyLoader {
        id: popupLoader
        active: true

        component: PopupWindow {
            id: popupWindow
            implicitWidth: weatherPopup.implicitWidth
            implicitHeight: weatherPopup.implicitHeight
            anchor.item: root
            anchor.edges: Edges.Bottom
            anchor.rect.x: (root.implicitWidth - popupWindow.implicitWidth) / 2
            anchor.rect.y: root.implicitHeight + 10
            color: "transparent"
            WeatherPopup {
                id: weatherPopup
            }
        }
    }
}
