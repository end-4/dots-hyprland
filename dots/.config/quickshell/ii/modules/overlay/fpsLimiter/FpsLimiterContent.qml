import qs.services
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.widgets

Rectangle {
    id: root
    color: Appearance.m3colors.m3surfaceContainer
    property real padding: 16
    property string iconState: "normal"
    anchors.fill: parent
    implicitWidth: content.implicitWidth + (padding * 2)
    implicitHeight: content.implicitHeight + (padding * 2)

    Timer {
        id: iconResetTimer
        interval: 1000
        onTriggered: {
            root.iconState = "normal";
        }
    }

    function applyLimit() {
        var fpsValue = parseInt(fpsField.text);
        if (isNaN(fpsValue) || fpsValue < 0) {
            root.iconState = "error";
            iconResetTimer.restart();
            fpsField.text = "";
            return;
        }

        var cfgPaths = [
            "~/.config/MangoHud/MangoHud.conf",
        ]; // MangoHud config files

        var updateCommands = cfgPaths.map(path => {
            return "if grep -q '^fps_limit=' " + path + "; " +
            "then sed -i 's/^fps_limit=.*/fps_limit=" + fpsValue + "/' " + path + "; " +
            "else echo 'fps_limit=" + fpsValue + "' >> " + path + "; fi";
        }).join("; ");

        var cmd = updateCommands + "; pkill -SIGUSR2 mangohud";

        fpsSetter.command = ["bash", "-c", cmd];
        fpsSetter.startDetached();

        root.iconState = "success";
        iconResetTimer.restart();

        // Clear the field after applying
        fpsField.text = "";
    }

    Process {
        id: fpsSetter
    }

    RowLayout {
        id: content
        anchors.centerIn: parent
        spacing: 4

        ToolbarTextField {
            id: fpsField
            Layout.fillWidth: true
            Layout.preferredWidth: 200
            placeholderText: root.iconState === "error" ? Translation.tr("Insert a valid number") : Translation.tr("Set FPS limit (e.g. 80)")
            inputMethodHints: Qt.ImhDigitsOnly
            focus: true

            onAccepted: {
                root.applyLimit();
            }
        }

        IconToolbarButton {
            id: applyButton
            text: root.iconState === "error" ? "close" : (root.iconState === "success" ? "check" : "save")
            enabled: root.iconState === "normal" && fpsField.text.length > 0
            onClicked: {
                root.applyLimit();
            }
        }
    }
}
