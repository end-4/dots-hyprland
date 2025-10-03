import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import "./translator/"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

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
    property string targetLanguage: Config.options.language.translator.targetLanguage
    property string sourceLanguage: Config.options.language.translator.sourceLanguage
    property string hostLanguage: targetLanguage

    property bool showLanguageSelector: false
    property bool languageSelectorTarget: false // true for target language, false for source language

    function showLanguageSelectorDialog(isTargetLang: bool) {
        root.languageSelectorTarget = isTargetLang;
        root.showLanguageSelector = true
    }

    onFocusChanged: (focus) => {
        if (focus) {
            root.inputField.forceActiveFocus()
        }
    }

    Timer {
        id: translateTimer
        interval: Config.options.sidebar.translator.delay
        repeat: false
        onTriggered: () => {
            if (root.inputField.text.trim().length > 0) {
                // console.log("Translating with command:", translateProc.command);
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
        command: ["bash", "-c", `trans -no-theme -no-bidi`
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
            // console.log("BUFFER:", translateProc.buffer);
            // console.log("SECTIONS:", sections);

            // 2. Extract relevant data
            root.translatedText = sections.length > 1 ? sections[1].trim() : "";
        }
    }

    Process {
        id: getLanguagesProc
        command: ["trans", "-list-languages", "-no-bidi"]
        property list<string> bufferList: ["auto"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                getLanguagesProc.bufferList.push(data.trim());
            }
        }
        onExited: (exitCode, exitStatus) => {
            // Ensure "auto" is always the first language
            let langs = getLanguagesProc.bufferList
                .filter(lang => lang.trim().length > 0 && lang !== "auto")
                .sort((a, b) => a.localeCompare(b));
            langs.unshift("auto");
            root.languages = langs;
            getLanguagesProc.bufferList = []; // Clear the buffer
        }
    }

    ColumnLayout {
        anchors.fill: parent
        StyledFlickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: contentColumn.implicitHeight

            ColumnLayout {
                id: contentColumn
                anchors.fill: parent

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
                    placeholderText: Translation.tr("Translation goes here...")
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
                            let url = Config.options.search.engineBaseUrl + outputCanvas.displayedText;
                            for (let site of Config.options.search.excludedSites) {
                                url += ` -site:${site}`;
                            }
                            Qt.openUrlExternally(url);
                        }
                    }
                }

            }    
        }

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
            placeholderText: Translation.tr("Enter text to translate...")
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
    }

    Loader {
        anchors.fill: parent
        active: root.showLanguageSelector
        visible: root.showLanguageSelector
        z: 9999
        sourceComponent: SelectionDialog {
            id: languageSelectorDialog
            titleText: Translation.tr("Select Language")
            items: root.languages
            defaultChoice: root.languageSelectorTarget ? root.targetLanguage : root.sourceLanguage
            onCanceled: () => {
                root.showLanguageSelector = false;
            }
            onSelected: (result) => {
                root.showLanguageSelector = false;
                if (!result || result.length === 0) return; // No selection made

                if (root.languageSelectorTarget) {
                    root.targetLanguage = result;
                    Config.options.language.translator.targetLanguage = result; // Save to config
                } else {
                    root.sourceLanguage = result;
                    Config.options.language.translator.sourceLanguage = result; // Save to config
                }

                translateTimer.restart(); // Restart translation after language change
            }
        }
    }
}
