import "modules/common"
import "modules/common/widgets"
import "services"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root

    property bool active: false
    property var focusedScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null
    
    // Dynamic properties passed via IPC
    property string deviceType: "mouse" // "mouse", "pen_drive", "ssd", "hdd"
    property string deviceName: ""
    property string deviceSubtype: ""

    function triggerPopup() {
        root.active = true;
        closeTimer.restart();
    }

    Timer {
        id: closeTimer
        interval: 4000 // 4 seconds
        repeat: false
        running: false
        onTriggered: {
            root.active = false;
        }
    }

    IpcHandler {
        target: "deviceConnectorService"

        function showDeviceConnected(deviceType: string, deviceName: string, deviceSubtype: string): void {
            root.deviceType = deviceType;
            root.deviceName = deviceName;
            root.deviceSubtype = deviceSubtype;
            root.triggerPopup();
        }
    }

    PanelWindow {
        id: winRoot
        color: "transparent"
        screen: root.focusedScreen
        visible: root.active || contentWrapper.opacity > 0.0

        WlrLayershell.namespace: "quickshell:deviceConnectNotification"
        WlrLayershell.layer: WlrLayer.Overlay
        
        anchors {
            top: !Config.options.bar.bottom
            bottom: Config.options.bar.bottom
        }

        exclusionMode: ExclusionMode.Ignore
        exclusiveZone: 0
        
        margins {
            top: !Config.options.bar.bottom ? (Appearance.sizes.barHeight + 6) : 0
            bottom: Config.options.bar.bottom ? (Appearance.sizes.barHeight + 6) : 0
        }

        implicitWidth: contentWrapper.implicitWidth
        implicitHeight: contentWrapper.implicitHeight

        Item {
            id: contentWrapper
            // Make sure there's enough space for the shadow and rotation
            implicitWidth: deviceContainer.width + 40
            implicitHeight: deviceContainer.height + 40

            opacity: root.active ? 1.0 : 0.0
            Behavior on opacity {
                NumberAnimation {
                    id: fadeOutAnim
                    duration: 300
                    easing.type: Easing.InOutQuad
                }
            }

            property real animOffset: root.active ? 0 : (!Config.options.bar.bottom ? -30 : 30)
            Behavior on animOffset {
                NumberAnimation {
                    duration: 450
                    easing.type: Easing.OutCubic
                }
            }

            StyledRectangularShadow {
                target: deviceContainer
                anchors.fill: deviceContainer
            }

            Rectangle {
                id: deviceContainer
                width: 280
                height: 84
                radius: Appearance.rounding.small
                color: Appearance.m3colors.m3surfaceContainer
                border.color: Appearance.colors.colLayer0Border
                border.width: 1

                anchors {
                    centerIn: parent
                    verticalCenterOffset: contentWrapper.animOffset
                }

                RowLayout {
                    anchors {
                        fill: parent
                        margins: 12
                        leftMargin: 20
                        rightMargin: 20
                    }
                    spacing: 18

                    // 3D-rotating graphic container
                    Item {
                        id: iconWrapper
                        Layout.preferredWidth: 38
                        Layout.preferredHeight: 56
                        Layout.alignment: Qt.AlignVCenter

                        Item {
                            id: rotatingIcon
                            anchors.fill: parent

                            // --- MOUSE GRAPHIC ---
                            Item {
                                anchors.fill: parent
                                visible: root.deviceType === "mouse"

                                Rectangle {
                                    anchors.fill: parent
                                    radius: width / 2
                                    color: "transparent"
                                    border.color: Appearance.colors.colPrimary
                                    border.width: 2.5

                                    // Button separator
                                    Rectangle {
                                        width: 2.5
                                        height: parent.height * 0.45
                                        color: Appearance.colors.colPrimary
                                        anchors.top: parent.top
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }

                                    // Scroll Wheel
                                    Rectangle {
                                        width: 4.5
                                        height: 11
                                        radius: 2
                                        color: Appearance.colors.colSecondary
                                        anchors.top: parent.top
                                        anchors.topMargin: 7
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }

                                    // DPI Button
                                    Rectangle {
                                        width: 4
                                        height: 4
                                        radius: 2
                                        color: Appearance.colors.colPrimary
                                        anchors.top: parent.top
                                        anchors.topMargin: 20
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                }
                            }

                            // --- PEN DRIVE GRAPHIC ---
                            Item {
                                anchors.fill: parent
                                visible: root.deviceType === "pen_drive"

                                // USB Metal Connector
                                Rectangle {
                                    width: 14
                                    height: 12
                                    color: "transparent"
                                    border.color: Appearance.colors.colPrimary
                                    border.width: 2.5
                                    anchors.top: parent.top
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    
                                    // USB Connector detailing
                                    Rectangle {
                                        width: 8
                                        height: 3
                                        color: Appearance.colors.colPrimary
                                        anchors.bottom: parent.bottom
                                        anchors.bottomMargin: 2
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                }
                                
                                // Pen Drive Body
                                Rectangle {
                                    width: 22
                                    height: 34
                                    radius: 4
                                    color: "transparent"
                                    border.color: Appearance.colors.colPrimary
                                    border.width: 2.5
                                    anchors.top: parent.top
                                    anchors.topMargin: 11
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    // Stripe / grip line
                                    Rectangle {
                                        width: 10
                                        height: 2
                                        color: Appearance.colors.colSecondary
                                        anchors.centerIn: parent
                                    }
                                    
                                    // Activity LED dot
                                    Rectangle {
                                        width: 3
                                        height: 3
                                        radius: 1.5
                                        color: Appearance.colors.colSecondary
                                        anchors.bottom: parent.bottom
                                        anchors.bottomMargin: 4
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                }
                            }

                            // --- SSD GRAPHIC ---
                            Item {
                                anchors.fill: parent
                                visible: root.deviceType === "ssd"

                                Rectangle {
                                    width: 32
                                    height: 48
                                    radius: 6
                                    color: "transparent"
                                    border.color: Appearance.colors.colPrimary
                                    border.width: 2.5
                                    anchors.centerIn: parent

                                    // USB-C port at the top
                                    Rectangle {
                                        width: 10
                                        height: 2
                                        radius: 1
                                        color: Appearance.colors.colSecondary
                                        anchors.top: parent.top
                                        anchors.topMargin: 4
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }

                                    // Modern speed stripes
                                    Rectangle {
                                        width: 18
                                        height: 2
                                        color: Appearance.colors.colPrimary
                                        anchors.centerIn: parent
                                        rotation: -45
                                    }
                                    Rectangle {
                                        width: 12
                                        height: 2
                                        color: Appearance.colors.colSecondary
                                        anchors.centerIn: parent
                                        anchors.verticalCenterOffset: 6
                                        anchors.horizontalCenterOffset: 6
                                        rotation: -45
                                    }
                                }
                            }

                            // --- HDD GRAPHIC ---
                            Item {
                                anchors.fill: parent
                                visible: root.deviceType === "hdd"

                                Rectangle {
                                    width: 34
                                    height: 50
                                    radius: 4
                                    color: "transparent"
                                    border.color: Appearance.colors.colPrimary
                                    border.width: 2.5
                                    anchors.centerIn: parent

                                    // Inner metal shield
                                    Rectangle {
                                        width: 26
                                        height: 42
                                        radius: 2
                                        color: "transparent"
                                        border.color: Appearance.colors.colSecondary
                                        border.width: 1.5
                                        anchors.centerIn: parent

                                        // Disk Platter
                                        Rectangle {
                                            width: 20
                                            height: 20
                                            radius: 10
                                            color: "transparent"
                                            border.color: Appearance.colors.colPrimary
                                            border.width: 2
                                            anchors.centerIn: parent

                                            // Spindle center
                                            Rectangle {
                                                width: 4
                                                height: 4
                                                radius: 2
                                                color: Appearance.colors.colPrimary
                                                anchors.centerIn: parent
                                            }
                                        }

                                        // Actuator arm
                                        Rectangle {
                                            width: 2
                                            height: 12
                                            color: Appearance.colors.colPrimary
                                            anchors.top: parent.top
                                            anchors.topMargin: 6
                                            anchors.right: parent.right
                                            anchors.rightMargin: 6
                                            rotation: -30
                                        }
                                    }
                                }
                            }

                            // --- CONTROLLER GRAPHICS ---
                            Item {
                                anchors.fill: parent
                                visible: root.deviceType === "controller_bluetooth" || root.deviceType === "controller_wired" || root.deviceType === "controller_dongle"

                                // Gamepad Base Body
                                Rectangle {
                                    id: gpBody
                                    width: 36
                                    height: 24
                                    radius: 8
                                    color: "transparent"
                                    border.color: Appearance.colors.colPrimary
                                    border.width: 2.5
                                    anchors.centerIn: parent
                                    anchors.verticalCenterOffset: 2

                                    // Left grip handle
                                    Rectangle {
                                        width: 10
                                        height: 18
                                        radius: 5
                                        color: "transparent"
                                        border.color: Appearance.colors.colPrimary
                                        border.width: 2.5
                                        anchors.left: parent.left
                                        anchors.leftMargin: -2
                                        anchors.bottom: parent.bottom
                                        anchors.bottomMargin: -10
                                        rotation: 20
                                    }

                                    // Right grip handle
                                    Rectangle {
                                        width: 10
                                        height: 18
                                        radius: 5
                                        color: "transparent"
                                        border.color: Appearance.colors.colPrimary
                                        border.width: 2.5
                                        anchors.right: parent.right
                                        anchors.rightMargin: -2
                                        anchors.bottom: parent.bottom
                                        anchors.bottomMargin: -10
                                        rotation: -20
                                    }

                                    // Left thumbstick
                                    Rectangle {
                                        width: 6
                                        height: 6
                                        radius: 3
                                        color: Appearance.colors.colSecondary
                                        anchors.left: parent.left
                                        anchors.leftMargin: 8
                                        anchors.bottom: parent.bottom
                                        anchors.bottomMargin: 4
                                    }

                                    // Right thumbstick
                                    Rectangle {
                                        width: 6
                                        height: 6
                                        radius: 3
                                        color: Appearance.colors.colSecondary
                                        anchors.right: parent.right
                                        anchors.rightMargin: 8
                                        anchors.bottom: parent.bottom
                                        anchors.bottomMargin: 4
                                    }

                                    // D-Pad
                                    Item {
                                        width: 8
                                        height: 8
                                        anchors.left: parent.left
                                        anchors.leftMargin: 6
                                        anchors.top: parent.top
                                        anchors.topMargin: 4

                                        // Horizontal bar
                                        Rectangle {
                                            width: 8
                                            height: 2.5
                                            color: Appearance.colors.colPrimary
                                            anchors.centerIn: parent
                                        }
                                        // Vertical bar
                                        Rectangle {
                                            width: 2.5
                                            height: 8
                                            color: Appearance.colors.colPrimary
                                            anchors.centerIn: parent
                                        }
                                    }

                                    // Action buttons (A/B/X/Y)
                                    Item {
                                        width: 8
                                        height: 8
                                        anchors.right: parent.right
                                        anchors.rightMargin: 6
                                        anchors.top: parent.top
                                        anchors.topMargin: 4

                                        // Y button (top)
                                        Rectangle { width: 2.5; height: 2.5; radius: 1.25; color: Appearance.colors.colPrimary; anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter }
                                        // A button (bottom)
                                        Rectangle { width: 2.5; height: 2.5; radius: 1.25; color: Appearance.colors.colPrimary; anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter }
                                        // X button (left)
                                        Rectangle { width: 2.5; height: 2.5; radius: 1.25; color: Appearance.colors.colPrimary; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter }
                                        // B button (right)
                                        Rectangle { width: 2.5; height: 2.5; radius: 1.25; color: Appearance.colors.colPrimary; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter }
                                    }
                                }

                                // --- BLUETOOTH EMBLEM ---
                                Item {
                                    visible: root.deviceType === "controller_bluetooth"
                                    width: 12
                                    height: 14
                                    anchors.right: parent.right
                                    anchors.rightMargin: -4
                                    anchors.top: parent.top
                                    anchors.topMargin: -4

                                    // stylized bluetooth B using lines
                                    Rectangle {
                                        width: 2
                                        height: 12
                                        color: Appearance.colors.colSecondary
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                    // Bluetooth loops
                                    Rectangle {
                                        width: 5
                                        height: 6
                                        color: "transparent"
                                        border.color: Appearance.colors.colSecondary
                                        border.width: 1.5
                                        radius: 3
                                        anchors.top: parent.top
                                        anchors.left: parent.horizontalCenter
                                    }
                                    Rectangle {
                                        width: 5
                                        height: 6
                                        color: "transparent"
                                        border.color: Appearance.colors.colSecondary
                                        border.width: 1.5
                                        radius: 3
                                        anchors.bottom: parent.bottom
                                        anchors.left: parent.horizontalCenter
                                    }
                                }

                                // --- USB CABLE ---
                                Item {
                                    visible: root.deviceType === "controller_wired"
                                    anchors.fill: parent

                                    // Cable line from top of controller to top of area
                                    Rectangle {
                                        width: 2
                                        height: 12
                                        color: Appearance.colors.colSecondary
                                        anchors.bottom: gpBody.top
                                        anchors.horizontalCenter: gpBody.horizontalCenter
                                    }
                                }

                                // --- DONGLE AND WAVES ---
                                Item {
                                    visible: root.deviceType === "controller_dongle"
                                    anchors.fill: parent

                                    // USB Dongle Receiver at the top
                                    Rectangle {
                                        id: dongleBody
                                        width: 8
                                        height: 6
                                        radius: 1
                                        color: "transparent"
                                        border.color: Appearance.colors.colSecondary
                                        border.width: 1.5
                                        anchors.top: parent.top
                                        anchors.topMargin: -2
                                        anchors.horizontalCenter: parent.horizontalCenter

                                        // metal part
                                        Rectangle {
                                            width: 4
                                            height: 3
                                            color: Appearance.colors.colSecondary
                                            anchors.top: parent.bottom
                                            anchors.horizontalCenter: parent.horizontalCenter
                                        }
                                    }

                                    // Wireless wave arcs
                                    // Wave 1
                                    Rectangle {
                                        width: 12
                                        height: 4
                                        radius: 2
                                        color: Appearance.colors.colSecondary
                                        opacity: 0.8
                                        anchors.top: dongleBody.bottom
                                        anchors.topMargin: 4
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                    
                                    // Wave 2
                                    Rectangle {
                                        width: 18
                                        height: 4
                                        radius: 2
                                        color: Appearance.colors.colSecondary
                                        opacity: 0.5
                                        anchors.top: dongleBody.bottom
                                        anchors.topMargin: 10
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                }
                            }

                            transform: Rotation {
                                id: rotationY
                                origin.x: rotatingIcon.width / 2
                                origin.y: rotatingIcon.height / 2
                                axis { x: 0; y: 1; z: 0 }
                                angle: 0
                            }

                            NumberAnimation {
                                target: rotationY
                                property: "angle"
                                from: 0
                                to: 360
                                duration: 2500
                                loops: Animation.Infinite
                                running: root.active
                            }
                        }
                    }

                    // Labels
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 2

                        StyledText {
                            text: root.deviceName
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.bold: true
                            color: Appearance.colors.colOnLayer1
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        StyledText {
                            text: root.deviceSubtype
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }
}
