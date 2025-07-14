pragma ComponentBehavior: Bound

import "root:/"
import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import "root:/modules/common/functions/color_utils.js" as ColorUtils
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: root
    readonly property bool fixedClockPosition: Config.options.background.fixedClockPosition
    readonly property real fixedClockX: Config.options.background.clockX
    readonly property real fixedClockY: Config.options.background.clockY

    Variants {
        // For each monitor
        model: Quickshell.screens

        PanelWindow {
            id: bgRoot

            required property var modelData
            property string wallpaperPath: Config.options.background.wallpaperPath
            // Position
            property real clockX: modelData.width / 2
            property real clockY: modelData.height / 2
            property var textHorizontalAlignment: clockX < screen.width / 3 ? Text.AlignLeft :
                (clockX > screen.width * 2 / 3 ? Text.AlignRight : Text.AlignHCenter)
            // Colors
            property color dominantColor: Appearance.colors.colPrimary
            property bool dominantColorIsDark: dominantColor.hslLightness < 0.5
            property color colText: ColorUtils.colorWithLightness(Appearance.colors.colPrimary, (dominantColorIsDark ? 0.8 : 0.12))

            // Layer props
            screen: modelData
            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.namespace: "quickshell:background"
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            color: "transparent"

            // Clock positioning
            function updateClockPosition() {
                leastBusyRegionProc.path = wallpaperPath // Somehow this is needed to make the proc correctly use the new path
                leastBusyRegionProc.contentWidth = clock.implicitWidth
                leastBusyRegionProc.contentHeight = clock.implicitHeight
                leastBusyRegionProc.running = false;
                leastBusyRegionProc.running = true;
            }
            onWallpaperPathChanged: {
                // console.log("[Background] Wallpaper path changed to:", wallpaperPath)
                bgRoot.updateClockPosition()
            }
            Process {
                id: leastBusyRegionProc
                running: true
                property string path: bgRoot.wallpaperPath
                property int contentWidth: bgRoot.screen.width
                property int contentHeight: bgRoot.screen.height
                command: [Quickshell.configPath("scripts/images/least_busy_region.py"),
                    "--screen-width", bgRoot.screen.width,
                    "--screen-height", bgRoot.screen.height,
                    "--width", contentWidth,
                    "--height", contentHeight,
                    path
                ]
                stdout: StdioCollector {
                    id: leastBusyRegionOutputCollector
                    onStreamFinished: {
                        const output = leastBusyRegionOutputCollector.text
                        // console.log("[Background] Least busy region output:", output)
                        if (output.length === 0) return;
                        const parsedContent = JSON.parse(output)
                        bgRoot.clockX = parsedContent.center_x
                        bgRoot.clockY = parsedContent.center_y
                        bgRoot.dominantColor = parsedContent.dominant_color || Appearance.colors.colPrimary
                    }
                }
            }

            // Wallpaper
            Image {
                z: 0
                anchors.fill: parent
                source: bgRoot.wallpaperPath
                fillMode: Image.PreserveAspectCrop
                sourceSize {
                    width: bgRoot.screen.width
                    height: bgRoot.screen.height
                }
            }

            // The clock
            Item {
                id: clock
                z: 1
                anchors {
                    left: parent.left
                    top: parent.top
                    leftMargin: (root.fixedClockPosition ? root.fixedClockX : bgRoot.clockX) - implicitWidth / 2
                    topMargin: (root.fixedClockPosition ? root.fixedClockY : bgRoot.clockY) - implicitHeight / 2
                    Behavior on leftMargin {
                        animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
                    }
                    Behavior on topMargin {
                        animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
                    }
                }

                implicitWidth: clockColumn.implicitWidth
                implicitHeight: clockColumn.implicitHeight

                ColumnLayout {
                    id: clockColumn
                    anchors.centerIn: parent
                    spacing: -5

                    StyledText {
                        Layout.fillWidth: true
                        horizontalAlignment: bgRoot.textHorizontalAlignment
                        font.pixelSize: 95
                        color: bgRoot.colText
                        style: Text.Raised
                        styleColor: Appearance.colors.colShadow
                        text: DateTime.time
                    }
                    StyledText {
                        Layout.fillWidth: true
                        horizontalAlignment: bgRoot.textHorizontalAlignment
                        font.pixelSize: 25
                        color: bgRoot.colText
                        style: Text.Raised
                        styleColor: Appearance.colors.colShadow
                        text: DateTime.date
                    }
                }
            }
        }
    }
}
