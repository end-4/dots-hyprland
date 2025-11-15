import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.modules.common
import qs.modules.common.functions
import qs.modules.waffle.looks

BarPopup {
    id: root
    default property var menuData
    property var model: [
        {iconName: "start-here", text: "Start", action: () => {print("hello")}}
    ]
    padding: 2

    contentItem: ColumnLayout {
        anchors.centerIn: parent
        spacing: 0

        Repeater {
            model: root.model
            delegate: WButton {
                id: btn
                Layout.fillWidth: true

                required property var modelData
                icon.name: modelData.iconName ? modelData.iconName : ""
                monochromeIcon: modelData.monochromeIcon ?? true
                text: modelData.text ? modelData.text : ""

                onClicked: {
                    if (modelData.action) modelData.action();
                    root.close();
                }
            }
        }
    }
}
