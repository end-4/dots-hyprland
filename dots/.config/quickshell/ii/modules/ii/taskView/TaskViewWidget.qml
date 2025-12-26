pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Item {
    id: root
    required property var panelWindow
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(panelWindow.screen)
    property var windowByAddress: HyprlandData.windowByAddress

    // Background blur/dim settings
    property real padding: 40
    property real spacing: 20

    // Smart Packing Logic - macOS-like grid layout
    property var layoutMap: ({})

    function recalculateLayout(windowList) {
        if (!windowList || windowList.length === 0) {
            root.layoutMap = {};
            return;
        }

        const count = windowList.length;
        const availableWidth = root.width - (root.padding * 2);
        const availableHeight = root.height - (root.padding * 2);

        // Calculate optimal grid dimensions (rows x cols)
        // Similar to macOS Mission Control
        let cols, rows;
        
        if (count === 1) {
            cols = 1;
            rows = 1;
        } else if (count === 2) {
            cols = 2;
            rows = 1;
        } else if (count <= 4) {
            cols = 2;
            rows = 2;
        } else if (count <= 6) {
            cols = 3;
            rows = 2;
        } else if (count <= 9) {
            cols = 3;
            rows = 3;
        } else if (count <= 12) {
            cols = 4;
            rows = 3;
        } else if (count <= 16) {
            cols = 4;
            rows = 4;
        } else if (count <= 20) {
            cols = 5;
            rows = 4;
        } else if (count <= 25) {
            cols = 5;
            rows = 5;
        } else {
            // For many windows, calculate based on aspect ratio
            const aspectRatio = availableWidth / availableHeight;
            cols = Math.ceil(Math.sqrt(count * aspectRatio));
            rows = Math.ceil(count / cols);
        }

        // Get aspect ratios for all windows
        const ratios = windowList.map(w => {
            const address = `0x${w.HyprlandToplevel?.address}`;
            const winData = root.windowByAddress[address];
            if (winData && winData.size && winData.size[1] > 0) {
                return winData.size[0] / winData.size[1];
            }
            return 16 / 9; // Fallback
        });

        // Calculate average aspect ratio for uniform sizing
        const avgAspectRatio = ratios.reduce((sum, ar) => sum + ar, 0) / ratios.length;

        // Calculate cell size that fits all windows
        // We need: cols * cellWidth + (cols - 1) * spacing <= availableWidth
        // And: rows * cellHeight + (rows - 1) * spacing <= availableHeight
        // Where cellWidth = cellHeight * avgAspectRatio
        
        // Try to fit based on width constraint
        const maxCellWidthFromWidth = (availableWidth - (cols - 1) * root.spacing) / cols;
        const maxCellHeightFromWidth = maxCellWidthFromWidth / avgAspectRatio;
        
        // Try to fit based on height constraint
        const maxCellHeightFromHeight = (availableHeight - (rows - 1) * root.spacing) / rows;
        const maxCellWidthFromHeight = maxCellHeightFromHeight * avgAspectRatio;
        
        // Use the smaller constraint to ensure everything fits
        let cellHeight, cellWidth;
        if (maxCellHeightFromWidth <= maxCellHeightFromHeight) {
            cellHeight = maxCellHeightFromWidth;
            cellWidth = maxCellWidthFromWidth;
        } else {
            cellHeight = maxCellHeightFromHeight;
            cellWidth = maxCellWidthFromHeight;
        }

        // Ensure minimum size for usability
        // If cells would be too small, we enforce minimum but may need to adjust grid
        const minCellSize = 120;
        if (cellWidth < minCellSize || cellHeight < minCellSize) {
            // Enforce minimum size
            if (cellWidth < minCellSize) {
                cellWidth = minCellSize;
                cellHeight = minCellSize / avgAspectRatio;
            }
            if (cellHeight < minCellSize) {
                cellHeight = minCellSize;
                cellWidth = minCellSize * avgAspectRatio;
            }
            
            // Recalculate grid dimensions
            const newGridWidth = cols * cellWidth + (cols - 1) * root.spacing;
            const newGridHeight = rows * cellHeight + (rows - 1) * root.spacing;
            
            // If grid exceeds available space, scale down proportionally
            const widthScale = newGridWidth > availableWidth ? availableWidth / newGridWidth : 1;
            const heightScale = newGridHeight > availableHeight ? availableHeight / newGridHeight : 1;
            const scale = Math.min(widthScale, heightScale);
            
            if (scale < 1) {
                cellWidth *= scale;
                cellHeight *= scale;
            }
        }

        // Calculate total grid dimensions
        const gridWidth = cols * cellWidth + (cols - 1) * root.spacing;
        const gridHeight = rows * cellHeight + (rows - 1) * root.spacing;

        // Center the grid
        const startX = root.padding + (availableWidth - gridWidth) / 2;
        const startY = root.padding + (availableHeight - gridHeight) / 2;

        // Layout windows in grid
        let newLayout = {};
        for (let i = 0; i < count && i < cols * rows; i++) {
            const col = i % cols;
            const row = Math.floor(i / cols);
            
            const w = windowList[i];
            const address = `0x${w.HyprlandToplevel?.address}`;
            const ar = ratios[i];
            
            // Use individual aspect ratio for each window
            // Scale to fit within cell while maintaining aspect ratio
            let finalWidth = cellHeight * ar;
            let finalHeight = cellHeight;
            
            // If window is too wide for cell, scale down to fit width
            if (finalWidth > cellWidth) {
                finalWidth = cellWidth;
                finalHeight = cellWidth / ar;
            }
            // If window is too tall for cell, scale down to fit height
            if (finalHeight > cellHeight) {
                finalHeight = cellHeight;
                finalWidth = cellHeight * ar;
            }
            
            // Center within cell
            const cellX = startX + col * (cellWidth + root.spacing);
            const cellY = startY + row * (cellHeight + root.spacing);
            const xOffset = (cellWidth - finalWidth) / 2;
            const yOffset = (cellHeight - finalHeight) / 2;

            newLayout[address] = {
                x: cellX + xOffset,
                y: cellY + yOffset,
                width: finalWidth,
                height: finalHeight
            };
        }

        root.layoutMap = newLayout;
    }

    // Helper to get active windows on current monitor & workspace
    property var activeWindows: {
        const activeWorkspaceId = monitor.activeWorkspace?.id;
        if (!activeWorkspaceId)
            return [];

        return ToplevelManager.toplevels.values.filter(toplevel => {
            const address = `0x${toplevel.HyprlandToplevel?.address}`;
            const win = windowByAddress[address];
            return win && win.workspace.id === activeWorkspaceId;
        });
    }

    onActiveWindowsChanged: {
        recalculateLayout(activeWindows);
    }

    onWidthChanged: recalculateLayout(activeWindows)
    onHeightChanged: recalculateLayout(activeWindows)

    // The windows
    Repeater {
        model: activeWindows
        delegate: TaskViewWindow {
            id: taskWindow
            required property var modelData
            property var address: `0x${modelData.HyprlandToplevel.address}`

            toplevel: modelData
            windowData: root.windowByAddress[address]
            monitorData: HyprlandData.monitors.find(m => m.id === windowData?.monitor)
            scale: 1 // We want 1:1 scale for previews in the grid

            widgetMonitor: HyprlandData.monitors.find(m => m.id === root.monitor.id)

            // Layout props
            targetX: (root.layoutMap[address]?.x || 0)
            targetY: (root.layoutMap[address]?.y || 0)
            targetWidth: (root.layoutMap[address]?.width || 100)
            targetHeight: (root.layoutMap[address]?.height || 100)

            // Initial position (animate from real window position?)
            // For now let's just appear. Can improve enter animation later.

            // Z-index handling
            z: hovered ? 100 : 1
        }
    }

    // Empty state message
    Text {
        anchors.centerIn: parent
        text: "No windows implemented"
        color: Appearance.colors.colOnSurface
        font.pixelSize: 24
        visible: activeWindows.length === 0
        opacity: 0.5
    }
}
