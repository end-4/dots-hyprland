import { Gio, GLib } from "astal";
import { userOptions } from "../modules/core/configuration/user_options";
const { langCode, Extra_logs } = userOptions.i18n
const translations: Record<string, Record<string, string>> = {};

let currentLanguage = langCode || getLanguageCode();

function getLanguageCode() {
    let langEnv = GLib.getenv('LANG') || GLib.getenv('LANGUAGE') || 'Default.';
    let langCode = langEnv.split('.')[0];
    return langCode;
}

// Load language file
function loadLanguage(lang: string) {
    if (!translations[lang]) {
        try {
            let filePath = `~/.config/agsv2/i18n/locales/${lang}.json`;
            filePath = filePath.replace(/^~/, GLib.get_home_dir());
            let file = Gio.File.new_for_path(filePath);
            let [success, contents] = file.load_contents(null);
            if (success) {
                let decoder = new TextDecoder('utf-8');
                let jsonString = decoder.decode(contents);
                translations[lang] = JSON.parse(jsonString);
            }
        } catch (error) {
            if (Extra_logs || lang === "Default")
                console.warn(`Failed to load language file, language code: ${lang}:\n`, error);
            return;
        }
    }
    currentLanguage = currentLanguage || lang;
}

// Initialize default language
function init() {
    try {
        loadLanguage(currentLanguage);
        if (Extra_logs)
            console.log(getString("Initialization complete!") || "Initialization complete!");
        loadLanguage("Default");
    } catch (error) {
        console.error('Failed to initialize default language:', error);
    }
}

// Get translation, if no corresponding value, return the key
function getString(key: string) {
    if (key && !translations[currentLanguage]?.[key] && Extra_logs)
        console.warn(`${translations[currentLanguage]["Not found"] || "Not found"}:::${key}`);
    return translations[currentLanguage]?.[key] || translations['Default']?.[key] || key;
}
export { getString, init };