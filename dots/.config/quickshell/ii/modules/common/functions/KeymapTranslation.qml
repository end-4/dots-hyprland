pragma Singleton
import Quickshell

/**
 * Layout-aware search helpers.
 */
Singleton {
    id: root

    // Physical layout maps. Bidirectional pairs are generated in the IIFE below.
    readonly property var _layouts: (function() {
        const list = [
            {
                name: "uk",
                map: {
                    "й":"q","ц":"w","у":"e","к":"r","е":"t","н":"y","г":"u",
                    "ш":"i","щ":"o","з":"p","х":"[","ї":"]",
                    "Й":"Q","Ц":"W","У":"E","К":"R","Е":"T","Н":"Y","Г":"U",
                    "Ш":"I","Щ":"O","З":"P","Х":"{","Ї":"}",
                    "ф":"a","і":"s","в":"d","а":"f","п":"g","р":"h","о":"j",
                    "л":"k","д":"l","ж":";","є":"'",
                    "Ф":"A","І":"S","В":"D","А":"F","П":"G","Р":"H","О":"J",
                    "Л":"K","Д":"L","Ж":":","Є":'"',
                    "я":"z","ч":"x","с":"c","м":"v","и":"b","т":"n","ь":"m",
                    "б":",","ю":".",
                    "Я":"Z","Ч":"X","С":"C","М":"V","И":"B","Т":"N","Ь":"M",
                    "Б":"<","Ю":">"
                }
            },
            {
                name: "de",
                map: {
                    "y":"z","Y":"Z","z":"y","Z":"Y",
                    "ü":"[","Ü":"{","ö":";","Ö":":","ä":"'","Ä":'"',"ß":"-"
                }
            },
            {
                name: "fr",
                map: {
                    "a":"q","A":"Q","z":"w","Z":"W","q":"a","Q":"A","w":"z","W":"Z",
                    "é":"2","è":"7","ê":"[","à":"0","ù":"`","ç":"9","œ":"p",
                    "m":";","M":":",";":"m",":":"M"
                }
            }
        ];

        // Make all layout maps bidirectional (for example, add "q":"й" for "uk").
        for (const layout of list) {
            const reversePairs = {};
            for (const [key, value] of Object.entries(layout.map)) {
                if (layout.map[value] === undefined) {
                    reversePairs[value] = key;
                }
            }
            Object.assign(layout.map, reversePairs);
        }

        return list;
    })()

    // Compact Cyrillic-to-Latin transliteration for search.
    readonly property var _cyrillicToLatin: ({
        "а":"a","б":"b","в":"v","г":"g","ґ":"g",
        "д":"d","е":"e","є":"e","ж":"z","з":"z",
        "и":"i","і":"i","ї":"i","й":"y","к":"k",
        "л":"l","м":"m","н":"n","о":"o","п":"p",
        "р":"r","с":"s","т":"t","у":"u","ф":"f",
        "х":"h","ц":"c","ч":"c","ш":"s","щ":"s",
        "ь":"","ъ":"","ю":"u","я":"a",
        "ы":"y","э":"e","ё":"o",
        "А":"A","Б":"B","В":"V","Г":"G","Ґ":"G",
        "Д":"D","Е":"E","Є":"E","Ж":"Z","З":"Z",
        "И":"I","І":"I","Ї":"I","Й":"Y","К":"K",
        "Л":"L","М":"M","Н":"N","О":"O","П":"P",
        "Р":"R","С":"S","Т":"T","У":"U","Ф":"F",
        "Х":"H","Ц":"C","Ч":"C","Ш":"S","Щ":"S",
        "Ь":"","Ъ":"","Ю":"U","Я":"A",
        "Ы":"Y","Э":"E","Ё":"O"
    })

    // Internal character mapping helper.
    function _mapWithLayout(str, layoutName) {
        const layout = root._layouts.find(l => l.name === layoutName);
        if (!layout) return str;
        return str.split("").map(ch => {
            const mapped = layout.map[ch];
            return mapped !== undefined ? mapped : ch;
        }).join("");
    }

    /**
     * Return unique layout-corrected variants.
     * Works in both directions for all configured layouts.
     */
    function translateAll(str) {
        if (!str) return [];
        
        const results = [];
        const seen = new Set([str]); // Keep input out of final results.

        for (const layout of root._layouts) {
            const translated = root._mapWithLayout(str, layout.name);
            if (!seen.has(translated)) {
                seen.add(translated);
                results.push(translated);
            }
        }
        return results;
    }

    /**
     * Return transliterated Latin text.
     * Return null when input contains no Cyrillic characters.
     */
    function transliterate(str) {
        if (!str || !/[Ѐ-ӿ]/.test(str)) return null;
        const table = root._cyrillicToLatin;
        return str.split("").map(ch => {
            const mapped = table[ch];
            return mapped !== undefined ? mapped : ch;
        }).join("").replace(/\s+/g, " ").trim();
    }
}