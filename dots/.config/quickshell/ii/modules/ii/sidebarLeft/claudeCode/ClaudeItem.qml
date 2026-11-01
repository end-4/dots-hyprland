pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.ii.sidebarLeft.aiChat
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

/**
 * One chat item from cc-host: user | text | thinking | tool | permission |
 * peer | system | result. Subagent items (depth 1) are indented.
 */
Item {
    id: root
    required property var item
    property bool showHeader: false

    readonly property bool assistantKind: ["text", "thinking", "tool", "permission"].includes(root.item?.kind)
    // Housekeeping tools: their effect already shows in the task list
    readonly property bool minorTool: root.item?.kind === "tool" && !root.item.permission && ["TaskCreate", "TaskUpdate", "TaskList", "TaskGet", "ToolSearch"].includes(root.item.name)

    implicitHeight: column.implicitHeight
    implicitWidth: column.implicitWidth

    ColumnLayout {
        id: column
        anchors {
            left: parent.left
            right: parent.right
        }
        spacing: 6

        Header { // First item of a reply
            visible: root.showHeader && root.assistantKind && (root.item?.depth ?? 0) === 0
            Layout.leftMargin: 7
            Layout.rightMargin: 7
            Layout.topMargin: 7
            iconSource: "claude-symbolic"
            label: ClaudeCode.activeMeta?.model ? `Claude · ${ClaudeCode.activeMeta.model}` : "Claude"
        }

    Loader {
        id: loader
        Layout.fillWidth: true
        Layout.leftMargin: (root.item?.depth ?? 0) * 14
        sourceComponent: {
            switch (root.item?.kind) {
            case "user":
                return userComponent;
            case "text":
                return textComponent;
            case "thinking":
                return thinkingComponent;
            case "tool":
                return root.minorTool ? minorToolComponent : toolComponent;
            case "permission":
                return permissionComponent;
            case "peer":
                return peerComponent;
            case "result":
                return resultComponent;
            default:
                return systemComponent;
            }
        }
    }
    }

    // ---------- shared pieces ----------

    component Header: Rectangle {
        id: header
        property string icon
        property string iconSource // an icon file in assets/icons, shown in Claude's orange
        property string label
        Layout.fillWidth: true
        implicitHeight: Math.max(headerRow.implicitHeight + 5 * 2, 30) + 4 * 2
        color: Appearance.colors.colSecondaryContainer
        radius: Appearance.rounding.small
        RowLayout {
            id: headerRow
            anchors {
                verticalCenter: parent.verticalCenter
                left: parent.left
                right: parent.right
                leftMargin: 14
                rightMargin: 14
            }
            spacing: 12
            MaterialSymbol {
                visible: !header.iconSource
                text: header.icon
                iconSize: Appearance.font.pixelSize.larger
                color: Appearance.m3colors.m3onSecondaryContainer
            }
            CustomIcon {
                visible: !!header.iconSource
                width: Appearance.font.pixelSize.larger
                height: Appearance.font.pixelSize.larger
                source: header.iconSource
                colorize: true
                color: "#D97757"
            }
            StyledText {
                Layout.fillWidth: true
                text: header.label
                elide: Text.ElideRight
                font.pixelSize: Appearance.font.pixelSize.normal
                color: Appearance.m3colors.m3onSecondaryContainer
            }
        }
    }

    component Markdown: ColumnLayout {
        id: md
        property string content
        property bool done: true
        readonly property var messageData: ({
                done: md.done,
                thinking: false,
                functionPending: false,
                content: md.content
            })
        spacing: 0
        Repeater {
            model: ScriptModel {
                values: StringUtils.splitMarkdownBlocks(md.content)
            }
            delegate: DelegateChooser {
                role: "type"
                DelegateChoice {
                    roleValue: "code"
                    MessageCodeBlock {
                        required property var modelData
                        segmentContent: modelData.content
                        segmentLang: modelData.lang || "txt"
                        messageData: md.messageData
                    }
                }
                DelegateChoice {
                    roleValue: "think"
                    MessageTextBlock {
                        required property var modelData
                        segmentContent: modelData.content
                        messageData: md.messageData
                        done: md.done
                    }
                }
                DelegateChoice {
                    roleValue: "text"
                    MessageTextBlock {
                        required property var modelData
                        segmentContent: modelData.content
                        messageData: md.messageData
                        done: md.done
                        forceDisableChunkSplitting: md.content.includes("```")
                    }
                }
            }
        }
    }

    component PermissionBar: ColumnLayout {
        id: bar
        property var permission // {requestId, description, canAlways, state}
        visible: !!permission
        spacing: 6
        StyledText {
            visible: bar.permission?.state === "pending"
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            text: Translation.tr("Claude wants to use this tool")
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colPrimary
        }
        RowLayout {
            visible: bar.permission?.state === "pending"
            spacing: 6
            DialogButton {
                buttonText: Translation.tr("Allow")
                onClicked: ClaudeCode.answerPermission(bar.permission.requestId, "allow")
            }
            DialogButton {
                visible: bar.permission?.canAlways ?? false
                buttonText: Translation.tr("Always allow")
                onClicked: ClaudeCode.answerPermission(bar.permission.requestId, "always")
            }
            Item {
                Layout.fillWidth: true
            }
            DialogButton {
                buttonText: Translation.tr("Deny")
                colEnabled: Appearance.colors.colError
                onClicked: ClaudeCode.answerPermission(bar.permission.requestId, "deny")
            }
        }
        StyledText {
            visible: bar.permission && bar.permission.state !== "pending"
            text: ({
                    allowed: Translation.tr("Allowed"),
                    always: Translation.tr("Always allowed"),
                    denied: Translation.tr("Denied"),
                    cancelled: Translation.tr("Cancelled")
                })[bar.permission?.state] ?? ""
            font.pixelSize: Appearance.font.pixelSize.smallest
            color: Appearance.colors.colSubtext
        }
    }

    component Mono: StyledText {
        Layout.fillWidth: true
        wrapMode: Text.WrapAnywhere
        textFormat: Text.PlainText
        font.family: Appearance.font.family.monospace
        font.pixelSize: Appearance.font.pixelSize.smaller
        color: Appearance.colors.colOnLayer2
    }

    // ---------- kinds ----------

    Component {
        id: userComponent
        Rectangle {
            implicitHeight: userColumn.implicitHeight + 7 * 2
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer1
            ColumnLayout {
                id: userColumn
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 7
                }
                spacing: 3
                Header {
                    icon: "person"
                    label: SystemInfo.username
                }
                Markdown {
                    Layout.fillWidth: true
                    content: root.item.text + (root.item.images ? `\n\n🖼 ×${root.item.images}` : "")
                }
            }
        }
    }

    Component {
        id: textComponent
        ColumnLayout {
            spacing: 3
            Markdown {
                Layout.fillWidth: true
                Layout.leftMargin: 7
                Layout.rightMargin: 7
                content: root.item.text
                done: root.item.done
            }
        }
    }

    Component {
        id: thinkingComponent
        RowLayout {
            spacing: 6
            Item {
                implicitWidth: 7
            }
            MaterialSymbol {
                text: "psychology"
                iconSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colSubtext
            }
            StyledText {
                Layout.fillWidth: true
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
                text: root.item.done ? (root.item.tokens > 0 ? Translation.tr("Thought · %1 tokens").arg(root.item.tokens) : Translation.tr("Thought")) : (root.item.tokens > 0 ? Translation.tr("Thinking… %1 tokens").arg(root.item.tokens) : Translation.tr("Thinking…"))
            }
        }
    }

    Component {
        id: toolComponent
        Rectangle {
            id: card
            readonly property var tool: root.item
            readonly property bool pending: tool.permission?.state === "pending"
            property bool expanded: pending || (!!tool.diff && tool.status !== "error")
            implicitHeight: toolColumn.implicitHeight + 8 * 2
            radius: Appearance.rounding.small
            color: Appearance.colors.colLayer2
            border.width: pending ? 1 : 0
            border.color: Appearance.colors.colPrimary

            readonly property string icon: ({
                    Bash: "terminal",
                    Read: "description",
                    Write: "edit_document",
                    Edit: "edit_note",
                    MultiEdit: "edit_note",
                    Grep: "search",
                    Glob: "folder_open",
                    WebFetch: "public",
                    WebSearch: "travel_explore",
                    Task: "account_tree",
                    Agent: "account_tree",
                    Skill: "auto_awesome",
                    SendMessage: "forum",
                    ListAgents: "groups",
                    TaskCreate: "add_task",
                    TaskUpdate: "task_alt",
                    TaskList: "checklist",
                    ToolSearch: "manage_search"
                })[tool.name] ?? "build"

            ColumnLayout {
                id: toolColumn
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 8
                }
                spacing: 6

                MouseArea {
                    Layout.fillWidth: true
                    implicitHeight: toolRow.implicitHeight
                    cursorShape: Qt.PointingHandCursor
                    onClicked: card.expanded = !card.expanded
                    RowLayout {
                        id: toolRow
                        anchors.fill: parent
                        spacing: 8
                        MaterialSymbol {
                            text: card.icon
                            iconSize: Appearance.font.pixelSize.larger
                            color: Appearance.colors.colOnLayer2
                        }
                        StyledText {
                            text: card.tool.name
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: Font.DemiBold
                            color: Appearance.colors.colOnLayer2
                        }
                        StyledText {
                            Layout.fillWidth: true
                            text: card.tool.title
                            elide: Text.ElideMiddle
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                        }
                        Item {
                            implicitWidth: 18
                            implicitHeight: 18
                            MaterialLoadingIndicator {
                                anchors.centerIn: parent
                                visible: card.tool.status === "running" && !card.pending
                                implicitSize: 18
                            }
                            MaterialSymbol {
                                anchors.centerIn: parent
                                visible: card.tool.status !== "running" || card.pending
                                text: card.pending ? "front_hand" : ({
                                        ok: "check_circle",
                                        error: "error",
                                        denied: "block"
                                    })[card.tool.status] ?? ""
                                iconSize: Appearance.font.pixelSize.larger
                                fill: 1
                                color: card.pending ? Appearance.colors.colPrimary : card.tool.status === "ok" ? Appearance.colors.colSubtext : Appearance.colors.colError
                            }
                        }
                    }
                }

                Mono { // Command
                    visible: card.expanded && card.tool.name === "Bash" && !!card.tool.input?.command
                    text: "$ " + (card.tool.input?.command ?? "")
                }
                DiffView {
                    Layout.fillWidth: true
                    visible: card.expanded && !!card.tool.diff
                    diff: card.tool.diff
                }
                Rectangle { // Output
                    Layout.fillWidth: true
                    visible: card.expanded && card.tool.output.length > 0 && !card.tool.diff
                    implicitHeight: Math.min(outputText.implicitHeight + 6 * 2, 220)
                    radius: Appearance.rounding.verysmall
                    color: Appearance.colors.colLayer1
                    clip: true
                    Mono {
                        id: outputText
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: 6
                        }
                        text: card.tool.output
                        color: card.tool.status === "ok" ? Appearance.colors.colOnLayer1 : Appearance.colors.colError
                    }
                }
                PermissionBar {
                    Layout.fillWidth: true
                    permission: card.tool.permission ?? null
                }
            }
        }
    }

    Component {
        id: minorToolComponent
        RowLayout {
            spacing: 6
            Item {
                implicitWidth: 7
            }
            MaterialSymbol {
                text: root.item.status === "error" ? "error" : "check_small"
                iconSize: Appearance.font.pixelSize.normal
                color: root.item.status === "error" ? Appearance.colors.colError : Appearance.colors.colSubtext
            }
            StyledText {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: `${root.item.name}  ${root.item.title}`
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
            }
        }
    }

    Component {
        id: permissionComponent
        Rectangle {
            implicitHeight: permColumn.implicitHeight + 8 * 2
            radius: Appearance.rounding.small
            color: Appearance.colors.colLayer2
            border.width: root.item.state === "pending" ? 1 : 0
            border.color: Appearance.colors.colPrimary
            ColumnLayout {
                id: permColumn
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 8
                }
                spacing: 6
                StyledText {
                    Layout.fillWidth: true
                    text: `${root.item.toolName}  ${root.item.title}`
                    elide: Text.ElideMiddle
                    color: Appearance.colors.colOnLayer2
                }
                Mono {
                    visible: root.item.command.length > 0
                    text: "$ " + root.item.command
                }
                DiffView {
                    Layout.fillWidth: true
                    visible: !!root.item.diff
                    diff: root.item.diff
                }
                PermissionBar {
                    Layout.fillWidth: true
                    permission: root.item
                }
            }
        }
    }

    Component {
        id: peerComponent
        Rectangle {
            implicitHeight: peerColumn.implicitHeight + 8 * 2
            radius: Appearance.rounding.small
            color: Appearance.colors.colTertiaryContainer
            ColumnLayout {
                id: peerColumn
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 8
                }
                spacing: 4
                RowLayout {
                    spacing: 6
                    MaterialSymbol {
                        text: "forum"
                        iconSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colOnTertiaryContainer
                    }
                    StyledText {
                        text: Translation.tr("Message from %1").arg(root.item.from)
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colOnTertiaryContainer
                    }
                }
                StyledText {
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    text: root.item.text
                    color: Appearance.colors.colOnTertiaryContainer
                }
            }
        }
    }

    Component {
        id: systemComponent
        StyledText {
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            text: root.item?.text ?? ""
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: root.item?.level === "error" ? Appearance.colors.colError : Appearance.colors.colSubtext
        }
    }

    Component {
        id: resultComponent
        ColumnLayout {
            spacing: 2
            StyledText {
                visible: root.item.text.length > 0
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                text: root.item.text
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colError
            }
            RowLayout {
                Layout.alignment: Qt.AlignRight
                Layout.rightMargin: 7
                spacing: 4
                MaterialSymbol {
                    text: root.item.ok ? "done_all" : "warning"
                    iconSize: Appearance.font.pixelSize.small
                    color: root.item.ok ? Appearance.colors.colSubtext : Appearance.colors.colError
                }
                StyledText {
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    color: Appearance.colors.colSubtext
                    text: {
                        const parts = [`${(root.item.durationMs / 1000).toFixed(1)}s`];
                        if (root.item.turns > 1)
                            parts.push(Translation.tr("%1 turns").arg(root.item.turns));
                        if (root.item.tokens > 0)
                            parts.push(Translation.tr("%1k tokens").arg(Math.round(root.item.tokens / 1000)));
                        return parts.join(" · ");
                    }
                }
            }
        }
    }
}
