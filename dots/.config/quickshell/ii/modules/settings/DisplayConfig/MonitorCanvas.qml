import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import "."

Rectangle {
    id: root

    property real canvasHeight: 320
    property var pendingPositions: ({})
    property int draggingCount: 0
    signal monitorPositionChanged(string outputName, int x, int y)

    width: parent.width
    height: canvasHeight
    color: Appearance.colors.colLayer1

    property var monitors: HyprlandData.monitors || []
    property var bounds: {
        if (!monitors || monitors.length === 0)
            return { minX: 0, minY: 0, width: 1920, height: 1080 };
        let minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity;
        for (const m of monitors) {
            const x = m.x ?? 0, y = m.y ?? 0;
            const w = Math.round((m.width ?? 1920) / (m.scale ?? 1));
            const h = Math.round((m.height ?? 1080) / (m.scale ?? 1));
            minX = Math.min(minX, x);
            minY = Math.min(minY, y);
            maxX = Math.max(maxX, x + w);
            maxY = Math.max(maxY, y + h);
        }
        if (minX === Infinity)
            return { minX: 0, minY: 0, width: 1920, height: 1080 };
        return { minX: minX, minY: minY, width: maxX - minX, height: maxY - minY };
    }

    Item {
        id: canvas
        anchors.fill: parent
        anchors.margins: 16

        property real scaleFactor: {
            const b = root.bounds;
            if (!b || b.width <= 0 || b.height <= 0) return 0.1;
            const pad = 16;
            const sX = (width - pad) / b.width;
            const sY = (height - pad) / b.height;
            return Math.min(sX, sY, 0.15);
        }
        property point offset: {
            const b = root.bounds;
            const sf = scaleFactor;
            return Qt.point(
                (width - b.width * sf) / 2 - b.minX * sf,
                (height - b.height * sf) / 2 - b.minY * sf
            );
        }

        Repeater {
            model: root.monitors

            delegate: MonitorRect {
                required property var modelData
                outputName: modelData.name
                outputData: modelData
                canvasScaleFactor: canvas.scaleFactor
                canvasOffset: canvas.offset
                pendingPosition: root.pendingPositions[modelData.name] || null

                onIsDraggingChanged: root.draggingCount += (isDragging ? 1 : -1)

                onPositionChanged: (x, y) => {
                    root.monitorPositionChanged(modelData.name, x, y);
                }
            }
        }
    }
}
