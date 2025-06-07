import "root:/"
import "root:/services"
import "root:/modules/common"
import "root:/modules/common/widgets"
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell.Io
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Hyprland

Scope { // Scope
    id: root
    property bool pinned: ConfigOptions?.dock.pinnedOnStartup ?? false

    Variants { // For each monitor
        model: Quickshell.screens
        PanelWindow { // Window
            required property var modelData
            id: dockRoot
            screen: modelData
            
            property bool reveal: root.pinned || dockMouseArea.containsMouse || dockApps.requestDockShow

            anchors {
                bottom: true
                left: true
                right: true
            }

            function hide() {
                cheatsheetLoader.active = false
            }
            exclusiveZone: root.pinned ? implicitHeight - Appearance.sizes.hyprlandGapsOut : 0

            implicitWidth: dockBackground.implicitWidth
            WlrLayershell.namespace: "quickshell:dock"
            color: "transparent"

            implicitHeight: (ConfigOptions?.dock.height ?? 70) + Appearance.sizes.elevationMargin + Appearance.sizes.hyprlandGapsOut

            mask: Region {
                item: dockMouseArea
            }

            MouseArea {
                id: dockMouseArea
                anchors.top: parent.top
                height: parent.height
                anchors.topMargin: dockRoot.reveal ? 0 : dockRoot.implicitHeight - ConfigOptions.dock.hoverRegionHeight
                anchors.left: parent.left
                anchors.right: parent.right
                hoverEnabled: true

                Behavior on anchors.topMargin {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }

                Item {
                    id: dockHoverRegion
                    anchors.fill: parent

                    Item {
                        id: dockBackground
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter

                        implicitWidth: dockRow.implicitWidth + 5 * 2
                        height: parent.height - Appearance.sizes.elevationMargin - Appearance.sizes.hyprlandGapsOut

                        StyledRectangularShadow {
                            target: dockVisualBackground
                        }
                        Rectangle {
                            id: dockVisualBackground
                            property real margin: Appearance.sizes.elevationMargin
                            anchors.fill: parent
                            anchors.topMargin: margin
                            anchors.bottomMargin: margin
                            color: Appearance.colors.colLayer0
                            radius: Appearance.rounding.large
                        }

                        RowLayout {
                            id: dockRow
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 3
                            property real padding: 5

                            VerticalButtonGroup {
                                GroupButton { // Pin button
                                    baseWidth: 35
                                    baseHeight: 35
                                    clickedWidth: baseWidth
                                    clickedHeight: baseHeight + 20
                                    buttonRadius: Appearance.rounding.normal
                                    toggled: root.pinned
                                    onClicked: root.pinned = !root.pinned
                                    contentItem: MaterialSymbol {
                                        text: "keep"
                                        horizontalAlignment: Text.AlignHCenter
                                        iconSize: Appearance.font.pixelSize.larger
                                        color: root.pinned ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer0
                                    }
                                }
                            }
                            DockSeparator {}
                            // Pinned apps
                            Repeater {
                                model: ConfigOptions?.dock.pinnedApps ?? []
                                
                                DockButton {
                                    id: pinnedAppButton
                                    required property string modelData
                                    property DesktopEntry entry: DesktopEntries.byId(modelData)
                                    onClicked: {
                                        pinnedAppButton?.entry.execute();
                                    }
                                    contentItem: IconImage {
                                        anchors.centerIn: parent
                                        source: Quickshell.iconPath(AppSearch.guessIcon(modelData), "image-missing")
                                    }
                                }
                            }
                            
                            DockSeparator { visible: (ConfigOptions?.dock.pinnedApps ?? []).length > 0 }
                            
                            DockApps { id: dockApps }
                            DockSeparator {}
                            DockButton {
                                onClicked: Hyprland.dispatch("global quickshell:overviewToggle")
                                contentItem: MaterialSymbol {
                                    anchors.centerIn: parent
                                    horizontalAlignment: Text.AlignHCenter
                                    font.pixelSize: parent.width / 2
                                    text: "apps"
                                    color: Appearance.colors.colOnLayer0
                                }
                            }
                        }
                    }    
                }

            }
        }
    }
}
