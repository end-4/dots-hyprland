import "root:/"
import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import "root:/modules/common/functions/color_utils.js" as ColorUtils
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.UPower

Scope {
    id: bar

    readonly property int barHeight: Appearance.sizes.barHeight
    readonly property int osdHideMouseMoveThreshold: 20
    property bool showBarBackground: ConfigOptions.bar.showBackground

    Variants { // For each monitor
        model: Quickshell.screens

        PanelWindow { // Bar window
            id: barRoot
            screen: modelData

            // Check screensList from config, If no screens are specified, show on all screens
            visible: ConfigOptions.bar.screensList.includes(modelData.name) || ConfigOptions.bar.screensList.length === 0

            property ShellScreen modelData
            property var brightnessMonitor: Brightness.getMonitorForScreen(modelData)
            property real useShortenedForm: (Appearance.sizes.barHellaShortenScreenWidthThreshold >= screen.width) ? 2 :
                (Appearance.sizes.barShortenScreenWidthThreshold >= screen.width) ? 1 : 0
            readonly property int centerSideModuleWidth: 
                (useShortenedForm == 2) ? Appearance.sizes.barCenterSideModuleWidthHellaShortened :
                (useShortenedForm == 1) ? Appearance.sizes.barCenterSideModuleWidthShortened : 
                    Appearance.sizes.barCenterSideModuleWidth

            WlrLayershell.namespace: "quickshell:bar"
            implicitHeight: barHeight + Appearance.rounding.screenRounding
            exclusiveZone: showBarBackground ? barHeight : (barHeight - 4)
            mask: Region {
                item: barContent
            }
            color: "transparent"

            anchors {
                top: !ConfigOptions.bar.bottom
                bottom: ConfigOptions.bar.bottom
                left: true
                right: true
            }

            Rectangle { // Bar background
                id: barContent
                anchors {
                    right: parent.right
                    left: parent.left
                    top: !ConfigOptions.bar.bottom ? parent.top : undefined
                    bottom: ConfigOptions.bar.bottom ? parent.bottom : undefined
                }
                color: showBarBackground ? Appearance.colors.colLayer0 : "transparent"
                height: barHeight
                
                MouseArea { // Left side | scroll to change brightness
                    id: barLeftSideMouseArea
                    anchors.left: parent.left
                    implicitHeight: barHeight
                    width: (barRoot.width - middleSection.width) / 2
                    property bool hovered: false
                    property real lastScrollX: 0
                    property real lastScrollY: 0
                    property bool trackingScroll: false
                    acceptedButtons: Qt.LeftButton
                    hoverEnabled: true
                    propagateComposedEvents: true
                    onEntered: (event) => {
                        barLeftSideMouseArea.hovered = true
                    }
                    onExited: (event) => {
                        barLeftSideMouseArea.hovered = false
                        barLeftSideMouseArea.trackingScroll = false
                    }
                    onPressed: (event) => {
                        if (event.button === Qt.LeftButton) {
                            Hyprland.dispatch('global quickshell:sidebarLeftOpen')
                        }
                    }
                    // Scroll to change brightness
                    WheelHandler {
                        onWheel: (event) => {
                            if (event.angleDelta.y < 0)
                                barRoot.brightnessMonitor.setBrightness(barRoot.brightnessMonitor.brightness - 0.05);
                            else if (event.angleDelta.y > 0)
                                barRoot.brightnessMonitor.setBrightness(barRoot.brightnessMonitor.brightness + 0.05);
                            // Store the mouse position and start tracking
                            barLeftSideMouseArea.lastScrollX = event.x;
                            barLeftSideMouseArea.lastScrollY = event.y;
                            barLeftSideMouseArea.trackingScroll = true;
                        }
                        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    }
                    onPositionChanged: (mouse) => {
                        if (barLeftSideMouseArea.trackingScroll) {
                            const dx = mouse.x - barLeftSideMouseArea.lastScrollX;
                            const dy = mouse.y - barLeftSideMouseArea.lastScrollY;
                            if (Math.sqrt(dx*dx + dy*dy) > osdHideMouseMoveThreshold) {
                                Hyprland.dispatch('global quickshell:osdBrightnessHide')
                                barLeftSideMouseArea.trackingScroll = false;
                            }
                        }
                    }
                    Item {  // Left section
                        anchors.fill: parent
                        implicitHeight: leftSectionRowLayout.implicitHeight
                        implicitWidth: leftSectionRowLayout.implicitWidth

                        ScrollHint {
                            reveal: barLeftSideMouseArea.hovered
                            icon: "light_mode"
                            tooltipText: qsTr("Scroll to change brightness")
                            side: "left"
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            
                        }
                        
                        RowLayout { // Content
                            id: leftSectionRowLayout
                            anchors.fill: parent
                            spacing: 10

                            RippleButton { // Left sidebar button
                                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                                Layout.leftMargin: Appearance.rounding.screenRounding
                                Layout.fillWidth: false
                                property real buttonPadding: 5
                                implicitWidth: distroIcon.width + buttonPadding * 2
                                implicitHeight: distroIcon.height + buttonPadding * 2
                                
                                buttonRadius: Appearance.rounding.full
                                colBackground: barLeftSideMouseArea.hovered ? Appearance.colors.colLayer1Hover : ColorUtils.transparentize(Appearance.colors.colLayer1Hover, 1)
                                colBackgroundHover: Appearance.colors.colLayer1Hover
                                colRipple: Appearance.colors.colLayer1Active
                                colBackgroundToggled: Appearance.m3colors.m3secondaryContainer
                                colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
                                colRippleToggled: Appearance.colors.colSecondaryContainerActive
                                toggled: GlobalStates.sidebarLeftOpen
                                    property color colText: toggled ? Appearance.m3colors.m3onSecondaryContainer : Appearance.colors.colOnLayer0

                                onPressed: {
                                    Hyprland.dispatch('global quickshell:sidebarLeftToggle')
                                }

                                CustomIcon {
                                    id: distroIcon
                                    anchors.centerIn: parent
                                    width: 19.5
                                    height: 19.5
                                    source: ConfigOptions.bar.topLeftIcon == 'distro' ? 
                                        SystemInfo.distroIcon : "spark-symbolic"
                                }
                                
                                ColorOverlay {
                                    anchors.fill: distroIcon
                                    source: distroIcon
                                    color: Appearance.colors.colOnLayer0
                                }
                            }

                            ActiveWindow {
                                visible: barRoot.useShortenedForm === 0
                                Layout.rightMargin: Appearance.rounding.screenRounding
                                Layout.fillWidth: true
                                bar: barRoot
                            }
                        }
                    }
                }

                RowLayout { // Middle section
                    id: middleSection
                    anchors.centerIn: parent
                    spacing: 8

                    RowLayout {
                        id: leftCenterGroup
                        Layout.preferredWidth: barRoot.centerSideModuleWidth
                        spacing: 4
                        Layout.fillHeight: true
                        implicitWidth: 350

                        Resources {
                            alwaysShowAllResources: barRoot.useShortenedForm === 2
                            Layout.fillWidth: barRoot.useShortenedForm === 2
                        }

                        Media {
                            visible: barRoot.useShortenedForm < 2
                            Layout.fillWidth: true
                        }

                    }

                    RowLayout {
                        id: middleCenterGroup
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Workspaces {
                            bar: barRoot
                            MouseArea { // Right-click to toggle overview
                                anchors.fill: parent
                                acceptedButtons: Qt.RightButton
                                
                                onPressed: (event) => {
                                    if (event.button === Qt.RightButton) {
                                        Hyprland.dispatch('global quickshell:overviewToggle')
                                    }
                                }
                            }
                        }

                    }

                    RowLayout {
                        id: rightCenterGroup
                        Layout.preferredWidth: leftCenterGroup.width
                        Layout.fillHeight: true
                        spacing: 4

                        ClockWidget {
                            showDate: barRoot.useShortenedForm < 2
                            Layout.alignment: Qt.AlignVCenter
                            Layout.fillWidth: true
                        }

                        UtilButtons {
                            visible: barRoot.useShortenedForm === 0
                            Layout.alignment: Qt.AlignVCenter
                        }

                        BatteryIndicator {
                            visible: (barRoot.useShortenedForm < 2 && UPower.displayDevice.isLaptopBattery)
                            Layout.alignment: Qt.AlignVCenter
                        }

                    }

                }

                MouseArea { // Right side | scroll to change volume
                    id: barRightSideMouseArea

                    anchors.right: parent.right
                    implicitHeight: barHeight
                    width: (barRoot.width - middleSection.width) / 2

                    property bool hovered: false
                    property real lastScrollX: 0
                    property real lastScrollY: 0
                    property bool trackingScroll: false
                    
                    acceptedButtons: Qt.LeftButton
                    hoverEnabled: true
                    propagateComposedEvents: true
                    onEntered: (event) => {
                        barRightSideMouseArea.hovered = true
                    }
                    onExited: (event) => {
                        barRightSideMouseArea.hovered = false
                        barRightSideMouseArea.trackingScroll = false
                    }
                    onPressed: (event) => {
                        if (event.button === Qt.LeftButton) {
                            Hyprland.dispatch('global quickshell:sidebarRightOpen')
                        }
                        else if (event.button === Qt.RightButton) {
                            MprisController.activePlayer.next()
                        }
                    }
                    // Scroll to change volume
                    WheelHandler {
                        onWheel: (event) => {
                            const currentVolume = Audio.value;
                            const step = currentVolume < 0.1 ? 0.01 : 0.02 || 0.2;
                            if (event.angleDelta.y < 0)
                                Audio.sink.audio.volume -= step;
                            else if (event.angleDelta.y > 0)
                                Audio.sink.audio.volume = Math.min(1, Audio.sink.audio.volume + step);
                            // Store the mouse position and start tracking
                            barRightSideMouseArea.lastScrollX = event.x;
                            barRightSideMouseArea.lastScrollY = event.y;
                            barRightSideMouseArea.trackingScroll = true;
                        }
                        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    }
                    onPositionChanged: (mouse) => {
                        if (barRightSideMouseArea.trackingScroll) {
                            const dx = mouse.x - barRightSideMouseArea.lastScrollX;
                            const dy = mouse.y - barRightSideMouseArea.lastScrollY;
                            if (Math.sqrt(dx*dx + dy*dy) > osdHideMouseMoveThreshold) {
                                Hyprland.dispatch('global quickshell:osdVolumeHide')
                                barRightSideMouseArea.trackingScroll = false;
                            }
                        }
                    }

                    Item {
                        anchors.fill: parent
                        implicitHeight: rightSectionRowLayout.implicitHeight
                        implicitWidth: rightSectionRowLayout.implicitWidth
                        
                        ScrollHint {
                            reveal: barRightSideMouseArea.hovered
                            icon: "volume_up"
                            tooltipText: qsTr("Scroll to change volume")
                            side: "right"
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        RowLayout {
                            id: rightSectionRowLayout
                            anchors.fill: parent
                            spacing: 5
                            layoutDirection: Qt.RightToLeft
                    
                            RippleButton { // Right sidebar button
                                id: rightSidebarButton
                                Layout.margins: 4
                                Layout.rightMargin: Appearance.rounding.screenRounding
                                Layout.fillHeight: true
                                implicitWidth: indicatorsRowLayout.implicitWidth + 10*2
                                buttonRadius: Appearance.rounding.full
                                colBackground: barRightSideMouseArea.hovered ? Appearance.colors.colLayer1Hover : ColorUtils.transparentize(Appearance.colors.colLayer1Hover, 1)
                                colBackgroundHover: Appearance.colors.colLayer1Hover
                                colRipple: Appearance.colors.colLayer1Active
                                colBackgroundToggled: Appearance.m3colors.m3secondaryContainer
                                colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
                                colRippleToggled: Appearance.colors.colSecondaryContainerActive
                                toggled: GlobalStates.sidebarRightOpen
                                property color colText: toggled ? Appearance.m3colors.m3onSecondaryContainer : Appearance.colors.colOnLayer0

                                Behavior on colText {
                                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                                }

                                onPressed: {
                                    Hyprland.dispatch('global quickshell:sidebarRightToggle')
                                }

                                RowLayout {
                                    id: indicatorsRowLayout
                                    anchors.centerIn: parent
                                    property real realSpacing: 15
                                    spacing: 0
                                    
                                    Revealer {
                                        reveal: Audio.sink?.audio?.muted ?? false
                                        Layout.fillHeight: true
                                        Layout.rightMargin: reveal ? indicatorsRowLayout.realSpacing : 0
                                        Behavior on Layout.rightMargin {
                                            NumberAnimation {
                                                duration: Appearance.animation.elementMoveFast.duration
                                                easing.type: Appearance.animation.elementMoveFast.type
                                                easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                                            }
                                        }
                                        MaterialSymbol {
                                            text: "volume_off"
                                            iconSize: Appearance.font.pixelSize.larger
                                            color: rightSidebarButton.colText
                                        }
                                    }
                                    Revealer {
                                        reveal: Audio.source?.audio?.muted ?? false
                                        Layout.fillHeight: true
                                        Layout.rightMargin: reveal ? indicatorsRowLayout.realSpacing : 0
                                        Behavior on Layout.rightMargin {
                                            NumberAnimation {
                                                duration: Appearance.animation.elementMoveFast.duration
                                                easing.type: Appearance.animation.elementMoveFast.type
                                                easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                                            }
                                        }
                                        MaterialSymbol {
                                            text: "mic_off"
                                            iconSize: Appearance.font.pixelSize.larger
                                            color: rightSidebarButton.colText
                                        }
                                    }
                                    MaterialSymbol {
                                        Layout.rightMargin: indicatorsRowLayout.realSpacing
                                        text: Network.materialSymbol
                                        iconSize: Appearance.font.pixelSize.larger
                                        color: rightSidebarButton.colText
                                    }
                                    MaterialSymbol {
                                        text: Bluetooth.bluetoothConnected ? "bluetooth_connected" : Bluetooth.bluetoothEnabled ? "bluetooth" : "bluetooth_disabled"
                                        iconSize: Appearance.font.pixelSize.larger
                                        color: rightSidebarButton.colText
                                    }
                                }
                            }

                            SysTray {
                                bar: barRoot
                                visible: barRoot.useShortenedForm === 0
                                Layout.fillWidth: false
                                Layout.fillHeight: true
                            }

                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                            }
                        }
                    }
                }
            }

            // Round decorators
            Item {
                anchors {
                    left: parent.left
                    right: parent.right
                    // top: barContent.bottom
                    top: ConfigOptions.bar.bottom ? undefined : barContent.bottom
                    bottom: ConfigOptions.bar.bottom ? barContent.top : undefined
                }
                height: Appearance.rounding.screenRounding

                RoundCorner {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    size: Appearance.rounding.screenRounding
                    corner: ConfigOptions.bar.bottom ? cornerEnum.bottomLeft : cornerEnum.topLeft
                    color: showBarBackground ? Appearance.colors.colLayer0 : "transparent"
                }
                RoundCorner {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    size: Appearance.rounding.screenRounding
                    corner: ConfigOptions.bar.bottom ? cornerEnum.bottomRight : cornerEnum.topRight
                    color: showBarBackground ? Appearance.colors.colLayer0 : "transparent"
                }
            }

        }

    }

}
