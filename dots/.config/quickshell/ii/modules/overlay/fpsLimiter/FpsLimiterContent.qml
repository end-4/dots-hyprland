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
    property real padding: 20
    implicitWidth: contentColumn.implicitWidth + padding * 2
    implicitHeight: contentColumn.implicitHeight + padding * 2

    function applyLimit() {
        var fpsValue = parseInt(fpsField.text);
        if (isNaN(fpsValue) || fpsValue < 0) {
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

        // Clear the field after applying
        fpsField.text = "";
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            fpsField.text = "";
            event.accepted = true;
        }
    }

    ColumnLayout {
        id: contentColumn
        anchors.centerIn: parent
        spacing: 15

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            ToolbarTextField {
                id: fpsField
                Layout.fillWidth: true
                Layout.preferredWidth: 200
                placeholderText: qsTr("Set FPS limit (e.g. 80)")
                inputMethodHints: Qt.ImhDigitsOnly
                focus: true

                Keys.onReturnPressed: {
                    root.applyLimit();
                    event.accepted = true;
                }
            }

            RippleButton {
                id: applyButton
                implicitWidth: 36
                implicitHeight: 36
                buttonRadius: Appearance.rounding.full
                onClicked: {
                    root.applyLimit();
                }
                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: Appearance.font.pixelSize.title
                    text: "keyboard_return"
                }
            }
        }

        Process {
            id: fpsSetter
        }
    }
}
