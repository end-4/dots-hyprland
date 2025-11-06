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
    property real padding: 20
    property bool showCheckIcon: false
    property bool showError: false
    implicitWidth: contentColumn.implicitWidth + padding * 2
    implicitHeight: contentColumn.implicitHeight + padding * 2

    Timer {
        id: iconResetTimer
        interval: 1000
        onTriggered: {
            root.showCheckIcon = false;
        }
    }

    Timer {
        id: errorResetTimer
        interval: 1000
        onTriggered: {
            root.showError = false;
        }
    }

    function applyLimit() {
        var fpsValue = parseInt(fpsField.text);
        if (isNaN(fpsValue) || fpsValue < 0) {
            root.showError = true;
            errorResetTimer.restart();
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

        root.showCheckIcon = true;
        iconResetTimer.restart();

        // Clear the field after applying
        fpsField.text = "";
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            fpsField.text = "";
            event.onAccepted();
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
                placeholderText: root.showError ? Translation.tr("Insert a valid number!") : Translation.tr("Set FPS limit (e.g. 80)")
                inputMethodHints: Qt.ImhDigitsOnly
                focus: true

                Keys.onReturnPressed: {
                    root.applyLimit();
                    event.onAccepted();
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
                    text: root.showError ? "close" : (root.showCheckIcon ? "check" : "save")
                    rotation: (root.showCheckIcon || root.showError) ? 360 : 0
                    color: root.showError ? "#ef5350" : (root.showCheckIcon ? Appearance.m3colors.m3primary : Appearance.m3colors.m3onSurface)

                    Behavior on rotation {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                        }
                    }
                }
            }
        }

        Process {
            id: fpsSetter
        }
    }
}
