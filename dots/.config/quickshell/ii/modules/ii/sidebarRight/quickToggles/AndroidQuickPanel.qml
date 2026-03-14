import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth

import qs.modules.ii.sidebarRight.quickToggles.androidStyle

AbstractQuickPanel {
    id: root
    property bool editMode: false
    Layout.fillWidth: true

    // Sizes
    implicitHeight: (editMode ? contentItem.implicitHeight : usedRows.implicitHeight) + root.padding * 2
    Behavior on implicitHeight {
        animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
    }
    property real spacing: 6
    property real padding: 6
    readonly property real baseCellWidth: {
        // This is the wrong calculation, but it looks correct in reality???
        // (theoretically spacing should be multiplied by 1 column less)
        const availableWidth = root.width - (root.padding * 2) - (root.spacing * (root.columns))
        return availableWidth / root.columns
    }
    readonly property real baseCellHeight: 56

    // Toggles
    readonly property list<string> availableToggleTypes: ["network", "bluetooth", "idleInhibitor", "easyEffects", "nightLight", "darkMode", "cloudflareWarp", "gameMode", "screenSnip", "colorPicker", "onScreenKeyboard", "mic", "audio", "notifications", "powerProfile","musicRecognition", "antiFlashbang"]
    readonly property int columns: Config.options.sidebar.quickToggles.android.columns
    readonly property list<var> toggles: Config.ready ? Config.options.sidebar.quickToggles.android.toggles : []
    readonly property list<var> toggleRows: toggleRowsForList(toggles)
    readonly property list<var> unusedToggles: {
        const types = availableToggleTypes.filter(type => !toggles.some(toggle => (toggle && toggle.type === type)))
        return types.map(type => { return { type: type, size: 1 } })
    }
    readonly property list<var> unusedToggleRows: toggleRowsForList(unusedToggles)

    property int dragIndex: -1  // flat config index of item being dragged (-1 = none)

    // Map (x, y) in usedRows coordinates → flat config index.
    // Uses the same stride math as the RowLayout so no item references are needed.
    function toggleIndexAt(x, y) {
        const rowH = root.baseCellHeight + root.spacing
        const rowIdx = Math.max(0, Math.min(root.toggleRows.length - 1, Math.floor(y / rowH)))
        if (root.toggleRows.length === 0) return -1
        let flatStart = 0
        for (let r = 0; r < rowIdx; r++) flatStart += root.toggleRows[r].length
        const row = root.toggleRows[rowIdx]
        if (!row || row.length === 0) return -1
        // Each column slot is (baseCellWidth + spacing) wide; a size-2 button takes 2 slots.
        const stride = root.baseCellWidth + root.spacing
        let accumulated = 0
        for (let c = 0; c < row.length; c++) {
            accumulated += row[c].size * stride
            // Drop target switches at the midpoint of the gap between buttons
            if (x < accumulated - root.spacing / 2 || c === row.length - 1) return flatStart + c
        }
        return flatStart + row.length - 1
    }

    function swapToggles(fromIdx, toIdx) {
        const list = Config.options.sidebar.quickToggles.android.toggles
        const temp = list[fromIdx]
        list[fromIdx] = list[toIdx]
        list[toIdx] = temp
    }

    function removeToggleAt(index) {
        Config.options.sidebar.quickToggles.android.toggles.splice(index, 1)
    }

    function resizeToggleAt(index) {
        const list = Config.options.sidebar.quickToggles.android.toggles
        if (index < 0 || index >= list.length) return
        list[index] = { type: list[index].type, size: 3 - list[index].size }
    }

    function toggleRowsForList(togglesList) {
        var rows = [];
        var row = [];
        var totalSize = 0; // Total cols taken in current row
        for (var i = 0; i < togglesList.length; i++) {
            if (!togglesList[i]) continue;
            if (totalSize + togglesList[i].size > columns) {
                rows.push(row);
                row = [];
                totalSize = 0;
            }
            row.push(togglesList[i]);
            totalSize += togglesList[i].size;
        }
        if (row.length > 0) {
            rows.push(row);
        }
        return rows;
    }

    Column {
        id: contentItem
        anchors {
            fill: parent
            margins: root.padding
        }
        spacing: 12
        
        Column {
            id: usedRows
            spacing: root.spacing

            Repeater {
                id: usedRowsRepeater
                model: ScriptModel {
                    values: Array(root.toggleRows.length)
                }
                delegate: ButtonGroup {
                    id: toggleRow
                    required property int index
                    property var modelData: root.toggleRows[index]
                    property int startingIndex: {
                        const rows = root.toggleRows;
                        let sum = 0;
                        for (let i = 0; i < index; i++) {
                            sum += rows[i].length;
                        }
                        return sum;
                    }
                    spacing: root.spacing

                    Repeater {
                        model: ScriptModel {
                            values: toggleRow?.modelData ?? []
                            objectProp: "type"
                        }
                        delegate: AndroidToggleDelegateChooser {
                            startingIndex: toggleRow.startingIndex
                            editMode: root.editMode
                            dragIndex: root.dragIndex
                            baseCellWidth: root.baseCellWidth
                            baseCellHeight: root.baseCellHeight
                            spacing: root.spacing
                            onOpenAudioOutputDialog: root.openAudioOutputDialog()
                            onOpenAudioInputDialog: root.openAudioInputDialog()
                            onOpenBluetoothDialog: root.openBluetoothDialog()
                            onOpenNightLightDialog: root.openNightLightDialog()
                            onOpenWifiDialog: root.openWifiDialog()
                        }
                    }
                }
            }
        }

        FadeLoader {
            shown: root.editMode
            anchors {
                left: parent.left
                right: parent.right
                leftMargin: root.baseCellHeight / 2
                rightMargin: root.baseCellHeight / 2
            }
            sourceComponent: Rectangle {
                implicitHeight: 1
                color: Appearance.colors.colOutlineVariant
            }
        }

        FadeLoader {
            shown: root.editMode
            sourceComponent: Column {
                id: unusedRows
                spacing: root.spacing

                Repeater {
                    model: ScriptModel {
                        values: Array(root.unusedToggleRows.length)
                    }
                    delegate: ButtonGroup {
                        id: unusedToggleRow
                        required property int index
                        property var modelData: root.unusedToggleRows[index]
                        spacing: root.spacing

                        Repeater {
                            model: ScriptModel {
                                values: unusedToggleRow?.modelData ?? []
                                objectProp: "type"
                            }
                            delegate: AndroidToggleDelegateChooser {
                                startingIndex: -1
                                editMode: root.editMode
                                baseCellWidth: root.baseCellWidth
                                baseCellHeight: root.baseCellHeight
                                spacing: root.spacing
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Edit-mode drag overlay ───────────────────────────────────────────────
    // Direct child of root so it floats above contentItem (z:100).
    // Positioned to exactly cover usedRows in root's coordinate space:
    //   contentItem has margins=root.padding, usedRows is contentItem's first child.
    // Intercepts all pointer events on the used-section buttons so drag, click,
    // and resize are all handled here. Unused-section buttons sit below this
    // overlay's height, so their own editModeInteraction MouseArea still fires.
    MouseArea {
        id: editDragOverlay
        z: 100
        x: root.padding
        y: root.padding
        width:  usedRows.width
        height: usedRows.height
        visible: root.editMode
        enabled: root.editMode
        hoverEnabled: true
        cursorShape: root.dragIndex >= 0 ? Qt.ClosedHandCursor : Qt.OpenHandCursor

        property int  sourceIndex:   -1
        property bool dragActive:    false
        property real pressX:        0
        property real pressY:        0
        property int  pressedButton: Qt.NoButton
        readonly property real dragThreshold: 6

        onPressed: (mouse) => {
            pressX        = mouse.x
            pressY        = mouse.y
            dragActive    = false
            pressedButton = mouse.button
            sourceIndex   = root.toggleIndexAt(mouse.x, mouse.y)
            if (mouse.button === Qt.RightButton && sourceIndex >= 0) {
                root.resizeToggleAt(sourceIndex)
                sourceIndex = -1
            }
        }

        onPositionChanged: (mouse) => {
            if (!dragActive && pressedButton === Qt.LeftButton) {
                const dx = mouse.x - pressX
                const dy = mouse.y - pressY
                if (Math.sqrt(dx * dx + dy * dy) > dragThreshold) {
                    dragActive     = true
                    root.dragIndex = sourceIndex
                }
            }
            if (dragActive && root.dragIndex >= 0) {
                const targetIdx = root.toggleIndexAt(mouse.x, mouse.y)
                if (targetIdx >= 0 && targetIdx !== root.dragIndex) {
                    root.swapToggles(root.dragIndex, targetIdx)
                    root.dragIndex = targetIdx   // follow the dragged item
                }
            }
        }

        onPressAndHold: {
            if (sourceIndex >= 0 && !dragActive) {
                root.resizeToggleAt(sourceIndex)
                sourceIndex = -1   // suppress the upcoming release click
            }
        }

        onReleased: (mouse) => {
            if (!dragActive && mouse.button === Qt.LeftButton && sourceIndex >= 0)
                root.removeToggleAt(sourceIndex)
            root.dragIndex = -1
            sourceIndex    = -1
            dragActive     = false
        }

        // Consume wheel events — scroll-to-reorder is replaced by drag
        onWheel: (wheel) => wheel.accepted = true
    }
    // ────────────────────────────────────────────────────────────────────────
}
