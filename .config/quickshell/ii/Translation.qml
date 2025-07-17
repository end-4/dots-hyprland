pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common

Singleton {
    id: root
    
    property var translations: ({})
    property string currentLanguage: "en_US"
    property var availableLanguages: ["en_US"]
    property bool isScanning: false
    property bool isLoading: false
    
    Process {
        id: scanLanguagesProcess
        command: ["find", Qt.resolvedUrl(Directories.config + "/quickshell/translations/").toString().replace("file://", ""), "-name", "*.json", "-exec", "basename", "{}", ".json", ";"]
        running: false
        
        stdout: SplitParser {
            onRead: data => {
                if (data.trim().length === 0) return
                
                var files = data.trim().split('\n')
                
                for (var i = 0; i < files.length; i++) {
                    var lang = files[i].trim()
                    if (lang.length > 0 && root.availableLanguages.indexOf(lang) === -1) {
                        root.availableLanguages.push(lang)
                    }
                }
            }
        }
        
        onExited: (exitCode, exitStatus) => {
            root.isScanning = false
            if (exitCode !== 0) {
                root.availableLanguages = ["en_US"]
            }
            root.loadTranslations()
        }
    }
    
    FileView {
        id: translationFileView
        onLoaded: {
            var textContent = ""
            try {
                textContent = text()
            } catch (e) {
                root.translations = {}
                root.isLoading = false
                return
            }
            
            if (textContent.length === 0) {
                root.translations = {}
                root.isLoading = false
                return
            }
            
            try {
                var jsonData = JSON.parse(textContent)
                root.translations = jsonData
                root.isLoading = false
            } catch (e) {
                root.translations = {}
                root.isLoading = false
            }
        }
        onLoadFailed: (error) => {
            root.translations = {}
            root.isLoading = false
        }
    }
    
    function detectSystemLanguage() {
        var locale = Qt.locale().name
        return locale
    }
    
    function getLanguageCode() {
        var configLang = "auto"
        try {
            configLang = ConfigOptions.language.ui
        } catch (e) {
            configLang = "auto"
        }
        
        if (configLang === "auto") {
            return detectSystemLanguage()
        } else {
            if (root.availableLanguages.indexOf(configLang) !== -1) {
                return configLang
            } else {
                return detectSystemLanguage()
            }
        }
    }
    
    function loadTranslations() {
        if (root.isScanning) {
            return
        }
        
        var targetLang = getLanguageCode()
        root.currentLanguage = targetLang
        
        // Use empty translations for English (default language)
        if (targetLang === "en_US" || targetLang === "en") {
            root.translations = {}
            return
        }
        
        // Check if target language is available
        if (root.availableLanguages.indexOf(targetLang) === -1) {
            root.currentLanguage = "en_US"
            root.translations = {}
            return
        }
        
        // Load translation file
        root.isLoading = true
        var translationsPath = Qt.resolvedUrl(Directories.config + "/quickshell/translations/" + targetLang + ".json")
        translationFileView.path = translationsPath
    }
    
    function tr(text) {
        if (!text) {
            return ""
        }
        
        var key = text.toString()
        
        if (root.isLoading) {
            return key
        }
        
        if (root.currentLanguage === "en_US" || root.currentLanguage === "en" || !root.translations) {
            return key
        }
        
        if (root.translations.hasOwnProperty(key)) {
            var translation = root.translations[key]
            if (translation && translation.toString().trim().length > 0) {
                var str = translation.toString().trim()
                if (str.endsWith("/*keep*/")) {
                    return str.substring(0, str.length - 8).trim()
                } else {
                    return str
                }
            } else {
                return translation.toString()
            }
        }

        return key // Fallback to key name
    }
    
    function reloadTranslations() {
        root.scanLanguages()
    }
    
    function scanLanguages() {
        var translationsDir = Qt.resolvedUrl(Directories.config + "/quickshell/translations/").toString().replace("file://", "")
        root.isScanning = true
        scanLanguagesProcess.running = true
    }
    
    Component.onCompleted: {
        root.scanLanguages()
    }
}
