import QtQuick
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item {
    id: root

    required property string outputName
    required property var outputData
    required property real canvasScaleFactor
    required property point canvasOffset
    property var pendingPosition: null

    property bool isDragging: false
    property real grabOffsetX: 0
    property real grabOffsetY: 0

    function getLogicalSize() {
        const w = outputData?.width ?? 1920;
        const h = outputData?.height ?? 1080;
        const scale = outputData?.scale ?? 1;
        return { w: Math.round(w / scale), h: Math.round(h / scale) };
    }

    property real displayX: (pendingPosition ? pendingPosition.x : (outputData?.x ?? 0)) * canvasScaleFactor + canvasOffset.x
    property real displayY: (pendingPosition ? pendingPosition.y : (outputData?.y ?? 0)) * canvasScaleFactor + canvasOffset.y

    width: getLogicalSize().w * canvasScaleFactor
    height: getLogicalSize().h * canvasScaleFactor

    Binding on x { when: !root.isDragging; value: root.displayX }
    Binding on y { when: !root.isDragging; value: root.displayY }

    Rectangle {
        id: rect
        anchors.fill: parent
        radius: Appearance.rounding.normal
        z: root.isDragging ? 100 : 0

        color: root.isDragging ? ColorUtils.transparentize(Appearance.colors.colPrimary, 0.6)
            : (dragArea.containsMouse ? ColorUtils.transparentize(Appearance.colors.colPrimary, 0.8) : Appearance.colors.colLayer2)
        border.color: root.isDragging ? Appearance.colors.colPrimary : Appearance.colors.colOutline
        border.width: root.isDragging ? 2 : 1

        Column {
            anchors.centerIn: parent
            spacing: 4
            MaterialSymbol {
                anchors.horizontalCenter: parent.horizontalCenter
                iconSize: Math.min(24, Math.min(rect.width * 0.15, rect.height * 0.15))
                text: "monitor"
                color: Appearance.colors.colOnSecondaryContainer
            }
            StyledText {
                text: outputData?.description || outputData?.model || outputData?.make || outputName
                font.pixelSize: Math.max(10, Math.min(12, rect.width * 0.08))
                color: Appearance.colors.colOnSecondaryContainer
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.min(implicitWidth, rect.width - 8)
                elide: Text.ElideMiddle
            }
            StyledText {
                text: (outputData?.width || 0) + "×" + (outputData?.height || 0)
                font.pixelSize: Math.max(8, Math.min(10, rect.width * 0.06))
                color: Appearance.colors.colSubtext
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    MouseArea {
        id: dragArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.isDragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        drag.threshold: 4

        onWheel: (w) => { if (root.isDragging) w.accepted = true; }

        onPressed: (mouse) => {
            grabOffsetX = mouse.x;
            grabOffsetY = mouse.y;
        }

        onPositionChanged: (mouse) => {
            if (!(mouse.buttons & Qt.LeftButton)) return;
            if (mouse.x < -1000 || mouse.y < -1000) return;
            if (!root.isDragging) {
                const dx = mouse.x - grabOffsetX;
                const dy = mouse.y - grabOffsetY;
                if (dx * dx + dy * dy >= 16) root.isDragging = true;
                else return;
            }
            root.x += (mouse.x - grabOffsetX);
            root.y += (mouse.y - grabOffsetY);
        }

        onReleased: (mouse) => {
            if (!root.isDragging) return;
            const newX = Math.round((root.x - canvasOffset.x) / canvasScaleFactor);
            const newY = Math.round((root.y - canvasOffset.y) / canvasScaleFactor);
            const baseX = pendingPosition ? pendingPosition.x : (outputData?.x ?? 0);
            const baseY = pendingPosition ? pendingPosition.y : (outputData?.y ?? 0);
            const changed = newX !== baseX || newY !== baseY;
            if (changed) root.positionChanged(newX, newY);
            root.isDragging = false;
        }
    }

    signal positionChanged(int x, int y)
}
