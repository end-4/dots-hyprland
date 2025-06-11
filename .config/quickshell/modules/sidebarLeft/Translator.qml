import "root:/"
import "root:/services"
import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/modules/common/functions/string_utils.js" as StringUtils
import "./translator/"
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
    // Widgets
    property var inputField: inputCanvas.inputTextArea
    // Widget variables
    property bool translationFor: false // Indicates if the translation is for an autocorrected text
    property string translatedText: ""
    property list<string> languages: []
    // Options
    property string targetLanguage: ConfigOptions.language.translator.targetLanguage
    property string sourceLanguage: ConfigOptions.language.translator.sourceLanguage
    property string hostLanguage: targetLanguage

    property bool showLanguageSelector: false
    property bool languageSelectorTarget: false // true for target language, false for source language
    property string languageSelectorLanguage: ""

    function showLanguageSelectorDialog(isTargetLang: bool) {
        root.showLanguageSelector = true
        root.languageSelectorTarget = isTargetLang;
        root.languageSelectorLanguage = isTargetLang ? root.targetLanguage : root.sourceLanguage;
    }

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
            if (root.inputField.text.trim().length > 0) {
                console.log("Translating with command:", translateProc.command);
                translateProc.running = false;
                translateProc.buffer = ""; // Clear the buffer
                translateProc.running = true; // Restart the process
            } else {
                root.translatedText = "";
            }
        }
    }

    Process {
        id: translateProc
        command: ["bash", "-c", `trans -no-theme`
            + ` -source '${StringUtils.shellSingleQuoteEscape(root.sourceLanguage)}'`
            + ` -target '${StringUtils.shellSingleQuoteEscape(root.targetLanguage)}'`
            + ` -no-ansi '${StringUtils.shellSingleQuoteEscape(root.inputField.text.trim())}'`]
        property string buffer: ""
        stdout: SplitParser {
            onRead: data => {
                translateProc.buffer += data + "\n";
            }
        }
        onExited: (exitCode, exitStatus) => {
            // 1. Split into sections by double newlines
            const sections = translateProc.buffer.trim().split(/\n\s*\n/);
            console.log("BUFFER:", translateProc.buffer);
            console.log("SECTIONS:", sections);

            // 2. Extract relevant data
            root.translatedText = sections.length > 1 ? sections[1].trim() : "";
        }
    }

    Process {
        id: getLanguagesProc
        command: ["trans", "-list-languages"]
        property list<string> bufferList: ["auto"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                getLanguagesProc.bufferList.push(data.trim());
            }
        }
        onExited: (exitCode, exitStatus) => {
            root.languages = getLanguagesProc.bufferList
                .filter(lang => lang.trim().length > 0) // Filter out empty lines
                .sort((a, b) => a.localeCompare(b)); // Sort alphabetically
            getLanguagesProc.bufferList = []; // Clear the buffer
        }
    }
    
    Flickable {
        anchors.fill: parent
        contentHeight: contentColumn.implicitHeight

        ColumnLayout {
            id: contentColumn
            anchors.fill: parent

            LanguageSelectorButton { // Source language button
                id: sourceLanguageButton
                displayText: root.sourceLanguage
                onClicked: {
                    root.showLanguageSelectorDialog(false);
                }
            }

            TextCanvas { // Content input
                id: inputCanvas
                isInput: true
                placeholderText: qsTr("Enter text to translate...")
                onInputTextChanged: {
                    translateTimer.restart();
                }
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
                    enabled: inputCanvas.inputTextArea.text.length > 0
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

            LanguageSelectorButton { // Target language button
                id: targetLanguageButton
                displayText: root.targetLanguage
                onClicked: {
                    root.showLanguageSelectorDialog(true);
                }
            }

            TextCanvas { // Content translation
                id: outputCanvas
                isInput: false
                placeholderText: qsTr("Translation goes here...")
                property bool hasTranslation: (root.translatedText.trim().length > 0)
                text: hasTranslation ? root.translatedText : ""
                GroupButton {
                    id: copyButton
                    baseWidth: height
                    buttonRadius: Appearance.rounding.small
                    enabled: outputCanvas.displayedText.trim().length > 0
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        iconSize: Appearance.font.pixelSize.larger
                        text: "content_copy"
                        color: copyButton.enabled ? Appearance.colors.colOnLayer1 : Appearance.colors.colSubtext
                    }
                    onClicked: {
                        Quickshell.clipboardText = outputCanvas.displayedText
                    }
                }
                GroupButton {
                    id: searchButton
                    baseWidth: height
                    buttonRadius: Appearance.rounding.small
                    enabled: outputCanvas.displayedText.trim().length > 0
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        iconSize: Appearance.font.pixelSize.larger
                        text: "travel_explore"
                        color: searchButton.enabled ? Appearance.colors.colOnLayer1 : Appearance.colors.colSubtext
                    }
                    onClicked: {
                        let url = ConfigOptions.search.engineBaseUrl + outputCanvas.displayedText;
                        for (let site of ConfigOptions.search.excludedSites) {
                            url += ` -site:${site}`;
                        }
                        Qt.openUrlExternally(url);
                    }
                }
            }

        }    
    }

    Loader {
        anchors.fill: parent
        active: root.showLanguageSelector
        visible: root.showLanguageSelector
        z: 9999
        sourceComponent: SelectionDialog {
            id: languageSelectorDialog
            titleText: qsTr("Select Language")
            items: root.languages
            onCanceled: () => {
                root.showLanguageSelector = false;
            }
            onSelected: (result) => {
                root.showLanguageSelector = false;
                if (!result || result.length === 0) return; // No selection made

                if (root.languageSelectorTarget) {
                    root.targetLanguage = result;
                    ConfigOptions.language.translator.targetLanguage = result; // Save to config
                } else {
                    root.sourceLanguage = result;
                    ConfigOptions.language.translator.sourceLanguage = result; // Save to config
                }
            }
        }
    }
}
