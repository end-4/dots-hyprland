import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.waffle.looks

Item {
    id: root

    Layout.fillHeight: true
    implicitHeight: row.implicitHeight
    implicitWidth: row.implicitWidth

    // Apps row
    RowLayout {
        id: row
        anchors.fill: parent
        spacing: 4

        Repeater {
            model: ScriptModel {
                objectProp: "appId"
                values: TaskbarApps.apps.filter(app => app.appId !== "SEPARATOR")
            }
            delegate: TaskAppButton {
                required property var modelData
                toplevel: modelData
            }
        }
    }

    // TODO: Previews popup
}
