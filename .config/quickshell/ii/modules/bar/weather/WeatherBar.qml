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

    StyledPopup {
        hoverTarget: root
        
        WeatherPopup {
            id: weatherPopup
            anchors.centerIn: parent
        }
    }
}
