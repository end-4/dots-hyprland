const Gio = imports.gi.Gio;
const GLib = imports.gi.GLib;
import configOptions from "../modules/.configuration/user_options.js";

function getLanguageCode() {
    let langEnv = GLib.getenv('LANG') || GLib.getenv('LANGUAGE') || 'C.UTF-8'; // Assume the default value contains a dot
    let langCode = langEnv.split('.')[0]; // Split the string and get the first part
    return langCode;
}

const translations = {};
let currentLanguage = configOptions.i18n.langCode || getLanguageCode();

// Load language file
async function loadLanguage(lang) {
    if (!translations[lang]) {
        try {
            let filePath = `~/.config/ags/i18n/locales/${lang}.json`;
            filePath = filePath.replace(/^~/, GLib.get_home_dir());

            let file = Gio.File.new_for_path(filePath);
            let [success, contents] = file.load_contents(null);
            if (success) {
                let decoder = new TextDecoder('utf-8');
                let jsonString = decoder.decode(contents);
                translations[lang] = JSON.parse(jsonString);
            } else {
                throw new Error(`Unable to load file: ${filePath}`);
            }
        } catch (error) {
            console.error(`Failed to load language file, language code: ${lang}:`, error);
            throw error;
        }
    }
    currentLanguage = lang;
}

// Set the current language
function setLanguage(lang) {
    try {
        loadLanguage(lang);
    } catch (error) {
        console.error(`Failed to set language, language code: ${lang}:`, error);
    }
}

// Get translation, if no corresponding value, return the key
function setString(key) {
    if (!translations[currentLanguage]?.[key]) {
        console.log('无:' + key);
    }
    return translations[currentLanguage]?.[key] || key;
}

// Initialize default language
function init() {
    try {
        loadLanguage(currentLanguage);
        console.log("初始化完成");

    } catch (error) {
        console.error('Failed to initialize default language:', error);
    }
}




export { setString, init, setLanguage };