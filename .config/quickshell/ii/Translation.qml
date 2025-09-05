pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.functions

Singleton {
    id: root

    property var translations: ({})
    property var availableLanguages: ["en_US"]
    property bool isScanning: scanLanguagesProcess.running
    property bool isLoading: false
    property string translationKeepSuffix: "/*keep*/"

    property string languageCode: {
        var configLang = Config?.options.language.ui ?? "auto";

        if (configLang !== "auto")
            return configLang;

        return Qt.locale().name;
    }

    Process {
        id: scanLanguagesProcess
        command: ["find", FileUtils.trimFileProtocol(Qt.resolvedUrl(Directories.config + "/quickshell/translations/").toString()), "-name", "*.json", "-exec", "basename", "{}", ".json", ";"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                if (data.trim().length === 0)
                    return;
                var files = data.trim().split('\n');

                for (var i = 0; i < files.length; i++) {
                    var lang = files[i].trim();
                    if (lang.length > 0 && root.availableLanguages.indexOf(lang) === -1) {
                        root.availableLanguages.push(lang);
                    }
                }
            }
        }

        onExited: (exitCode, exitStatus) => {
            root.availableLanguages = [...root.availableLanguages] // Forcibly emit change

            if (exitCode !== 0) {
                root.availableLanguages = ["en_US"];
            }
            // TODO: notify and offer to translate when translation not available
        }
    }

    onLanguageCodeChanged: {
        translationFileView.reload();
    }

    FileView {
        id: translationFileView
        path: root.languageCode?.length > 0 ? Qt.resolvedUrl(Directories.config + "/quickshell/translations/" + root.languageCode + ".json") : ""

        onLoaded: {
            var textContent = "";
            try {
                textContent = text();
                var jsonData = JSON.parse(textContent);
                root.translations = jsonData;
            } catch (e) {
                console.log("[Translation] Failed to load translations:", e);
                root.translations = {};
            }
            root.isLoading = false;
        }
        onLoadFailed: error => {
            root.translations = {};
            root.isLoading = false;
        }
    }

    function tr(text) {
        if (!text)
            return "";
        var key = text.toString();
        if (root.isLoading)
            return key;

        if (root.translations.hasOwnProperty(key)) {
            var translation = root.translations[key].toString().trim();
            if (translation.length === 0)
                return key;

            if (translation.endsWith(root.translationKeepSuffix)) {
                translation = translation.substring(0, translation.length - root.translationKeepSuffix.length).trim();
            }
            return translation;
        }

        return key; // Fallback to key name
    }
}
