import "../common"
import "../common/widgets"
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
        id: toggleSidebarRight
        command: ["qs", "ipc", "call", "sidebarRight", "toggle"]
    }
    Process {
        id: toggleSidebarLeft
        command: ["qs", "ipc", "call", "sidebarLeft", "toggle"]
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
                    spacing: 20
                    layoutDirection: Qt.RightToLeft

                    Item { // TODO make this wifi & bluetooth
                        Layout.leftMargin: Appearance.rounding.screenRounding
                        Layout.fillWidth: false
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
                    anchors.fill: rightSection
                    acceptedButtons: Qt.LeftButton
                    onPressed: (event) => {
                        if (event.button === Qt.LeftButton) {
                            toggleSidebarRight.running = true
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
