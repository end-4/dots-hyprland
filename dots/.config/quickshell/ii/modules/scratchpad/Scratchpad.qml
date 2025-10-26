import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root

    readonly property real panelWidth: 440
    readonly property real panelHeight: 340
    readonly property real panelPadding: 20
    property string scratchpadContents: ""
    property bool pendingReload: false
    property var copylistEntries: []
    property string lastParsedCopylistText: ""
    property var parsedCopylistLines: []

    Component.onCompleted: {
        scratchpadFile.reload()
        updateCopylistEntries()
    }

    function saveScratchpad() {
        if (!scratchpadInput)
            return
        scratchpadContents = scratchpadInput.text
        scratchpadFile.setText(scratchpadContents)
    }

    function focusScratchpadAtEnd() {
        if (!scratchpadInput)
            return
        scratchpadInput.forceActiveFocus()
        const endPos = scratchpadInput.text.length
        applySelection(endPos, endPos)
    }

    function applySelection(cursorPos, anchorPos) {
        if (!scratchpadInput)
            return
        const textLength = scratchpadInput.text.length
        const cursor = Math.max(0, Math.min(cursorPos, textLength))
        const anchor = Math.max(0, Math.min(anchorPos, textLength))
        scratchpadInput.select(anchor, cursor)
        if (cursor === anchor)
            scratchpadInput.deselect()
    }

    function scheduleCopylistUpdate(immediate = false) {
        if (!scratchpadInput)
            return
        if (immediate) {
            copylistDebounce.stop()
            updateCopylistEntries()
        } else {
            copylistDebounce.restart()
        }
    }

    function updateCopylistEntries() {
        if (!scratchpadInput)
            return
        const textValue = scratchpadInput.text
        if (!textValue || textValue.length === 0) {
            lastParsedCopylistText = ""
            parsedCopylistLines = []
            copylistEntries = []
            return
        }

        if (textValue !== lastParsedCopylistText) {
            const lineRegex = /(.*?)(\r?\n|$)/g
            let match = null
            const parsed = []
            while ((match = lineRegex.exec(textValue)) !== null) {
                const lineText = match[1]
                const newlineText = match[2]
                const lineStart = match.index
                const lineEnd = lineStart + lineText.length
                const bulletMatch = lineText.match(/^\s*-\s+(.*\S)\s*$/)
                if (bulletMatch) {
                    parsed.push({
                        content: bulletMatch[1].trim(),
                        start: lineStart,
                        end: lineEnd
                    })
                }
                if (newlineText === "")
                    break
            }
            lastParsedCopylistText = textValue
            parsedCopylistLines = parsed
            if (parsed.length === 0) {
                copylistEntries = []
                return
            }
        }

        updateCopylistPositions()
    }

    function updateCopylistPositions() {
        if (!scratchpadInput || parsedCopylistLines.length === 0)
            return

        const rawSelectionStart = scratchpadInput.selectionStart
        const rawSelectionEnd = scratchpadInput.selectionEnd
        const selectionStart = rawSelectionStart === -1 ? scratchpadInput.cursorPosition : rawSelectionStart
        const selectionEnd = rawSelectionEnd === -1 ? scratchpadInput.cursorPosition : rawSelectionEnd
        const rangeStart = Math.min(selectionStart, selectionEnd)
        const rangeEnd = Math.max(selectionStart, selectionEnd)

        const entries = parsedCopylistLines.map(line => {
            const caretIntersects = rangeEnd > line.start && rangeStart <= line.end
            if (caretIntersects)
                return null
            const startRect = scratchpadInput.positionToRectangle(line.start)
            let endRect = scratchpadInput.positionToRectangle(line.end)
            if (!isFinite(startRect.y))
                return null
            if (!isFinite(endRect.y))
                endRect = startRect
            const lineBottom = endRect.y + endRect.height
            const rectHeight = Math.max(lineBottom - startRect.y, scratchpadInput.font.pixelSize + 8)
            return {
                content: line.content,
                y: startRect.y,
                height: rectHeight
            }
        }).filter(entry => entry !== null)

        copylistEntries = entries
    }

    PanelWindow {
        id: scratchpadWindow
        screen: Quickshell.primaryScreen ? Quickshell.primaryScreen
                                         : (Quickshell.screens.length > 0 ? Quickshell.screens[0] : null)
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        exclusiveZone: 0
        implicitWidth: panelWidth + Appearance.sizes.elevationMargin * 2
        implicitHeight: panelHeight + Appearance.sizes.elevationMargin * 2
        WlrLayershell.namespace: "quickshell:scratchpad"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
        visible: GlobalStates.scratchpadOpen || scratchpadBackground.opacity > 0.01

        readonly property real openMargin: (Config.options.bar.bottom ? Appearance.sizes.hyprlandGapsOut + Appearance.sizes.elevationMargin
                                                                     : Appearance.sizes.barHeight + Appearance.sizes.hyprlandGapsOut + Appearance.sizes.elevationMargin)
        readonly property real hiddenMargin: -panelHeight - Appearance.sizes.barHeight - Appearance.sizes.elevationMargin * 2
        property real topOffset: GlobalStates.scratchpadOpen ? openMargin : hiddenMargin

        anchors {
            top: true
            right: true
        }

        margins {
            top: scratchpadWindow.topOffset
            right: Appearance.sizes.hyprlandGapsOut
        }

        Behavior on topOffset {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }

        mask: Region {
            item: scratchpadBackground
        }

        StyledRectangularShadow {
            target: scratchpadBackground
        }

        Rectangle {
            id: scratchpadBackground
            anchors {
                top: parent.top
                right: parent.right
                topMargin: Appearance.sizes.elevationMargin
                rightMargin: Appearance.sizes.elevationMargin
            }
            width: panelWidth
            height: panelHeight
            radius: Appearance.rounding.windowRounding
            color: Appearance.colors.colLayer0
            border.width: 1
            border.color: Appearance.colors.colLayer0Border
            opacity: GlobalStates.scratchpadOpen ? 1 : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: 120
                    easing.type: Easing.OutQuad
                }
            }

            ColumnLayout {
                id: scratchpadLayout
                anchors {
                    fill: parent
                    margins: panelPadding
                }
                spacing: 14
                Layout.fillHeight: true

                ScrollView {
                    id: editorScrollView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.bottomMargin: 10
                    clip: true
                    ScrollBar.vertical.policy: ScrollBar.AsNeeded
                    onWidthChanged: root.scheduleCopylistUpdate(true)

                    StyledTextArea {
                        id: scratchpadInput
                        wrapMode: TextEdit.Wrap
                        placeholderText: Translation.tr("Write...")
                        selectByMouse: true
                        persistentSelection: true
                        textFormat: TextEdit.PlainText
                        background: null
                        rightPadding: 44
                        Keys.onPressed: (event) => {
                            if (event.key === Qt.Key_Escape && event.modifiers === Qt.NoModifier) {
                                GlobalStates.scratchpadOpen = false
                                event.accepted = true
                                return
                            }
                        }
                        onTextChanged: {
                            if (scratchpadInput.activeFocus) {
                                saveDebounce.restart()
                            }
                            root.scheduleCopylistUpdate(true)
                        }
                        onCursorPositionChanged: root.scheduleCopylistUpdate()
                        onSelectionStartChanged: root.scheduleCopylistUpdate()
                        onSelectionEndChanged: root.scheduleCopylistUpdate()
                        onHeightChanged: root.scheduleCopylistUpdate(true)
                        onContentHeightChanged: root.scheduleCopylistUpdate(true)
                    }

                    Item {
                        anchors.fill: scratchpadInput
                        visible: copylistEntries.length > 0
                        clip: true

                        Repeater {
                            model: copylistEntries
                            delegate: Item {
                                readonly property real lineHeight: Math.max(modelData.height, Appearance.font.pixelSize.normal + 6)
                                readonly property real iconSizeLocal: Appearance.font.pixelSize.normal
                                readonly property real hitPadding: 6

                                width: iconSizeLocal + hitPadding * 2
                                height: lineHeight
                                y: modelData.y
                                x: Math.max(scratchpadInput.width - width - 8, 0)
                                z: 5

                                Rectangle {
                                    id: feedbackFlash
                                    anchors.centerIn: iconItem
                                    width: iconSizeLocal + hitPadding
                                    height: width
                                    radius: width / 2
                                    color: Appearance.colors.colLayer2
                                    opacity: 0
                                    z: -1
                                }

                                MaterialSymbol {
                                    id: iconItem
                                    anchors.centerIn: parent
                                    text: "content_copy"
                                    iconSize: iconSizeLocal
                                    color: Appearance.colors.colOnLayer1
                                    opacity: mouseArea.containsMouse ? 1 : 0.85
                                    scale: 1
                                    Behavior on scale {
                                        NumberAnimation {
                                            duration: 120
                                            easing.type: Easing.OutQuad
                                        }
                                    }
                                    Behavior on opacity {
                                        NumberAnimation {
                                            duration: 120
                                        }
                                    }
                                }

                                MouseArea {
                                    id: mouseArea
                                    anchors.fill: parent
                                    anchors.margins: hitPadding
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onPressed: iconItem.scale = 0.85
                                    onReleased: iconItem.scale = 1
                                    onCanceled: iconItem.scale = 1
                                    onClicked: {
                                        feedbackFlash.opacity = 0.6
                                        feedbackFade.restart()
                                        Quickshell.clipboardText = modelData.content
                                    }
                                }

                                NumberAnimation {
                                    id: feedbackFade
                                    target: feedbackFlash
                                    property: "opacity"
                                    to: 0
                                    duration: 200
                                    easing.type: Easing.OutQuad
                                }
                            }
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Appearance.font.pixelSize.small + 8

                    StyledText {
                        id: statusLabel
                        anchors {
                            right: parent.right
                            bottom: parent.bottom
                        }
                        text: saveDebounce.running ? Translation.tr("Saving...") : Translation.tr("Saved")
                        color: saveDebounce.running ? Appearance.colors.colSubtext : Appearance.m3colors.m3outline
                        font.pixelSize: Appearance.font.pixelSize.small
                    }
                }
            }

        }

        Timer {
            id: saveDebounce
            interval: 500
            repeat: false
            onTriggered: saveScratchpad()
        }

        Timer {
            id: copylistDebounce
            interval: 100
            repeat: false
            onTriggered: updateCopylistPositions()
        }

        Connections {
            target: GlobalStates
            function onScratchpadOpenChanged() {
                if (GlobalStates.scratchpadOpen) {
                    pendingReload = true
                    scratchpadFile.reload()
                    Qt.callLater(focusScratchpadAtEnd)
                } else {
                    if (saveDebounce.running) {
                        saveDebounce.stop()
                    }
                    root.updateCopylistPositions()
                    saveScratchpad()
                }
            }
        }

    }

    FileView {
        id: scratchpadFile
        path: Qt.resolvedUrl(Directories.scratchpadPath)
        onLoaded: {
            scratchpadContents = scratchpadFile.text()
            if (scratchpadInput && scratchpadInput.text !== scratchpadContents) {
                const previousCursor = scratchpadInput.cursorPosition
                const previousAnchor = scratchpadInput.selectionStart
                scratchpadInput.text = scratchpadContents
                applySelection(previousCursor, previousAnchor)
            }
            if (pendingReload && GlobalStates.scratchpadOpen) {
                pendingReload = false
                Qt.callLater(focusScratchpadAtEnd)
            }
            Qt.callLater(root.updateCopylistEntries)
        }
        onLoadFailed: (error) => {
            if (error === FileViewError.FileNotFound) {
                scratchpadContents = ""
                scratchpadFile.setText(scratchpadContents)
                if (scratchpadInput)
                    scratchpadInput.text = scratchpadContents
                if (pendingReload && GlobalStates.scratchpadOpen) {
                    pendingReload = false
                    Qt.callLater(focusScratchpadAtEnd)
                }
                Qt.callLater(root.updateCopylistEntries)
            } else {
                console.log("[Scratchpad] Error loading file: " + error)
            }
        }
    }

    IpcHandler {
        target: "scratchpad"

        function toggle(): void {
            GlobalStates.scratchpadOpen = !GlobalStates.scratchpadOpen
        }

        function open(): void {
            GlobalStates.scratchpadOpen = true
        }

        function close(): void {
            GlobalStates.scratchpadOpen = false
        }
    }

    GlobalShortcut {
        name: "scratchpadToggle"
        description: "Toggles dropdown scratchpad"
        onPressed: GlobalStates.scratchpadOpen = !GlobalStates.scratchpadOpen
    }

    GlobalShortcut {
        name: "scratchpadOpen"
        description: "Opens dropdown scratchpad"
        onPressed: GlobalStates.scratchpadOpen = true
    }

    GlobalShortcut {
        name: "scratchpadClose"
        description: "Closes dropdown scratchpad"
        onPressed: GlobalStates.scratchpadOpen = false
    }
}
