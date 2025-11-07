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
    implicitWidth: contentColumn.implicitWidth + padding * 2
    implicitHeight: contentColumn.implicitHeight + padding * 2

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
                Layout.preferredWidth: 180
                placeholderText: root.iconState === "error" ? Translation.tr("Insert a valid number") : Translation.tr("Set FPS limit (e.g. 80)")
                inputMethodHints: Qt.ImhDigitsOnly
                focus: true

                onAccepted: {
                    root.applyLimit();
                }
            }

            RippleButton {
                id: applyButton
                implicitWidth: 25
                implicitHeight: 25
                buttonRadius: Appearance.rounding.full
                onClicked: {
                    root.applyLimit();
                }
                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: Appearance.font.pixelSize.title
                    text: root.iconState === "error" ? "close" : (root.iconState === "success" ? "check" : "save")
                    rotation: root.iconState !== "normal" ? 360 : 0
                    color: root.iconState === "error" ? "#ef5350" : (root.iconState === "success" ? Appearance.m3colors.m3primary : Appearance.m3colors.m3onSurface)

                    Behavior on rotation {
                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                    }

                    Behavior on color {
                        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                    }
                }
            }
        }

        Process {
            id: fpsSetter
        }
    }
}
