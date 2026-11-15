pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import org.kde.syntaxhighlighting

ColumnLayout {
    id: root
    // These are needed on the parent loader
    property bool editing: false
    property bool renderMarkdown: true
    property bool enableMouseSelection: false
    property var segmentContent: ({})
    property var segmentLang: "txt"
    property var messageData: {}
    property bool isPendingCommand: false
    // Command fences carry tool name then state: command:Bash:running, command:Read:done...
    // Either segment can be absent on fences written outside the CLI path
    property var commandFlags: (segmentLang ?? "").split(":").slice(1).filter(s => s.length > 0)
    property bool isCommandRequest: (segmentLang ?? "").split(":")[0] === "command"
    property string commandState: isCommandRequest
        ? (commandFlags.filter(s => StringUtils.commandFenceStates.includes(s)).pop() ?? "")
        : ""
    property string commandToolName: isCommandRequest
        ? (commandFlags.find(s => !StringUtils.commandFenceStates.includes(s)) ?? "Bash")
        : ""
    // Unfinished states keep their token for good, so being live is checked against the message
    // rather than read off the fence. What is left over reads as denied: the command never ran
    readonly property string state: {
        if (commandState === "streaming") {
            return (messageData?.done ?? true) ? "denied" : "streaming";
        }
        if (commandState === "pending"
                && !(isPendingCommand && (messageData?.functionPending ?? false))) {
            return "denied";
        }
        // One that did run is left over only when the shell died before the turn could settle
        // it, which is the same end the CLI strategy gives an interrupted run
        if (commandState === "running" && (messageData?.done ?? true)) {
            return "failed";
        }
        return commandState;
    }
    // Spelled out because the translation extractor only sees literal keys. Streaming shows
    // nothing: there is no state to report yet, and the message has its own loading indicator
    readonly property var commandStateLabels: ({
        "streaming": "",
        "pending": Translation.tr("pending"),
        "running": Translation.tr("running"),
        "done": Translation.tr("done"),
        "failed": Translation.tr("failed"),
        // Labelled for the Reject button that produces it, as the rest of the copy already is
        "denied": Translation.tr("rejected"),
        "answered": Translation.tr("answered"),
    })
    // Written by the CLI strategy: t<epoch milliseconds> while running, d<seconds> once finished
    readonly property double startedAtMs: Number(commandFlags.find(s => /^t\d+$/.test(s))?.slice(1) ?? 0)
    readonly property int finishedSeconds: Number(commandFlags.find(s => /^d\d+$/.test(s))?.slice(1) ?? 0)
    property double clockMs: 0
    readonly property int runningSeconds: (startedAtMs > 0 && clockMs > 0)
        ? Math.max(0, Math.floor((clockMs - startedAtMs) / 1000)) : 0
    readonly property string stateLabel: commandStateLabels[state] ?? state
    readonly property string durationLabel: {
        const seconds = state === "running" ? runningSeconds : finishedSeconds;
        if (["running", "done", "failed"].includes(state) && seconds >= 1)
            return StringUtils.friendlyDurationForSeconds(seconds);
        return "";
    }

    Timer {
        running: root.state === "running" && root.startedAtMs > 0
        interval: 1000
        repeat: true
        triggeredOnStart: true
        // Recomputed from the start rather than counted up, so a dropped tick costs nothing
        onTriggered: root.clockMs = Date.now()
    }
    // Bash runs shell commands; every other tool takes JSON input
    property var displayLang: isCommandRequest
        ? (commandToolName === "Bash" ? "bash" : "json")
        : segmentLang

    // Only command fences carry a log, and only they may be split on the separator a plain
    // block could contain
    readonly property var commandBody: isCommandRequest
        ? StringUtils.splitCommandFenceBody(segmentContent)
        : ({ command: String(segmentContent ?? ""), output: "" })
    readonly property string commandOutput: commandBody.output
    // The strategy prefixes a log it had to cut short; that is a note about the log, not a line of it
    readonly property bool outputTruncated: commandOutput.startsWith("…\n")
    readonly property string outputBody: outputTruncated ? commandOutput.slice(2) : commandOutput
    // Rows rather than lines, so one long line cannot make the peek arbitrarily tall
    readonly property int outputPeekRows: 3
    // Off the laid-out total rather than the cursor rectangle, which is a couple of pixels
    // adrift of the row spacing
    readonly property real outputRowHeight: outputTextEdit.lineCount > 0
        ? outputTextEdit.contentHeight / outputTextEdit.lineCount : 0
    readonly property real outputPeekHeight:
        outputRowHeight * Math.min(outputPeekRows, outputTextEdit.lineCount)
    readonly property bool outputClipped: outputTextEdit.lineCount > outputPeekRows
    readonly property var outputLineStarts: StringUtils.lineStartOffsets(outputBody)
    readonly property int outputLineCount: outputLineStarts.length
    function outputRowOf(offset) {
        if (outputRowHeight <= 0) return 0;
        // Width read so a rewrap resettles every line
        return Math.round((outputTextEdit.width, outputTextEdit.positionToRectangle(offset).y)
            / outputRowHeight);
    }
    // The line the peek's last row belongs to is a line you can read, so it counts as shown
    readonly property int hiddenOutputLines: outputClipped
        ? outputLineCount - outputLineStarts.filter(s => outputRowOf(s) < outputPeekRows).length
        : 0
    property bool outputExpanded: false

    property real codeBlockBackgroundRounding: Appearance.rounding.small
    property real codeBlockHeaderPadding: 3
    property real codeBlockComponentSpacing: 2
    // The log has no TextArea padding of its own, so its band and gutter share this
    property real outputBandPadding: 6

    spacing: codeBlockComponentSpacing

    component HeaderDot: Rectangle {
        implicitWidth: 4
        implicitHeight: 4
        radius: implicitWidth / 2
        color: Appearance.colors.colOnLayer1Inactive
    }

    component LineNumberColumn: Rectangle {
        id: gutter
        required property var textItem
        // Matches the band's own top padding, so numbers share the rows' baselines
        property real contentInset: 0
        // Bands with something under the text set this to the text's own height, so numbers
        // stop where it does rather than at the band's bottom edge
        property real contentHeight: gutter.height - gutter.contentInset * 2

        implicitWidth: 40
        Layout.fillHeight: true
        Layout.fillWidth: false
        topLeftRadius: Appearance.rounding.unsharpen
        topRightRadius: Appearance.rounding.unsharpen
        bottomLeftRadius: Appearance.rounding.unsharpen
        bottomRightRadius: Appearance.rounding.unsharpen
        color: Appearance.colors.colLayer2

        Item {
            // Clips here rather than on the gutter, whose padding leaves room below the last row
            clip: true
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.rightMargin: 5
            y: gutter.contentInset
            height: gutter.contentHeight

            Repeater {
                // Wrapped lines share one number, so this walks lines rather than rows
                model: StringUtils.lineStartOffsets(gutter.textItem.text)
                Text {
                    required property int index
                    required property var modelData
                    anchors.right: parent.right
                    // Width referenced so rewrapping recomputes each line's y
                    y: (gutter.textItem.width, gutter.textItem.positionToRectangle(modelData).y)
                    font.family: Appearance.font.family.monospace
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                    horizontalAlignment: Text.AlignRight
                    text: index + 1
                }
            }
        }
    }

    Rectangle { // Code background
        Layout.fillWidth: true
        topLeftRadius: codeBlockBackgroundRounding
        topRightRadius: codeBlockBackgroundRounding
        bottomLeftRadius: Appearance.rounding.unsharpen
        bottomRightRadius: Appearance.rounding.unsharpen
        color: Appearance.colors.colSurfaceContainerHighest
        implicitHeight: codeBlockTitleBarRowLayout.implicitHeight + codeBlockHeaderPadding * 2

        RowLayout { // Language and buttons
            id: codeBlockTitleBarRowLayout
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: codeBlockHeaderPadding
            anchors.rightMargin: codeBlockHeaderPadding
            spacing: 5

            RowLayout {
                Layout.alignment: Qt.AlignLeft
                Layout.topMargin: 7
                Layout.bottomMargin: 7
                Layout.leftMargin: 10
                spacing: 6

                StyledText {
                    id: codeBlockLanguage
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer2
                    text: root.isCommandRequest
                        ? root.commandToolName
                        : (root.displayLang ? Repository.definitionForName(root.displayLang).name : "plain")
                }
                HeaderDot {
                    visible: root.stateLabel.length > 0
                }
                StyledText {
                    visible: root.stateLabel.length > 0
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.DemiBold
                    color: ["denied", "failed"].includes(root.state)
                        ? Appearance.colors.colTertiary
                        : Appearance.colors.colSubtext
                    text: root.stateLabel
                }
                HeaderDot {
                    visible: root.durationLabel.length > 0
                }
                StyledText {
                    visible: root.durationLabel.length > 0
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colSubtext
                    text: root.durationLabel
                }
            }

            Item { Layout.fillWidth: true }

            ButtonGroup {
                AiMessageCopyButton {
                    copyText: root.commandBody.command
                    tooltipText: Translation.tr("Copy code")
                }
                AiMessageSaveButton {
                    saveText: root.commandBody.command
                    fileName: `code.${root.displayLang || "txt"}`
                    notificationTitle: Translation.tr("Code saved to file")
                }
            }
        }
    }

    RowLayout { // Line numbers and code
        Layout.fillWidth: true
        spacing: codeBlockComponentSpacing

        LineNumberColumn {
            textItem: codeTextArea
            bottomLeftRadius: root.commandOutput.length > 0
                ? Appearance.rounding.unsharpen
                : codeBlockBackgroundRounding
        }

        Rectangle { // Code background
            Layout.fillWidth: true
            topLeftRadius: Appearance.rounding.unsharpen
            bottomLeftRadius: Appearance.rounding.unsharpen
            topRightRadius: Appearance.rounding.unsharpen
            bottomRightRadius: root.commandOutput.length > 0
                ? Appearance.rounding.unsharpen
                : codeBlockBackgroundRounding
            color: Appearance.colors.colLayer2
            implicitHeight: codeColumnLayout.implicitHeight

            ColumnLayout {
                id: codeColumnLayout
                anchors.fill: parent
                spacing: 0
                TextArea { // Code
                    id: codeTextArea
                    Layout.fillWidth: true
                    readOnly: !editing
                    selectByMouse: enableMouseSelection || editing
                    renderType: Text.NativeRendering
                    font.family: Appearance.font.family.monospace
                    font.hintingPreference: Font.PreferNoHinting // Prevent weird bold text
                    font.pixelSize: Appearance.font.pixelSize.small
                    selectedTextColor: Appearance.m3colors.m3onSecondaryContainer
                    selectionColor: Appearance.colors.colSecondaryContainer
                    wrapMode: TextEdit.Wrap
                    color: messageData.thinking ? Appearance.colors.colSubtext : Appearance.colors.colOnLayer1

                    text: root.commandBody.command
                    // Output is not editable, but it has to survive an edit of the command
                    onTextChanged: {
                        segmentContent = root.commandOutput.length > 0
                            ? `${text}\n${StringUtils.commandOutputSeparator}\n${root.commandOutput}`
                            : text
                    }

                    Keys.onPressed: (event) => {
                        if (event.key === Qt.Key_Tab) {
                            // Insert 4 spaces at cursor
                            const cursor = codeTextArea.cursorPosition;
                            codeTextArea.insert(cursor, "    ");
                            codeTextArea.cursorPosition = cursor + 4;
                            event.accepted = true;
                        } else if ((event.key === Qt.Key_C) && event.modifiers == Qt.ControlModifier) {
                            codeTextArea.copy();
                            event.accepted = true;
                        }
                    }

                    SyntaxHighlighter {
                        id: highlighter
                        textEdit: codeTextArea
                        repository: Repository
                        definition: Repository.definitionForName(root.displayLang || "plaintext")
                        theme: Appearance.syntaxHighlightingTheme
                    }
                }
                Loader {
                    active: root.isCommandRequest && root.isPendingCommand && root.messageData.functionPending
                    visible: active
                    Layout.fillWidth: true
                    Layout.margins: 6
                    Layout.topMargin: 0
                    sourceComponent: RowLayout {
                        Item { Layout.fillWidth: true }
                        ButtonGroup {
                            GroupButton {
                                // The default hover (colLayer1Hover) is invisible on the
                                // block's colLayer2 background
                                colBackgroundHover: Appearance.colors.colLayer2Hover
                                colBackgroundActive: Appearance.colors.colLayer2Active
                                contentItem: StyledText {
                                    text: Translation.tr("Reject")
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    color: Appearance.colors.colOnLayer2
                                }
                                onClicked: Ai.rejectCommand(root.messageData)
                            }
                            GroupButton {
                                toggled: true
                                contentItem: StyledText {
                                    text: Translation.tr("Approve")
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    color: Appearance.colors.colOnPrimary
                                }
                                onClicked: Ai.approveCommand(root.messageData)
                            }
                        }
                    }
                }
            }
        }
    }

    Rectangle { // Output header, styled like the block's own title bar
        visible: root.commandOutput.length > 0
        Layout.fillWidth: true
        radius: Appearance.rounding.unsharpen
        color: Appearance.colors.colSurfaceContainerHighest
        implicitHeight: outputHeaderRowLayout.implicitHeight + codeBlockHeaderPadding * 2

        RowLayout {
            id: outputHeaderRowLayout
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: codeBlockHeaderPadding
            anchors.rightMargin: codeBlockHeaderPadding
            spacing: 5

            RowLayout {
                Layout.alignment: Qt.AlignLeft
                Layout.topMargin: 7
                Layout.bottomMargin: 7
                Layout.leftMargin: 10
                spacing: 6

                StyledText {
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer2
                    text: Translation.tr("Output")
                }
                HeaderDot {}
                StyledText {
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colSubtext
                    // Spelled out per case: the translation extractor only sees literal keys
                    text: root.outputLineCount === 1
                        ? Translation.tr("1 line")
                        : Translation.tr("%1 lines").arg(root.outputLineCount)
                }
                HeaderDot {
                    visible: root.outputTruncated
                }
                StyledText {
                    visible: root.outputTruncated
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colSubtext
                    text: Translation.tr("truncated")
                }
            }

            Item { Layout.fillWidth: true }

            ButtonGroup {
                AiMessageCopyButton {
                    copyText: root.outputBody
                    tooltipText: Translation.tr("Copy output")
                }
                AiMessageSaveButton {
                    saveText: root.outputBody
                    fileName: "output.log"
                    notificationTitle: Translation.tr("Output saved to file")
                }
            }
        }
    }

    RowLayout { // Line numbers and output
        visible: root.commandOutput.length > 0
        Layout.fillWidth: true
        spacing: codeBlockComponentSpacing

        LineNumberColumn {
            textItem: outputTextEdit
            contentInset: root.outputBandPadding
            contentHeight: outputCollapsibleContent.implicitHeight
            bottomLeftRadius: codeBlockBackgroundRounding
        }

        Rectangle { // Command output
            Layout.fillWidth: true
            topLeftRadius: Appearance.rounding.unsharpen
            topRightRadius: Appearance.rounding.unsharpen
            bottomLeftRadius: Appearance.rounding.unsharpen
            bottomRightRadius: codeBlockBackgroundRounding
            color: Appearance.colors.colLayer2
            implicitHeight: outputColumnLayout.implicitHeight + root.outputBandPadding * 2

            ColumnLayout {
                id: outputColumnLayout
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: root.outputBandPadding
                // Lines up with the command above, which shares this column
                anchors.leftMargin: codeTextArea.leftPadding
                anchors.rightMargin: codeTextArea.rightPadding
                spacing: 4

                CollapsibleContent {
                    id: outputCollapsibleContent
                    collapsed: !root.outputExpanded
                    contentHeight: outputTextEdit.implicitHeight
                    collapsedHeight: Math.min(contentHeight, root.outputPeekHeight)

                    TextEdit {
                        id: outputTextEdit
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        readOnly: true
                        selectByMouse: root.enableMouseSelection || root.editing
                        renderType: Text.NativeRendering
                        font.family: Appearance.font.family.monospace
                        font.hintingPreference: Font.PreferNoHinting
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnLayer1
                        selectedTextColor: Appearance.m3colors.m3onSecondaryContainer
                        selectionColor: Appearance.colors.colSecondaryContainer
                        wrapMode: TextEdit.Wrap
                        text: root.outputBody
                    }
                }

                GroupButton {
                    visible: root.outputClipped
                    // Outside a ButtonGroup this defaults to filling the whole band
                    Layout.fillWidth: false
                    Layout.alignment: Qt.AlignLeft
                    buttonRadius: Appearance.rounding.full
                    // The default hover (colLayer1Hover) is invisible on the band's colLayer2
                    colBackgroundHover: Appearance.colors.colLayer2Hover
                    colBackgroundActive: Appearance.colors.colLayer2Active
                    contentItem: StyledText {
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colOnLayer1
                        // Spelled out per case: the translation extractor only sees literal keys.
                        // What is cut can be the tail of a line, which has no honest count
                        text: root.outputExpanded ? Translation.tr("Show less")
                            : root.hiddenOutputLines === 0 ? Translation.tr("Show more")
                            : root.hiddenOutputLines === 1 ? Translation.tr("+1 more line")
                            : Translation.tr("+%1 more lines").arg(root.hiddenOutputLines)
                    }
                    onClicked: root.outputExpanded = !root.outputExpanded
                }
            }
        }
    }
}