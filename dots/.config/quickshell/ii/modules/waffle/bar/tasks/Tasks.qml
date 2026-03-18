import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.waffle.looks

MouseArea {
    id: root

    Layout.fillHeight: true
    implicitHeight: appRow.implicitHeight
    implicitWidth: appRow.implicitWidth
    hoverEnabled: true

    function showPreviewPopup(appEntry, button) {
        previewPopup.show(appEntry, button);
    }

    Behavior on implicitWidth {
        animation: Looks.transition.move.createObject(this)
    }

    WListView {
        id: appRow
        anchors {
            top: parent.top
            bottom: parent.bottom
        }
        orientation: Qt.Horizontal
        spacing: 0
        implicitWidth: contentWidth
        clip: true
        interactive: false
        // TODO: Include only apps (and windows) in current workspace only | wait, does that even make sense in a Hyprland workflow?
        model: ScriptModel {
            objectProp: "appId"
            values: TaskbarApps.apps.filter(app => app.appId !== "SEPARATOR")
        }
        delegate: TaskAppButton {
            required property var modelData
            appEntry: modelData

            onHoverPreviewRequested: {
                root.showPreviewPopup(appEntry, this);
            }
            onHoverPreviewDismissed: {
                previewPopup.close();
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
