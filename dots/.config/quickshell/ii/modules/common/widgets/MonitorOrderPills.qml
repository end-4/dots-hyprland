import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Flow {
    id: root

    property bool selectable: true
    property string selectedMonitor: ""
    signal monitorSelected(string name)

    Layout.fillWidth: true
    spacing: 6

    readonly property string mainMonitorName: {
        const pref = Config.options.bar.workspaces.defaultMonitor ?? "";
        if (pref !== "" && Quickshell.screens.some(s => s.name === pref))
            return pref;
        let best = "";
        let bestArea = -1;
        for (let i = 0; i < Quickshell.screens.length; i++) {
            const s = Quickshell.screens[i];
            const area = s.width * s.height;
            if (area > bestArea) {
                bestArea = area;
                best = s.name;
            }
        }
        return best;
    }

    readonly property var orderedScreens: {
        const screens = Array.from(Quickshell.screens);
        const order = Config.options.background.monitorOrder ?? [];
        if (order.length > 0) {
            screens.sort((a, b) => {
                const ia = order.indexOf(a.name);
                const ib = order.indexOf(b.name);
                if (ia !== -1 && ib !== -1) return ia - ib;
                if (ia !== -1) return -1;
                if (ib !== -1) return 1;
                return (a.x ?? 0) - (b.x ?? 0);
            });
        } else {
            screens.sort((a, b) => (a.x ?? 0) - (b.x ?? 0));
        }
        return screens;
    }

    function applyMonitorOrder(newOrder) {
        Config.options.background.monitorOrder = newOrder;
    }

    Repeater {
        model: root.orderedScreens
        delegate: Item {
            id: pillSlot
            required property var modelData
            required property int index
            readonly property bool isSel: root.selectable && root.selectedMonitor === modelData.name
            readonly property bool isMain: root.mainMonitorName === modelData.name
            implicitWidth: monBtn.implicitWidth
            implicitHeight: 34
            z: monDragArea.drag.active ? 10 : 0

            Rectangle {
                id: monBtn
                implicitWidth: monBtnRow.implicitWidth + 20
                implicitHeight: 34
                width: implicitWidth
                height: implicitHeight
                radius: Appearance.rounding.full
                color: isSel ? Appearance.colors.colPrimary : Appearance.colors.colLayer2
                opacity: monDragArea.drag.active ? 0.85 : 1.0

                MouseArea {
                    id: monDragArea
                    anchors.fill: parent
                    cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                    drag.target: monBtn
                    drag.axis: Drag.XAxis
                    property real startX: 0
                    onPressed: startX = monBtn.x
                    onReleased: {
                        const dx = monBtn.x - startX;
                        monBtn.x = 0;
                        if (Math.abs(dx) > 32 && root.orderedScreens.length > 1) {
                            const names = root.orderedScreens.map(s => s.name);
                            const cur = names.indexOf(modelData.name);
                            const target = dx > 0 ? Math.min(names.length - 1, cur + 1) : Math.max(0, cur - 1);
                            if (cur !== -1 && target !== cur) {
                                const tmp = names[cur];
                                names[cur] = names[target];
                                names[target] = tmp;
                                root.applyMonitorOrder(names);
                            }
                        } else if (root.selectable) {
                            root.monitorSelected(modelData.name);
                        }
                    }
                }

                RowLayout {
                    id: monBtnRow
                    anchors.centerIn: parent
                    spacing: 5
                    MouseArea {
                        id: starArea
                        implicitWidth: 20
                        implicitHeight: 20
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Config.options.bar.workspaces.defaultMonitor = modelData.name
                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "star"
                            fill: isMain ? 1 : 0
                            iconSize: 17
                            color: isMain
                                ? (isSel ? Appearance.m3colors.m3onPrimary : Appearance.colors.colPrimary)
                                : (isSel ? Appearance.m3colors.m3onPrimary : Appearance.colors.colSubtext)
                        }
                        StyledToolTip {
                            extraVisibleCondition: starArea.containsMouse
                            text: isMain ? Translation.tr("Main monitor") : Translation.tr("Set as main monitor")
                        }
                    }
                    StyledText {
                        text: `${index + 1} · ${modelData.name} (${modelData.width}×${modelData.height})`
                        color: isSel ? Appearance.m3colors.m3onPrimary : Appearance.m3colors.m3onSurface
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: isSel ? Font.Medium : Font.Normal
                    }
                }
            }
        }
    }
}
