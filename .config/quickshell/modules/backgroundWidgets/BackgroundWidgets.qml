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
import Quickshell.Hyprland
import Quickshell.Services.UPower

Scope {
    id: root
    property string filePath: `${Directories.state}/user/generated/wallpaper/least_busy_region.json`
    property real defaultX: (Config.options?.background.clockX ?? -500)
    property real defaultY: (Config.options?.background.clockY ?? -500)
    property real centerX: defaultX
    property real centerY: defaultY
    property real effectiveCenterX: Config.options?.background.fixedClockPosition ? defaultX : centerX
    property real effectiveCenterY: Config.options?.background.fixedClockPosition ? defaultY : centerY
    property color dominantColor: Appearance.colors.colPrimary
    property bool dominantColorIsDark: dominantColor.hslLightness < 0.5
    property color colBackground: ColorUtils.transparentize(ColorUtils.mix(Appearance.colors.colPrimary, Appearance.colors.colSecondaryContainer), 1)
    property color colText: ColorUtils.colorWithLightness(Appearance.colors.colPrimary, (root.dominantColorIsDark ? 0.8 : 0.12))

    function updateWidgetPosition(fileContent) {
        // console.log("[BackgroundWidgets] Updating widget position with content:", fileContent)
        const parsedContent = JSON.parse(fileContent)
        root.centerX = parsedContent.center_x
        root.centerY = parsedContent.center_y
        root.dominantColor = parsedContent.dominant_color || Appearance.colors.colPrimary
    }
    
    Timer {
        id: delayedFileRead
        interval: Config.options.hacks.arbitraryRaceConditionDelay
        running: false
        onTriggered: {
            root.updateWidgetPosition(leastBusyRegionFileView.text())
        }
    }

    FileView { 
        id: leastBusyRegionFileView
        path: Qt.resolvedUrl(root.filePath)
        watchChanges: !Config.options?.background.fixedClockPosition
        onFileChanged: {
            this.reload()
            delayedFileRead.start()
        }
        onLoadedChanged: {
            const fileContent = leastBusyRegionFileView.text()
            root.updateWidgetPosition(fileContent)
        }
    }

    Variants { // For each monitor
        model: Quickshell.screens

        LazyLoader {
            required property var modelData
            readonly property HyprlandMonitor monitor: Hyprland.monitorFor(modelData)
            activeAsync: !ToplevelManager.activeToplevel?.activated
            component: PanelWindow { // Window
                id: windowRoot
                screen: modelData
                property var textHorizontalAlignment: root.effectiveCenterX / monitor.scale < windowRoot.width / 3 ? Text.AlignLeft :
                    (root.effectiveCenterX / monitor.scale > windowRoot.width * 2 / 3 ? Text.AlignRight : Text.AlignHCenter)

                WlrLayershell.layer: WlrLayer.Bottom
                WlrLayershell.namespace: "quickshell:backgroundWidgets"
                
                anchors {
                    top: true
                    bottom:true
                    left: true
                    right: true
                }
                color: "transparent"
                HyprlandWindow.visibleMask: Region {
                    item: widgetBackground
                }

                Rectangle {
                    id: widgetBackground
                    property real verticalPadding: 20
                    property real horizontalPadding: 30
                    radius: 40
                    color: root.colBackground
                    implicitHeight: columnLayout.implicitHeight + verticalPadding * 2
                    implicitWidth: columnLayout.implicitWidth + horizontalPadding * 2
                    anchors {
                        left: parent.left
                        top: parent.top
                        leftMargin: (root.effectiveCenterX / monitor.scale - implicitWidth / 2)
                        topMargin: (root.effectiveCenterY / monitor.scale - implicitHeight / 2)
                        Behavior on leftMargin {
                            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
                        }
                        Behavior on topMargin {
                            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
                        }
                    }

                    ColumnLayout {
                        id: columnLayout
                        anchors.centerIn: parent
                        spacing: -5

                        StyledText {
                            Layout.fillWidth: true
                            horizontalAlignment: windowRoot.textHorizontalAlignment
                            font.pixelSize: 95
                            color: root.colText
                            style: Text.Raised
                            styleColor: Appearance.colors.colShadow
                            text: DateTime.time
                        }
                        StyledText {
                            Layout.fillWidth: true
                            horizontalAlignment: windowRoot.textHorizontalAlignment
                            font.pixelSize: 25
                            color: root.colText
                            style: Text.Raised
                            styleColor: Appearance.colors.colShadow
                            text: DateTime.date
                        }
                    }
                }

            }
        }

    }

}
