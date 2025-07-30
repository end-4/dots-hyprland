//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

// Adjust this to make it smaller or larger
//@ pragma Env QT_SCALE_FACTOR=1

pragma ComponentBehavior: "Bound"
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
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Hyprland

ShellRoot {
    id: root
    property string screenshotDir: Directories.screenshotTemp
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
    property real standardRounding: 4
    readonly property var windows: HyprlandData.windowList
    readonly property var layers: HyprlandData.layers
    readonly property real falsePositivePreventionRatio: 0.5

    // Force initialization of some singletons
    Component.onCompleted: {
        MaterialThemeLoader.reapplyTheme();
    }

    component TargetRegion: Rectangle {
        id: regionRect
        property bool showIcon: false
        property bool targeted: false
        property color borderColor
        property color fillColor: "transparent"
        property string text: ""
        property real textPadding: 10
        z: 2
        color: fillColor
        border.color: borderColor
        border.width: targeted ? 3 : 1
        radius: root.standardRounding

        Rectangle {
            id: regionLabelBackground
            property real verticalPadding: 5
            property real horizontalPadding: 10
            radius: 10
            color: root.genericContentColor
            border.width: 1
            border.color: Appearance.m3colors.m3outlineVariant
            anchors {
                top: parent.top
                left: parent.left
                topMargin: regionRect.textPadding
                leftMargin: regionRect.textPadding
            }
            implicitWidth: regionInfoRow.implicitWidth + horizontalPadding * 2
            implicitHeight: regionInfoRow.implicitHeight + verticalPadding * 2
            RowLayout {
                id: regionInfoRow
                anchors.centerIn: parent
                spacing: 8

                Loader {
                    id: regionIconLoader
                    active: regionRect.showIcon
                    visible: active
                    sourceComponent: IconImage {
                        implicitSize: Appearance.font.pixelSize.larger
                        source: Quickshell.iconPath(AppSearch.guessIcon(regionRect.text), "image-missing")
                    }
                }

                StyledText {
                    id: regionText
                    text: regionRect.text
                    color: root.genericContentForeground
                }
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: panelWindow
            required property var modelData
            readonly property HyprlandMonitor hyprlandMonitor: Hyprland.monitorFor(modelData)
            readonly property real monitorScale: hyprlandMonitor.scale
            readonly property real monitorOffsetX: hyprlandMonitor.x
            readonly property real monitorOffsetY: hyprlandMonitor.y
            property int activeWorkspaceId: hyprlandMonitor.activeWorkspace?.id ?? 0
            property string screenshotPath: `${root.screenshotDir}/image-${modelData.name}`
            property real dragStartX: 0
            property real dragStartY: 0
            property real draggingX: 0
            property real draggingY: 0
            property real dragDiffX: 0
            property real dragDiffY: 0
            property bool draggedAway: (dragDiffX !== 0 || dragDiffY !== 0)
            property bool dragging: false
            property var mouseButton: null
            property var imageRegions: []
            readonly property list<var> windowRegions: filterWindowRegionsByLayers(
                root.windows.filter(w => w.workspace.id === panelWindow.activeWorkspaceId),
                panelWindow.layerRegions
            ).map(window => {
                return {
                    at: [window.at[0] - panelWindow.monitorOffsetX, window.at[1] - panelWindow.monitorOffsetY],
                    size: [window.size[0], window.size[1]],
                    class: window.class,
                    title: window.title,
                }
            })
            readonly property list<var> layerRegions: {
                const layersOfThisMonitor = root.layers[panelWindow.hyprlandMonitor.name]
                const topLayers = layersOfThisMonitor.levels["2"]
                const nonBarTopLayers = topLayers
                    .filter(layer => !(layer.namespace.includes(":bar") || layer.namespace.includes(":dock")))
                    .map(layer => {
                    return {
                        at: [layer.x, layer.y],
                        size: [layer.w, layer.h],
                        namespace: layer.namespace,
                    }
                })
                const offsetAdjustedLayers = nonBarTopLayers.map(layer => {
                    return {
                        at: [layer.at[0] - panelWindow.monitorOffsetX, layer.at[1] - panelWindow.monitorOffsetY],
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
                const clickedRegion = panelWindow.imageRegions.find(region => {
                    return region.at[0] <= x && x <= region.at[0] + region.size[0] && region.at[1] <= y && y <= region.at[1] + region.size[1];
                });
                if (clickedRegion) {
                    panelWindow.targetedRegionX = clickedRegion.at[0];
                    panelWindow.targetedRegionY = clickedRegion.at[1];
                    panelWindow.targetedRegionWidth = clickedRegion.size[0];
                    panelWindow.targetedRegionHeight = clickedRegion.size[1];
                    return;
                }

                // Layer regions
                const clickedLayer = panelWindow.layerRegions.find(region => {
                    return region.at[0] <= x && x <= region.at[0] + region.size[0] && region.at[1] <= y && y <= region.at[1] + region.size[1];
                });
                if (clickedLayer) {
                    panelWindow.targetedRegionX = clickedLayer.at[0];
                    panelWindow.targetedRegionY = clickedLayer.at[1];
                    panelWindow.targetedRegionWidth = clickedLayer.size[0];
                    panelWindow.targetedRegionHeight = clickedLayer.size[1];
                    return;
                }

                // Window regions
                const clickedWindow = panelWindow.windowRegions.find(region => {
                    return region.at[0] <= x && x <= region.at[0] + region.size[0] && region.at[1] <= y && y <= region.at[1] + region.size[1];
                });
                if (clickedWindow) {
                    panelWindow.targetedRegionX = clickedWindow.at[0];
                    panelWindow.targetedRegionY = clickedWindow.at[1];
                    panelWindow.targetedRegionWidth = clickedWindow.size[0];
                    panelWindow.targetedRegionHeight = clickedWindow.size[1];
                    return;
                }

                panelWindow.targetedRegionX = -1;
                panelWindow.targetedRegionY = -1;
                panelWindow.targetedRegionWidth = 0;
                panelWindow.targetedRegionHeight = 0;
            }

            property real regionWidth: Math.abs(draggingX - dragStartX)
            property real regionHeight: Math.abs(draggingY - dragStartY)
            property real regionX: Math.min(dragStartX, draggingX)
            property real regionY: Math.min(dragStartY, draggingY)

            visible: false
            screen: modelData
            WlrLayershell.namespace: "quickshell:screenshot"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            exclusionMode: ExclusionMode.Ignore
            anchors {
                left: true
                right: true
                top: true
                bottom: true
            }

            Process {
                id: screenshotProcess
                running: true
                command: ["bash", "-c", `mkdir -p '${StringUtils.shellSingleQuoteEscape(root.screenshotDir)}' && grim -o '${StringUtils.shellSingleQuoteEscape(modelData.name)}' '${StringUtils.shellSingleQuoteEscape(panelWindow.screenshotPath)}'`]
                onExited: (exitCode, exitStatus) => {
                    panelWindow.visible = true;
                    imageDetectionProcess.running = true;
                }
            }

            Process {
                id: imageDetectionProcess
                command: ["bash", "-c", `${Directories.scriptPath}/images/find_regions.py ` 
                    + `--hyprctl ` 
                    + `--image '${StringUtils.shellSingleQuoteEscape(panelWindow.screenshotPath)}' ` 
                    + `--max-width ${Math.round(panelWindow.screen.width * root.falsePositivePreventionRatio)} ` 
                    + `--max-height ${Math.round(panelWindow.screen.height * root.falsePositivePreventionRatio)} `]
                stdout: StdioCollector {
                    id: imageDimensionCollector
                    onStreamFinished: {
                        imageRegions = filterImageRegions(
                            JSON.parse(imageDimensionCollector.text),
                            panelWindow.windowRegions
                        );
                    }
                }
            }

            Process {
                id: snipProc
                function snip() {
                    if (panelWindow.regionWidth <= 0 || panelWindow.regionHeight <= 0) {
                        console.warn("Invalid region size, skipping snip.");
                        Qt.quit();
                    }
                    snipProc.startDetached();
                    Qt.quit();
                }
                command: ["bash", "-c", 
                    `magick ${StringUtils.shellSingleQuoteEscape(panelWindow.screenshotPath)} `
                    + `-crop ${panelWindow.regionWidth * panelWindow.monitorScale}x${panelWindow.regionHeight * panelWindow.monitorScale}+${panelWindow.regionX * panelWindow.monitorScale}+${panelWindow.regionY * panelWindow.monitorScale} - ` 
                    + `| ${panelWindow.mouseButton === Qt.LeftButton ? "wl-copy" : "swappy -f -"}`]
            }

            ScreencopyView {
                anchors.fill: parent
                live: false
                captureSource: modelData

                focus: panelWindow.visible
                Keys.onPressed: (event) => { // Esc to close
                    if (event.key === Qt.Key_Escape) {
                        Qt.quit();
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.CrossCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    hoverEnabled: true

                    // Controls
                    onPressed: mouse => {
                        panelWindow.dragStartX = mouse.x;
                        panelWindow.dragStartY = mouse.y;
                        panelWindow.draggingX = mouse.x;
                        panelWindow.draggingY = mouse.y;
                        panelWindow.dragging = true;
                        panelWindow.mouseButton = mouse.button;
                    }
                    onReleased: mouse => {
                        // Detect if it was a click

                        // Image regions
                        if (panelWindow.draggingX === panelWindow.dragStartX && panelWindow.draggingY === panelWindow.dragStartY) {
                            if (panelWindow.targetedRegionX >= 0 && panelWindow.targetedRegionY >= 0) {
                                panelWindow.regionX = panelWindow.targetedRegionX;
                                panelWindow.regionY = panelWindow.targetedRegionY;
                                panelWindow.regionWidth = panelWindow.targetedRegionWidth;
                                panelWindow.regionHeight = panelWindow.targetedRegionHeight;
                            }
                        }
                        snipProc.snip();
                    }
                    onPositionChanged: mouse => {
                        if (panelWindow.dragging) {
                            panelWindow.draggingX = mouse.x;
                            panelWindow.draggingY = mouse.y;
                            panelWindow.dragDiffX = mouse.x - panelWindow.dragStartX;
                            panelWindow.dragDiffY = mouse.y - panelWindow.dragStartY;
                        }
                        panelWindow.updateTargetedRegion(mouse.x, mouse.y);
                    }

                    // Overlay to darken screen
                    Rectangle { // Base
                        id: overlayRect
                        z: 0
                        anchors.fill: parent
                        color: root.overlayColor
                        layer.enabled: true
                    }
                    Rectangle {
                        // TODO: Make this mask the base instead of just overlaying a border
                        z: 1
                        anchors {
                            left: parent.left
                            top: parent.top
                            leftMargin: panelWindow.regionX
                            topMargin: panelWindow.regionY
                        }
                        width: panelWindow.regionWidth
                        height: panelWindow.regionHeight
                        color: "transparent"
                        border.color: root.selectionBorderColor
                        border.width: 2
                        radius: root.standardRounding
                    }

                    // Instructions
                    Rectangle {
                        anchors {
                            top: parent.top
                            horizontalCenter: parent.horizontalCenter
                            topMargin: (Appearance.sizes.barHeight - implicitHeight) / 2
                        }

                        opacity: panelWindow.dragging ? 0 : 1
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

                        RowLayout {
                            id: instructionsRow
                            anchors.centerIn: parent
                            Item {
                                Layout.fillHeight: true
                                implicitWidth: screenshotRegionIcon.implicitWidth
                                MaterialSymbol {
                                    id: screenshotRegionIcon
                                    anchors.centerIn: parent
                                    iconSize: Appearance.font.pixelSize.larger
                                    text: "screenshot_region"
                                    color: root.genericContentForeground
                                }
                            }
                            StyledText {
                                text: Translation.tr("Drag or click a region • LMB: Copy • RMB: Edit")
                                color: root.genericContentForeground
                            }
                        }
                    }

                    // Window regions
                    Repeater {
                        model: ScriptModel {
                            values: panelWindow.windowRegions
                        }
                        delegate: TargetRegion {
                            z: 2
                            required property var modelData
                            showIcon: true
                            targeted: !panelWindow.draggedAway &&
                                (panelWindow.targetedRegionX === modelData.at[0] 
                                && panelWindow.targetedRegionY === modelData.at[1]
                                && panelWindow.targetedRegionWidth === modelData.size[0]
                                && panelWindow.targetedRegionHeight === modelData.size[1])

                            opacity: panelWindow.draggedAway ? 0 : 1
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
                            values: panelWindow.layerRegions
                        }
                        delegate: TargetRegion {
                            z: 3
                            required property var modelData
                            targeted: !panelWindow.draggedAway &&
                                (panelWindow.targetedRegionX === modelData.at[0] 
                                && panelWindow.targetedRegionY === modelData.at[1]
                                && panelWindow.targetedRegionWidth === modelData.size[0]
                                && panelWindow.targetedRegionHeight === modelData.size[1])

                            opacity: panelWindow.draggedAway ? 0 : 1
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
                            values: Config.options.screenshotTool.showContentRegions ? panelWindow.imageRegions : []
                        }
                        delegate: TargetRegion {
                            z: 4
                            required property var modelData
                            targeted: !panelWindow.draggedAway &&
                                (panelWindow.targetedRegionX === modelData.at[0] 
                                && panelWindow.targetedRegionY === modelData.at[1]
                                && panelWindow.targetedRegionWidth === modelData.size[0]
                                && panelWindow.targetedRegionHeight === modelData.size[1])

                            opacity: panelWindow.draggedAway ? 0 : 1
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
    }
}
