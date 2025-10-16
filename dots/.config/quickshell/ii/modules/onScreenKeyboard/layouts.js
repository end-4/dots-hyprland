// We're going to use ydotool
// See /usr/include/linux/input-event-codes.h for keycodes

const defaultLayout = "English (US)";
const byName = {
    "English (US)": {
        name_short: "US",
        description: "QWERTY - Full",
        comment: "Like physical keyboard",
        // A key looks like this: { k: "a", ks: "A", t: "normal" } (key, key-shift, type)
        // key types are: normal, tab, caps, shift, control, fn (normal w/ half height), space, expand
        // keys: [
        //     [{ k: "Esc", t: "fn" }, { k: "F1", t: "fn" }, { k: "F2", t: "fn" }, { k: "F3", t: "fn" }, { k: "F4", t: "fn" }, { k: "F5", t: "fn" }, { k: "F6", t: "fn" }, { k: "F7", t: "fn" }, { k: "F8", t: "fn" }, { k: "F9", t: "fn" }, { k: "F10", t: "fn" }, { k: "F11", t: "fn" }, { k: "F12", t: "fn" }, { k: "PrtSc", t: "fn" }, { k: "Del", t: "fn" }],
        //     [{ k: "`", ks: "~", t: "normal" }, { k: "1", ks: "!", t: "normal" }, { k: "2", ks: "@", t: "normal" }, { k: "3", ks: "#", t: "normal" }, { k: "4", ks: "$", t: "normal" }, { k: "5", ks: "%", t: "normal" }, { k: "6", ks: "^", t: "normal" }, { k: "7", ks: "&", t: "normal" }, { k: "8", ks: "*", t: "normal" }, { k: "9", ks: "(", t: "normal" }, { k: "0", ks: ")", t: "normal" }, { k: "-", ks: "_", t: "normal" }, { k: "=", ks: "+", t: "normal" }, { k: "Backspace", t: "shift" }],
        //     [{ k: "Tab", t: "tab" }, { k: "q", ks: "Q", t: "normal" }, { k: "w", ks: "W", t: "normal" }, { k: "e", ks: "E", t: "normal" }, { k: "r", ks: "R", t: "normal" }, { k: "t", ks: "T", t: "normal" }, { k: "y", ks: "Y", t: "normal" }, { k: "u", ks: "U", t: "normal" }, { k: "i", ks: "I", t: "normal" }, { k: "o", ks: "O", t: "normal" }, { k: "p", ks: "P", t: "normal" }, { k: "[", ks: "{", t: "normal" }, { k: "]", ks: "}", t: "normal" }, { k: "\\", ks: "|", t: "expand" }],
        //     [{ k: "Caps", t: "caps" }, { k: "a", ks: "A", t: "normal" }, { k: "s", ks: "S", t: "normal" }, { k: "d", ks: "D", t: "normal" }, { k: "f", ks: "F", t: "normal" }, { k: "g", ks: "G", t: "normal" }, { k: "h", ks: "H", t: "normal" }, { k: "j", ks: "J", t: "normal" }, { k: "k", ks: "K", t: "normal" }, { k: "l", ks: "L", t: "normal" }, { k: ";", ks: ":", t: "normal" }, { k: "'", ks: '"', t: "normal" }, { k: "Enter", t: "expand" }],
        //     [{ k: "Shift", t: "shift" }, { k: "z", ks: "Z", t: "normal" }, { k: "x", ks: "X", t: "normal" }, { k: "c", ks: "C", t: "normal" }, { k: "v", ks: "V", t: "normal" }, { k: "b", ks: "B", t: "normal" }, { k: "n", ks: "N", t: "normal" }, { k: "m", ks: "M", t: "normal" }, { k: ",", ks: "<", t: "normal" }, { k: ".", ks: ">", t: "normal" }, { k: "/", ks: "?", t: "normal" }, { k: "Shift", t: "expand" }],
        //     [{ k: "Ctrl", t: "control" }, { k: "Fn", t: "normal" }, { k: "Win", t: "normal" }, { k: "Alt", t: "normal" }, { k: "Space", t: "space" }, { k: "Alt", t: "normal" }, { k: "Menu", t: "normal" }, { k: "Ctrl", t: "control" }]
        // ]
        // A normal key looks like this: {label: "a", labelShift: "A", shape: "normal", keycode: 30, type: "normal"}
        // A modkey looks like this: {label: "Ctrl", shape: "control", keycode: 29, type: "modkey"}
        // key types are: normal, tab, caps, shift, control, fn (normal w/ half height), space, expand
        keys: [
            [
                { keytype: "normal", label: "Esc", shape: "fn", keycode: 1 },
                { keytype: "normal", label: "F1", shape: "fn", keycode: 59 },
                { keytype: "normal", label: "F2", shape: "fn", keycode: 60 },
                { keytype: "normal", label: "F3", shape: "fn", keycode: 61 },
                { keytype: "normal", label: "F4", shape: "fn", keycode: 62 },
                { keytype: "normal", label: "F5", shape: "fn", keycode: 63 },
                { keytype: "normal", label: "F6", shape: "fn", keycode: 64 },
                { keytype: "normal", label: "F7", shape: "fn", keycode: 65 },
                { keytype: "normal", label: "F8", shape: "fn", keycode: 66 },
                { keytype: "normal", label: "F9", shape: "fn", keycode: 67 },
                { keytype: "normal", label: "F10", shape: "fn", keycode: 68 },
                { keytype: "normal", label: "F11", shape: "fn", keycode: 87 },
                { keytype: "normal", label: "F12", shape: "fn", keycode: 88 },
                { keytype: "normal", label: "PrtSc", shape: "fn", keycode: 99 },
                { keytype: "normal", label: "Del", shape: "fn", keycode: 111 }
            ],
            [
                { keytype: "normal", label: "`", labelShift: "~", shape: "normal", keycode: 41 },
                { keytype: "normal", label: "1", labelShift: "!", shape: "normal", keycode: 2 },
                { keytype: "normal", label: "2", labelShift: "@", shape: "normal", keycode: 3 },
                { keytype: "normal", label: "3", labelShift: "#", shape: "normal", keycode: 4 },
                { keytype: "normal", label: "4", labelShift: "$", shape: "normal", keycode: 5 },
                { keytype: "normal", label: "5", labelShift: "%", shape: "normal", keycode: 6 },
                { keytype: "normal", label: "6", labelShift: "^", shape: "normal", keycode: 7 },
                { keytype: "normal", label: "7", labelShift: "&", shape: "normal", keycode: 8 },
                { keytype: "normal", label: "8", labelShift: "*", shape: "normal", keycode: 9 },
                { keytype: "normal", label: "9", labelShift: "(", shape: "normal", keycode: 10 },
                { keytype: "normal", label: "0", labelShift: ")", shape: "normal", keycode: 11 },
                { keytype: "normal", label: "-", labelShift: "_", shape: "normal", keycode: 12 },
                { keytype: "normal", label: "=", labelShift: "+", shape: "normal", keycode: 13 },
                { keytype: "normal", label: "Backspace", shape: "expand", keycode: 14 }
            ],
            [
                { keytype: "normal", label: "Tab", shape: "tab", keycode: 15 },
                { keytype: "normal", label: "q", labelShift: "Q", shape: "normal", keycode: 16 },
                { keytype: "normal", label: "w", labelShift: "W", shape: "normal", keycode: 17 },
                { keytype: "normal", label: "e", labelShift: "E", shape: "normal", keycode: 18 },
                { keytype: "normal", label: "r", labelShift: "R", shape: "normal", keycode: 19 },
                { keytype: "normal", label: "t", labelShift: "T", shape: "normal", keycode: 20 },
                { keytype: "normal", label: "y", labelShift: "Y", shape: "normal", keycode: 21 },
                { keytype: "normal", label: "u", labelShift: "U", shape: "normal", keycode: 22 },
                { keytype: "normal", label: "i", labelShift: "I", shape: "normal", keycode: 23 },
                { keytype: "normal", label: "o", labelShift: "O", shape: "normal", keycode: 24 },
                { keytype: "normal", label: "p", labelShift: "P", shape: "normal", keycode: 25 },
                { keytype: "normal", label: "[", labelShift: "{", shape: "normal", keycode: 26 },
                { keytype: "normal", label: "]", labelShift: "}", shape: "normal", keycode: 27 },
                { keytype: "normal", label: "\\", labelShift: "|", shape: "expand", keycode: 43 }
            ],
            [
                //{ keytype: "normal", label: "Caps", shape: "caps", keycode: 58 }, // not needed as double-pressing shift does that
                { keytype: "spacer", label: "", shape: "empty" },
                { keytype: "spacer", label: "", shape: "empty" },
                { keytype: "normal", label: "a", labelShift: "A", shape: "normal", keycode: 30 },
                { keytype: "normal", label: "s", labelShift: "S", shape: "normal", keycode: 31 },
                { keytype: "normal", label: "d", labelShift: "D", shape: "normal", keycode: 32 },
                { keytype: "normal", label: "f", labelShift: "F", shape: "normal", keycode: 33 },
                { keytype: "normal", label: "g", labelShift: "G", shape: "normal", keycode: 34 },
                { keytype: "normal", label: "h", labelShift: "H", shape: "normal", keycode: 35 },
                { keytype: "normal", label: "j", labelShift: "J", shape: "normal", keycode: 36 },
                { keytype: "normal", label: "k", labelShift: "K", shape: "normal", keycode: 37 },
                { keytype: "normal", label: "l", labelShift: "L", shape: "normal", keycode: 38 },
                { keytype: "normal", label: ";", labelShift: ":", shape: "normal", keycode: 39 },
                { keytype: "normal", label: "'", labelShift: '"', shape: "normal", keycode: 40 },
                { keytype: "normal", label: "Enter", shape: "expand", keycode: 28 }
            ],
            [
                { keytype: "modkey", label: "Shift", labelShift: "Shift", labelCaps: "Caps", shape: "shift", keycode: 42 },
                { keytype: "normal", label: "z", labelShift: "Z", shape: "normal", keycode: 44 },
                { keytype: "normal", label: "x", labelShift: "X", shape: "normal", keycode: 45 },
                { keytype: "normal", label: "c", labelShift: "C", shape: "normal", keycode: 46 },
                { keytype: "normal", label: "v", labelShift: "V", shape: "normal", keycode: 47 },
                { keytype: "normal", label: "b", labelShift: "B", shape: "normal", keycode: 48 },
                { keytype: "normal", label: "n", labelShift: "N", shape: "normal", keycode: 49 },
                { keytype: "normal", label: "m", labelShift: "M", shape: "normal", keycode: 50 },
                { keytype: "normal", label: ",", labelShift: "<", shape: "normal", keycode: 51 },
                { keytype: "normal", label: ".", labelShift: ">", shape: "normal", keycode: 52 },
                { keytype: "normal", label: "/", labelShift: "?", shape: "normal", keycode: 53 },
                { keytype: "modkey", label: "Shift", labelShift: "Shift", labelCaps: "Caps", shape: "expand", keycode: 54 } // optional
            ],
            [
                { keytype: "modkey", label: "Ctrl", shape: "control", keycode: 29 },
                // { label: "Super", shape: "normal", keycode: 125 }, // dangerous
                { keytype: "modkey", label: "Alt", shape: "normal", keycode: 56 },
                { keytype: "normal", label: "Space", shape: "space", keycode: 57 },
                { keytype: "modkey", label: "Alt", shape: "normal", keycode: 100 },
                // { label: "Super", shape: "normal", keycode: 126 }, // dangerous
                { keytype: "normal", label: "Menu", shape: "normal", keycode: 139 },
                { keytype: "modkey", label: "Ctrl", shape: "control", keycode: 97 }
            ]
        ]
    },
    "German": {
        name_short: "DE",
        description: "QWERTZ - Full",
        comment: "Keyboard layout commonly used in German-speaking countries",
        keys: [
            [
                { keytype: "normal", label: "Esc", shape: "fn", keycode: 1 },
                { keytype: "normal", label: "F1", shape: "fn", keycode: 59 },
                { keytype: "normal", label: "F2", shape: "fn", keycode: 60 },
                { keytype: "normal", label: "F3", shape: "fn", keycode: 61 },
                { keytype: "normal", label: "F4", shape: "fn", keycode: 62 },
                { keytype: "normal", label: "F5", shape: "fn", keycode: 63 },
                { keytype: "normal", label: "F6", shape: "fn", keycode: 64 },
                { keytype: "normal", label: "F7", shape: "fn", keycode: 65 },
                { keytype: "normal", label: "F8", shape: "fn", keycode: 66 },
                { keytype: "normal", label: "F9", shape: "fn", keycode: 67 },
                { keytype: "normal", label: "F10", shape: "fn", keycode: 68 },
                { keytype: "normal", label: "F11", shape: "fn", keycode: 87 },
                { keytype: "normal", label: "F12", shape: "fn", keycode: 88 },
                { keytype: "normal", label: "Druck", shape: "fn", keycode: 99 },
                { keytype: "normal", label: "Entf", shape: "fn", keycode: 111 }
            ],
            [
                { keytype: "normal", label: "^", labelShift: "°", labelAlt: "′", shape: "normal", keycode: 41 },
                { keytype: "normal", label: "1", labelShift: "!", labelAlt: "¹", shape: "normal", keycode: 2 },
                { keytype: "normal", label: "2", labelShift: "\"", labelAlt: "²", shape: "normal", keycode: 3 },
                { keytype: "normal", label: "3", labelShift: "§", labelAlt: "³", shape: "normal", keycode: 4 },
                { keytype: "normal", label: "4", labelShift: "$", labelAlt: "¼", shape: "normal", keycode: 5 },
                { keytype: "normal", label: "5", labelShift: "%", labelAlt: "½", shape: "normal", keycode: 6 },
                { keytype: "normal", label: "6", labelShift: "&", labelAlt: "¬", shape: "normal", keycode: 7 },
                { keytype: "normal", label: "7", labelShift: "/", labelAlt: "{", shape: "normal", keycode: 8 },
                { keytype: "normal", label: "8", labelShift: "(", labelAlt: "[", shape: "normal", keycode: 9 },
                { keytype: "normal", label: "9", labelShift: ")", labelAlt: "]", shape: "normal", keycode: 10 },
                { keytype: "normal", label: "0", labelShift: "=", labelAlt: "}", shape: "normal", keycode: 11 },
                { keytype: "normal", label: "ß", labelShift: "?", labelAlt: "\\", shape: "normal", keycode: 12 },
                { keytype: "normal", label: "´", labelShift: "`", labelAlt: "¸", shape: "normal", keycode: 13 },
                { keytype: "normal", label: "⟵", shape: "expand", keycode: 14 }
            ],
            [
                { keytype: "normal", label: "Tab ⇆", shape: "tab", keycode: 15 },
                { keytype: "normal", label: "q", labelShift: "Q", labelAlt: "@", shape: "normal", keycode: 16 },
                { keytype: "normal", label: "w", labelShift: "W", labelAlt: "ſ", shape: "normal", keycode: 17 },
                { keytype: "normal", label: "e", labelShift: "E", labelAlt: "€", shape: "normal", keycode: 18 },
                { keytype: "normal", label: "r", labelShift: "R", labelAlt: "¶", shape: "normal", keycode: 19 },
                { keytype: "normal", label: "t", labelShift: "T", labelAlt: "ŧ", shape: "normal", keycode: 20 },
                { keytype: "normal", label: "z", labelShift: "Z", labelAlt: "←", shape: "normal", keycode: 21 },
                { keytype: "normal", label: "u", labelShift: "U", labelAlt: "↓", shape: "normal", keycode: 22 },
                { keytype: "normal", label: "i", labelShift: "I", labelAlt: "→", shape: "normal", keycode: 23 },
                { keytype: "normal", label: "o", labelShift: "O", labelAlt: "ø", shape: "normal", keycode: 24 },
                { keytype: "normal", label: "p", labelShift: "P", labelAlt: "þ", shape: "normal", keycode: 25 },
                { keytype: "normal", label: "ü", labelShift: "Ü", labelAlt: "¨", shape: "normal", keycode: 26 },
                { keytype: "normal", label: "+", labelShift: "*", labelAlt: "~", shape: "normal", keycode: 27 },
                { keytype: "normal", label: "↵", shape: "expand", keycode: 28 }
            ],
            [
                //{ keytype: "normal", label: "Umschalt ⇩", shape: "caps", keycode: 58 },
                { keytype: "spacer", label: "", shape: "empty" },
                { keytype: "spacer", label: "", shape: "empty" },
                { keytype: "normal", label: "a", labelShift: "A", labelAlt: "æ", shape: "normal", keycode: 30 },
                { keytype: "normal", label: "s", labelShift: "S", labelAlt: "ſ", shape: "normal", keycode: 31 },
                { keytype: "normal", label: "d", labelShift: "D", labelAlt: "ð", shape: "normal", keycode: 32 },
                { keytype: "normal", label: "f", labelShift: "F", labelAlt: "đ", shape: "normal", keycode: 33 },
                { keytype: "normal", label: "g", labelShift: "G", labelAlt: "ŋ", shape: "normal", keycode: 34 },
                { keytype: "normal", label: "h", labelShift: "H", labelAlt: "ħ", shape: "normal", keycode: 35 },
                { keytype: "normal", label: "j", labelShift: "J", labelAlt: "", shape: "normal", keycode: 36 },
                { keytype: "normal", label: "k", labelShift: "K", labelAlt: "ĸ", shape: "normal", keycode: 37 },
                { keytype: "normal", label: "l", labelShift: "L", labelAlt: "ł", shape: "normal", keycode: 38 },
                { keytype: "normal", label: "ö", labelShift: "Ö", labelAlt: "˝", shape: "normal", keycode: 39 },
                { keytype: "normal", label: "ä", labelShift: 'Ä', labelAlt: "^", shape: "normal", keycode: 40 },
                { keytype: "normal", label: "#", labelShift: '\'', labelAlt: "’", shape: "normal", keycode: 43 },
                { keytype: "spacer", label: "", shape: "empty" },
                //{ keytype: "normal", label: "↵", shape: "expand", keycode: 28 }
            ],
            [
                { keytype: "modkey", label: "Shift", labelShift: "Shift ⇧", labelCaps: "Locked ⇩", shape: "shift", keycode: 42 },
                { keytype: "normal", label: "<", labelShift: ">", labelAlt: "|", shape: "normal", keycode: 86 },
                { keytype: "normal", label: "y", labelShift: "Y", labelAlt: "»", shape: "normal", keycode: 44 },
                { keytype: "normal", label: "x", labelShift: "X", labelAlt: "«", shape: "normal", keycode: 45 },
                { keytype: "normal", label: "c", labelShift: "C", labelAlt: "¢", shape: "normal", keycode: 46 },
                { keytype: "normal", label: "v", labelShift: "V", labelAlt: "„", shape: "normal", keycode: 47 },
                { keytype: "normal", label: "b", labelShift: "B", labelAlt: "“", shape: "normal", keycode: 48 },
                { keytype: "normal", label: "n", labelShift: "N", labelAlt: "”", shape: "normal", keycode: 49 },
                { keytype: "normal", label: "m", labelShift: "M", labelAlt: "µ", shape: "normal", keycode: 50 },
                { keytype: "normal", label: ",", labelShift: ";", labelAlt: "·", shape: "normal", keycode: 51 },
                { keytype: "normal", label: ".", labelShift: ":", labelAlt: "…", shape: "normal", keycode: 52 },
                { keytype: "normal", label: "-", labelShift: "_", labelAlt: "–", shape: "normal", keycode: 53 },
                { keytype: "modkey", label: "Shift", labelShift: "Shift ⇧", labelCaps: "Locked ⇩", shape: "expand", keycode: 54 }, // optional
            ],
            [
                { keytype: "modkey", label: "Strg", shape: "control", keycode: 29 },
                //{ keytype: "normal", label: "", shape: "normal", keycode: 125 }, // dangerous
                { keytype: "modkey", label: "Alt", shape: "normal", keycode: 56 },
                { keytype: "normal", label: "Leertaste", shape: "space", keycode: 57 },
                { keytype: "modkey", label: "Alt Gr", shape: "normal", keycode: 100 },
                // { label: "Super", shape: "normal", keycode: 126 }, // dangerous
                //{ keytype: "normal", label: "Menu", shape: "normal", keycode: 139 }, // doesn't work?
                { keytype: "modkey", label: "Strg", shape: "control", keycode: 97 },
                { keytype: "normal", label: "⇦", shape: "normal", keycode: 105 },
                { keytype: "normal", label: "⇨", shape: "normal", keycode: 106 },
            ]
        ]
    },
    "Russian": {
        name_short: "RU",
        description: "ЙЦУКЕН - Full",
        comment: "Standard Russian keyboard layout",
        keys: [
            [
                { keytype: "normal", label: "Esc", shape: "fn", keycode: 1 },
                { keytype: "normal", label: "F1", shape: "fn", keycode: 59 },
                { keytype: "normal", label: "F2", shape: "fn", keycode: 60 },
                { keytype: "normal", label: "F3", shape: "fn", keycode: 61 },
                { keytype: "normal", label: "F4", shape: "fn", keycode: 62 },
                { keytype: "normal", label: "F5", shape: "fn", keycode: 63 },
                { keytype: "normal", label: "F6", shape: "fn", keycode: 64 },
                { keytype: "normal", label: "F7", shape: "fn", keycode: 65 },
                { keytype: "normal", label: "F8", shape: "fn", keycode: 66 },
                { keytype: "normal", label: "F9", shape: "fn", keycode: 67 },
                { keytype: "normal", label: "F10", shape: "fn", keycode: 68 },
                { keytype: "normal", label: "F11", shape: "fn", keycode: 87 },
                { keytype: "normal", label: "F12", shape: "fn", keycode: 88 },
                { keytype: "normal", label: "PrtSc", shape: "fn", keycode: 99 },
                { keytype: "normal", label: "Del", shape: "fn", keycode: 111 }
            ],
            [
                { keytype: "normal", label: "ё", labelShift: "Ё", shape: "normal", keycode: 41 },
                { keytype: "normal", label: "1", labelShift: "!", shape: "normal", keycode: 2 },
                { keytype: "normal", label: "2", labelShift: "\"", shape: "normal", keycode: 3 },
                { keytype: "normal", label: "3", labelShift: "№", shape: "normal", keycode: 4 },
                { keytype: "normal", label: "4", labelShift: ";", shape: "normal", keycode: 5 },
                { keytype: "normal", label: "5", labelShift: "%", shape: "normal", keycode: 6 },
                { keytype: "normal", label: "6", labelShift: ":", shape: "normal", keycode: 7 },
                { keytype: "normal", label: "7", labelShift: "?", shape: "normal", keycode: 8 },
                { keytype: "normal", label: "8", labelShift: "*", shape: "normal", keycode: 9 },
                { keytype: "normal", label: "9", labelShift: "(", shape: "normal", keycode: 10 },
                { keytype: "normal", label: "0", labelShift: ")", shape: "normal", keycode: 11 },
                { keytype: "normal", label: "-", labelShift: "_", shape: "normal", keycode: 12 },
                { keytype: "normal", label: "=", labelShift: "+", shape: "normal", keycode: 13 },
                { keytype: "normal", label: "Backspace", shape: "expand", keycode: 14 }
            ],
            [
                { keytype: "normal", label: "Tab", shape: "tab", keycode: 15 },
                { keytype: "normal", label: "й", labelShift: "Й", shape: "normal", keycode: 16 },
                { keytype: "normal", label: "ц", labelShift: "Ц", shape: "normal", keycode: 17 },
                { keytype: "normal", label: "у", labelShift: "У", shape: "normal", keycode: 18 },
                { keytype: "normal", label: "к", labelShift: "К", shape: "normal", keycode: 19 },
                { keytype: "normal", label: "е", labelShift: "Е", shape: "normal", keycode: 20 },
                { keytype: "normal", label: "н", labelShift: "Н", shape: "normal", keycode: 21 },
                { keytype: "normal", label: "г", labelShift: "Г", shape: "normal", keycode: 22 },
                { keytype: "normal", label: "ш", labelShift: "Ш", shape: "normal", keycode: 23 },
                { keytype: "normal", label: "щ", labelShift: "Щ", shape: "normal", keycode: 24 },
                { keytype: "normal", label: "з", labelShift: "З", shape: "normal", keycode: 25 },
                { keytype: "normal", label: "х", labelShift: "Х", shape: "normal", keycode: 26 },
                { keytype: "normal", label: "ъ", labelShift: "Ъ", shape: "normal", keycode: 27 },
                { keytype: "normal", label: "\\", labelShift: "/", shape: "expand", keycode: 43 }
            ],
            [
                { keytype: "spacer", label: "", shape: "empty" },
                { keytype: "spacer", label: "", shape: "empty" },
                { keytype: "normal", label: "ф", labelShift: "Ф", shape: "normal", keycode: 30 },
                { keytype: "normal", label: "ы", labelShift: "Ы", shape: "normal", keycode: 31 },
                { keytype: "normal", label: "в", labelShift: "В", shape: "normal", keycode: 32 },
                { keytype: "normal", label: "а", labelShift: "А", shape: "normal", keycode: 33 },
                { keytype: "normal", label: "п", labelShift: "П", shape: "normal", keycode: 34 },
                { keytype: "normal", label: "р", labelShift: "Р", shape: "normal", keycode: 35 },
                { keytype: "normal", label: "о", labelShift: "О", shape: "normal", keycode: 36 },
                { keytype: "normal", label: "л", labelShift: "Л", shape: "normal", keycode: 37 },
                { keytype: "normal", label: "д", labelShift: "Д", shape: "normal", keycode: 38 },
                { keytype: "normal", label: "ж", labelShift: "Ж", shape: "normal", keycode: 39 },
                { keytype: "normal", label: "э", labelShift: "Э", shape: "normal", keycode: 40 },
                { keytype: "normal", label: "Enter", shape: "expand", keycode: 28 }
            ],
            [
                { keytype: "modkey", label: "Shift", shape: "shift", keycode: 42 },
                { keytype: "normal", label: "я", labelShift: "Я", shape: "normal", keycode: 44 },
                { keytype: "normal", label: "ч", labelShift: "Ч", shape: "normal", keycode: 45 },
                { keytype: "normal", label: "с", labelShift: "С", shape: "normal", keycode: 46 },
                { keytype: "normal", label: "м", labelShift: "М", shape: "normal", keycode: 47 },
                { keytype: "normal", label: "и", labelShift: "И", shape: "normal", keycode: 48 },
                { keytype: "normal", label: "т", labelShift: "Т", shape: "normal", keycode: 49 },
                { keytype: "normal", label: "ь", labelShift: "Ь", shape: "normal", keycode: 50 },
                { keytype: "normal", label: "б", labelShift: "Б", shape: "normal", keycode: 51 },
                { keytype: "normal", label: "ю", labelShift: "Ю", shape: "normal", keycode: 52 },
                { keytype: "normal", label: ".", labelShift: ",", shape: "normal", keycode: 53 },
                { keytype: "modkey", label: "Shift", shape: "expand", keycode: 54 }
            ],
            [
                { keytype: "modkey", label: "Ctrl", shape: "control", keycode: 29 },
                { keytype: "modkey", label: "Alt", shape: "normal", keycode: 56 },
                { keytype: "normal", label: "Space", shape: "space", keycode: 57 },
                { keytype: "modkey", label: "Alt", shape: "normal", keycode: 100 },
                { keytype: "normal", label: "Menu", shape: "normal", keycode: 139 },
                { keytype: "modkey", label: "Ctrl", shape: "control", keycode: 97 }
            ]
        ]
    }
}
