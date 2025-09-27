pragma ComponentBehavior: Bound

import qs
import qs.services
import qs.modules.common
import qs.modules.common.models
import qs.modules.common.widgets
import qs.modules.common.functions as CF
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Variants {
    id: root
    readonly property bool fixedClockPosition: Config.options.background.clock.fixedPosition
    readonly property real fixedClockX: Config.options.background.clock.x
    readonly property real fixedClockY: Config.options.background.clock.y
    readonly property real clockSizePadding: 20
    readonly property real screenSizePadding: 50
    readonly property string clockStyle: Config.options.background.clock.style
    model: Quickshell.screens

    PanelWindow {
        id: bgRoot

        required property var modelData

        // Hide when fullscreen
        property list<HyprlandWorkspace> workspacesForMonitor: Hyprland.workspaces.values.filter(workspace => workspace.monitor && workspace.monitor.name == monitor.name)
        property var activeWorkspaceWithFullscreen: workspacesForMonitor.filter(workspace => ((workspace.toplevels.values.filter(window => window.wayland?.fullscreen)[0] != undefined) && workspace.active))[0]
        visible: GlobalStates.screenLocked || (!(activeWorkspaceWithFullscreen != undefined)) || !Config?.options.background.hideWhenFullscreen

        // Workspaces
        property HyprlandMonitor monitor: Hyprland.monitorFor(modelData)
        property list<var> relevantWindows: HyprlandData.windowList.filter(win => win.monitor == monitor?.id && win.workspace.id >= 0).sort((a, b) => a.workspace.id - b.workspace.id)
        property int firstWorkspaceId: relevantWindows[0]?.workspace.id || 1
        property int lastWorkspaceId: relevantWindows[relevantWindows.length - 1]?.workspace.id || 10
        // Wallpaper
        property bool wallpaperIsVideo: Config.options.background.wallpaperPath.endsWith(".mp4") || Config.options.background.wallpaperPath.endsWith(".webm") || Config.options.background.wallpaperPath.endsWith(".mkv") || Config.options.background.wallpaperPath.endsWith(".avi") || Config.options.background.wallpaperPath.endsWith(".mov")
        property string wallpaperPath: wallpaperIsVideo ? Config.options.background.thumbnailPath : Config.options.background.wallpaperPath
        property bool wallpaperSafetyTriggered: {
            const enabled = Config.options.workSafety.enable.wallpaper
            const sensitiveWallpaper = (CF.StringUtils.stringListContainsSubstring(wallpaperPath.toLowerCase(), Config.options.workSafety.triggerCondition.fileKeywords))
            const sensitiveNetwork = (CF.StringUtils.stringListContainsSubstring(Network.networkName.toLowerCase(), Config.options.workSafety.triggerCondition.networkNameKeywords))
            return enabled && sensitiveWallpaper && sensitiveNetwork;
        }
        property real wallpaperToScreenRatio: Math.min(wallpaperWidth / screen.width, wallpaperHeight / screen.height)
        property real preferredWallpaperScale: Config.options.background.parallax.workspaceZoom
        property real effectiveWallpaperScale: 1 // Some reasonable init value, to be updated
        property int wallpaperWidth: modelData.width // Some reasonable init value, to be updated
        property int wallpaperHeight: modelData.height // Some reasonable init value, to be updated
        property real movableXSpace: ((wallpaperWidth / wallpaperToScreenRatio * effectiveWallpaperScale) - screen.width) / 2
        property real movableYSpace: ((wallpaperHeight / wallpaperToScreenRatio * effectiveWallpaperScale) - screen.height) / 2
        readonly property bool verticalParallax: (Config.options.background.parallax.autoVertical && wallpaperHeight > wallpaperWidth) || Config.options.background.parallax.vertical
        // Position
        property real clockX: (modelData.width / 2)
        property real clockY: (modelData.height / 2)
        property var textHorizontalAlignment: {
            if ((Config.options.lock.centerClock && GlobalStates.screenLocked) || wallpaperSafetyTriggered)
                return Text.AlignHCenter;
            if (clockX < screen.width / 3)
                return Text.AlignLeft;
            if (clockX > screen.width * 2 / 3)
                return Text.AlignRight;
            return Text.AlignHCenter;
        }
        // Colors
        property bool shouldBlur: (GlobalStates.screenLocked && Config.options.lock.blur.enable)
        property color dominantColor: Appearance.colors.colPrimary // Default, to be changed
        property bool dominantColorIsDark: dominantColor.hslLightness < 0.5
        property color colText: {
            if (wallpaperSafetyTriggered)
                return CF.ColorUtils.mix(Appearance.colors.colOnLayer0, Appearance.colors.colPrimary, 0.75);
            return (GlobalStates.screenLocked && shouldBlur) ? Appearance.colors.colOnLayer0 : CF.ColorUtils.colorWithLightness(Appearance.colors.colPrimary, (dominantColorIsDark ? 0.8 : 0.12));
        }
        Behavior on colText {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        // Layer props
        screen: modelData
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: (GlobalStates.screenLocked && !scaleAnim.running) ? WlrLayer.Overlay : WlrLayer.Bottom
        // WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.namespace: "quickshell:background"
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        color: CF.ColorUtils.transparentize(CF.ColorUtils.mix(Appearance.colors.colLayer0, Appearance.colors.colPrimary, 0.75), (bgRoot.wallpaperIsVideo ? 1 : 0))
        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        onWallpaperPathChanged: {
            bgRoot.updateZoomScale();
            // Clock position gets updated after zoom scale is updated
        }

        // Wallpaper zoom scale
        function updateZoomScale() {
            getWallpaperSizeProc.path = bgRoot.wallpaperPath;
            getWallpaperSizeProc.running = true;
        }
        Process {
            id: getWallpaperSizeProc
            property string path: bgRoot.wallpaperPath
            command: ["magick", "identify", "-format", "%w %h", path]
            stdout: StdioCollector {
                id: wallpaperSizeOutputCollector
                onStreamFinished: {
                    const output = wallpaperSizeOutputCollector.text;
                    const [width, height] = output.split(" ").map(Number);
                    const [screenWidth, screenHeight] = [bgRoot.screen.width, bgRoot.screen.height];
                    bgRoot.wallpaperWidth = width;
                    bgRoot.wallpaperHeight = height;

                    if (width <= screenWidth || height <= screenHeight) {
                        // Undersized/perfectly sized wallpapers
                        bgRoot.effectiveWallpaperScale = Math.max(screenWidth / width, screenHeight / height);
                    } else {
                        // Oversized = can be zoomed for parallax, yay
                        bgRoot.effectiveWallpaperScale = Math.min(bgRoot.preferredWallpaperScale, width / screenWidth, height / screenHeight);
                    }

                    bgRoot.updateClockPosition();
                }
            }
        }

        // Clock positioning
        function updateClockPosition() {
            // Somehow all this manual setting is needed to make the proc correctly use the new values
            leastBusyRegionProc.path = bgRoot.wallpaperPath;
            leastBusyRegionProc.contentWidth = clockLoader.implicitWidth + root.clockSizePadding * 2;
            leastBusyRegionProc.contentHeight = clockLoader.implicitHeight + root.clockSizePadding * 2;
            leastBusyRegionProc.horizontalPadding = bgRoot.movableXSpace + root.screenSizePadding * 2;
            leastBusyRegionProc.verticalPadding = bgRoot.movableYSpace + root.screenSizePadding * 2;
            leastBusyRegionProc.running = false;
            leastBusyRegionProc.running = true;
        }
        Process {
            id: leastBusyRegionProc
            property string path: bgRoot.wallpaperPath
            property int contentWidth: 300
            property int contentHeight: 300
            property int horizontalPadding: bgRoot.movableXSpace
            property int verticalPadding: bgRoot.movableYSpace
            command: [Quickshell.shellPath("scripts/images/least_busy_region.py"), "--screen-width", Math.round(bgRoot.screen.width / bgRoot.effectiveWallpaperScale), "--screen-height", Math.round(bgRoot.screen.height / bgRoot.effectiveWallpaperScale), "--width", contentWidth, "--height", contentHeight, "--horizontal-padding", horizontalPadding, "--vertical-padding", verticalPadding, path
                // "--visual-output",
                ,]
            stdout: StdioCollector {
                id: leastBusyRegionOutputCollector
                onStreamFinished: {
                    const output = leastBusyRegionOutputCollector.text;
                    // console.log("[Background] Least busy region output:", output)
                    if (output.length === 0)
                        return;
                    const parsedContent = JSON.parse(output);
                    bgRoot.clockX = parsedContent.center_x * bgRoot.effectiveWallpaperScale;
                    bgRoot.clockY = parsedContent.center_y * bgRoot.effectiveWallpaperScale;
                    bgRoot.dominantColor = parsedContent.dominant_color || Appearance.colors.colPrimary;
                }
            }
        }

        // Wallpaper
        Item {
            anchors.fill: parent
            clip: true

            Image {
                id: wallpaper
                visible: opacity > 0 && !blurLoader.active
                opacity: (status === Image.Ready && !bgRoot.wallpaperIsVideo) ? 1 : 0
                Behavior on opacity {
                    animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
                }
                cache: false
                asynchronous: true
                retainWhileLoading: true
                smooth: false
                // Range = groups that workspaces span on
                property int chunkSize: Config?.options.bar.workspaces.shown ?? 10
                property int lower: Math.floor(bgRoot.firstWorkspaceId / chunkSize) * chunkSize
                property int upper: Math.ceil(bgRoot.lastWorkspaceId / chunkSize) * chunkSize
                property int range: upper - lower
                property real valueX: {
                    let result = 0.5;
                    if (Config.options.background.parallax.enableWorkspace && !bgRoot.verticalParallax) {
                        result = ((bgRoot.monitor.activeWorkspace?.id - lower) / range);
                    }
                    if (Config.options.background.parallax.enableSidebar) {
                        result += (0.15 * GlobalStates.sidebarRightOpen - 0.15 * GlobalStates.sidebarLeftOpen);
                    }
                    return result;
                }
                property real valueY: {
                    let result = 0.5;
                    if (Config.options.background.parallax.enableWorkspace && bgRoot.verticalParallax) {
                        result = ((bgRoot.monitor.activeWorkspace?.id - lower) / range);
                    }
                    return result;
                }
                property real effectiveValueX: Math.max(0, Math.min(1, valueX))
                property real effectiveValueY: Math.max(0, Math.min(1, valueY))
                x: -(bgRoot.movableXSpace) - (effectiveValueX - 0.5) * 2 * bgRoot.movableXSpace
                y: -(bgRoot.movableYSpace) - (effectiveValueY - 0.5) * 2 * bgRoot.movableYSpace
                source: bgRoot.wallpaperSafetyTriggered ? "" : bgRoot.wallpaperPath
                fillMode: Image.PreserveAspectCrop
                Behavior on x {
                    NumberAnimation {
                        duration: 600
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on y {
                    NumberAnimation {
                        duration: 600
                        easing.type: Easing.OutCubic
                    }
                }
                sourceSize {
                    width: bgRoot.screen.width * bgRoot.effectiveWallpaperScale * bgRoot.monitor.scale
                    height: bgRoot.screen.height * bgRoot.effectiveWallpaperScale * bgRoot.monitor.scale
                }
                width: bgRoot.wallpaperWidth / bgRoot.wallpaperToScreenRatio * bgRoot.effectiveWallpaperScale
                height: bgRoot.wallpaperHeight / bgRoot.wallpaperToScreenRatio * bgRoot.effectiveWallpaperScale
            }

            Loader {
                id: blurLoader
                active: Config.options.lock.blur.enable && (GlobalStates.screenLocked || scaleAnim.running)
                anchors.fill: wallpaper
                scale: GlobalStates.screenLocked ? Config.options.lock.blur.extraZoom : 1
                Behavior on scale {
                    NumberAnimation {
                        id: scaleAnim
                        duration: 400
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.animationCurves.expressiveDefaultSpatial
                    }
                }
                sourceComponent: GaussianBlur {
                    source: wallpaper
                    radius: GlobalStates.screenLocked ? Config.options.lock.blur.radius : 0
                    samples: radius * 2 + 1

                    Rectangle {
                        opacity: GlobalStates.screenLocked ? 1 : 0
                        anchors.fill: parent
                        color: CF.ColorUtils.transparentize(Appearance.colors.colLayer0, 0.7)
                    }
                }
            }

            // The clock
            Loader {
                id: clockLoader
                scale: Config.options.background.clock.scale
                active: Config.options.background.clock.show
                anchors {
                    left: wallpaper.left
                    top: wallpaper.top
                    horizontalCenter: undefined
                    verticalCenter: undefined
                    leftMargin: bgRoot.movableXSpace + ((root.fixedClockPosition ? root.fixedClockX : bgRoot.clockX * bgRoot.effectiveWallpaperScale) - implicitWidth / 2)
                    topMargin: bgRoot.movableYSpace + ((root.fixedClockPosition ? root.fixedClockY : bgRoot.clockY * bgRoot.effectiveWallpaperScale) - implicitHeight / 2)
                    Behavior on leftMargin {
                        animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
                    }
                    Behavior on topMargin {
                        animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
                    }
                }
                states: State {
                    name: "centered"
                    when: (GlobalStates.screenLocked && Config.options.lock.centerClock) || bgRoot.wallpaperSafetyTriggered
                    AnchorChanges {
                        target: clockLoader
                        anchors {
                            left: undefined
                            right: undefined
                            top: undefined
                            verticalCenter: parent.verticalCenter
                            horizontalCenter: parent.horizontalCenter
                        }
                    }
                }
                transitions: Transition {
                    AnchorAnimation {
                        duration: Appearance.animation.elementMove.duration
                        easing.type: Appearance.animation.elementMove.type
                        easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
                    }
                }
                sourceComponent: ColumnLayout {
                    spacing: 8

                    Loader {
                        id: digitalClockLoader
                        visible: root.clockStyle === "digital"
                        active: visible
                        sourceComponent: ColumnLayout {
                            id: clockColumn
                            spacing: 6

                            ClockText {
                                font.pixelSize: 90
                                text: DateTime.time
                            }
                            ClockText {
                                Layout.topMargin: -5
                                text: DateTime.date
                            }
                            StyledText {
                                // Somehow gets fucked up if made a ClockText???
                                visible: Config.options.background.quote.length > 0
                                Layout.fillWidth: true
                                horizontalAlignment: bgRoot.textHorizontalAlignment
                                font {
                                    family: Appearance.font.family.main
                                    pixelSize: Appearance.font.pixelSize.normal
                                    weight: 350
                                    italic: true
                                }
                                color: bgRoot.colText
                                style: Text.Raised
                                styleColor: Appearance.colors.colShadow
                                text: Config.options.background.quote
                            }
                        }
                    }

                    Loader {
                        id: cookieClockLoader
                        Layout.alignment: Qt.AlignHCenter
                        visible: root.clockStyle === "cookie"
                        active: visible
                        sourceComponent: CookieClock {}
                    }
                }

                Item {
                    anchors {
                        top: clockLoader.bottom
                        topMargin: 8
                        horizontalCenter: (bgRoot.textHorizontalAlignment === Text.AlignHCenter || root.clockStyle === "cookie") ? clockLoader.horizontalCenter : undefined
                        left: (bgRoot.textHorizontalAlignment === Text.AlignLeft) ? clockLoader.left : undefined
                        right: (bgRoot.textHorizontalAlignment === Text.AlignRight) ? clockLoader.right : undefined
                        leftMargin: -26
                        rightMargin: -26
                    }
                    implicitWidth: statusTextBg.implicitWidth
                    implicitHeight: statusTextBg.implicitHeight

                    StyledRectangularShadow {
                        target: statusTextBg
                        visible: statusTextBg.visible && root.clockStyle === "cookie"
                        opacity: statusTextBg.opacity
                    }

                    Rectangle {
                        id: statusTextBg
                        anchors.centerIn: parent
                        clip: true
                        opacity: (safetyStatusText.shown || lockStatusText.shown) ? 1 : 0
                        visible: opacity > 0
                        implicitHeight: statusTextRow.implicitHeight + 5 * 2
                        implicitWidth: statusTextRow.implicitWidth + 5 * 2
                        radius: Appearance.rounding.small
                        color: CF.ColorUtils.transparentize(Appearance.colors.colSecondaryContainer, root.clockStyle === "cookie" ? 0 : 1)

                        Behavior on implicitWidth {
                            animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
                        }
                        Behavior on implicitHeight {
                            animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
                        }
                        Behavior on opacity {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }

                        RowLayout {
                            id: statusTextRow
                            anchors.centerIn: parent
                            spacing: 14
                            Item {
                                Layout.fillWidth: bgRoot.textHorizontalAlignment !== Text.AlignLeft
                                implicitWidth: 1
                            }
                            ClockStatusText {
                                id: safetyStatusText
                                shown: bgRoot.wallpaperSafetyTriggered
                                statusIcon: "hide_image"
                                statusText: qsTr("Wallpaper safety enforced")
                            }
                            ClockStatusText {
                                id: lockStatusText
                                shown: GlobalStates.screenLocked && Config.options.lock.showLockedText
                                statusIcon: "lock"
                                statusText: qsTr("Locked")
                            }
                            Item {
                                Layout.fillWidth: bgRoot.textHorizontalAlignment !== Text.AlignRight
                                implicitWidth: 1
                            }
                        }
                    }
                }
            }
        }
    }

    // Components
    component ClockText: StyledText {
        Layout.fillWidth: true
        horizontalAlignment: bgRoot.textHorizontalAlignment
        font {
            family: Appearance.font.family.expressive
            pixelSize: 20
            weight: Font.DemiBold
        }
        color: bgRoot.colText
        style: Text.Raised
        styleColor: Appearance.colors.colShadow
        animateChange: true
    }
    component ClockStatusText: RowLayout {
        id: statusTextRow
        property alias statusIcon: statusIconWidget.text
        property alias statusText: statusTextWidget.text
        property bool shown: true
        property color textColor: root.clockStyle === "cookie" ? Appearance.colors.colOnSecondaryContainer : bgRoot.colText
        opacity: shown ? 1 : 0
        visible: opacity > 0
        Behavior on opacity {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
        Layout.fillWidth: false
        MaterialSymbol {
            id: statusIconWidget
            Layout.fillWidth: false
            iconSize: Appearance.font.pixelSize.huge
            color: statusTextRow.textColor
            style: Text.Raised
            styleColor: Appearance.colors.colShadow
        }
        ClockText {
            id: statusTextWidget
            Layout.fillWidth: false
            color: statusTextRow.textColor
            font {
                family: Appearance.font.family.main
                pixelSize: Appearance.font.pixelSize.large
                weight: Font.Normal
            }
            style: Text.Raised
            styleColor: Appearance.colors.colShadow
        }
    }
}
