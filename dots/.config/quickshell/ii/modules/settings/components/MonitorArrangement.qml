
import QtQuick
import QtQuick.Layouts

import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root

    property var monitors: []
    property string selectedMonitorName: ""

    signal monitorSelected(string name)
    signal layoutChanged(var positions)

    implicitHeight: 260
    Layout.fillWidth: true
    clip: true

    property var pendingPositions: ({})

    readonly property bool hasPendingChanges:
        Object.keys(pendingPositions).length > 0

    readonly property real paddingSize: 20

    // Keep the preview geometry stable while dragging.
    property bool dragging: false
    property real frozenScale: 1
    property real frozenOffsetX: 0
    property real frozenOffsetY: 0
    property real frozenMinX: 0
    property real frozenMinY: 0

    function monitorX(monitor) {
        const position = pendingPositions[monitor.name];
        return position ? position.x : monitor.x;
    }

    function monitorY(monitor) {
        const position = pendingPositions[monitor.name];
        return position ? position.y : monitor.y;
    }

    function logicalWidth(monitor) {
        const rotated = monitor.transform % 2 !== 0;

        return (rotated ? monitor.height : monitor.width)
            / monitor.scale;
    }

    function logicalHeight(monitor) {
        const rotated = monitor.transform % 2 !== 0;

        return (rotated ? monitor.width : monitor.height)
            / monitor.scale;
    }

    function moveMonitor(name, x, y) {
        const positions = Object.assign({}, pendingPositions);

        positions[name] = {
            x: Math.round(x),
            y: Math.round(y)
        };

        pendingPositions = positions;
        layoutChanged(positions);
    }

    function resetLayout() {
        pendingPositions = {};
        layoutChanged(pendingPositions);
    }

    function rectanglesOverlap(ax, ay, aw, ah, bx, by, bw, bh) {
        return ax < bx + bw
            && ax + aw > bx
            && ay < by + bh
            && ay + ah > by;
    }

    // Find the nearest non-overlapping position touching another monitor.
    function snapMonitor(name, x, y) {
        const moving = monitors.find(m => m.name === name);

        if (!moving)
            return;

        const w = logicalWidth(moving);
        const h = logicalHeight(moving);

        const others = monitors.filter(m => m.name !== name);

        if (others.length === 0) {
            moveMonitor(name, x, y);
            return;
        }

        let bestX = x;
        let bestY = y;
        let bestDistance = Infinity;

        for (const other of others) {
            const ox = monitorX(other);
            const oy = monitorY(other);
            const ow = logicalWidth(other);
            const oh = logicalHeight(other);

            const candidates = [
                {
                    x: ox + ow,
                    y: Math.max(oy - h + 1, Math.min(y, oy + oh - 1))
                },
                {
                    x: ox - w,
                    y: Math.max(oy - h + 1, Math.min(y, oy + oh - 1))
                },
                {
                    x: Math.max(ox - w + 1, Math.min(x, ox + ow - 1)),
                    y: oy + oh
                },
                {
                    x: Math.max(ox - w + 1, Math.min(x, ox + ow - 1)),
                    y: oy - h
                }
            ];

            for (const candidate of candidates) {
                const overlapsAny = others.some(m =>
                    rectanglesOverlap(
                        candidate.x,
                        candidate.y,
                        w,
                        h,
                        monitorX(m),
                        monitorY(m),
                        logicalWidth(m),
                        logicalHeight(m)
                    )
                );

                if (overlapsAny)
                    continue;

                const distance = Math.hypot(
                    candidate.x - x,
                    candidate.y - y
                );

                if (distance < bestDistance) {
                    bestDistance = distance;
                    bestX = candidate.x;
                    bestY = candidate.y;
                }
            }
        }

        if (bestDistance !== Infinity)
            moveMonitor(name, bestX, bestY);
    }

    readonly property real minX: monitors.length > 0
        ? Math.min(...monitors.map(m => monitorX(m)))
        : 0

    readonly property real minY: monitors.length > 0
        ? Math.min(...monitors.map(m => monitorY(m)))
        : 0

    readonly property real maxX: monitors.length > 0
        ? Math.max(...monitors.map(
            m => monitorX(m) + logicalWidth(m)))
        : 1

    readonly property real maxY: monitors.length > 0
        ? Math.max(...monitors.map(
            m => monitorY(m) + logicalHeight(m)))
        : 1

    readonly property real layoutWidth:
        Math.max(1, maxX - minX)

    readonly property real layoutHeight:
        Math.max(1, maxY - minY)

    readonly property real availableWidth:
        Math.max(1, width - paddingSize * 2)

    readonly property real availableHeight:
        Math.max(1, height - paddingSize * 2)

    readonly property real previewScale: Math.min(
        availableWidth / layoutWidth,
        availableHeight / layoutHeight
    )

    readonly property real offsetX:
        (width - layoutWidth * previewScale) / 2

    readonly property real offsetY:
        (height - layoutHeight * previewScale) / 2

    readonly property real effectiveScale:
        dragging ? frozenScale : previewScale

    readonly property real effectiveOffsetX:
        dragging ? frozenOffsetX : offsetX

    readonly property real effectiveOffsetY:
        dragging ? frozenOffsetY : offsetY

    readonly property real effectiveMinX:
        dragging ? frozenMinX : minX

    readonly property real effectiveMinY:
        dragging ? frozenMinY : minY

    function clamp(value, minimum, maximum) {
        return Math.max(minimum, Math.min(value, maximum));
    }

    // Keep the entire rectangle inside the preview area.
    function clampPreviewX(x, monitorWidth) {
        return clamp(
            x,
            paddingSize,
            Math.max(paddingSize, width - paddingSize - monitorWidth)
        );
    }

    function clampPreviewY(y, monitorHeight) {
        return clamp(
            y,
            paddingSize,
            Math.max(paddingSize, height - paddingSize - monitorHeight)
        );
    }

    function beginDrag() {
        frozenScale = previewScale;
        frozenOffsetX = offsetX;
        frozenOffsetY = offsetY;
        frozenMinX = minX;
        frozenMinY = minY;
        dragging = true;
    }

    function endDrag() {
        dragging = false;
    }

    Rectangle {
        anchors.fill: parent
        radius: Appearance.rounding.large
        color: Appearance.m3colors.m3surfaceContainerLow
    }

    Repeater {
        model: root.monitors

        delegate: Rectangle {
            id: monitorRect

            required property var modelData
            required property int index

            readonly property bool selected:
                modelData.name === root.selectedMonitorName

            readonly property real baseX:
                root.effectiveOffsetX
                + (root.monitorX(modelData) - root.effectiveMinX)
                * root.effectiveScale

            readonly property real baseY:
                root.effectiveOffsetY
                + (root.monitorY(modelData) - root.effectiveMinY)
                * root.effectiveScale

            property real dragX: 0
            property real dragY: 0

            x: baseX + dragX
            y: baseY + dragY

            width: Math.max(
                1,
                root.logicalWidth(modelData) * root.effectiveScale
            )

            height: Math.max(
                1,
                root.logicalHeight(modelData) * root.effectiveScale
            )

            z: dragHandler.active ? 10 : selected ? 2 : 1

            radius: Appearance.rounding.normal

            color: selected
                ? Appearance.m3colors.m3primaryContainer
                : Appearance.m3colors.m3surfaceContainerHigh

            border.width: selected ? 3 : 1

            border.color: selected
                ? Appearance.m3colors.m3primary
                : Appearance.m3colors.m3outlineVariant

            Behavior on color {
                ColorAnimation {
                    duration: 160
                }
            }

            Column {
                anchors.centerIn: parent
                width: Math.max(0, parent.width - 12)
                spacing: 4

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: String(monitorRect.index + 1)
                    font.pixelSize: 28
                    font.weight: Font.Bold

                    color: monitorRect.selected
                        ? Appearance.m3colors.m3onPrimaryContainer
                        : Appearance.m3colors.m3onSurface
                }

                StyledText {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    text: monitorRect.modelData.name

                    color: monitorRect.selected
                        ? Appearance.m3colors.m3onPrimaryContainer
                        : Appearance.m3colors.m3onSurface
                }
            }

            TapHandler {
                onTapped: {
                    root.monitorSelected(monitorRect.modelData.name);
                }
            }

            DragHandler {
                id: dragHandler

                target: null
                acceptedButtons: Qt.LeftButton

                property real startScale: 1
                property real initialMonitorX: 0
                property real initialMonitorY: 0

                onActiveChanged: {
                    if (active) {
                        root.monitorSelected(monitorRect.modelData.name);

                        root.beginDrag();

                        startScale = root.frozenScale;

                        initialMonitorX =
                            root.monitorX(monitorRect.modelData);

                        initialMonitorY =
                            root.monitorY(monitorRect.modelData);
                    } else {
                        if (root.dragging) {
                            if (Math.abs(monitorRect.dragX) > 0.5
                                || Math.abs(monitorRect.dragY) > 0.5) {

                                const newX = initialMonitorX
                                    + monitorRect.dragX / startScale;

                                const newY = initialMonitorY
                                    + monitorRect.dragY / startScale;

                                root.snapMonitor(
                                    monitorRect.modelData.name,
                                    newX,
                                    newY
                                );
                            }

                            monitorRect.dragX = 0;
                            monitorRect.dragY = 0;

                            root.endDrag();
                        }
                    }
                }

                onTranslationChanged: {
                    if (!active)
                        return;

                    // Proposed position in preview pixels.
                    const proposedX =
                        monitorRect.baseX + translation.x;

                    const proposedY =
                        monitorRect.baseY + translation.y;

                    // Stop at the preview boundaries.
                    const boundedX = root.clampPreviewX(
                        proposedX,
                        monitorRect.width
                    );

                    const boundedY = root.clampPreviewY(
                        proposedY,
                        monitorRect.height
                    );

                    monitorRect.dragX =
                        boundedX - monitorRect.baseX;

                    monitorRect.dragY =
                        boundedY - monitorRect.baseY;
                }
            }
        }
    }

    StyledText {
        anchors.centerIn: parent
        visible: root.monitors.length === 0
        text: "No connected displays"
        color: Appearance.m3colors.m3outline
    }
}
