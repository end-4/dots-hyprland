import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell

WindowDialog {
    id: root
    backgroundWidth: 400
    backgroundHeight: 520
    readonly property var ordered: {
        const list = (Displays.monitors || []).slice();
        list.sort((a, b) => {
            if (!!a.disabled !== !!b.disabled) return a.disabled ? 1 : -1;
            return a.x - b.x || a.y - b.y || a.name.localeCompare(b.name);
        });
        return list;
    }
    readonly property var preview: Displays.previewLayout(Displays.monitors)
    readonly property var bounds: {
        const list = preview || [];
        let minX = 0;
        let minY = 0;
        let maxX = 1;
        let maxY = 1;
        if (list.length) {
            minX = Infinity;
            minY = Infinity;
            maxX = -Infinity;
            maxY = -Infinity;
            for (let i = 0; i < list.length; i++) {
                const m = list[i];
                minX = Math.min(minX, m.posX);
                minY = Math.min(minY, m.posY);
                maxX = Math.max(maxX, m.posX + (m.boxW || 1));
                maxY = Math.max(maxY, m.posY + (m.boxH || 1));
            }
        }
        return { minX: minX, minY: minY, maxX: maxX, maxY: maxY };
    }

    WindowDialogTitle {
        text: Translation.tr("Displays")
    }

    WindowDialogParagraph {
        Layout.fillWidth: true
        text: Translation.tr("Turn screens on or off. Arrange opens a window to drag them into place.")
    }

    Item {
        id: map
        Layout.fillWidth: true
        Layout.preferredHeight: 120
        implicitHeight: 120
        visible: ordered.length > 0
        readonly property real spanX: Math.max(1, root.bounds.maxX - root.bounds.minX)
        readonly property real spanY: Math.max(1, root.bounds.maxY - root.bounds.minY)
        readonly property real fit: Math.min((width - 4) / spanX, (height - 4) / spanY)
        readonly property real usedW: spanX * fit
        readonly property real usedH: spanY * fit

        Repeater {
            model: ScriptModel {
                values: root.preview
            }
            delegate: Rectangle {
                required property var modelData
                x: (map.width - map.usedW) / 2 + (modelData.posX - root.bounds.minX) * map.fit
                y: (map.height - map.usedH) / 2 + (modelData.posY - root.bounds.minY) * map.fit
                width: (modelData.boxW || 1) * map.fit
                height: (modelData.boxH || 1) * map.fit
                radius: 4
                color: Appearance.colors.colLayer2
                border.width: 1
                border.color: Appearance.colors.colOutlineVariant

                StyledText {
                    anchors.centerIn: parent
                    width: parent.width - 4
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colOnLayer2
                    text: modelData.name
                }
            }
        }
    }

    Column {
        Layout.fillWidth: true
        spacing: 2

        Repeater {
            model: ScriptModel {
                values: root.ordered
            }
            delegate: ColumnLayout {
                required property var modelData
                width: parent.width
                spacing: 2
                opacity: modelData.disabled ? 0.55 : 1

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    MaterialSymbol {
                        iconSize: Appearance.font.pixelSize.larger
                        color: Appearance.colors.colOnSurfaceVariant
                        text: /^(eDP|LVDS|DSI)/i.test(modelData.name) ? "laptop" : "monitor"
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            color: Appearance.colors.colOnSurfaceVariant
                            text: modelData.name
                        }

                        StyledText {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                            text: {
                                const parts = [];
                                if (modelData.model) parts.push(modelData.model);
                                else if (modelData.description) parts.push(modelData.description);
                                if (modelData.width && modelData.height)
                                    parts.push(modelData.width + "×" + modelData.height);
                                if (modelData.refreshRate)
                                    parts.push(Math.round(modelData.refreshRate) + " Hz");
                                if (modelData.disabled) parts.push(Translation.tr("Off"));
                                return parts.join(" · ");
                            }
                        }
                    }
                }

                RowLayout {
                    visible: modelData.disabled || Displays.enabledCount > 1
                    Layout.fillWidth: true
                    Layout.leftMargin: 34
                    spacing: 4

                    DisplayButton {
                        visible: !modelData.disabled && Displays.enabledCount > 1
                        buttonText: Translation.tr("Turn off")
                        onClicked: Displays.setEnabled(modelData.name, false)
                    }

                    DisplayButton {
                        visible: modelData.disabled
                        primary: true
                        buttonText: Translation.tr("Turn on")
                        onClicked: Displays.setEnabled(modelData.name, true)
                    }

                    Item { Layout.fillWidth: true }
                }
            }
        }

        StyledText {
            visible: ordered.length === 0
            width: parent.width
            wrapMode: Text.Wrap
            color: Appearance.colors.colSubtext
            text: Translation.tr("No displays reported")
        }
    }

    StyledText {
        visible: Displays.lastError !== ""
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        color: Appearance.colors.colError
        font.pixelSize: Appearance.font.pixelSize.small
        text: Displays.lastError
    }

    WindowDialogButtonRow {
        DisplayButton {
            visible: Displays.enabledCount > 1
            buttonText: Translation.tr("Arrange")
            onClicked: {
                Displays.openArrange();
                GlobalStates.sidebarRightOpen = false;
            }
        }
        Item { Layout.fillWidth: true }
        DisplayButton {
            buttonText: Translation.tr("Done")
            onClicked: root.dismiss()
        }
    }
}
