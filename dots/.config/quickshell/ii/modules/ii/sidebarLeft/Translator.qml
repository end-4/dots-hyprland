import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.ii.sidebarLeft.translator
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls 2.15
import Quickshell
import Quickshell.Io

/**
 * Translator widget - Final Polished UI (English Comments & Generic Tilde Path)
 */
Item {
    id: root

    // --- Sizes ---
    property real padding: 4

    // --- Widgets Reference ---
    property var inputField: inputCanvas.inputTextArea

    // --- Variables ---
    property bool translationFor: false
    property string translatedText: ""
    property list<string> languages: []

    // --- Options & Config ---
    property string targetLanguage: Config.options.language.translator.targetLanguage
    property string sourceLanguage: Config.options.language.translator.sourceLanguage
    property string activeSourceLanguage: sourceLanguage
    property string activeTargetLanguage: targetLanguage
    property bool useLocalTranslation: Config.options.sidebar?.translator?.useLocal ?? true
    property string pythonExecutable: Config.options.sidebar?.translator?.pythonBinary ?? "/usr/bin/python3"

    // ✅ Generic Path: Using '~' (Tilde expansion) which requires '/bin/sh -c' for execution below.
    property string localScriptPath: "~/.config/quickshell/ii/modules/ii/sidebarLeft/local_translate.py"
    property int translateDelay: Math.max(100, Config.options.sidebar.translator.delay - 100)

    // --- States ---
    property bool showLanguageSelector: false
    property bool languageSelectorTarget: false
    property bool showIndexManager: false // Controls the management overlay visibility
    property var availableIndexLanguages: []

    // --- Language Detection Patterns ---
    readonly property var languageDetectionPatterns: ({
        "ar": /[\u0600-\u06FF]/, "en": /[A-Za-z]/, "fa": /[\u0600-\u06FF]/,
        "ru": /[\u0400-\u04FF]/, "tr": /[A-Za-zÇĞİŞÖÜçğışöü]/, "ja": /[\u3040-\u309F\u30A0-\u30FF\u31F0-\u31FF]/,
        "zh": /[\u4E00-\u9FFF]/, "ko": /[\u1100-\u11FF\u3130-\u318F\uAC00-\uD7AF]/,
    })

    // ============================================================
    // Logic Functions
    // ============================================================
    function showLanguageSelectorDialog(isTargetLang: bool) {
        root.languageSelectorTarget = isTargetLang;
        root.showLanguageSelector = true
    }

    function normalizedLanguageCode(name) {
        if (!name) return "";
        const trimmed = name.trim().toLowerCase();
        if (/^[a-z]{2,3}(?:-[a-z]{2,3})?$/.test(trimmed)) return trimmed;
        if (trimmed.includes("arab") || /[\u0600-\u06FF]/.test(name)) return "ar";
        if (trimmed.startsWith("en")) return "en";
        return trimmed.substring(0, 2);
    }

    function detectLanguageFromText(text) {
        const trimmed = text?.trim() ?? "";
        if (!trimmed.length) return root.sourceLanguage;
        const srcCode = root.normalizedLanguageCode(root.sourceLanguage);
        const tgtCode = root.normalizedLanguageCode(root.targetLanguage);

        const targetPattern = root.languageDetectionPatterns[tgtCode];
        if (targetPattern && targetPattern.test(trimmed)) return root.targetLanguage;

        const sourcePattern = root.languageDetectionPatterns[srcCode];
        if (sourcePattern && sourcePattern.test(trimmed)) return root.sourceLanguage;

        if (/[A-Za-z]/.test(trimmed)) {
            if (srcCode === 'en') return root.sourceLanguage;
            if (tgtCode === 'en') return root.targetLanguage;
            return "English";
        }
        if (/[\u0600-\u06FF]/.test(trimmed)) {
            if (srcCode === 'ar') return root.sourceLanguage;
            if (tgtCode === 'ar') return root.targetLanguage;
            return "Arabic";
        }
        return root.sourceLanguage;
    }

    function resolveActiveLanguages(text) {
        const detectedName = root.detectLanguageFromText(text);
        const detectedCode = root.normalizedLanguageCode(detectedName);
        const targetCode = root.normalizedLanguageCode(root.targetLanguage);
        if (detectedCode === targetCode) {
            root.activeSourceLanguage = root.targetLanguage;
            root.activeTargetLanguage = root.sourceLanguage;
        } else {
            root.activeSourceLanguage = root.sourceLanguage;
            root.activeTargetLanguage = root.targetLanguage;
        }
    }

    // ---------------- Processes (Backend) ----------------
    function checkLocalCache(text) {
        const src = root.normalizedLanguageCode(root.activeSourceLanguage);
        const tgt = root.normalizedLanguageCode(root.activeTargetLanguage);
        // Execute via sh -c to expand the '~' path and safely quote the text argument.
        const cmd = root.pythonExecutable + " " + root.localScriptPath +
        " get " + src + " " + tgt + " " + JSON.stringify(text);
        localCheckProc.command = ["/bin/sh", "-c", cmd];
        localCheckProc.running = true;
    }

    function fetchOnlineTranslation() {
        const text = root.inputField.text.trim(); if(!text) return;
        const src = root.normalizedLanguageCode(root.activeSourceLanguage) || "auto";
        const tgt = root.normalizedLanguageCode(root.activeTargetLanguage) || "en";
        const xhr = new XMLHttpRequest();
        xhr.open("GET", `https://translate.googleapis.com/translate_a/single?client=gtx&sl=${src}&tl=${tgt}&dt=t&q=${encodeURIComponent(text)}`);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === 4 && xhr.status === 200) {
                try {
                    const res = JSON.parse(xhr.responseText);
                    let out = ""; if(res && res[0]) for(let i=0; i<res[0].length; i++) if(res[0][i][0]) out += res[0][i][0];
                    root.translatedText = out;
                    saveToLocalCache(text, out);
                } catch(e) { root.translatedText = "Error"; }
            }
        }
        xhr.send();
    }

    function saveToLocalCache(orig, trans) {
        if(!root.useLocalTranslation) return;
        const src = root.normalizedLanguageCode(root.activeSourceLanguage);
        const tgt = root.normalizedLanguageCode(root.activeTargetLanguage);
        // Execute via sh -c to expand the '~' path and safely quote the text and translation arguments.
        const cmd = root.pythonExecutable + " " + root.localScriptPath +
        " set " + src + " " + tgt + " " + JSON.stringify(orig) + " " + JSON.stringify(trans);
        localSaveProc.command = ["/bin/sh", "-c", cmd];
        localSaveProc.running = true;
    }

    Process {
        id: localCheckProc; command: [];
        stdout: SplitParser { onRead: data => { if(data.trim() && data.trim() !== "__NOT_FOUND__") root.translatedText = data.trim(); else if(data.trim() === "__NOT_FOUND__") fetchOnlineTranslation(); } }
    }
    Process { id: localSaveProc; command: [] }

    // Process: Get Available Index Languages - Must also use sh -c
    Process {
        id: getAvailableLangsProc
        property string cmdString: root.pythonExecutable + " " + root.localScriptPath + " get_languages"
        command: ["/bin/sh", "-c", cmdString]
        stdout: SplitParser { onRead: data => { try { root.availableIndexLanguages = JSON.parse(data.trim()); } catch(e) { root.availableIndexLanguages = []; } } }
    }

    // Process: Delete Index Language - Must also use sh -c
    Process {
        id: deleteLangProc; command: []
        onExited: (exitCode, exitStatus) => { getAvailableLangsProc.running = true; } // Refresh list after delete
        function deleteLanguage(langCode) {
            const cmd = root.pythonExecutable + " " + root.localScriptPath + " delete_language " + langCode;
            command = ["/bin/sh", "-c", cmd];
            running = true;
        }
    }

    // Process: Get Supported Languages (using 'trans' tool) - No change needed here
    Process {
        id: getLanguagesProc; command: ["trans", "-list-languages", "-no-bidi"]; running: true
        stdout: SplitParser { onRead: data => getLanguagesProc.bufferList.push(data.trim()) }
        property list<string> bufferList: ["auto"]
        onExited: {
            let langs = bufferList.filter(l => l.trim() && l !== "auto").sort();
            langs.unshift("auto"); root.languages = langs;
        }
    }

    Timer {
        id: translateTimer; interval: root.translateDelay; repeat: false
        onTriggered: {
            const txt = root.inputField.text.trim();
            if(txt) { resolveActiveLanguages(txt); if(root.useLocalTranslation) checkLocalCache(txt); else fetchOnlineTranslation(); }
            else root.translatedText = "";
        }
    }

    onSourceLanguageChanged: Config.options.language.translator.sourceLanguage = root.sourceLanguage;
    onTargetLanguageChanged: Config.options.language.translator.targetLanguage = root.targetLanguage;

    // ============================================================
    // UI Layout
    // ============================================================

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.padding

        StyledFlickable {
            Layout.fillWidth: true; Layout.fillHeight: true; contentHeight: contentColumn.implicitHeight
            ColumnLayout {
                id: contentColumn; anchors.fill: parent
                RowLayout {
                    Layout.fillWidth: true; spacing: root.padding
                    LanguageSelectorButton { id: sourceLanguageButton; Layout.fillWidth: true; displayText: root.activeSourceLanguage; onClicked: root.showLanguageSelectorDialog(false); }
                    MaterialSymbol { Layout.alignment: Qt.AlignVCenter; text: "sync_alt"; iconSize: Appearance.font.pixelSize.large; color: Appearance.colors.colOnLayer2 }
                    LanguageSelectorButton { id: targetLanguageButton; Layout.fillWidth: true; displayText: root.activeTargetLanguage; onClicked: root.showLanguageSelectorDialog(true); }
                }
                TextCanvas {
                    id: outputCanvas; isInput: false; placeholderText: Translation.tr("Translation goes here..."); text: root.translatedText
                    GroupButton { id: copyButton; baseWidth: height; buttonRadius: Appearance.rounding.small; enabled: outputCanvas.displayedText.trim().length > 0; contentItem: MaterialSymbol { anchors.centerIn: parent; iconSize: Appearance.font.pixelSize.larger; text: "content_copy"; color: copyButton.enabled ? Appearance.colors.colOnLayer1 : Appearance.colors.colSubtext } onClicked: Quickshell.clipboardText = outputCanvas.displayedText }
                    GroupButton { id: searchButton; baseWidth: height; buttonRadius: Appearance.rounding.small; enabled: outputCanvas.displayedText.trim().length > 0; contentItem: MaterialSymbol { anchors.centerIn: parent; iconSize: Appearance.font.pixelSize.larger; text: "travel_explore"; color: searchButton.enabled ? Appearance.colors.colOnLayer1 : Appearance.colors.colSubtext } onClicked: Qt.openUrlExternally(Config.options.search.engineBaseUrl + outputCanvas.displayedText) }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true; spacing: root.padding
            TextCanvas {
                Layout.fillWidth: true; id: inputCanvas; isInput: true; placeholderText: Translation.tr("Enter text to translate..."); onInputTextChanged: translateTimer.restart();
                // Manage Button
                GroupButton {
                    id: manageCacheButton; baseWidth: height; buttonRadius: Appearance.rounding.small; enabled: root.useLocalTranslation
                    contentItem: MaterialSymbol { anchors.centerIn: parent; iconSize: Appearance.font.pixelSize.larger; text: "folder_managed"; color: Appearance.colors.colOnLayer1 }
                    onClicked: { getAvailableLangsProc.running = true; root.showIndexManager = true; }
                }
                GroupButton {
                    id: localToggleButton; baseWidth: height; buttonRadius: Appearance.rounding.small; toggled: root.useLocalTranslation; enabled: true
                    contentItem: MaterialSymbol { anchors.centerIn: parent; iconSize: Appearance.font.pixelSize.larger; text: root.useLocalTranslation ? "sync_saved_locally" : "cloud_sync"; color: localToggleButton.enabled ? (root.useLocalTranslation ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1) : Appearance.colors.colSubtext }
                    onClicked: { root.useLocalTranslation = !root.useLocalTranslation; Config.options.sidebar.translator.useLocal = root.useLocalTranslation; }
                }
                GroupButton { id: pasteButton; baseWidth: height; buttonRadius: Appearance.rounding.small; contentItem: MaterialSymbol { anchors.centerIn: parent; iconSize: Appearance.font.pixelSize.larger; text: "content_paste"; color: Appearance.colors.colOnLayer1 } onClicked: root.inputField.text = Quickshell.clipboardText }
                GroupButton { id: deleteButton; baseWidth: height; buttonRadius: Appearance.rounding.small; enabled: inputCanvas.inputTextArea.text.length > 0; contentItem: MaterialSymbol { anchors.centerIn: parent; iconSize: Appearance.font.pixelSize.larger; text: "close"; color: deleteButton.enabled ? Appearance.colors.colOnLayer1 : Appearance.colors.colSubtext } onClicked: root.inputField.text = "" }
            }
        }
    }

    // --- Dialog Loader (Language Selector) ---
    Loader {
        anchors.fill: parent; active: root.showLanguageSelector; visible: root.showLanguageSelector; z: 9999
        sourceComponent: SelectionDialog {
            id: languageSelectorDialog; titleText: Translation.tr("Select Language"); items: root.languages; defaultChoice: root.languageSelectorTarget ? root.targetLanguage : root.sourceLanguage
            onCanceled: root.showLanguageSelector = false; onSelected: (result) => { root.showLanguageSelector = false; if(!result) return; if(root.languageSelectorTarget) { root.targetLanguage = result; Config.options.language.translator.targetLanguage = result; } else { root.sourceLanguage = result; Config.options.language.translator.sourceLanguage = result; } translateTimer.restart(); }
        }
    }

    // ✅ Management Overlay (Custom Smooth Design)
    Rectangle {
        id: indexManagerOverlay
        anchors.fill: parent; z: 10000; visible: root.showIndexManager; color: "#AA000000" // Dimmed background

        MouseArea { anchors.fill: parent; onClicked: root.showIndexManager = false } // Prevent clicks behind the window

        // Main Window Box
        Rectangle {
            width: parent.width * 0.9; height: parent.height * 0.7; anchors.centerIn: parent

            color: Appearance.colors.colLayer2 // Design: Uses the same color as inner containers (TextCanvas) with no border.
            radius: Appearance.rounding.normal // Uses a large rounding radius for a smooth, consistent look.
            border.width: 0 // Removes the sharp white border.

            MouseArea { anchors.fill: parent }

            ColumnLayout {
                anchors.fill: parent; anchors.margins: 15; spacing: 10

                // Title
                Text {
                    Layout.fillWidth: true; text: Translation.tr("Manage Indexes"); font.pixelSize: Appearance.font.pixelSize.large
                    font.bold: true; color: Appearance.colors.colOnLayer1; horizontalAlignment: Text.AlignHCenter
                }

                // Smooth Separator
                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Appearance.colors.colOnLayer2; opacity: 0.1 }

                // List
                ListView {
                    Layout.fillWidth: true; Layout.fillHeight: true; clip: true; model: root.availableIndexLanguages; spacing: 5
                    delegate: Rectangle {
                        width: parent.width; height: 45;
                        color: Appearance.colors.colLayer1; // Item background color (consistent with containers)
                        radius: Appearance.rounding.small
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 15; anchors.rightMargin: 5
                            Text { Layout.fillWidth: true; text: model.modelData.toUpperCase(); font.pixelSize: Appearance.font.pixelSize.medium; font.bold: true; color: Appearance.colors.colOnLayer1; verticalAlignment: Text.AlignVCenter }
                            // Transparent Delete Button
                            GroupButton {
                                Layout.preferredWidth: 35; Layout.preferredHeight: 35; buttonRadius: Appearance.rounding.small;
                                background: Item {} // Transparent background to blend the button with the design
                                contentItem: MaterialSymbol { anchors.centerIn: parent; text: "delete"; iconSize: Appearance.font.pixelSize.larger; color: Appearance.colors.colError }
                                onClicked: deleteLangProc.deleteLanguage(model.modelData);
                            }
                        }
                    }
                    // Empty State Message
                    Text { visible: root.availableIndexLanguages.length === 0; text: Translation.tr("No indexes found."); color: Appearance.colors.colSubtext; anchors.centerIn: parent; font.pixelSize: Appearance.font.pixelSize.medium }
                }

                // Close Button (Standard Button Design)
                GroupButton {
                    Layout.alignment: Qt.AlignHCenter; Layout.topMargin: 5; Layout.preferredWidth: 100; Layout.preferredHeight: 40; buttonRadius: Appearance.rounding.small
                    background: Rectangle { // Use a distinctive button color
                        color: Appearance.colors.colSurfaceContainer; radius: parent.buttonRadius
                    }
                    contentItem: Text { text: Translation.tr("Close"); color: Appearance.colors.colOnLayer1; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.bold: true }
                    onClicked: root.showIndexManager = false
                }
            }
        }
    }
}
