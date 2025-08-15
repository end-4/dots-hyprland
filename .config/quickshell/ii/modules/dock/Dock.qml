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
    property bool pinned: Config.options?.dock.pinnedOnStartup ?? false

    Variants { // For each monitor
        model: Quickshell.screens

        LazyLoader {
            id: dockLoader
            required property var modelData
            activeAsync: Config.options?.dock.hoverToReveal || (!ToplevelManager.activeToplevel?.activated)

            component: PanelWindow { // Window
                id: dockRoot
                screen: dockLoader.modelData
                
                property bool reveal: root.pinned 
                    || (Config.options?.dock.hoverToReveal && dockMouseArea.containsMouse) 
                    || dockApps.requestDockShow 
                    || (!ToplevelManager.activeToplevel?.activated)

                anchors {
                    bottom: true
                    left: true
                    right: true
                }

                exclusiveZone: root.pinned ? implicitHeight 
                    - (Appearance.sizes.hyprlandGapsOut) 
                    - (Appearance.sizes.elevationMargin - Appearance.sizes.hyprlandGapsOut) : 0

                implicitWidth: dockBackground.implicitWidth
                WlrLayershell.namespace: "quickshell:dock"
                color: "transparent"

                implicitHeight: (Config.options?.dock.height ?? 70) + Appearance.sizes.elevationMargin + Appearance.sizes.hyprlandGapsOut

                mask: Region {
                    item: dockMouseArea
                }

                MouseArea {
                    id: dockMouseArea
                    anchors.top: parent.top
                    height: parent.height
                    anchors.topMargin: dockRoot.reveal ? 0 : 
                        Config.options?.dock.hoverToReveal ? (dockRoot.implicitHeight - Config.options.dock.hoverRegionHeight) :
                        (dockRoot.implicitHeight + 1)
                        
                    anchors.left: parent.left
                    anchors.right: parent.right
                    hoverEnabled: true

                    Behavior on anchors.topMargin {
                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                    }

                    Item {
                        id: dockHoverRegion
                        anchors.fill: parent

                        Item { // Wrapper for the dock background
                            id: dockBackground
                            anchors {
                                top: parent.top
                                bottom: parent.bottom
                                horizontalCenter: parent.horizontalCenter
                            }

                            implicitWidth: dockRow.implicitWidth + 5 * 2
                            height: parent.height - Appearance.sizes.elevationMargin - Appearance.sizes.hyprlandGapsOut

                            StyledRectangularShadow {
                                target: dockVisualBackground
                            }
                            Rectangle { // The real rectangle that is visible
                                id: dockVisualBackground
                                property real margin: Appearance.sizes.elevationMargin
                                anchors.fill: parent
                                anchors.topMargin: Appearance.sizes.elevationMargin
                                anchors.bottomMargin: Appearance.sizes.hyprlandGapsOut
                                color: Appearance.colors.colLayer0
                                border.width: 1
                                border.color: Appearance.m3colors.m3outlineVariant
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
                                    Layout.topMargin: Appearance.sizes.hyprlandGapsOut // why does this work
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
                                DockApps { id: dockApps; }
                                DockSeparator {}
                                DockButton {
                                    Layout.fillHeight: true
                                    onClicked: Hyprland.dispatch("global quickshell:overviewToggle")
                                    contentItem: MaterialSymbol {
                                        anchors.fill: parent
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
}
