import "./weather"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.UPower
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item { // Bar content region
    id: root

    property var screen: root.QsWindow.window?.screen
    property var brightnessMonitor: Brightness.getMonitorForScreen(screen)
    property real useShortenedForm: (Appearance.sizes.barHellaShortenScreenWidthThreshold >= screen?.width) ? 2 : (Appearance.sizes.barShortenScreenWidthThreshold >= screen?.width) ? 1 : 0
    readonly property int centerSideModuleWidth: (useShortenedForm == 2) ? Appearance.sizes.barCenterSideModuleWidthHellaShortened : (useShortenedForm == 1) ? Appearance.sizes.barCenterSideModuleWidthShortened : Appearance.sizes.barCenterSideModuleWidth

    component VerticalBarSeparator: Rectangle {
        Layout.topMargin: Appearance.sizes.baseBarHeight / 3
        Layout.bottomMargin: Appearance.sizes.baseBarHeight / 3
        Layout.fillHeight: true
        implicitWidth: 1
        color: Appearance.colors.colOutlineVariant
    }

    // Background shadow
    Loader {
        active: Config.options.bar.showBackground && Config.options.bar.cornerStyle === 1
        anchors.fill: barBackground
        sourceComponent: StyledRectangularShadow {
            anchors.fill: undefined // The loader's anchors act on this, and this should not have any anchor
            target: barBackground
        }
    }
    // Background
    Rectangle {
        id: barBackground
        anchors {
            fill: parent
            margins: Config.options.bar.cornerStyle === 1 ? (Appearance.sizes.hyprlandGapsOut) : 0 // idk why but +1 is needed
        }
        color: Config.options.bar.showBackground ? Appearance.colors.colLayer0 : "transparent"
        radius: Config.options.bar.cornerStyle === 1 ? Appearance.rounding.windowRounding : 0
        border.width: Config.options.bar.cornerStyle === 1 ? 1 : 0
        border.color: Appearance.colors.colLayer0Border
    }

    MouseArea { // Left side | scroll to change brightness
        id: barLeftSideMouseArea
        anchors.left: parent.left
        implicitHeight: Appearance.sizes.baseBarHeight
        height: Appearance.sizes.barHeight
        width: (root.width - middleSection.width) / 2
        property bool hovered: false
        property real lastScrollX: 0
        property real lastScrollY: 0
        property bool trackingScroll: false
        acceptedButtons: Qt.LeftButton
        hoverEnabled: true
        propagateComposedEvents: true
        onEntered: event => {
            barLeftSideMouseArea.hovered = true;
        }
        onExited: event => {
            barLeftSideMouseArea.hovered = false;
            barLeftSideMouseArea.trackingScroll = false;
        }
        onPressed: event => {
            if (event.button === Qt.LeftButton) {
                GlobalStates.sidebarLeftOpen = !GlobalStates.sidebarLeftOpen;
            }
        }
        // Scroll to change brightness
        WheelHandler {
            onWheel: event => {
                if (event.angleDelta.y < 0)
                    root.brightnessMonitor.setBrightness(root.brightnessMonitor.brightness - 0.05);
                else if (event.angleDelta.y > 0)
                    root.brightnessMonitor.setBrightness(root.brightnessMonitor.brightness + 0.05);
                // Store the mouse position and start tracking
                barLeftSideMouseArea.lastScrollX = event.x;
                barLeftSideMouseArea.lastScrollY = event.y;
                barLeftSideMouseArea.trackingScroll = true;
            }
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        }
        onPositionChanged: mouse => {
            if (barLeftSideMouseArea.trackingScroll) {
                const dx = mouse.x - barLeftSideMouseArea.lastScrollX;
                const dy = mouse.y - barLeftSideMouseArea.lastScrollY;
                if (Math.sqrt(dx * dx + dy * dy) > osdHideMouseMoveThreshold) {
                    GlobalStates.osdBrightnessOpen = false;
                    barLeftSideMouseArea.trackingScroll = false;
                }
            }
        }
        Item {
            // Left section
            anchors.fill: parent
            implicitHeight: leftSectionRowLayout.implicitHeight
            implicitWidth: leftSectionRowLayout.implicitWidth

            ScrollHint {
                reveal: barLeftSideMouseArea.hovered
                icon: "light_mode"
                tooltipText: Translation.tr("Scroll to change brightness")
                side: "left"
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
            }

            RowLayout { // Content
                id: leftSectionRowLayout
                anchors.fill: parent
                spacing: 10

                RippleButton {
                    // Left sidebar button
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
                    colBackgroundToggled: Appearance.colors.colSecondaryContainer
                    colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
                    colRippleToggled: Appearance.colors.colSecondaryContainerActive
                    toggled: GlobalStates.sidebarLeftOpen
                    property color colText: toggled ? Appearance.m3colors.m3onSecondaryContainer : Appearance.colors.colOnLayer0

                    onPressed: {
                        GlobalStates.sidebarLeftOpen = !GlobalStates.sidebarLeftOpen;
                    }

                    CustomIcon {
                        id: distroIcon
                        anchors.centerIn: parent
                        width: 19.5
                        height: 19.5
                        source: Config.options.bar.topLeftIcon == 'distro' ? SystemInfo.distroIcon : `${Config.options.bar.topLeftIcon}-symbolic`
                        colorize: true
                        color: Appearance.colors.colOnLayer0
                    }
                }

                ActiveWindow {
                    visible: root.useShortenedForm === 0
                    Layout.rightMargin: Appearance.rounding.screenRounding
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }
        }
    }

    RowLayout { // Middle section
        id: middleSection
        anchors.centerIn: parent
        spacing: Config.options?.bar.borderless ? 4 : 8

        BarGroup {
            id: leftCenterGroup
            Layout.preferredWidth: root.centerSideModuleWidth
            Layout.fillHeight: true

            Resources {
                alwaysShowAllResources: root.useShortenedForm === 2
                Layout.fillWidth: root.useShortenedForm === 2
            }

            Media {
                visible: root.useShortenedForm < 2
                Layout.fillWidth: true
            }
        }

        VerticalBarSeparator {
            visible: Config.options?.bar.borderless
        }

        BarGroup {
            id: middleCenterGroup
            padding: workspacesWidget.widgetPadding
            Layout.fillHeight: true

            Workspaces {
                id: workspacesWidget
                Layout.fillHeight: true
                MouseArea {
                    // Right-click to toggle overview
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton

                    onPressed: event => {
                        if (event.button === Qt.RightButton) {
                            GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
                        }
                    }
                }
            }
        }

        VerticalBarSeparator {
            visible: Config.options?.bar.borderless
        }

        MouseArea {
            id: rightCenterGroup
            implicitWidth: rightCenterGroupContent.implicitWidth
            implicitHeight: rightCenterGroupContent.implicitHeight
            Layout.preferredWidth: root.centerSideModuleWidth
            Layout.fillHeight: true

            onPressed: {
                GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen;
            }

            BarGroup {
                id: rightCenterGroupContent
                anchors.fill: parent

                ClockWidget {
                    showDate: (Config.options.bar.verbose && root.useShortenedForm < 2)
                    Layout.alignment: Qt.AlignVCenter
                    Layout.fillWidth: true
                }

                UtilButtons {
                    visible: (Config.options.bar.verbose && root.useShortenedForm === 0)
                    Layout.alignment: Qt.AlignVCenter
                }

                BatteryIndicator {
                    visible: (root.useShortenedForm < 2 && UPower.displayDevice.isLaptopBattery)
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }

        VerticalBarSeparator {
            visible: Config.options.bar.borderless && Config.options.bar.weather.enable
        }
    }

    MouseArea { // Right side | scroll to change volume
        id: barRightSideMouseArea

        anchors.right: parent.right
        implicitHeight: Appearance.sizes.baseBarHeight
        height: Appearance.sizes.barHeight
        width: (root.width - middleSection.width) / 2

        property bool hovered: false
        property real lastScrollX: 0
        property real lastScrollY: 0
        property bool trackingScroll: false

        acceptedButtons: Qt.LeftButton
        hoverEnabled: true
        propagateComposedEvents: true
        onEntered: event => {
            barRightSideMouseArea.hovered = true;
        }
        onExited: event => {
            barRightSideMouseArea.hovered = false;
            barRightSideMouseArea.trackingScroll = false;
        }
        onPressed: event => {
            if (event.button === Qt.LeftButton) {
                GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen;
            } else if (event.button === Qt.RightButton) {
                MprisController.activePlayer.next();
            }
        }
        // Scroll to change volume
        WheelHandler {
            onWheel: event => {
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
        onPositionChanged: mouse => {
            if (barRightSideMouseArea.trackingScroll) {
                const dx = mouse.x - barRightSideMouseArea.lastScrollX;
                const dy = mouse.y - barRightSideMouseArea.lastScrollY;
                if (Math.sqrt(dx * dx + dy * dy) > osdHideMouseMoveThreshold) {
                    GlobalStates.osdVolumeOpen = false;
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
                tooltipText: Translation.tr("Scroll to change volume")
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

                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                    Layout.rightMargin: Appearance.rounding.screenRounding
                    Layout.fillWidth: false

                    implicitWidth: indicatorsRowLayout.implicitWidth + 10 * 2
                    implicitHeight: indicatorsRowLayout.implicitHeight + 5 * 2

                    buttonRadius: Appearance.rounding.full
                    colBackground: barRightSideMouseArea.hovered ? Appearance.colors.colLayer1Hover : ColorUtils.transparentize(Appearance.colors.colLayer1Hover, 1)
                    colBackgroundHover: Appearance.colors.colLayer1Hover
                    colRipple: Appearance.colors.colLayer1Active
                    colBackgroundToggled: Appearance.colors.colSecondaryContainer
                    colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
                    colRippleToggled: Appearance.colors.colSecondaryContainerActive
                    toggled: GlobalStates.sidebarRightOpen
                    property color colText: toggled ? Appearance.m3colors.m3onSecondaryContainer : Appearance.colors.colOnLayer0

                    Behavior on colText {
                        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                    }

                    onPressed: {
                        GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen;
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
                        Loader {
                            active: HyprlandXkb.layoutCodes.length > 1
                            visible: active
                            Layout.rightMargin: indicatorsRowLayout.realSpacing
                            sourceComponent: StyledText {
                                text: HyprlandXkb.currentLayoutCode
                                font.pixelSize: Appearance.font.pixelSize.small
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
                    visible: root.useShortenedForm === 0
                    Layout.fillWidth: false
                    Layout.fillHeight: true
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                // Weather
                Loader {
                    Layout.leftMargin: 8
                    Layout.fillHeight: true
                    active: Config.options.bar.weather.enable
                    sourceComponent: BarGroup {
                        implicitHeight: Appearance.sizes.baseBarHeight
                        WeatherBar {}
                    }
                }
            }
        }
    }
}
