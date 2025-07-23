pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import Quickshell
import QtQuick
import QtQuick.Layouts

MouseArea {
    id: root
    property real margin: 10
    property bool hovered: false
    implicitWidth: rowLayout.implicitWidth + margin * 2
    implicitHeight: rowLayout.implicitHeight

    hoverEnabled: true

    RowLayout {
        id: rowLayout
        anchors.centerIn: parent
        
        MaterialSymbol {
            fill: 0
            text: WeatherIcons.codeToName[Weather.data.wCode]
            iconSize: Appearance.font.pixelSize.large
            color: Appearance.colors.colOnLayer1
            Layout.alignment: Qt.AlignVCenter
        }

        StyledText {
            visible: true
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer1
            text: Weather.data.temp
            Layout.alignment: Qt.AlignVCenter
        }
    }

    LazyLoader {
        id: popupLoader
        active: root.containsMouse

        component: PopupWindow {
            id: popupWindow
            visible: true
            implicitWidth: weatherPopup.implicitWidth
            implicitHeight: weatherPopup.implicitHeight
            anchor.item: root
            anchor.edges: Edges.Top
            anchor.rect.x: (root.implicitWidth - popupWindow.implicitWidth) / 2
            anchor.rect.y: Config.options.bar.bottom ? 
                (-weatherPopup.implicitHeight - 15) :
                (root.implicitHeight + 15 )
            color: "transparent"
            WeatherPopup {
                id: weatherPopup
            }
        }
    }
}
