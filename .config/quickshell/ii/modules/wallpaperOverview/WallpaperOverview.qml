import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

// Fullscreen panel similar to Overview, but shows a grid of wallpaper previews.
Scope {
    id: scope

    Variants {
        id: variants
        model: Quickshell.screens

                    PanelWindow {
                id: root
                required property var modelData
                readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.screen)
                property bool monitorIsFocused: (Hyprland.focusedMonitor?.id == monitor?.id)
                screen: modelData
                visible: GlobalStates.wallpaperOverviewOpen && monitorIsFocused

            WlrLayershell.namespace: "quickshell:wallpaper-overview"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            color: "transparent"

            anchors { top: true; bottom: true; left: true; right: true }

            ColumnLayout {
                id: layout
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                spacing: 8

                Item { width: 1; height: 1 }

                Rectangle {
                    id: bg
                    focus: true
                    color: Appearance.colors.colLayer0
                    border.width: 1
                    border.color: Appearance.colors.colLayer0Border
                    radius: Appearance.rounding.screenRounding

                    // Compact size for 4 thumbnails per row, 3 rows high
                    implicitWidth: Math.min(root.width * 0.7, 900)
                    implicitHeight: Math.min(root.height * 0.6, 500)

                    Keys.onPressed: (event) => {
                        if (event.key === Qt.Key_Escape) {
                            GlobalStates.wallpaperOverviewOpen = false
                            event.accepted = true
                        } else if (event.key === Qt.Key_Left) {
                            grid.moveSelection(-1)
                            event.accepted = true
                        } else if (event.key === Qt.Key_Right) {
                            grid.moveSelection(1)
                            event.accepted = true
                        } else if (event.key === Qt.Key_Up) {
                            grid.moveSelection(-grid.columns)
                            event.accepted = true
                        } else if (event.key === Qt.Key_Down) {
                            grid.moveSelection(grid.columns)
                            event.accepted = true
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            grid.activateCurrent()
                            event.accepted = true
                        }
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 8

                        GridView {
                            id: grid
                            readonly property int columns: 4  // Fixed to 4 columns
                            property int currentIndex: 0
                            readonly property int rows: Math.max(1, Math.ceil(count / columns))

                            Layout.preferredWidth: columns * cellWidth
                            Layout.alignment: Qt.AlignHCenter
                            Layout.fillHeight: true
                            cellWidth: 220
                            cellHeight: 140
                            clip: true
                            interactive: true
                            keyNavigationWraps: true
                            boundsBehavior: Flickable.StopAtBounds
                            
                            // Performance optimization: cache more delegates for smoother scrolling
                            cacheBuffer: cellHeight * 2  // Cache 2 extra rows above/below visible area
                            ScrollBar.horizontal: ScrollBar { 
                                policy: ScrollBar.AsNeeded
                                visible: false
                            }
                            ScrollBar.vertical: ScrollBar { 
                                policy: ScrollBar.AsNeeded
                                visible: false
                            }
                            // Back to simple wallpapers array
                            model: Wallpapers.wallpapers
                            onModelChanged: currentIndex = 0

                            function moveSelection(delta) {
                                // Clear all hover states when using keyboard navigation
                                for (let i = 0; i < count; i++) {
                                    const item = itemAtIndex(i)
                                    if (item) {
                                        item.isHovered = false
                                    }
                                }
                                currentIndex = Math.max(0, Math.min(count - 1, currentIndex + delta))
                                positionViewAtIndex(currentIndex, GridView.Contain)
                            }
                            function activateCurrent() {
                                const path = Wallpapers.wallpapers[currentIndex]
                                if (!path) return
                                GlobalStates.wallpaperOverviewOpen = false
                                Wallpapers.apply(path)
                            }

                            delegate: Item {
                                width: grid.cellWidth
                                height: grid.cellHeight
                                property bool isHovered: false

                                Rectangle {
                                    anchors.fill: parent
                                    radius: Appearance.rounding.windowRounding
                                    color: Appearance.colors.colLayer1
                                    border.width: (index === grid.currentIndex || parent.isHovered) ? 3 : 0
                                    border.color: Appearance.colors.colSecondary
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    color: Appearance.colors.colLayer2
                                    radius: Appearance.rounding.elementRounding
                                    
                                    // Loading placeholder
                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: Math.min(parent.width * 0.4, 32)
                                        height: Math.min(parent.height * 0.4, 32)
                                        radius: Appearance.rounding.elementRounding
                                        color: Appearance.colors.colLayer3
                                        visible: thumbnailImage.status !== Image.Ready
                                        
                                        // Simple loading animation
                                        opacity: 0.3
                                        SequentialAnimation on opacity {
                                            running: parent.visible
                                            loops: Animation.Infinite
                                            NumberAnimation { to: 1.0; duration: 800; easing.type: Easing.InOutSine }
                                            NumberAnimation { to: 0.3; duration: 800; easing.type: Easing.InOutSine }
                                        }
                                    }

                                    Image {
                                        id: thumbnailImage
                                        anchors.fill: parent
                                        source: `file://${modelData}`
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                        cache: false
                                        smooth: true
                                        
                                        // Much smaller sourceSize for faster loading - this is key!
                                        // Using smaller dimensions significantly reduces decode time
                                        sourceSize.width: Math.min(128, grid.cellWidth - 16)
                                        sourceSize.height: Math.min(96, grid.cellHeight - 16)
                                        
                                        // Disable mipmap for faster loading (quality vs speed tradeoff)
                                        mipmap: false
                                        
                                        // Smooth fade-in when ready
                                        opacity: status === Image.Ready ? 1 : 0
                                        Behavior on opacity {
                                            NumberAnimation { 
                                                duration: 200
                                                easing.type: Easing.OutCubic 
                                            }
                                        }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onEntered: {
                                        // Clear all other hover states and set current index
                                        for (let i = 0; i < grid.count; i++) {
                                            const item = grid.itemAtIndex(i)
                                            if (item && item !== parent) {
                                                item.isHovered = false
                                            }
                                        }
                                        parent.isHovered = true
                                        grid.currentIndex = index
                                    }
                                    onExited: {
                                        parent.isHovered = false
                                    }
                                    onClicked: {
                                        GlobalStates.wallpaperOverviewOpen = false
                                        Wallpapers.apply(modelData)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Connections {
                target: GlobalStates
                function onWallpaperOverviewOpenChanged() {
                    if (GlobalStates.wallpaperOverviewOpen && monitorIsFocused) {
                        bg.forceActiveFocus();
                    }
                }
            }
        }
    }

    GlobalShortcut {
        name: "wallpaperOverviewToggle"
        description: "Toggle wallpaper overview"
        onPressed: { GlobalStates.wallpaperOverviewOpen = !GlobalStates.wallpaperOverviewOpen }
    }
}


