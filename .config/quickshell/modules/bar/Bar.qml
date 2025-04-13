import "../common"
import "../common/widgets"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

Scope {
    id: bar

    readonly property int barHeight: Appearance.sizes.barHeight
    readonly property int barCenterSideModuleWidth: Appearance.sizes.barCenterSideModuleWidth

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: barRoot

            property var modelData

            screen: modelData
            height: barHeight + Appearance.rounding.screenRounding
            exclusiveZone: barHeight
            mask: Region {
                item: barContent
            }
            color: "transparent"

            anchors {
                top: true
                left: true
                right: true
            }

            Rectangle {
                id: barContent
                anchors.right: parent.right
                anchors.left: parent.left
                anchors.top: parent.top
                color: Appearance.colors.colLayer0
                height: barHeight
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
                        Layout.preferredWidth: barCenterSideModuleWidth
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
                        Layout.preferredWidth: barCenterSideModuleWidth
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
            }

            // Round decorators
            Item {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: Appearance.rounding.screenRounding

                RoundCorner {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    size: Appearance.rounding.screenRounding
                    corner: cornerEnum.topLeft
                    color: Appearance.colors.colLayer0
                }
                RoundCorner {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    size: Appearance.rounding.screenRounding
                    corner: cornerEnum.topRight
                    color: Appearance.colors.colLayer0
                }
            }

        }

    }

}
