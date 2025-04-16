import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Scope {
    id: bar

    readonly property int barHeight: Appearance.sizes.barHeight
    readonly property int barCenterSideModuleWidth: Appearance.sizes.barCenterSideModuleWidth

    Process {
        id: openSidebarRight
        command: ["qs", "ipc", "call", "sidebarRight", "open"]
    }
    Process {
        id: openSidebarLeft
        command: ["qs", "ipc", "call", "sidebarLeft", "open"]
    }

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
                    id: leftSection
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
                    id: middleSection
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
                    id: rightSection
                    anchors.right: parent.right
                    implicitHeight: barHeight
                    width: Appearance.sizes.barPreferredSideSectionWidth
                    spacing: 5
                    layoutDirection: Qt.RightToLeft
            
                    Rectangle {
                        Layout.margins: 4
                        Layout.rightMargin: Appearance.rounding.screenRounding
                        Layout.fillHeight: true
                        implicitWidth: rowLayout.implicitWidth + 10*2
                        radius: Appearance.rounding.full
                        color: barRightSideMouseArea.pressed ? Appearance.colors.colLayer1Active : barRightSideMouseArea.hovered ? Appearance.colors.colLayer1Hover : "transparent"
                        RowLayout {
                            id: rowLayout
                            anchors.centerIn: parent
                            spacing: 15
                            
                            MaterialSymbol {
                                text: (Network.networkName.length > 0 && Network.networkName != "lo") ? (
                                    Network.networkStrength > 80 ? "signal_wifi_4_bar" :
                                    Network.networkStrength > 60 ? "network_wifi_3_bar" :
                                    Network.networkStrength > 40 ? "network_wifi_2_bar" :
                                    Network.networkStrength > 20 ? "network_wifi_1_bar" :
                                    "signal_wifi_0_bar"
                                ) : "signal_wifi_off"
                                font.pixelSize: Appearance.font.pixelSize.larger
                                color: Appearance.colors.colOnLayer0
                            }
                            MaterialSymbol {
                                text: Bluetooth.bluetoothConnected ? "bluetooth_connected" : Bluetooth.bluetoothEnabled ? "bluetooth" : "bluetooth_disabled"
                                font.pixelSize: Appearance.font.pixelSize.larger
                                color: Appearance.colors.colOnLayer0
                            }
                        }
                    }

                    SysTray {
                        bar: barRoot
                        Layout.fillWidth: false
                    }

                    Item {
                        Layout.fillWidth: true
                    }


                }
                MouseArea {
                    id: barRightSideMouseArea
                    property bool hovered: false
                    anchors.fill: rightSection
                    acceptedButtons: Qt.LeftButton
                    hoverEnabled: true
                    propagateComposedEvents: true
                    onEntered: (event) => {
                        barRightSideMouseArea.hovered = true
                    }
                    onExited: (event) => {
                        barRightSideMouseArea.hovered = false
                    }
                    onPressed: (event) => {
                        if (event.button === Qt.LeftButton) {
                            openSidebarRight.running = true
                        }
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
