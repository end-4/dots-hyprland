import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.overlay

OverlayBackground {
    id: root

    property alias stickypadContents: stickypadInput.text
    property bool pendingReload: false
    property var copyListEntries: []
    property string lastParsedCopylistText: ""
    property var parsedCopylistLines: []
    property bool isClickthrough: false

    Component.onCompleted: {
        stickypadFile.reload();
        updateCopyListEntries();
    }

    function saveStickypad() {
        if (!stickypadInput)
            return;
        stickypadFile.setText(root.stickypadContents);
    }

    function focusStickypadAtEnd() {
        if (!stickypadInput)
            return;
        stickypadInput.forceActiveFocus();
        const endPos = root.stickypadContents.length;
        applySelection(endPos, endPos);
    }

    function applySelection(cursorPos, anchorPos) {
        if (!stickypadInput)
            return;
        const textLength = root.stickypadContents.length;
        const cursor = Math.max(0, Math.min(cursorPos, textLength));
        const anchor = Math.max(0, Math.min(anchorPos, textLength));
        stickypadInput.select(anchor, cursor);
        if (cursor === anchor)
            stickypadInput.deselect();
    }

    function scheduleCopylistUpdate(immediate = false) {
        if (!stickypadInput)
            return;
        if (immediate) {
            copyListDebounce?.stop();
            updateCopyListEntries();
        } else {
            copyListDebounce.restart();
        }
    }

    function updateCopyListEntries() {
        if (!stickypadInput)
            return;
        const textValue = root.stickypadContents;
        if (!textValue || textValue.length === 0) {
            lastParsedCopylistText = "";
            parsedCopylistLines = [];
            root.copyListEntries = [];
            return;
        }

        if (textValue !== lastParsedCopylistText) {
            const lineRegex = /(.*?)(\r?\n|$)/g;
            let match = null;
            const parsed = [];
            while ((match = lineRegex.exec(textValue)) !== null) {
                const lineText = match[1];
                const newlineText = match[2];
                const lineStart = match.index;
                const lineEnd = lineStart + lineText.length;
                const bulletMatch = lineText.match(/^\s*-\s+(.*\S)\s*$/);
                if (bulletMatch) {
                    parsed.push({
                        content: bulletMatch[1].trim(),
                        start: lineStart,
                        end: lineEnd
                    });
                }
                if (newlineText === "")
                    break;
            }
            lastParsedCopylistText = textValue;
            parsedCopylistLines = parsed;
            if (parsed.length === 0) {
                root.copyListEntries = [];
                return;
            }
        }

        updateCopylistPositions();
    }

    function updateCopylistPositions() {
        if (!stickypadInput || parsedCopylistLines.length === 0)
            return;
        const rawSelectionStart = stickypadInput.selectionStart;
        const rawSelectionEnd = stickypadInput.selectionEnd;
        const selectionStart = rawSelectionStart === -1 ? stickypadInput.cursorPosition : rawSelectionStart;
        const selectionEnd = rawSelectionEnd === -1 ? stickypadInput.cursorPosition : rawSelectionEnd;
        const rangeStart = Math.min(selectionStart, selectionEnd);
        const rangeEnd = Math.max(selectionStart, selectionEnd);

        const entries = parsedCopylistLines.map(line => {
            const caretIntersects = rangeEnd > line.start && rangeStart <= line.end;
            if (caretIntersects)
                return null;
            const startRect = stickypadInput.positionToRectangle(line.start);
            let endRect = stickypadInput.positionToRectangle(line.end);
            if (!isFinite(startRect.y))
                return null;
            if (!isFinite(endRect.y))
                endRect = startRect;
            const lineBottom = endRect.y + endRect.height;
            const rectHeight = Math.max(lineBottom - startRect.y, stickypadInput.font.pixelSize + 8);
            return {
                content: line.content,
                y: startRect.y,
                height: rectHeight
            };
        }).filter(entry => entry !== null);

        root.copyListEntries = entries;
    }

    ColumnLayout {
        id: stickypadLayout
        anchors.fill: parent
        spacing: 0

        ScrollView {
            id: editorScrollView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            ScrollBar.vertical.policy: ScrollBar.AsNeeded
            onWidthChanged: root.scheduleCopylistUpdate(true)

            StyledTextArea {
                id: stickypadInput
                anchors {
                    left: parent.left
                    right: parent.right
                }
                wrapMode: TextEdit.Wrap
                placeholderText: Translation.tr("Write something here...\nUse '-' to create copyable bullet points, like this:\n\nSheep fricker\n- 4x Slab\n- 1x Boat\n- 4x Redstone Dust\n- 1x Sticky Piston\n- 1x End Rod\n- 4x Redstone Repeater\n- 1x Redstone Torch\n- 1x Sheep")
                selectByMouse: true
                persistentSelection: true
                textFormat: TextEdit.PlainText
                background: null
                padding: 16
                rightPadding: 44 + padding

                onTextChanged: {
                    if (stickypadInput.activeFocus) {
                        saveDebounce.restart();
                    }
                    root.scheduleCopylistUpdate(true);
                }
                
                onHeightChanged: root.scheduleCopylistUpdate(true)
                onContentHeightChanged: root.scheduleCopylistUpdate(true)
            }

            Item {
                anchors.fill: stickypadInput
                visible: root.copyListEntries.length > 0
                clip: true

                Repeater {
                    model: ScriptModel {
                        values: root.copyListEntries
                    }
                    delegate: Item {
                        readonly property real lineHeight: Math.max(modelData.height, Appearance.font.pixelSize.normal + 6)
                        readonly property real iconSizeLocal: Appearance.font.pixelSize.normal
                        readonly property real hitPadding: 6

                        width: iconSizeLocal + hitPadding * 2
                        height: lineHeight
                        y: modelData.y
                        x: Math.max(stickypadInput.width - width - 8, 0)
                        z: 5

                        Rectangle {
                            id: feedbackFlash
                            anchors.centerIn: iconItem
                            width: iconSizeLocal + hitPadding
                            height: width
                            radius: width / 2
                            color: Appearance.colors.colLayer2
                            opacity: 0
                            z: 999
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
                                feedbackFlash.opacity = 0.6;
                                feedbackFade.restart();
                                Quickshell.clipboardText = modelData.content;
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

        StyledText {
            id: statusLabel
            Layout.fillWidth: true
            Layout.margins: 16
            horizontalAlignment: Text.AlignRight
            text: saveDebounce.running ? Translation.tr("Saving...") : Translation.tr("Saved    ")
            color: Appearance.colors.colSubtext
        }
    }

    Timer {
        id: saveDebounce
        interval: 500
        repeat: false
        onTriggered: saveStickypad()
    }

    Timer {
        id: copyListDebounce
        interval: 100
        repeat: false
        onTriggered: updateCopylistPositions()
    }

    FileView {
        id: stickypadFile
        path: Qt.resolvedUrl(Directories.stickypadPath)
        onLoaded: {
            root.stickypadContents = stickypadFile.text();
            if (root.stickypadContents !== root.stickypadContents) {
                const previousCursor = stickypadInput.cursorPosition;
                const previousAnchor = stickypadInput.selectionStart;
                root.stickypadContents = root.stickypadContents;
                applySelection(previousCursor, previousAnchor);
            }
            if (pendingReload) {
                pendingReload = false;
                Qt.callLater(root.focusStickypadAtEnd);
            }
            Qt.callLater(root.updateCopyListEntries);
        }
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                root.stickypadContents = "";
                stickypadFile.setText(root.stickypadContents);
                if (pendingReload) {
                    pendingReload = false;
                    Qt.callLater(root.focusStickypadAtEnd);
                }
                Qt.callLater(root.updateCopyListEntries);
            } else {
                console.log("[Stickypad] Error loading file: " + error);
            }
        }
    }
}
