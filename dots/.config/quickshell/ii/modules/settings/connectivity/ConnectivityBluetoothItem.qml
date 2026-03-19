import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth

Rectangle {
    id: root
    required property BluetoothDevice device
    
    property bool isConnected: device?.connected ?? false
    property bool isPaired: device?.paired ?? false
    property bool expanded: false
    property real batteryLevel: device?.battery ?? 0
    property bool hasBattery: device?.batteryAvailable ?? false

    Layout.fillWidth: true
    implicitHeight: contentColumn.implicitHeight + 24
    radius: Appearance.rounding.normal
    color: isConnected ? Appearance.colors.colPrimaryContainer : 
           root.hovered ? Appearance.colors.colLayer2Hover : Appearance.colors.colLayer2

    property bool hovered: mouseArea.containsMouse

    Behavior on color {
        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
    }
    
    Behavior on implicitHeight {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        
        onClicked: {
            root.expanded = !root.expanded;
        }
    }

    ColumnLayout {
        id: contentColumn
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 12
        }
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            // Device icon with connection indicator
            Item {
                implicitWidth: 32
                implicitHeight: 32
                
                Rectangle {
                    anchors.fill: parent
                    radius: 8
                    color: root.isConnected ? Appearance.colors.colPrimary : Appearance.colors.colLayer3
                    opacity: root.isConnected ? 0.2 : 0.5
                }
                
                MaterialSymbol {
                    anchors.centerIn: parent
                    text: Icons.getBluetoothDeviceMaterialSymbol(root.device?.icon ?? "")
                    iconSize: 20
                    color: root.isConnected ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer2
                }
            }

            // Device info
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                
                StyledText {
                    Layout.fillWidth: true
                    text: root.device?.name ?? Translation.tr("Unknown device")
                    elide: Text.ElideRight
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: root.isConnected ? Font.Medium : Font.Normal
                    color: root.isConnected ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer2
                }
                
                RowLayout {
                    spacing: 8
                    
                    // Status badge
                    Item {
                        visible: root.isConnected || root.isPaired
                        implicitWidth: statusRow.implicitWidth + 10
                        implicitHeight: 18
                        
                        Rectangle {
                            anchors.fill: parent
                            radius: 4
                            color: root.isConnected ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer2
                            opacity: root.isConnected ? 0.2 : 0.1
                        }
                        
                        RowLayout {
                            id: statusRow
                            anchors.centerIn: parent
                            spacing: 3
                            
                            MaterialSymbol {
                                text: root.isConnected ? "bluetooth_connected" : "bluetooth"
                                iconSize: 12
                                color: root.isConnected ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colSubtext
                            }
                            StyledText {
                                text: root.isConnected ? Translation.tr("Connected") : Translation.tr("Paired")
                                font.pixelSize: 10
                                font.weight: Font.Medium
                                color: root.isConnected ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colSubtext
                            }
                        }
                    }
                    
                    // Battery indicator
                    RowLayout {
                        visible: root.hasBattery && root.batteryLevel > 0
                        spacing: 4
                        
                        MaterialSymbol {
                            text: root.batteryLevel < 0.2 ? "battery_alert" : 
                                  root.batteryLevel < 0.5 ? "battery_3_bar" : "battery_full"
                            iconSize: 14
                            color: root.batteryLevel < 0.2 ? Appearance.colors.colError : 
                                   (root.isConnected ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colSubtext)
                        }
                        
                        StyledText {
                            text: `${Math.round(root.batteryLevel * 100)}%`
                            font.pixelSize: 10
                            color: root.isConnected ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colSubtext
                        }
                    }
                }
            }

            // Expand indicator
            MaterialSymbol {
                text: "keyboard_arrow_down"
                iconSize: 20
                color: root.isConnected ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer2
                rotation: root.expanded ? 180 : 0
                
                Behavior on rotation {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
            }
        }

        // Expanded actions
        ColumnLayout {
            visible: root.expanded
            Layout.fillWidth: true
            Layout.leftMargin: 44
            spacing: 10

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Appearance.colors.colOutlineVariant
                opacity: 0.5
            }
            
            // Device details (when connected or paired)
            ColumnLayout {
                visible: root.isPaired || root.isConnected
                Layout.fillWidth: true
                spacing: 4
                
                RowLayout {
                    Layout.fillWidth: true
                    StyledText {
                        text: Translation.tr("Status")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: root.isConnected ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer2
                        opacity: 0.7
                    }
                    Item { Layout.fillWidth: true }
                    StyledText {
                        text: root.isConnected ? Translation.tr("Connected") : Translation.tr("Paired")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: root.isConnected ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer2
                    }
                }
                
                RowLayout {
                    visible: root.hasBattery && root.batteryLevel > 0
                    Layout.fillWidth: true
                    StyledText {
                        text: Translation.tr("Battery")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: root.isConnected ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer2
                        opacity: 0.7
                    }
                    Item { Layout.fillWidth: true }
                    StyledText {
                        text: `${Math.round(root.batteryLevel * 100)}%`
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: root.isConnected ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer2
                    }
                }
            }
            
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                // Pair button (for unpaired devices)
                Item {
                    visible: !root.isPaired && !root.isConnected
                    implicitWidth: 36
                    implicitHeight: 36
                    
                    Rectangle {
                        anchors.fill: parent
                        radius: 18
                        color: pairMouseArea.containsMouse ? Appearance.colors.colPrimaryHover : Appearance.colors.colPrimary
                        
                        Behavior on color {
                            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                        }
                    }
                    
                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "bluetooth_searching"
                        iconSize: 20
                        color: Appearance.colors.colOnPrimary
                    }
                    
                    MouseArea {
                        id: pairMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.device?.connect()  // connect() on unpaired device pairs it
                    }
                }
                
                StyledText {
                    visible: !root.isPaired && !root.isConnected
                    text: Translation.tr("Tap to pair")
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                }

                // Connect button (for paired but not connected)
                Item {
                    visible: root.isPaired && !root.isConnected
                    implicitWidth: 36
                    implicitHeight: 36
                    
                    Rectangle {
                        anchors.fill: parent
                        radius: 18
                        color: connectMouseArea.containsMouse ? Appearance.colors.colPrimaryHover : Appearance.colors.colPrimary
                        
                        Behavior on color {
                            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                        }
                    }
                    
                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "bluetooth"
                        iconSize: 20
                        color: Appearance.colors.colOnPrimary
                    }
                    
                    MouseArea {
                        id: connectMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.device?.connect()
                    }
                }
                
                StyledText {
                    visible: root.isPaired && !root.isConnected
                    text: Translation.tr("Tap to connect")
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                }

                // Disconnect button (for connected devices)
                Item {
                    visible: root.isConnected
                    implicitWidth: 36
                    implicitHeight: 36
                    
                    Rectangle {
                        anchors.fill: parent
                        radius: 18
                        color: disconnectMouseArea.containsMouse ? Appearance.colors.colLayer3Hover : Appearance.colors.colLayer3
                        
                        Behavior on color {
                            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                        }
                    }
                    
                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "bluetooth_disabled"
                        iconSize: 20
                        color: Appearance.colors.colOnLayer3
                    }
                    
                    MouseArea {
                        id: disconnectMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.device?.disconnect()
                    }
                }
                
                StyledText {
                    visible: root.isConnected
                    text: Translation.tr("Tap to disconnect")
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                }
                
                Item { Layout.fillWidth: true }

                // Forget button (only for paired devices)
                Item {
                    visible: root.isPaired
                    implicitWidth: 36
                    implicitHeight: 36
                    
                    Rectangle {
                        anchors.fill: parent
                        radius: 18
                        color: forgetMouseArea.containsMouse ? Appearance.colors.colErrorHover : Appearance.colors.colError
                        
                        Behavior on color {
                            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                        }
                    }
                    
                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "delete"
                        iconSize: 20
                        color: Appearance.colors.colOnError
                    }
                    
                    MouseArea {
                        id: forgetMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.device?.forget()
                    }
                }
            }
        }
    }
}
