
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

    readonly property real paddingSize: 16
    readonly property real epsilon: 0.01
    readonly property real monitorGap: 4
    readonly property real alignmentTolerance: 16

    property bool dragging: false
    property var dragGuide: null

    property real frozenScale: 1
    property real frozenMinX: 0
    property real frozenMinY: 0
    property real frozenOffsetX: 0
    property real frozenOffsetY: 0

    function clamp(value, low, high) {
        return Math.max(low, Math.min(high, value));
    }

    function logicalWidth(m) {
        const rotated = Number(m.transform || 0) % 2 !== 0;
        return (rotated ? Number(m.height) : Number(m.width))
            / Math.max(0.01, Number(m.scale) || 1);
    }

    function logicalHeight(m) {
        const rotated = Number(m.transform || 0) % 2 !== 0;
        return (rotated ? Number(m.width) : Number(m.height))
            / Math.max(0.01, Number(m.scale) || 1);
    }

    readonly property real minX: monitors.length
        ? Math.min(...monitors.map(m => Number(m.x) || 0))
        : 0

    readonly property real minY: monitors.length
        ? Math.min(...monitors.map(m => Number(m.y) || 0))
        : 0

    readonly property real maxX: monitors.length
        ? Math.max(...monitors.map(m =>
            (Number(m.x) || 0) + logicalWidth(m)))
        : 1

    readonly property real maxY: monitors.length
        ? Math.max(...monitors.map(m =>
            (Number(m.y) || 0) + logicalHeight(m)))
        : 1

    readonly property real layoutWidth: Math.max(1, maxX - minX)
    readonly property real layoutHeight: Math.max(1, maxY - minY)

    readonly property real availableWidth:
        Math.max(1, width - paddingSize * 2)

    readonly property real availableHeight:
        Math.max(1, height - paddingSize * 2)

    readonly property real previewScale: Math.min(
        availableWidth / layoutWidth,
        availableHeight / layoutHeight
    )

    readonly property real offsetX: paddingSize
        + (availableWidth - layoutWidth * previewScale) / 2

    readonly property real offsetY: paddingSize
        + (availableHeight - layoutHeight * previewScale) / 2

    readonly property real effectiveScale:
        dragging ? frozenScale : previewScale

    readonly property real effectiveMinX:
        dragging ? frozenMinX : minX

    readonly property real effectiveMinY:
        dragging ? frozenMinY : minY

    readonly property real effectiveOffsetX:
        dragging ? frozenOffsetX : offsetX

    readonly property real effectiveOffsetY:
        dragging ? frozenOffsetY : offsetY

    function previewX(x) {
        return effectiveOffsetX
            + (x - effectiveMinX) * effectiveScale;
    }

    function previewY(y) {
        return effectiveOffsetY
            + (y - effectiveMinY) * effectiveScale;
    }

    function beginDrag() {
        frozenScale = previewScale;
        frozenMinX = minX;
        frozenMinY = minY;
        frozenOffsetX = offsetX;
        frozenOffsetY = offsetY;
        dragGuide = null;
        dragging = true;
    }

    function overlaps(ax, ay, aw, ah, bx, by, bw, bh) {
        return ax < bx + bw - epsilon
            && ax + aw > bx + epsilon
            && ay < by + bh - epsilon
            && ay + ah > by + epsilon;
    }

    function validPosition(name, x, y) {
        const moving = monitors.find(m => m.name === name);

        if (!moving)
            return false;

        const w = logicalWidth(moving);
        const h = logicalHeight(moving);

        return !monitors.some(other =>
            other.name !== name && overlaps(
                x, y, w, h,
                Number(other.x) || 0,
                Number(other.y) || 0,
                logicalWidth(other),
                logicalHeight(other)
            )
        );
    }

    // Normaliza todas as posições sem alterar a disposição relativa.
    function emitNormalizedLayout(name, x, y) {
        const positions = {};

        for (const monitor of monitors) {
            positions[monitor.name] = {
                x: monitor.name === name
                    ? Math.round(x)
                    : Math.round(Number(monitor.x) || 0),
                y: monitor.name === name
                    ? Math.round(y)
                    : Math.round(Number(monitor.y) || 0)
            };
        }

        const names = Object.keys(positions);

        if (!names.length)
            return;

        const minX = Math.min(
            ...names.map(key => positions[key].x)
        );
        const minY = Math.min(
            ...names.map(key => positions[key].y)
        );

        for (const key of names) {
            positions[key].x -= minX;
            positions[key].y -= minY;
        }

        layoutChanged(positions);
    }

    function alignNear(value, candidates) {
        let closest = value;
        let distance = alignmentTolerance;

        for (const candidate of candidates) {
            const delta = Math.abs(value - candidate);

            if (delta <= distance) {
                closest = candidate;
                distance = delta;
            }
        }

        return closest;
    }

    function findSnap(name, requestedX, requestedY) {
        const moving = monitors.find(m => m.name === name);

        if (!moving)
            return null;

        const others = monitors.filter(m => m.name !== name);

        if (!others.length) {
            return {
                x: Math.round(requestedX),
                y: Math.round(requestedY),
                alignedX: false,
                alignedY: false
            };
        }

        const w = logicalWidth(moving);
        const h = logicalHeight(moving);

        let best = null;
        let bestDistance = Infinity;

        for (const other of others) {
            const ox = Number(other.x) || 0;
            const oy = Number(other.y) || 0;
            const ow = logicalWidth(other);
            const oh = logicalHeight(other);

            const candidates = [
                {
                    x: Math.ceil(ox + ow),
                    y: Math.round(clamp(
                        requestedY,
                        oy - h + 1,
                        oy + oh - 1
                    ))
                },
                {
                    x: Math.floor(ox - w),
                    y: Math.round(clamp(
                        requestedY,
                        oy - h + 1,
                        oy + oh - 1
                    ))
                },
                {
                    x: Math.round(clamp(
                        requestedX,
                        ox - w + 1,
                        ox + ow - 1
                    )),
                    y: Math.ceil(oy + oh)
                },
                {
                    x: Math.round(clamp(
                        requestedX,
                        ox - w + 1,
                        ox + ow - 1
                    )),
                    y: Math.floor(oy - h)
                }
            ];

            // Encaixe lateral: alinha bordas e centros verticais.
            for (const candidate of candidates.slice(0, 2)) {
                const originalY = candidate.y;

                candidate.y = Math.round(alignNear(
                    candidate.y,
                    [
                        oy,
                        oy + oh - h,
                        oy + (oh - h) / 2
                    ]
                ));

                candidate.alignedY =
                    Math.abs(candidate.y - originalY) > 0.01
                    || [
                        oy,
                        oy + oh - h,
                        oy + (oh - h) / 2
                    ].some(value =>
                        Math.abs(candidate.y - value) <= 0.5
                    );

                candidate.alignedX = false;
            }

            // Encaixe vertical: alinha bordas e centros horizontais.
            for (const candidate of candidates.slice(2)) {
                const originalX = candidate.x;

                candidate.x = Math.round(alignNear(
                    candidate.x,
                    [
                        ox,
                        ox + ow - w,
                        ox + (ow - w) / 2
                    ]
                ));

                candidate.alignedX =
                    Math.abs(candidate.x - originalX) > 0.01
                    || [
                        ox,
                        ox + ow - w,
                        ox + (ow - w) / 2
                    ].some(value =>
                        Math.abs(candidate.x - value) <= 0.5
                    );

                candidate.alignedY = false;
            }

            for (const candidate of candidates) {
                if (!validPosition(
                    name,
                    candidate.x,
                    candidate.y
                )) {
                    continue;
                }

                const distance = Math.hypot(
                    candidate.x - requestedX,
                    candidate.y - requestedY
                );

                if (distance < bestDistance) {
                    bestDistance = distance;
                    best = candidate;
                }
            }
        }

        return best;
    }

    function snapMonitor(name, requestedX, requestedY) {
        const best = findSnap(name, requestedX, requestedY);

        if (best)
            emitNormalizedLayout(name, best.x, best.y);
    }

    // Fundo: deve permanecer atrás dos monitores e das guias.
    Rectangle {
        anchors.fill: parent
        radius: Appearance.rounding.large
        color: Appearance.m3colors.m3surfaceContainerLow
        z: -1
    }

    // Guia vertical.
    Rectangle {
        visible: root.dragging
            && root.dragGuide !== null
            && root.dragGuide.alignedX

        x: root.dragGuide
            ? root.previewX(root.dragGuide.x)
            : 0

        y: root.dragGuide
            ? root.previewY(root.dragGuide.y)
            : 0

        width: 2

        height: root.dragGuide
            ? root.dragGuide.height * root.effectiveScale
            : 0

        radius: 1
        color: Appearance.m3colors.m3primary
        opacity: 0.9
        z: 100
    }

    // Guia horizontal.
    Rectangle {
        visible: root.dragging
            && root.dragGuide !== null
            && root.dragGuide.alignedY

        x: root.dragGuide
            ? root.previewX(root.dragGuide.x)
            : 0

        y: root.dragGuide
            ? root.previewY(root.dragGuide.y)
            : 0

        width: root.dragGuide
            ? root.dragGuide.width * root.effectiveScale
            : 0

        height: 2
        radius: 1
        color: Appearance.m3colors.m3primary
        opacity: 0.9
        z: 100
    }

    // Contorno da posição prevista de encaixe.
    Rectangle {
        visible: root.dragging && root.dragGuide !== null

        x: root.dragGuide
            ? root.previewX(root.dragGuide.x)
            : 0

        y: root.dragGuide
            ? root.previewY(root.dragGuide.y)
            : 0

        width: root.dragGuide
            ? root.dragGuide.width * root.effectiveScale
            : 0

        height: root.dragGuide
            ? root.dragGuide.height * root.effectiveScale
            : 0

        radius: Appearance.rounding.normal
        color: "transparent"
        border.width: 3
        border.color: Appearance.m3colors.m3primary
        opacity: 0.95
        z: 99
    }

    // Marcador central da posição prevista.
    Rectangle {
        visible: root.dragging && root.dragGuide !== null

        x: root.dragGuide
            ? root.previewX(
                root.dragGuide.x + root.dragGuide.width / 2
            ) - 4
            : 0

        y: root.dragGuide
            ? root.previewY(
                root.dragGuide.y + root.dragGuide.height / 2
            ) - 4
            : 0

        width: 8
        height: 8
        radius: 4
        color: Appearance.m3colors.m3primary
        z: 101
    }

    Repeater {
        model: root.monitors.length

        delegate: Item {
            id: monitorItem

            required property int index

            readonly property var monitorData:
                root.monitors[index] ?? null

            readonly property bool selected:
                monitorData !== null
                && monitorData.name === root.selectedMonitorName

            property real visualDX: 0
            property real visualDY: 0
            property real dragStartX: 0
            property real dragStartY: 0
            property real dragScale: 1
            property real requestedDX: 0
            property real requestedDY: 0

            x: root.previewX(Number(monitorData.x) || 0)
                + visualDX

            y: root.previewY(Number(monitorData.y) || 0)
                + visualDY

            width: Math.max(
                1,
                root.logicalWidth(monitorData)
                    * root.effectiveScale
            )

            height: Math.max(
                1,
                root.logicalHeight(monitorData)
                    * root.effectiveScale
            )

            z: dragHandler.active ? 10 : selected ? 2 : 1

            Rectangle {
                id: monitorVisual

                anchors.fill: parent
                anchors.margins: root.monitorGap / 2
                radius: Appearance.rounding.normal

                color: monitorItem.selected
                    ? Appearance.m3colors.m3primaryContainer
                    : Appearance.m3colors.m3surfaceContainerHigh

                border.width: monitorItem.selected ? 3 : 1

                border.color: monitorItem.selected
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
                        anchors.horizontalCenter:
                            parent.horizontalCenter

                        text: String(monitorItem.index + 1)

                        font.pixelSize:
                            monitorVisual.width < 165
                            || monitorVisual.height < 115
                                ? 22 : 28

                        font.weight: Font.Bold

                        color: monitorItem.selected
                            ? Appearance.m3colors.m3onPrimaryContainer
                            : Appearance.m3colors.m3onSurface
                    }

                    StyledText {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight

                        text: monitorItem.monitorData
                            ? monitorItem.monitorData.name
                            : ""

                        color: monitorItem.selected
                            ? Appearance.m3colors.m3onPrimaryContainer
                            : Appearance.m3colors.m3onSurface
                    }

                    Column {
                        width: parent.width
                        spacing: 1

                        visible:
                            monitorItem.monitorData !== null
                            && monitorVisual.width >= 100
                            && monitorVisual.height >= 80

                        readonly property color detailColor:
                            monitorItem.selected
                                ? Appearance.m3colors.m3onPrimaryContainer
                                : Appearance.m3colors.m3onSurface

                        StyledText {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            color: parent.detailColor

                            text: monitorItem.monitorData
                                ? (
                                    String(
                                        monitorItem.monitorData.make ?? ""
                                    )
                                    + " "
                                    + String(
                                        monitorItem.monitorData.model ?? ""
                                    )
                                ).trim()
                                : ""
                        }

                        StyledText {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            color: parent.detailColor

                            text: monitorItem.monitorData
                                ? (
                                    monitorItem.monitorData.width
                                    + " × "
                                    + monitorItem.monitorData.height
                                    + " @ "
                                    + Number(
                                        monitorItem.monitorData.refreshRate
                                    ).toFixed(2)
                                    + " Hz"
                                )
                                : ""
                        }

                        StyledText {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            font.pixelSize: 10
                            font.weight: Font.Medium
                            color: parent.detailColor

                            text: monitorItem.monitorData
                                ? "Escala: "
                                    + Number(
                                        monitorItem.monitorData.scale
                                    ).toFixed(2)
                                : ""
                        }
                    }
                }
            }

            // Seleção por clique.
            TapHandler {
                acceptedButtons: Qt.LeftButton

                onTapped: {
                    if (!monitorItem.monitorData)
                        return;

                    root.monitorSelected(
                        monitorItem.monitorData.name
                    );
                }
            }

            // Arraste dos monitores.
            DragHandler {
                id: dragHandler
                target: null
                acceptedButtons: Qt.LeftButton
                dragThreshold: 2

                onActiveChanged: {
                    if (active) {
                        root.beginDrag();

                        root.monitorSelected(
                            monitorItem.monitorData.name
                        );

                        monitorItem.dragStartX =
                            Number(monitorItem.monitorData.x) || 0;

                        monitorItem.dragStartY =
                            Number(monitorItem.monitorData.y) || 0;

                        monitorItem.dragScale = root.frozenScale;
                        monitorItem.visualDX = 0;
                        monitorItem.visualDY = 0;
                        monitorItem.requestedDX = 0;
                        monitorItem.requestedDY = 0;
                    } else {
                        if (!root.dragging)
                            return;

                        const name = monitorItem.monitorData.name;

                        const requestedX =
                            monitorItem.dragStartX
                            + monitorItem.visualDX
                            / monitorItem.dragScale;

                        const requestedY =
                            monitorItem.dragStartY
                            + monitorItem.visualDY
                            / monitorItem.dragScale;

                        monitorItem.visualDX = 0;
                        monitorItem.visualDY = 0;
                        root.dragging = false;
                        root.dragGuide = null;

                        root.snapMonitor(
                            name,
                            requestedX,
                            requestedY
                        );
                    }
                }

                onTranslationChanged: {
                    if (!active)
                        return;

                    monitorItem.requestedDX = translation.x;
                    monitorItem.requestedDY = translation.y;

                    const baseX =
                        root.frozenOffsetX
                        + (
                            monitorItem.dragStartX
                            - root.frozenMinX
                        ) * monitorItem.dragScale;

                    const baseY =
                        root.frozenOffsetY
                        + (
                            monitorItem.dragStartY
                            - root.frozenMinY
                        ) * monitorItem.dragScale;

                    const minDX =
                        root.paddingSize - baseX;

                    const maxDX =
                        root.width
                        - root.paddingSize
                        - monitorItem.width
                        - baseX;

                    const minDY =
                        root.paddingSize - baseY;

                    const maxDY =
                        root.height
                        - root.paddingSize
                        - monitorItem.height
                        - baseY;

                    monitorItem.visualDX = root.clamp(
                        translation.x,
                        Math.min(minDX, maxDX),
                        Math.max(minDX, maxDX)
                    );

                    monitorItem.visualDY = root.clamp(
                        translation.y,
                        Math.min(minDY, maxDY),
                        Math.max(minDY, maxDY)
                    );

                    const candidate = root.findSnap(
                        monitorItem.monitorData.name,
                        monitorItem.dragStartX
                            + monitorItem.visualDX
                            / monitorItem.dragScale,
                        monitorItem.dragStartY
                            + monitorItem.visualDY
                            / monitorItem.dragScale
                    );

                    if (candidate) {
                        root.dragGuide = {
                            x: candidate.x,
                            y: candidate.y,
                            width: root.logicalWidth(
                                monitorItem.monitorData
                            ),
                            height: root.logicalHeight(
                                monitorItem.monitorData
                            ),
                            alignedX: candidate.alignedX || false,
                            alignedY: candidate.alignedY || false
                        };
                    } else {
                        root.dragGuide = null;
                    }
                }
            }
        }
    }

    StyledText {
        anchors.centerIn: parent
        visible: root.monitors.length === 0
        text: "Nenhum monitor conectado"
        color: Appearance.m3colors.m3outline
    }
}
