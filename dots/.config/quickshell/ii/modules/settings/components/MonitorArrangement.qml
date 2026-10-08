
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

    // Espaçamento somente visual entre os monitores.
    // Não altera as coordenadas nem a área de arraste.
    readonly property real monitorGap: 4

    property bool dragging: false
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

    function snapMonitor(name, requestedX, requestedY) {
        const moving = monitors.find(m => m.name === name);

        if (!moving)
            return;

        const others = monitors.filter(m => m.name !== name);

        if (!others.length) {
            layoutChanged({
                [name]: {
                    x: Math.round(requestedX),
                    y: Math.round(requestedY)
                }
            });
            return;
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

        if (best) {
            layoutChanged({
                [name]: {
                    x: best.x,
                    y: best.y
                }
            });
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: Appearance.rounding.large
        color: Appearance.m3colors.m3surfaceContainerLow
    }

    Repeater {
        model: root.monitors

        // A área externa mantém o tamanho lógico completo.
        // O retângulo interno recebe apenas a margem visual.
        delegate: Item {
            id: monitorItem

            required property var modelData
            required property int index

            readonly property bool selected:
                modelData.name === root.selectedMonitorName

            property real visualDX: 0
            property real visualDY: 0
            property real dragStartX: 0
            property real dragStartY: 0
            property real dragScale: 1
            property real requestedDX: 0
            property real requestedDY: 0

            x: root.previewX(Number(modelData.x) || 0)
                + visualDX

            y: root.previewY(Number(modelData.y) || 0)
                + visualDY

            width: Math.max(
                1,
                root.logicalWidth(modelData) * root.effectiveScale
            )

            height: Math.max(
                1,
                root.logicalHeight(modelData) * root.effectiveScale
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
                        font.pixelSize: 28
                        font.weight: Font.Bold

                        color: monitorItem.selected
                            ? Appearance.m3colors.m3onPrimaryContainer
                            : Appearance.m3colors.m3onSurface
                    }

                    StyledText {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        text: monitorItem.modelData.name

                        color: monitorItem.selected
                            ? Appearance.m3colors.m3onPrimaryContainer
                            : Appearance.m3colors.m3onSurface
                    }
                }
            }

            // Clique seleciona sem movimentar.
            TapHandler {
                acceptedButtons: Qt.LeftButton

                onTapped: {
                    root.monitorSelected(
                        monitorItem.modelData.name
                    );
                }
            }

            // Arraste preservado da versão funcional.
            DragHandler {
                id: dragHandler

                target: null
                acceptedButtons: Qt.LeftButton
                dragThreshold: 2

                onActiveChanged: {
                    if (active) {
                        root.beginDrag();

                        root.monitorSelected(
                            monitorItem.modelData.name
                        );

                        monitorItem.dragStartX =
                            Number(monitorItem.modelData.x) || 0;

                        monitorItem.dragStartY =
                            Number(monitorItem.modelData.y) || 0;

                        monitorItem.dragScale = root.frozenScale;

                        monitorItem.visualDX = 0;
                        monitorItem.visualDY = 0;
                        monitorItem.requestedDX = 0;
                        monitorItem.requestedDY = 0;
                    } else {
                        if (!root.dragging)
                            return;

                        const name = monitorItem.modelData.name;

                        const requestedX =
                            monitorItem.dragStartX
                            + monitorItem.requestedDX
                            / monitorItem.dragScale;

                        const requestedY =
                            monitorItem.dragStartY
                            + monitorItem.requestedDY
                            / monitorItem.dragScale;

                        monitorItem.visualDX = 0;
                        monitorItem.visualDY = 0;

                        root.dragging = false;

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

                    const baseX = root.frozenOffsetX
                        + (monitorItem.dragStartX
                        - root.frozenMinX)
                        * monitorItem.dragScale;

                    const baseY = root.frozenOffsetY
                        + (monitorItem.dragStartY
                        - root.frozenMinY)
                        * monitorItem.dragScale;

                    const minDX = root.paddingSize - baseX;

                    const maxDX =
                        root.width
                        - root.paddingSize
                        - monitorItem.width
                        - baseX;

                    const minDY = root.paddingSize - baseY;

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
