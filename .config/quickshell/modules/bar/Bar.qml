import "../common"
import "../common/widgets"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

Scope {
    id: bar

    readonly property int barHeight: 40
    readonly property int sideCenterModuleWidth: 360

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: barRoot

            property var modelData

            screen: modelData
            height: barHeight
            color: Appearance.colors.colLayer0

            // Left section
            RowLayout {
                anchors.left: parent.left
                implicitHeight: barHeight

                ActiveWindow {
                    bar: barRoot
                }

                // Scroll to change brightness
                WheelHandler {
                    onWheel: (event) => {
                        if (event.angleDelta.y < 0)
                            Brightness.value = -1;
                        else if (event.angleDelta.y > 0)
                            Brightness.value = 1;
                    }
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                }

            }

            // Middle section
            RowLayout {
                anchors.centerIn: parent
                spacing: 8

                RowLayout {
                    Layout.preferredWidth: sideCenterModuleWidth
                    spacing: 4
                    Layout.fillHeight: true
                    implicitWidth: 350

                    Resources {
                    }

                    Media {
                        Layout.fillWidth: true
                    }

                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 4

                    Workspaces {
                        bar: barRoot
                    }

                }

                RowLayout {
                    Layout.preferredWidth: sideCenterModuleWidth
                    Layout.fillHeight: true
                    spacing: 4

                    ClockWidget {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.fillWidth: true
                    }

                    UtilButtons {
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Battery {
                        Layout.alignment: Qt.AlignVCenter
                    }

                }

            }

            // Right section
            RowLayout {
                anchors.right: parent.right
                implicitHeight: barHeight
                spacing: 20

                SysTray {
                    bar: barRoot
                }

                Item { // TODO make this wifi & bluetooth
                    Layout.leftMargin: Appearance.rounding.screenRounding
                }

                // Scroll to change volume
                WheelHandler {
                    onWheel: (event) => {
                        const currentVolume = Audio.sink?.audio.volume;
                        const step = currentVolume < 0.1 ? 0.01 : 0.02 || 0.2;
                        if (event.angleDelta.y < 0)
                            Audio.sink.audio.volume -= step;
                        else if (event.angleDelta.y > 0)
                            Audio.sink.audio.volume += step;
                    }
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                }

            }

            anchors {
                top: true
                left: true
                right: true
            }

        }

    }

}
