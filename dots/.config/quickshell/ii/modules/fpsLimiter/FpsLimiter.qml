import qs.services
import qs.modules.common
import qs.modules.common.widgets
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Scope {
    id: root

    Loader {
        id: fpsLoader
        active: false

        sourceComponent: PanelWindow {
            id: fpsWindow
            visible: fpsLoader.active
            exclusiveZone: 0
            implicitWidth: fpsBackground.implicitWidth + Appearance.sizes.elevationMargin * 2
            implicitHeight: fpsBackground.implicitHeight + Appearance.sizes.elevationMargin * 2
            color: "transparent"
            WlrLayershell.namespace: "quickshell:fpsLimiter"

            mask: Region {
                item: fpsBackground
            }

            function hide() {
                fpsLoader.active = false;
            }

            function applyLimit() {
                var fpsValue = parseInt(fpsField.text);
                if (isNaN(fpsValue) || fpsValue < 0) {
                    hide();
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

                var cmd = updateCommands;

                fpsSetter.command = ["bash", "-c", cmd];
                fpsSetter.startDetached();

                hide();
            }
            HyprlandFocusGrab {
                id: grab
                windows: [fpsWindow]
                active: fpsWindow.visible
                onCleared: () => {
                    if (!active) {
                        fpsWindow.hide();
                    }
                }
            }

            StyledRectangularShadow {
                target: fpsBackground
            }

            Rectangle {
                id: fpsBackground
                anchors.centerIn: parent
                color: Appearance.colors.colLayer0
                border.width: 1
                border.color: Appearance.colors.colLayer0Border
                radius: Appearance.rounding.windowRounding

                property real padding: 20
                implicitWidth: fpsColumn.implicitWidth + padding * 2
                implicitHeight: fpsColumn.implicitHeight + padding * 2
                Keys.onPressed: event => {

                    if (event.key === Qt.Key_Escape) {
                        fpsWindow.hide();
                        event.accepted = true;
                    }
                }

                ColumnLayout {
                    id: fpsColumn
                    anchors.centerIn: parent
                    spacing: 15

                    /*
                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        font.family: Appearance.font.family.title
                        font.pixelSize: Appearance.font.pixelSize.title
                        text: qsTr("Set FPS limit")
                    }
                    */

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        ToolbarTextField {
                            id: fpsField
                            Layout.fillWidth: true
                            placeholderText: qsTr("Set FPS limit (e.g. 80)")
                            inputMethodHints: Qt.ImhDigitsOnly
                            focus: true

                            Keys.onReturnPressed: {
                                fpsWindow.applyLimit();
                                event.accepted = true;
                            }
                        }

                        RippleButton {
                            id: applyButton
                            implicitWidth: 36
                            implicitHeight: 36
                            buttonRadius: Appearance.rounding.full
                            onClicked: {
                                fpsWindow.applyLimit();
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
        }
    }

    IpcHandler {
        target: "fpsLimiter"
        function toggle() { fpsLoader.active = !fpsLoader.active; }
        function open() { fpsLoader.active = true; }
        function close() { fpsLoader.active = false; }
    }

    GlobalShortcut {
        name: "fpsLimiterToggle"
        description: qsTr("Toggle FPS limiter popup")
        onPressed: {
            fpsLoader.active = !fpsLoader.active;
        }
    }
}
