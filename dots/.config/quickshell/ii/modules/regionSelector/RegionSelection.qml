pragma ComponentBehavior: Bound
import qs
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland

PanelWindow {
    id: root
    visible: false
    WlrLayershell.namespace: "quickshell:regionSelector"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore
    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    // TODO: Ask: sidebar AI; Ocr: tesseract
    enum SnipAction { Copy, Edit, Search } 
    enum SelectionMode { RectCorners, Circle }
    property var action: RegionSelection.SnipAction.Copy
    property var selectionMode: RegionSelection.SelectionMode.RectCorners
    signal dismiss()
    
    property string screenshotDir: Directories.screenshotTemp
    property string imageSearchEngineBaseUrl: Config.options.search.imageSearch.imageSearchEngineBaseUrl
    property string fileUploadApiEndpoint: Config.options.search.imageSearch.fileUploadApiEndpoint
    property color overlayColor: "#77111111"
    property color genericContentColor: Qt.alpha(root.overlayColor, 0.9)
    property color genericContentForeground: "#ddffffff"
    property color selectionBorderColor: "#ddf1f1f1"
    property color selectionFillColor: "#33ffffff"
    property color windowBorderColor: "#dda0c0da"
    property color windowFillColor: "#22a0c0da"
    property color imageBorderColor: "#ddf1d1ff"
    property color imageFillColor: "#33f1d1ff"
    property color onBorderColor: "#ff000000"
    readonly property var windows: [...HyprlandData.windowList].sort((a, b) => {
        // Sort floating=true windows before others
        if (a.floating === b.floating) return 0;
        return a.floating ? -1 : 1;
    })
    readonly property var layers: HyprlandData.layers
    readonly property real falsePositivePreventionRatio: 0.5

    readonly property HyprlandMonitor hyprlandMonitor: Hyprland.monitorFor(screen)
    readonly property real monitorScale: hyprlandMonitor.scale
    readonly property real monitorOffsetX: hyprlandMonitor.x
    readonly property real monitorOffsetY: hyprlandMonitor.y
    property int activeWorkspaceId: hyprlandMonitor.activeWorkspace?.id ?? 0
    property string screenshotPath: `${root.screenshotDir}/image-${screen.name}`
    property real dragStartX: 0
    property real dragStartY: 0
    property real draggingX: 0
    property real draggingY: 0
    property real dragDiffX: 0
    property real dragDiffY: 0
    property bool draggedAway: (dragDiffX !== 0 || dragDiffY !== 0)
    property bool dragging: false
    property list<point> points: []
    property var mouseButton: null
    property var imageRegions: []
    readonly property list<var> windowRegions: filterWindowRegionsByLayers(
        root.windows.filter(w => w.workspace.id === root.activeWorkspaceId),
        root.layerRegions
    ).map(window => {
        return {
            at: [window.at[0] - root.monitorOffsetX, window.at[1] - root.monitorOffsetY],
            size: [window.size[0], window.size[1]],
            class: window.class,
            title: window.title,
        }
    })
    readonly property list<var> layerRegions: {
        const layersOfThisMonitor = root.layers[root.hyprlandMonitor.name]
        const topLayers = layersOfThisMonitor?.levels["2"]
        if (!topLayers) return [];
        const nonBarTopLayers = topLayers
            .filter(layer => !(layer.namespace.includes(":bar") || layer.namespace.includes(":verticalBar") || layer.namespace.includes(":dock")))
            .map(layer => {
            return {
                at: [layer.x, layer.y],
                size: [layer.w, layer.h],
                namespace: layer.namespace,
            }
        })
        const offsetAdjustedLayers = nonBarTopLayers.map(layer => {
            return {
                at: [layer.at[0] - root.monitorOffsetX, layer.at[1] - root.monitorOffsetY],
                size: layer.size,
                namespace: layer.namespace,
            }
        });
        return offsetAdjustedLayers;
    }

    property real targetedRegionX: -1
    property real targetedRegionY: -1
    property real targetedRegionWidth: 0
    property real targetedRegionHeight: 0

    function intersectionOverUnion(regionA, regionB) {
        // region: { at: [x, y], size: [w, h] }
        const ax1 = regionA.at[0], ay1 = regionA.at[1];
        const ax2 = ax1 + regionA.size[0], ay2 = ay1 + regionA.size[1];
        const bx1 = regionB.at[0], by1 = regionB.at[1];
        const bx2 = bx1 + regionB.size[0], by2 = by1 + regionB.size[1];

        const interX1 = Math.max(ax1, bx1);
        const interY1 = Math.max(ay1, by1);
        const interX2 = Math.min(ax2, bx2);
        const interY2 = Math.min(ay2, by2);

        const interArea = Math.max(0, interX2 - interX1) * Math.max(0, interY2 - interY1);
        const areaA = (ax2 - ax1) * (ay2 - ay1);
        const areaB = (bx2 - bx1) * (by2 - by1);
        const unionArea = areaA + areaB - interArea;

        return unionArea > 0 ? interArea / unionArea : 0;
    }

    function filterOverlappingImageRegions(regions) {
        let keep = [];
        let removed = new Set();
        for (let i = 0; i < regions.length; ++i) {
            if (removed.has(i)) continue;
            let regionA = regions[i];
            for (let j = i + 1; j < regions.length; ++j) {
                if (removed.has(j)) continue;
                let regionB = regions[j];
                if (intersectionOverUnion(regionA, regionB) > 0) {
                    // Compare areas
                    let areaA = regionA.size[0] * regionA.size[1];
                    let areaB = regionB.size[0] * regionB.size[1];
                    if (areaA <= areaB) {
                        removed.add(j);
                    } else {
                        removed.add(i);
                    }
                }
            }
        }
        for (let i = 0; i < regions.length; ++i) {
            if (!removed.has(i)) keep.push(regions[i]);
        }
        return keep;
    }

    function filterWindowRegionsByLayers(windowRegions, layerRegions) {
        return windowRegions.filter(windowRegion => {
            for (let i = 0; i < layerRegions.length; ++i) {
                if (intersectionOverUnion(windowRegion, layerRegions[i]) > 0)
                    return false;
            }
            return true;
        });
    }

    function filterImageRegions(regions, windowRegions, threshold = 0.1) {
        // Remove image regions that overlap too much with any window region
        let filtered = regions.filter(region => {
            for (let i = 0; i < windowRegions.length; ++i) {
                if (intersectionOverUnion(region, windowRegions[i]) > threshold)
                    return false;
            }
            return true;
        });
        // Remove overlapping image regions, keep only the smaller one
        return filterOverlappingImageRegions(filtered);
    }

    function updateTargetedRegion(x, y) {
        // Image regions
        const clickedRegion = root.imageRegions.find(region => {
            return region.at[0] <= x && x <= region.at[0] + region.size[0] && region.at[1] <= y && y <= region.at[1] + region.size[1];
        });
        if (clickedRegion) {
            root.targetedRegionX = clickedRegion.at[0];
            root.targetedRegionY = clickedRegion.at[1];
            root.targetedRegionWidth = clickedRegion.size[0];
            root.targetedRegionHeight = clickedRegion.size[1];
            return;
        }

        // Layer regions
        const clickedLayer = root.layerRegions.find(region => {
            return region.at[0] <= x && x <= region.at[0] + region.size[0] && region.at[1] <= y && y <= region.at[1] + region.size[1];
        });
        if (clickedLayer) {
            root.targetedRegionX = clickedLayer.at[0];
            root.targetedRegionY = clickedLayer.at[1];
            root.targetedRegionWidth = clickedLayer.size[0];
            root.targetedRegionHeight = clickedLayer.size[1];
            return;
        }

        // Window regions
        const clickedWindow = root.windowRegions.find(region => {
            return region.at[0] <= x && x <= region.at[0] + region.size[0] && region.at[1] <= y && y <= region.at[1] + region.size[1];
        });
        if (clickedWindow) {
            root.targetedRegionX = clickedWindow.at[0];
            root.targetedRegionY = clickedWindow.at[1];
            root.targetedRegionWidth = clickedWindow.size[0];
            root.targetedRegionHeight = clickedWindow.size[1];
            return;
        }

        root.targetedRegionX = -1;
        root.targetedRegionY = -1;
        root.targetedRegionWidth = 0;
        root.targetedRegionHeight = 0;
    }

    property real regionWidth: Math.abs(draggingX - dragStartX)
    property real regionHeight: Math.abs(draggingY - dragStartY)
    property real regionX: Math.min(dragStartX, draggingX)
    property real regionY: Math.min(dragStartY, draggingY)

    Process {
        id: screenshotProcess
        running: true
        command: ["bash", "-c", `mkdir -p '${StringUtils.shellSingleQuoteEscape(root.screenshotDir)}' && grim -o '${StringUtils.shellSingleQuoteEscape(root.screen.name)}' '${StringUtils.shellSingleQuoteEscape(root.screenshotPath)}'`]
        onExited: (exitCode, exitStatus) => {
            root.visible = true;
            imageDetectionProcess.running = true;
        }
    }

    Process {
        id: imageDetectionProcess
        command: ["bash", "-c", `${Directories.scriptPath}/images/find-regions-venv.sh ` 
            + `--hyprctl ` 
            + `--image '${StringUtils.shellSingleQuoteEscape(root.screenshotPath)}' ` 
            + `--max-width ${Math.round(root.screen.width * root.falsePositivePreventionRatio)} ` 
            + `--max-height ${Math.round(root.screen.height * root.falsePositivePreventionRatio)} `]
        stdout: StdioCollector {
            id: imageDimensionCollector
            onStreamFinished: {
                imageRegions = filterImageRegions(
                    JSON.parse(imageDimensionCollector.text),
                    root.windowRegions
                );
            }
        }
    }

    function snip() {
        // Validity check
        if (root.regionWidth <= 0 || root.regionHeight <= 0) {
            console.warn("[Region Selector] Invalid region size, skipping snip.");
            root.dismiss();
        }

        // Adjust action
        if (root.action === RegionSelection.SnipAction.Copy || root.action === RegionSelection.SnipAction.Edit) {
            root.action = root.mouseButton === Qt.RightButton ? RegionSelection.SnipAction.Edit : RegionSelection.SnipAction.Copy;
        }

        // Set command for action
        const cropBase = `magick ${StringUtils.shellSingleQuoteEscape(root.screenshotPath)} `
            + `-crop ${root.regionWidth * root.monitorScale}x${root.regionHeight * root.monitorScale}+${root.regionX * root.monitorScale}+${root.regionY * root.monitorScale}`
        const cropToStdout = `${cropBase} -`
        const cropInPlace = `${cropBase} '${StringUtils.shellSingleQuoteEscape(root.screenshotPath)}'`
        const cleanup = `rm '${StringUtils.shellSingleQuoteEscape(root.screenshotPath)}'`
        const uploadAndGetUrl = (filePath) => {
            return `curl -sF files[]=@'${StringUtils.shellSingleQuoteEscape(filePath)}' ${root.fileUploadApiEndpoint} | jq -r '.files[0].url'`
        }
        switch (root.action) {
            case RegionSelection.SnipAction.Copy:
                snipProc.command = ["bash", "-c", `${cropToStdout} | wl-copy && ${cleanup}`]
                break;
            case RegionSelection.SnipAction.Edit:
                snipProc.command = ["bash", "-c", `${cropToStdout} | swappy -f - && ${cleanup}`]
                break;
            case RegionSelection.SnipAction.Search:
                snipProc.command = ["bash", "-c", `${cropInPlace} && xdg-open "${root.imageSearchEngineBaseUrl}$(${uploadAndGetUrl(root.screenshotPath)})"`]
                break;
            default:
                console.warn("[Region Selector] Unknown snip action, skipping snip.");
                root.dismiss();
                return;
        }

        // Image post-processing
        snipProc.startDetached();
        root.dismiss();
    }

    Process {
        id: snipProc
    }

    ScreencopyView {
        anchors.fill: parent
        live: false
        captureSource: root.screen

        focus: root.visible
        Keys.onPressed: (event) => { // Esc to close
            if (event.key === Qt.Key_Escape) {
                root.dismiss();
            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            cursorShape: Qt.CrossCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            hoverEnabled: true

            // Controls
            onPressed: (mouse) => {
                root.dragStartX = mouse.x;
                root.dragStartY = mouse.y;
                root.draggingX = mouse.x;
                root.draggingY = mouse.y;
                root.dragging = true;
                root.mouseButton = mouse.button;
            }
            onReleased: (mouse) => {
                // Circle dragging?
                if (root.selectionMode === RegionSelection.SelectionMode.Circle) {
                    const maxX = Math.max(...root.points.map(p => p.x));
                    const minX = Math.min(...root.points.map(p => p.x));
                    const maxY = Math.max(...root.points.map(p => p.y));
                    const minY = Math.min(...root.points.map(p => p.y));
                    root.regionX = minX;
                    root.regionY = minY;
                    root.regionWidth = maxX - minX;
                    root.regionHeight = maxY - minY;
                }
                // Detect if it was a click -> Try to select targeted region
                if (root.draggingX === root.dragStartX && root.draggingY === root.dragStartY) {
                    if (root.targetedRegionX >= 0 && root.targetedRegionY >= 0) {
                        root.regionX = root.targetedRegionX;
                        root.regionY = root.targetedRegionY;
                        root.regionWidth = root.targetedRegionWidth;
                        root.regionHeight = root.targetedRegionHeight;
                    }
                }
                root.snip();
            }
            onPositionChanged: (mouse) => {
                root.updateTargetedRegion(mouse.x, mouse.y);
                if (!root.dragging) return;
                root.draggingX = mouse.x;
                root.draggingY = mouse.y;
                root.dragDiffX = mouse.x - root.dragStartX;
                root.dragDiffY = mouse.y - root.dragStartY;
                root.points.push({ x: mouse.x, y: mouse.y });
            }
            
            Loader {
                z: 2
                anchors.fill: parent
                active: root.selectionMode === RegionSelection.SelectionMode.RectCorners
                sourceComponent: RectCornersSelectionDetails {
                    regionX: root.regionX
                    regionY: root.regionY
                    regionWidth: root.regionWidth
                    regionHeight: root.regionHeight
                    mouseX: mouseArea.mouseX
                    mouseY: mouseArea.mouseY
                    color: root.selectionBorderColor
                    overlayColor: root.overlayColor
                }
            }

            Loader {
                z: 2
                anchors.fill: parent
                active: root.selectionMode === RegionSelection.SelectionMode.Circle
                sourceComponent: CircleSelectionDetails {
                    color: root.selectionBorderColor
                    overlayColor: root.overlayColor
                    points: root.points
                }
            }

            // Instructions
            Rectangle {
                z: 9999
                anchors {
                    top: parent.top
                    horizontalCenter: parent.horizontalCenter
                    topMargin: (Appearance.sizes.barHeight - implicitHeight) / 2
                }

                opacity: root.dragging ? 0 : 1
                visible: opacity > 0
                Behavior on opacity {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }

                color: root.genericContentColor
                radius: 10
                border.width: 1
                border.color: Appearance.m3colors.m3outlineVariant
                implicitWidth: instructionsRow.implicitWidth + 10 * 2
                implicitHeight: instructionsRow.implicitHeight + 5 * 2

                Row {
                    id: instructionsRow
                    anchors.centerIn: parent
                    spacing: 4
                    MaterialSymbol {
                        id: screenshotRegionIcon
                        // anchors.centerIn: parent
                        iconSize: Appearance.font.pixelSize.larger
                        text: switch(root.selectionMode) {
                            case RegionSelection.SelectionMode.RectCorners:
                                return "activity_zone"
                                break;
                            case RegionSelection.SelectionMode.Circle:
                                return "gesture"
                                break;
                            default:
                                return "activity_zone"
                        }
                        color: root.genericContentForeground
                    }
                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: {
                            var instructionText = "";
                            var actionText = "";
                            if (root.selectionMode === RegionSelection.SelectionMode.RectCorners) {
                                instructionText = Translation.tr("Drag or click a region");
                            } else if (root.selectionMode === RegionSelection.SelectionMode.Circle) {
                                instructionText = Translation.tr("Circle");
                            }
                            switch (root.action) {
                                case RegionSelection.SnipAction.Copy:
                                case RegionSelection.SnipAction.Edit:
                                    actionText = Translation.tr(" | LMB: Copy • RMB: Edit");
                                    break;
                                case RegionSelection.SnipAction.Search:
                                    actionText = Translation.tr(" to search");
                                    break;
                                default:
                                    actionText = "";
                            }
                            return instructionText + actionText;
                        }
                        color: root.genericContentForeground
                    }
                }
            }

            // Window regions
            Repeater {
                model: ScriptModel {
                    values: root.windowRegions
                }
                delegate: TargetRegion {
                    z: 2
                    required property var modelData
                    showIcon: true
                    targeted: !root.draggedAway &&
                        (root.targetedRegionX === modelData.at[0] 
                        && root.targetedRegionY === modelData.at[1]
                        && root.targetedRegionWidth === modelData.size[0]
                        && root.targetedRegionHeight === modelData.size[1])

                    colBackground: root.genericContentColor
                    colForeground: root.genericContentForeground
                    opacity: root.draggedAway ? 0 : 1
                    visible: opacity > 0
                    Behavior on opacity {
                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                    }

                    x: modelData.at[0]
                    y: modelData.at[1]
                    width: modelData.size[0]
                    height: modelData.size[1]
                    borderColor: root.windowBorderColor
                    fillColor: targeted ? root.windowFillColor : "transparent"
                    border.width: targeted ? 4 : 2
                    text: `${modelData.class}`
                    radius: Appearance.rounding.windowRounding
                }
            }

            // Layer regions
            Repeater {
                model: ScriptModel {
                    values: root.layerRegions
                }
                delegate: TargetRegion {
                    z: 3
                    required property var modelData
                    targeted: !root.draggedAway &&
                        (root.targetedRegionX === modelData.at[0] 
                        && root.targetedRegionY === modelData.at[1]
                        && root.targetedRegionWidth === modelData.size[0]
                        && root.targetedRegionHeight === modelData.size[1])

                    colBackground: root.genericContentColor
                    colForeground: root.genericContentForeground
                    opacity: root.draggedAway ? 0 : 1
                    visible: opacity > 0
                    Behavior on opacity {
                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                    }

                    x: modelData.at[0]
                    y: modelData.at[1]
                    width: modelData.size[0]
                    height: modelData.size[1]
                    borderColor: root.windowBorderColor
                    fillColor: targeted ? root.windowFillColor : "transparent"
                    border.width: targeted ? 4 : 2
                    text: `${modelData.namespace}`
                    radius: Appearance.rounding.windowRounding
                }
            }

            // Image regions
            Repeater {
                model: ScriptModel {
                    values: Config.options.screenshotTool.showContentRegions ? root.imageRegions : []
                }
                delegate: TargetRegion {
                    z: 4
                    required property var modelData
                    targeted: !root.draggedAway &&
                        (root.targetedRegionX === modelData.at[0] 
                        && root.targetedRegionY === modelData.at[1]
                        && root.targetedRegionWidth === modelData.size[0]
                        && root.targetedRegionHeight === modelData.size[1])

                    colBackground: root.genericContentColor
                    colForeground: root.genericContentForeground
                    opacity: root.draggedAway ? 0 : 1
                    visible: opacity > 0
                    Behavior on opacity {
                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                    }

                    x: modelData.at[0]
                    y: modelData.at[1]
                    width: modelData.size[0]
                    height: modelData.size[1]
                    borderColor: root.imageBorderColor
                    fillColor: targeted ? root.imageFillColor : "transparent"
                    border.width: targeted ? 4 : 2
                    text: "Content region"
                }
            }
        }
    }
}
