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

Scope {
    id: bar

    readonly property int osdHideMouseMoveThreshold: 20
    property bool showBarBackground: Config.options.bar.showBackground

    Variants {
        // For each monitor
        model: {
            const screens = Quickshell.screens;
            const list = Config.options.bar.screenList;
            if (!list || list.length === 0)
                return screens;
            return screens.filter(screen => list.includes(screen.name));
        }
        LazyLoader {
            id: barLoader
            active: GlobalStates.barOpen && !GlobalStates.screenLocked
            required property ShellScreen modelData
            component: PanelWindow { // Bar window
                id: barRoot
                screen: barLoader.modelData

                property var brightnessMonitor: Brightness.getMonitorForScreen(barLoader.modelData)
                property real useShortenedForm: (Appearance.sizes.barHellaShortenScreenWidthThreshold >= screen.width) ? 2 : (Appearance.sizes.barShortenScreenWidthThreshold >= screen.width) ? 1 : 0
                readonly property int centerSideModuleWidth: (useShortenedForm == 2) ? Appearance.sizes.barCenterSideModuleWidthHellaShortened : (useShortenedForm == 1) ? Appearance.sizes.barCenterSideModuleWidthShortened : Appearance.sizes.barCenterSideModuleWidth

                exclusionMode: ExclusionMode.Ignore
                exclusiveZone: Appearance.sizes.baseBarHeight + (Config.options.bar.cornerStyle === 1 ? Appearance.sizes.hyprlandGapsOut : 0)
                WlrLayershell.namespace: "quickshell:bar"
                implicitHeight: Appearance.sizes.barHeight + Appearance.rounding.screenRounding
                mask: Region {
                    item: barContent
                }
                color: "transparent"

                anchors {
                    top: !Config.options.bar.bottom
                    bottom: Config.options.bar.bottom
                    left: true
                    right: true
                }

                BarContent {
                    id: barContent
                    
                    anchors {
                        right: parent.right
                        left: parent.left
                        top: parent.top
                        bottom: undefined
                    }
                    implicitHeight: Appearance.sizes.barHeight

                    states: State {
                        name: "bottom"
                        when: Config.options.bar.bottom
                        AnchorChanges {
                            target: barContent
                            anchors {
                                right: parent.right
                                left: parent.left
                                top: undefined
                                bottom: parent.bottom
                            }
                        }
                    }
                }

                // Round decorators
                Loader {
                    id: roundDecorators
                    anchors {
                        left: parent.left
                        right: parent.right
                    }
                    y: Appearance.sizes.barHeight
                    width: parent.width
                    height: Appearance.rounding.screenRounding
                    active: showBarBackground && Config.options.bar.cornerStyle === 0 // Hug

                    states: State {
                        name: "bottom"
                        when: Config.options.bar.bottom
                        PropertyChanges {
                            roundDecorators.y: 0
                        }
                    }

                    sourceComponent: Item {
                        implicitHeight: Appearance.rounding.screenRounding
                        RoundCorner {
                            id: leftCorner
                            anchors {
                                top: parent.top
                                bottom: parent.bottom
                                left: parent.left
                            }

                            implicitSize: Appearance.rounding.screenRounding
                            color: showBarBackground ? Appearance.colors.colLayer0 : "transparent"

                            corner: RoundCorner.CornerEnum.TopLeft
                            states: State {
                                name: "bottom"
                                when: Config.options.bar.bottom
                                PropertyChanges {
                                    leftCorner.corner: RoundCorner.CornerEnum.BottomLeft
                                }
                            }
                        }
                        RoundCorner {
                            id: rightCorner
                            anchors {
                                right: parent.right
                                top: !Config.options.bar.bottom ? parent.top : undefined
                                bottom: Config.options.bar.bottom ? parent.bottom : undefined
                            }
                            implicitSize: Appearance.rounding.screenRounding
                            color: showBarBackground ? Appearance.colors.colLayer0 : "transparent"

                            corner: RoundCorner.CornerEnum.TopRight
                            states: State {
                                name: "bottom"
                                when: Config.options.bar.bottom
                                PropertyChanges {
                                    rightCorner.corner: RoundCorner.CornerEnum.BottomRight
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "bar"

        function toggle(): void {
            GlobalStates.barOpen = !GlobalStates.barOpen
        }

        function close(): void {
            GlobalStates.barOpen = false
        }

        function open(): void {
            GlobalStates.barOpen = true
        }
    }

    GlobalShortcut {
        name: "barToggle"
        description: "Toggles bar on press"

        onPressed: {
            GlobalStates.barOpen = !GlobalStates.barOpen;
        }
    }

    GlobalShortcut {
        name: "barOpen"
        description: "Opens bar on press"

        onPressed: {
            GlobalStates.barOpen = true;
        }
    }

    GlobalShortcut {
        name: "barClose"
        description: "Closes bar on press"

        onPressed: {
            GlobalStates.barOpen = false;
        }
    }
}
