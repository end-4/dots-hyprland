import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs.services.network
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    required property WifiAccessPoint wifiNetwork
    
    property bool isConnecting: Network.wifiConnectTarget === root.wifiNetwork && !wifiNetwork?.active
    property bool isActive: wifiNetwork?.active ?? false
    property bool isAskingPassword: wifiNetwork?.askingPassword ?? false
    property bool expanded: false
    
    // Parse security type for display
    property string securityType: {
        const sec = (wifiNetwork?.security ?? "").toUpperCase();
        if (sec.includes("WPA3")) return "WPA3";
        if (sec.includes("WPA2")) return "WPA2";
        if (sec.includes("WPA")) return "WPA";
        if (sec.includes("WEP")) return "WEP";
        if (sec.length === 0) return "Open";
        return sec;
    }
    
    // Frequency band (2.4GHz vs 5GHz)
    property string frequencyBand: {
        const freq = wifiNetwork?.frequency ?? 0;
        if (freq >= 5000) return "5 GHz";
        if (freq >= 2400) return "2.4 GHz";
        return "";
    }
    
    Layout.fillWidth: true
    implicitHeight: contentColumn.implicitHeight + 24
    radius: Appearance.rounding.normal
    color: isActive ? Appearance.colors.colPrimaryContainer : 
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
        enabled: !isConnecting && !isAskingPassword
        
        onClicked: {
            if (isActive) {
                root.expanded = !root.expanded;
            } else {
                Network.connectToWifiNetwork(wifiNetwork);
            }
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

            // Animated signal strength icon
            Item {
                implicitWidth: 28
                implicitHeight: 28
                
                MaterialSymbol {
                    id: signalIcon
                    anchors.centerIn: parent
                    property int strength: root.wifiNetwork?.strength ?? 0
                    text: strength > 80 ? "signal_wifi_4_bar" : 
                          strength > 60 ? "network_wifi_3_bar" : 
                          strength > 40 ? "network_wifi_2_bar" : 
                          strength > 20 ? "network_wifi_1_bar" : "signal_wifi_0_bar"
                    iconSize: 26
                    color: root.isActive ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer2
                    opacity: 1.0
                    
                    // Pulsing animation when connecting
                    NumberAnimation on opacity {
                        running: root.isConnecting
                        from: 0.4
                        to: 1.0
                        duration: 800
                        loops: Animation.Infinite
                        easing.type: Easing.InOutSine
                    }

                    onOpacityChanged: {
                        if (!root.isConnecting && opacity !== 1.0) {
                            opacity = 1.0;
                        }
                    }
                }
            }

            // Network info
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                
                StyledText {
                    text: root.wifiNetwork?.ssid ?? Translation.tr("Unknown")
                    elide: Text.ElideRight
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: root.isActive ? Font.Medium : Font.Normal
                    color: root.isActive ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer2
                    Layout.fillWidth: true
                }
                
                RowLayout {
                    spacing: 6
                    
                    // Security badge - using Item wrapper to avoid opacity issues
                    Item {
                        visible: root.securityType !== "Open"
                        implicitWidth: securityBadge.width
                        implicitHeight: securityBadge.height
                        
                        Rectangle {
                            id: securityBadge
                            width: securityRow.implicitWidth + 12
                            height: 20
                            radius: 4
                            color: Appearance.colors.colPrimary
                            opacity: 0.15
                        }
                        
                        RowLayout {
                            id: securityRow
                            anchors.centerIn: securityBadge
                            spacing: 4
                            z: 1  // Ensure content is above background
                            
                            MaterialSymbol {
                                text: "lock"
                                iconSize: 12
                                color: root.isActive ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer2
                            }
                            StyledText {
                                text: root.securityType
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                color: root.isActive ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer2
                            }
                        }
                    }
                    
                    // Open network badge
                    Item {
                        visible: root.securityType === "Open"
                        implicitWidth: openBadge.width
                        implicitHeight: openBadge.height
                        
                        Rectangle {
                            id: openBadge
                            width: openRow.implicitWidth + 12
                            height: 20
                            radius: 4
                            color: Appearance.colors.colTertiary
                            opacity: 0.2
                        }
                        
                        RowLayout {
                            id: openRow
                            anchors.centerIn: openBadge
                            spacing: 4
                            z: 1
                            
                            MaterialSymbol {
                                text: "lock_open"
                                iconSize: 12
                                color: Appearance.colors.colTertiary
                            }
                            StyledText {
                                text: Translation.tr("Open")
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                color: Appearance.colors.colTertiary
                            }
                        }
                    }
                    
                    // Frequency badge
                    Item {
                        visible: root.frequencyBand.length > 0
                        implicitWidth: freqBadge.width
                        implicitHeight: freqBadge.height
                        
                        Rectangle {
                            id: freqBadge
                            width: freqText.implicitWidth + 12
                            height: 20
                            radius: 4
                            color: Appearance.colors.colOnLayer2
                            opacity: 0.1
                        }
                        
                        StyledText {
                            id: freqText
                            anchors.centerIn: freqBadge
                            text: root.frequencyBand
                            font.pixelSize: 11
                            color: root.isActive ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colSubtext
                        }
                    }
                    
                    // Status text
                    StyledText {
                        visible: root.isConnecting
                        text: Translation.tr("Connecting...")
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                    }
                    
                    // Error message
                    StyledText {
                        visible: root.wifiNetwork?.connectionError?.length > 0
                        text: root.wifiNetwork?.connectionError ?? ""
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colError
                    }
                }
            }

            // Expand/action indicator
            MaterialSymbol {
                visible: root.isActive && !root.isAskingPassword
                text: "keyboard_arrow_down"
                iconSize: 20
                color: Appearance.colors.colOnPrimaryContainer
                rotation: root.expanded ? 180 : 0
                
                Behavior on rotation {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
            }

            // Disconnect icon for active network
            Item {
                visible: root.isActive && !root.expanded
                implicitWidth: 36
                implicitHeight: 36
                
                Rectangle {
                    anchors.fill: parent
                    radius: 18
                    color: disconnectMouseArea.containsMouse ? Appearance.colors.colErrorHover : Appearance.colors.colError
                    
                    Behavior on color {
                        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                    }
                }
                
                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "link_off"
                    iconSize: 20
                    color: Appearance.colors.colOnError
                }
                
                MouseArea {
                    id: disconnectMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Network.disconnectWifiNetwork()
                }
            }

            // Cancel button (when connecting)
            Item {
                visible: root.isConnecting
                implicitWidth: 36
                implicitHeight: 36
                
                Rectangle {
                    anchors.fill: parent
                    radius: 18
                    color: cancelMouseArea.containsMouse ? Appearance.colors.colLayer3Hover : Appearance.colors.colLayer3
                    
                    Behavior on color {
                        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                    }
                }
                
                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "close"
                    iconSize: 20
                    color: Appearance.colors.colOnLayer3
                }
                
                MouseArea {
                    id: cancelMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Network.cancelConnection()
                }

                StyledToolTip {
                    extraVisibleCondition: root.isConnecting
                    text: Translation.tr("Cancel")
                }
            }

            // Delete button (for saved networks, not active/connecting)
            Item {
                visible: (root.wifiNetwork?.isSaved ?? false) && !root.isActive && !root.isConnecting && !root.isAskingPassword
                implicitWidth: 36
                implicitHeight: 36
                
                Rectangle {
                    anchors.fill: parent
                    radius: 18
                    color: deleteMouseArea.containsMouse ? Appearance.colors.colErrorHover : Appearance.colors.colLayer3
                    
                    Behavior on color {
                        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                    }
                }
                
                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "delete"
                    iconSize: 20
                    color: deleteMouseArea.containsMouse ? Appearance.colors.colOnError : Appearance.colors.colOnLayer3
                }
                
                MouseArea {
                    id: deleteMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Network.forgetWifiNetwork(root.wifiNetwork)
                }

                StyledToolTip {
                    extraVisibleCondition: deleteMouseArea.containsMouse
                    text: Translation.tr("Forget network")
                }
            }
        }

        // Expanded details section (for connected network)
        ColumnLayout {
            visible: root.expanded && root.isActive
            Layout.fillWidth: true
            Layout.leftMargin: 40
            spacing: 8
            
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Appearance.colors.colOutlineVariant
                opacity: 0.5
            }
            
            RowLayout {
                Layout.fillWidth: true
                
                StyledText {
                    text: Translation.tr("Signal Strength")
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnPrimaryContainer
                    opacity: 0.7
                }
                Item { Layout.fillWidth: true }
                StyledText {
                    text: `${root.wifiNetwork?.strength ?? 0}%`
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnPrimaryContainer
                }
            }
            
            RowLayout {
                Layout.fillWidth: true
                
                StyledText {
                    text: Translation.tr("Security")
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnPrimaryContainer
                    opacity: 0.7
                }
                Item { Layout.fillWidth: true }
                StyledText {
                    text: root.wifiNetwork?.security || Translation.tr("None")
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnPrimaryContainer
                }
            }
            
            RowLayout {
                Layout.fillWidth: true
                
                StyledText {
                    text: Translation.tr("Frequency")
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnPrimaryContainer
                    opacity: 0.7
                }
                Item { Layout.fillWidth: true }
                StyledText {
                    text: `${root.wifiNetwork?.frequency ?? 0} MHz`
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnPrimaryContainer
                }
            }
            
            // Actions Row
            RowLayout {
                Layout.alignment: Qt.AlignRight
                Layout.topMargin: 4
                spacing: 12

                // Disconnect button
                Item {
                    implicitWidth: 36
                    implicitHeight: 36
                    property bool hovered: expandedDisconnectMouse.containsMouse
                    
                    Rectangle {
                        anchors.fill: parent
                        radius: 18
                        color: expandedDisconnectMouse.containsMouse ? Appearance.colors.colErrorHover : Appearance.colors.colError
                        
                        Behavior on color {
                            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                        }
                    }
                    
                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "link_off"
                        iconSize: 20
                        color: Appearance.colors.colOnError
                    }
                    
                    MouseArea {
                        id: expandedDisconnectMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Network.disconnectWifiNetwork()
                    }

                    StyledToolTip {
                        extraVisibleCondition: root.expanded && root.isActive
                        text: Translation.tr("Disconnect")
                    }
                }
                
                // Forget button
                Item {
                    implicitWidth: 36
                    implicitHeight: 36
                    property bool hovered: forgetMouseArea.containsMouse
                    
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
                        onClicked: Network.forgetWifiNetwork(root.wifiNetwork)
                    }
                    
                    StyledToolTip {
                        extraVisibleCondition: root.expanded && root.isActive
                        text: Translation.tr("Forget Network")
                    }
                }
            }
        }

        // Password entry section
        ColumnLayout {
            visible: root.isAskingPassword
            Layout.fillWidth: true
            Layout.topMargin: 4
            spacing: 10

            MaterialTextField {
                id: passwordField
                Layout.fillWidth: true
                placeholderText: Translation.tr("Enter password")
                echoMode: TextInput.Password
                inputMethodHints: Qt.ImhSensitiveData
                
                onAccepted: {
                    Network.changePassword(root.wifiNetwork, passwordField.text);
                    passwordField.text = "";
                }
            }

            RowLayout {
                Layout.fillWidth: true
                
                Item { Layout.fillWidth: true }
                
                RippleButton {
                    implicitWidth: 80
                    implicitHeight: 32
                    buttonRadius: Appearance.rounding.full
                    colBackground: Appearance.colors.colLayer3
                    colBackgroundHover: Appearance.colors.colLayer3Hover
                    
                    onClicked: {
                        root.wifiNetwork.askingPassword = false;
                        passwordField.text = "";
                    }
                    
                    contentItem: StyledText {
                        anchors.centerIn: parent
                        text: Translation.tr("Cancel")
                        color: Appearance.colors.colOnLayer3
                    }
                }
                
                RippleButton {
                    implicitWidth: 100
                    implicitHeight: 32
                    buttonRadius: Appearance.rounding.full
                    colBackground: Appearance.colors.colPrimary
                    colBackgroundHover: Appearance.colors.colPrimaryHover
                    enabled: passwordField.text.length > 0
                    
                    onClicked: {
                        Network.changePassword(root.wifiNetwork, passwordField.text);
                        passwordField.text = "";
                    }
                    
                    contentItem: RowLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        MaterialSymbol {
                            text: "wifi"
                            iconSize: 16
                            color: Appearance.colors.colOnPrimary
                        }
                        StyledText {
                            text: Translation.tr("Connect")
                            color: Appearance.colors.colOnPrimary
                        }
                    }
                }
            }
        }
    }
}
