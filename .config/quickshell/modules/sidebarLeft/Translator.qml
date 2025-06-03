import "root:/"
import "root:/services"
import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/modules/common/functions/string_utils.js" as StringUtils
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

/**
 * Translator widget with the `trans` commandline tool.
 */
Item {
    id: root
    property var inputField: inputTextArea
    property var outputField: outputTextArea

    property bool translationFor: false // Indicates if the translation is for an autocorrected text
    property string translatedText: ""

    onFocusChanged: (focus) => {
        if (focus) {
            root.inputField.forceActiveFocus()
        }
    }

    Timer {
        id: translateTimer
        interval: ConfigOptions.sidebar.translator.delay
        repeat: false
        onTriggered: () => {
            if (inputTextArea.text.trim().length > 0) {
                translateProc.running = false;
                translateProc.buffer = ""; // Clear the buffer
                translateProc.running = true; // Restart the process
            } else {
                outputTextArea.text = "";
            }
        }
    }

    Process {
        id: translateProc
        command: ["bash", "-c", `trans -no-theme -no-ansi '${StringUtils.shellSingleQuoteEscape(inputTextArea.text.trim())}'`]
        property string buffer: ""
        stdout: SplitParser {
            onRead: data => {
                translateProc.buffer += data + "\n";
            }
        }
        onExited: (exitCode, exitStatus) => {
            // 1. Split into sections by double newlines
            const sections = translateProc.buffer.trim().split(/\n\s*\n/);
            // console.log("BUFFER:", translateProc.buffer);
            // console.log("SECTIONS:", sections);

            // 2. Extract relevant data
            root.translatedText = sections.length > 1 ? sections[1].trim() : "";
            root.outputField.text = root.translatedText;
        }
    }
    
    Flickable {
        anchors.fill: parent
        contentHeight: contentColumn.implicitHeight

        ColumnLayout {
            id: contentColumn
            anchors.fill: parent

            Rectangle { // INPUT
                id: inputCanvas
                Layout.fillWidth: true
                implicitHeight: Math.max(150, inputColumn.implicitHeight)
                color: Appearance.colors.colLayer1
                radius: Appearance.rounding.normal
                border.color: Appearance.m3colors.m3outlineVariant
                border.width: 1

                ColumnLayout {
                    id: inputColumn
                    anchors.fill: parent
                    spacing: 0

                    StyledTextArea { // Input area
                        id: inputTextArea
                        Layout.fillWidth: true
                        placeholderText: qsTr("Enter text to translate...")
                        wrapMode: TextEdit.Wrap
                        textFormat: TextEdit.PlainText
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnLayer1
                        padding: 15
                        background: null
                        onTextChanged: {
                            if (inputTextArea.text.trim().length > 0) {
                                translateTimer.restart();
                            } else {
                                outputTextArea.text = "";
                            }
                        }
                    }

                    Item { Layout.fillHeight: true } 

                    RowLayout { // Status row
                        Layout.fillWidth: true
                        Layout.margins: 10
                        spacing: 10

                        Text {
                            Layout.leftMargin: 10
                            text: qsTr("%1 characters").arg(inputTextArea.text.length)
                            color: Appearance.colors.colOnLayer1
                            font.pixelSize: Appearance.font.pixelSize.smaller
                        }
                        Item { Layout.fillWidth: true }
                        ButtonGroup {
                            GroupButton {
                                id: pasteButton
                                baseWidth: height
                                buttonRadius: Appearance.rounding.small
                                contentItem: MaterialSymbol {
                                    anchors.centerIn: parent
                                    horizontalAlignment: Text.AlignHCenter
                                    iconSize: Appearance.font.pixelSize.larger
                                    text: "content_paste"
                                    color: deleteButton.enabled ? Appearance.colors.colOnLayer1 : Appearance.colors.colSubtext
                                }
                                onClicked: {
                                    root.inputField.text = Quickshell.clipboardText
                                }
                            }
                            GroupButton {
                                id: deleteButton
                                baseWidth: height
                                buttonRadius: Appearance.rounding.small
                                enabled: inputTextArea.text.length > 0
                                contentItem: MaterialSymbol {
                                    anchors.centerIn: parent
                                    horizontalAlignment: Text.AlignHCenter
                                    iconSize: Appearance.font.pixelSize.larger
                                    text: "close"
                                    color: deleteButton.enabled ? Appearance.colors.colOnLayer1 : Appearance.colors.colSubtext
                                }
                                onClicked: {
                                    root.inputField.text = ""
                                }
                            }
                        }
                    }
                }
            }

            Rectangle { // OUTPUT
                id: outputCanvas
                Layout.fillWidth: true
                implicitHeight: Math.max(150, outputColumn.implicitHeight)
                color: Appearance.m3colors.m3surfaceContainer
                radius: Appearance.rounding.normal

                ColumnLayout { // Output column
                    id: outputColumn
                    anchors.fill: parent
                    spacing: 0

                    StyledText { // Output area
                        id: outputTextArea
                        Layout.fillWidth: true
                        property bool hasTranslation: (root.translatedText.trim().length > 0)
                        wrapMode: TextEdit.Wrap
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: hasTranslation ? Appearance.colors.colOnLayer1 : Appearance.colors.colSubtext
                        padding: 15
                        text: hasTranslation ? root.translatedText : ""
                    }
                    Item { Layout.fillHeight: true } 
                    RowLayout { // Status row
                        Layout.fillWidth: true
                        Layout.margins: 10
                        spacing: 10
                        Item { Layout.fillWidth: true }
                        ButtonGroup {
                            GroupButton {
                                id: copyButton
                                baseWidth: height
                                buttonRadius: Appearance.rounding.small
                                enabled: root.outputField.text.trim().length > 0
                                contentItem: MaterialSymbol {
                                    anchors.centerIn: parent
                                    horizontalAlignment: Text.AlignHCenter
                                    iconSize: Appearance.font.pixelSize.larger
                                    text: "content_copy"
                                    color: deleteButton.enabled ? Appearance.colors.colOnLayer1 : Appearance.colors.colSubtext
                                }
                                onClicked: {
                                    Quickshell.clipboardText = root.outputField.text
                                }
                            }
                            GroupButton {
                                id: searchButton
                                baseWidth: height
                                buttonRadius: Appearance.rounding.small
                                enabled: root.outputField.text.trim().length > 0
                                contentItem: MaterialSymbol {
                                    anchors.centerIn: parent
                                    horizontalAlignment: Text.AlignHCenter
                                    iconSize: Appearance.font.pixelSize.larger
                                    text: "travel_explore"
                                    color: deleteButton.enabled ? Appearance.colors.colOnLayer1 : Appearance.colors.colSubtext
                                }
                                onClicked: {
                                    let url = ConfigOptions.search.engineBaseUrl + root.outputField.text;
                                    for (let site of ConfigOptions.search.excludedSites) {
                                        url += ` -site:${site}`;
                                    }
                                    Qt.openUrlExternally(url);
                                }
                            }
                        }
                    }
                }
            }
        }    
    }
}
