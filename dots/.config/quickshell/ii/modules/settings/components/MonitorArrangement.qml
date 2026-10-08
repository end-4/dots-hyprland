
import QtQuick
import QtQuick.Layouts

import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root

    property var monitors: []
    property string selectedMonitorName: ""

    signal monitorSelected(string name)

    implicitHeight: 240
    Layout.fillWidth: true

    readonly property real paddingSize: 20

    readonly property real minX: monitors.length > 0
        ? Math.min(...monitors.map(m => m.x)) : 0

    readonly property real minY: monitors.length > 0
        ? Math.min(...monitors.map(m => m.y)) : 0

    readonly property real maxX: monitors.length > 0
        ? Math.max(...monitors.map(m => m.x + m.width / m.scale)) : 1

    readonly property real maxY: monitors.length > 0
        ? Math.max(...monitors.map(m => m.y + m.height / m.scale)) : 1

    readonly property real layoutWidth: Math.max(1, maxX - minX)
    readonly property real layoutHeight: Math.max(1, maxY - minY)

    readonly property real availableWidth: Math.max(1, width - paddingSize * 2)
    readonly property real availableHeight: Math.max(1, height - paddingSize * 2)

    readonly property real previewScale: Math.min(
        availableWidth / layoutWidth,
        availableHeight / layoutHeight
    )

    readonly property real offsetX:
        (width - layoutWidth * previewScale) / 2

    readonly property real offsetY:
        (height - layoutHeight * previewScale) / 2

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

            readonly property bool rotated:
                modelData.transform % 2 !== 0

            readonly property real logicalWidth:
                (rotated ? modelData.height : modelData.width) / modelData.scale

            readonly property real logicalHeight:
                (rotated ? modelData.width : modelData.height) / modelData.scale

            x: root.offsetX +
                (modelData.x - root.minX) * root.previewScale

            y: root.offsetY +
                (modelData.y - root.minY) * root.previewScale

            width: Math.max(1, logicalWidth * root.previewScale)
            height: Math.max(1, logicalHeight * root.previewScale)

            radius: Appearance.rounding.normal

            color: selected
                ? Appearance.m3colors.m3primaryContainer
                : Appearance.m3colors.m3surfaceContainerHigh

            border.width: selected ? 3 : 1

            border.color: selected
                ? Appearance.m3colors.m3primary
                : Appearance.m3colors.m3outlineVariant

            Behavior on color {
                ColorAnimation { duration: 160 }
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

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.monitorSelected(monitorRect.modelData.name)
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
