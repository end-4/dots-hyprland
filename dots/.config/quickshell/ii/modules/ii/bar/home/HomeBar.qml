pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

MouseArea {
    id: root

    property bool opened: false

    implicitWidth: rowLayout.implicitWidth + 10 * 2
    implicitHeight: Appearance.sizes.barHeight

    acceptedButtons: Qt.LeftButton | Qt.RightButton
    hoverEnabled: true

    onPressed: mouse => {
        if (mouse.button === Qt.LeftButton) {
            root.opened = !root.opened;
            mouse.accepted = true;
            return;
        }

        if (mouse.button === Qt.RightButton) {
            HomeAssistant.refresh();
            mouse.accepted = true;
        }
    }

    RowLayout {
        id: rowLayout
        anchors.centerIn: parent

        MaterialSymbol {
            fill: 1
            text: "home"
            iconSize: Appearance.font.pixelSize.large
            color: Appearance.colors.colOnLayer1
            Layout.alignment: Qt.AlignVCenter
        }

        StyledText {
            visible: Config.options.bar.homeAssistant.showDeviceCounts
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer1
            text: HomeAssistant.loading
                ? Translation.tr("…")
                : `${HomeAssistant.onlineCount()}/${HomeAssistant.configuredCount()}`
            Layout.alignment: Qt.AlignVCenter
        }
    }

    HomePopup {
        id: homePopup
        hoverTarget: root
        active: root.opened || root.containsMouse
        onActiveChanged: {
            if (!active) {
                root.opened = false;
            }
        }
    }
}
