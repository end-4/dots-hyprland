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

    // Apps row
    RowLayout {
        id: row
        anchors.fill: parent
        spacing: 0

        Repeater {
            // TODO: Include only apps (and windows) in current workspace only
            model: ScriptModel {
                objectProp: "appId"
                values: TaskbarApps.apps.filter(app => app.appId !== "SEPARATOR")
            }
            delegate: TaskAppButton {
                required property var modelData
                appEntry: modelData

                onHoverPreviewRequested: {
                    previewPopup.show(appEntry, this)
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
