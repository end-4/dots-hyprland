import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.waffle.looks

MouseArea {
    id: root

    Layout.fillHeight: true
    implicitHeight: row.implicitHeight
    implicitWidth: row.implicitWidth
    hoverEnabled: true

    function showPreviewPopup(appEntry, button) {
        previewPopup.show(appEntry, button);
    }

    // Apps row
    RowLayout {
        id: row
        anchors.fill: parent
        spacing: 0

        Repeater {
            // TODO: Include only apps (and windows) in current workspace only | wait, does that even make sense in a Hyprland workflow?
            model: ScriptModel {
                objectProp: "appId"
                values: TaskbarApps.apps.filter(app => app.appId !== "SEPARATOR")
            }
            delegate: TaskAppButton {
                required property var modelData
                appEntry: modelData

                onHoverPreviewRequested: {
                    root.showPreviewPopup(appEntry, this)
                }
            }
        }
    }

    // Previews popup
    TaskPreview {
        id: previewPopup
        tasksHovered: root.containsMouse
        anchor.window: root.QsWindow.window
    }
}
