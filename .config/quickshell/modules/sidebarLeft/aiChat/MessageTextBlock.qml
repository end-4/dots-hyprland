pragma ComponentBehavior: Bound

import "root:/"
import "root:/services"
import "root:/modules/common/"
import "root:/modules/common/widgets"
import "../"
import "root:/modules/common/functions/string_utils.js" as StringUtils
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland
import Qt5Compat.GraphicalEffects

ColumnLayout {
    id: root
    // These are needed on the parent loader
    property bool editing: parent?.editing ?? false
    property bool renderMarkdown: parent?.renderMarkdown ?? true
    property bool enableMouseSelection: parent?.enableMouseSelection ?? false
    property string segmentContent: parent?.segmentContent ?? ({})
    property var messageData: parent?.messageData ?? {}
    property bool done: parent?.done ?? true
    property list<string> renderedLatexHashes: []

    property string renderedSegmentContent: ""

    Layout.fillWidth: true

    Timer {
        id: renderTimer
        interval: 1000
        repeat: false
        onTriggered: {
            renderLatex()
            for (const hash of renderedLatexHashes) {
                handleRenderedLatex(hash, true);
            }
        }
    }

    function renderLatex() {
        // Regex for $...$, $$...$$, \[...\]
        // Note: This is a simple approach and may need refinement for edge cases
        let regex = /(\$\$([\s\S]+?)\$\$)|(\$([^\$]+?)\$)|(\\\[((?:.|\n)+?)\\\])|(\\\(([\s\S]+?)\\\))/g;
        let match;
        while ((match = regex.exec(segmentContent)) !== null) {
            let expression = match[1] || match[2] || match[3] || match[4] || match[5] || match[6] || match[7] || match[8];
            if (expression) {
                Qt.callLater(() => {
                    const [renderHash, isNew] = LatexRenderer.requestRender(expression.trim());
                    if (!renderedLatexHashes.includes(renderHash)) {
                        renderedLatexHashes.push(renderHash);
                    }
                });
            }
        }
    }

    function handleRenderedLatex(hash, force = false) {
        if (renderedLatexHashes.includes(hash) || force) {
            const imagePath = LatexRenderer.renderedImagePaths[hash];
            const markdownImage = `![latex](${imagePath})`;

            const expression = LatexRenderer.processedExpressions[hash];
            renderedSegmentContent = renderedSegmentContent.replace(expression, markdownImage);
        }
    }

    onDoneChanged: {
        renderTimer.restart();
    }
    onEditingChanged: {
        if (!editing) {
            renderLatex()
        } else {
            // console.log("Editing mode enabled", segmentContent)
            textArea.text = segmentContent
        }
    }

    onSegmentContentChanged: {
        // console.log("Segment content changed: " + segmentContent);
        renderedSegmentContent = segmentContent;
        if (!root.editing && segmentContent) {
            root.renderLatex();
        }
    }

    onRenderedSegmentContentChanged: {
        // console.log("Rendered segment content changed: " + renderedSegmentContent);
        if (renderedSegmentContent) {
            textArea.text = renderedSegmentContent;
        }
    }

    // When something finishes rendering
    // 1. Check if the hash is in the list
    // 2. If it is, replace the expression with the image path
    Connections {
        target: LatexRenderer
        function onRenderFinished(hash, imagePath) {
            const expression = LatexRenderer.processedExpressions[hash];
            // console.log("Render finished: " + hash + " " + expression);
            handleRenderedLatex(hash);
        }
    }

    TextArea {
        id: textArea

        Layout.fillWidth: true
        readOnly: !editing
        selectByMouse: enableMouseSelection || editing
        renderType: Text.NativeRendering
        font.family: Appearance.font.family.reading
        font.hintingPreference: Font.PreferNoHinting // Prevent weird bold text
        font.pixelSize: Appearance.font.pixelSize.small
        selectedTextColor: Appearance.m3colors.m3onSecondaryContainer
        selectionColor: Appearance.colors.colSecondaryContainer
        wrapMode: TextEdit.Wrap
        color: messageData.thinking ? Appearance.colors.colSubtext : Appearance.colors.colOnLayer1
        textFormat: renderMarkdown ? TextEdit.MarkdownText : TextEdit.PlainText
        text: qsTr("Waiting for response...")

        onTextChanged: {
            if (!root.editing) return
            segmentContent = text
        }

        onLinkActivated: (link) => {
            Qt.openUrlExternally(link)
            Hyprland.dispatch("global quickshell:sidebarLeftClose")
        }

        MouseArea { // Pointing hand for links
            anchors.fill: parent
            acceptedButtons: Qt.NoButton // Only for hover
            hoverEnabled: true
            cursorShape: parent.hoveredLink !== "" ? Qt.PointingHandCursor : 
                (enableMouseSelection || editing) ? Qt.IBeamCursor : Qt.ArrowCursor
        }
    }
}
