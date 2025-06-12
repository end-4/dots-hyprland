pragma ComponentBehavior: Bound

import "root:/"
import "root:/services"
import "root:/modules/common/"
import "root:/modules/common/widgets"
import "../"
import "root:/modules/common/functions/string_utils.js" as StringUtils
import "root:/modules/common/functions/file_utils.js" as FileUtils
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland
import Qt5Compat.GraphicalEffects
import org.kde.syntaxhighlighting

ColumnLayout {
    // These are needed on the parent loader
    property bool editing: parent?.editing ?? false
    property bool renderMarkdown: parent?.renderMarkdown ?? true
    property bool enableMouseSelection: parent?.enableMouseSelection ?? false
    property var segmentContent: parent?.segmentContent ?? ({})
    property var segmentLang: parent?.segmentLang ?? "txt"
    property var messageData: parent?.messageData ?? {}

    property real codeBlockBackgroundRounding: Appearance.rounding.small
    property real codeBlockHeaderPadding: 3
    property real codeBlockComponentSpacing: 2

    spacing: codeBlockComponentSpacing
    anchors.left: parent.left
    anchors.right: parent.right

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

            StyledText {
                id: codeBlockLanguage
                Layout.alignment: Qt.AlignLeft
                Layout.fillWidth: false
                Layout.topMargin: 7
                Layout.bottomMargin: 7
                Layout.leftMargin: 10
                font.pixelSize: Appearance.font.pixelSize.small
                font.weight: Font.DemiBold
                color: Appearance.colors.colOnLayer2
                text: segmentLang ? Repository.definitionForName(segmentLang).name : "plain"
            }

            Item { Layout.fillWidth: true }

            ButtonGroup {
                AiMessageControlButton {
                    id: copyCodeButton
                    buttonIcon: activated ? "inventory" : "content_copy"

                    onClicked: {
                        Hyprland.dispatch(`exec wl-copy '${StringUtils.shellSingleQuoteEscape(segmentContent)}'`)
                        copyCodeButton.activated = true
                        copyIconTimer.restart()
                    }

                    Timer {
                        id: copyIconTimer
                        interval: 1500
                        repeat: false
                        onTriggered: {
                            copyCodeButton.activated = false
                        }
                    }
                    StyledToolTip {
                        content: qsTr("Copy code")
                    }
                }
                AiMessageControlButton {
                    id: saveCodeButton
                    buttonIcon: activated ? "check" : "save"

                    onClicked: {
                        const downloadPath = FileUtils.trimFileProtocol(Directories.downloads)
                        Hyprland.dispatch(`exec echo '${StringUtils.shellSingleQuoteEscape(segmentContent)}' > '${downloadPath}/code.${segmentLang || "txt"}'`)
                        Hyprland.dispatch(`exec notify-send 'Code saved to file' '${downloadPath}/code.${segmentLang || "txt"}' -a Shell`)
                        saveCodeButton.activated = true
                        saveIconTimer.restart()
                    }

                    Timer {
                        id: saveIconTimer
                        interval: 1500
                        repeat: false
                        onTriggered: {
                            saveCodeButton.activated = false
                        }
                    }
                    StyledToolTip {
                        content: qsTr("Save to Downloads")
                    }
                }
            }
        }
    }

    RowLayout { // Line numbers and code
        spacing: codeBlockComponentSpacing

        Rectangle { // Line numbers
            implicitWidth: 40
            Layout.fillHeight: true
            Layout.fillWidth: false
            topLeftRadius: Appearance.rounding.unsharpen
            bottomLeftRadius: codeBlockBackgroundRounding
            topRightRadius: Appearance.rounding.unsharpen
            bottomRightRadius: Appearance.rounding.unsharpen
            color: Appearance.colors.colLayer2

            ColumnLayout {
                id: lineNumberColumnLayout
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.rightMargin: 5
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0
                
                Repeater {
                    model: codeTextArea.text.split("\n").length
                    Text {
                        required property int index
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignRight
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
            topLeftRadius: Appearance.rounding.unsharpen
            bottomLeftRadius: Appearance.rounding.unsharpen
            topRightRadius: Appearance.rounding.unsharpen
            bottomRightRadius: codeBlockBackgroundRounding
            color: Appearance.colors.colLayer2
            implicitHeight: codeTextArea.implicitHeight

            ScrollView {
                id: codeScrollView
                Layout.fillWidth: true
                Layout.fillHeight: true
                implicitWidth: parent.width
                implicitHeight: codeTextArea.implicitHeight + 1
                contentWidth: codeTextArea.width - 1
                // contentHeight: codeTextArea.contentHeight
                clip: true
                ScrollBar.vertical.policy: ScrollBar.AlwaysOff
                
                ScrollBar.horizontal: ScrollBar {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    padding: 5
                    policy: ScrollBar.AsNeeded
                    opacity: visualSize == 1 ? 0 : 1
                    visible: opacity > 0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Appearance.animation.elementMoveFast.duration
                            easing.type: Appearance.animation.elementMoveFast.type
                            easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                        }
                    }
                    
                    contentItem: Rectangle {
                        implicitHeight: 6
                        radius: Appearance.rounding.small
                        color: Appearance.colors.colLayer2Active
                    }
                }

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
                    // wrapMode: TextEdit.Wrap
                    color: messageData.thinking ? Appearance.colors.colSubtext : Appearance.colors.colOnLayer1

                    text: segmentContent
                    onTextChanged: {
                        segmentContent = text
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
                        definition: Repository.definitionForName(segmentLang || "plaintext")
                        theme: Appearance.syntaxHighlightingTheme
                    }
                }
            }

            // MouseArea to block scrolling
            // MouseArea {
            //     id: codeBlockMouseArea
            //     anchors.fill: parent
            //     acceptedButtons: editing ? Qt.NoButton : Qt.LeftButton
            //     cursorShape: (enableMouseSelection || editing) ? Qt.IBeamCursor : Qt.ArrowCursor
            //     onWheel: (event) => {
            //         event.accepted = false
            //     }
            // }
        }
    }
}