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
  },
  "Greek (polytonic)": {
    name_short: "EL",
    description: "Polytonic Greek - Full",
    comment: "Greek keyboard layout with polytonic diacritical marks (XKB gr(polytonic))",
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
        { keytype: "normal", label: "῀", labelShift: "῀", labelAlt: "`", shape: "normal", keycode: 41 }, // dead perispomeni / AltGr: grave
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
        { keytype: "normal", label: "῀", labelShift: "῀", labelAlt: ";", shape: "normal", keycode: 16 }, // q → dead perispomeni / AltGr: ; (Greek question mark)
        { keytype: "normal", label: "ς", labelShift: "Σ", labelAlt: "¨", shape: "normal", keycode: 17 }, // w → final sigma / AltGr: dead diaeresis
        { keytype: "normal", label: "ε", labelShift: "Ε", shape: "normal", keycode: 18 },
        { keytype: "normal", label: "ρ", labelShift: "Ρ", shape: "normal", keycode: 19 },
        { keytype: "normal", label: "τ", labelShift: "Τ", shape: "normal", keycode: 20 },
        { keytype: "normal", label: "υ", labelShift: "Υ", shape: "normal", keycode: 21 },
        { keytype: "normal", label: "θ", labelShift: "Θ", shape: "normal", keycode: 22 },
        { keytype: "normal", label: "ι", labelShift: "Ι", shape: "normal", keycode: 23 },
        { keytype: "normal", label: "ο", labelShift: "Ο", shape: "normal", keycode: 24 },
        { keytype: "normal", label: "π", labelShift: "Π", shape: "normal", keycode: 25 },
        { keytype: "normal", label: "[", labelShift: "{", labelAlt: "«", shape: "normal", keycode: 26 },
        { keytype: "normal", label: "]", labelShift: "}", labelAlt: "»", shape: "normal", keycode: 27 },
        { keytype: "normal", label: "\\", labelShift: "|", shape: "expand", keycode: 43 }
      ],
      [
        { keytype: "spacer", label: "", shape: "empty" },
        { keytype: "spacer", label: "", shape: "empty" },
        { keytype: "normal", label: "α", labelShift: "Α", shape: "normal", keycode: 30 },
        { keytype: "normal", label: "σ", labelShift: "Σ", shape: "normal", keycode: 31 },
        { keytype: "normal", label: "δ", labelShift: "Δ", shape: "normal", keycode: 32 },
        { keytype: "normal", label: "φ", labelShift: "Φ", shape: "normal", keycode: 33 },
        { keytype: "normal", label: "γ", labelShift: "Γ", shape: "normal", keycode: 34 },
        { keytype: "normal", label: "η", labelShift: "Η", shape: "normal", keycode: 35 },
        { keytype: "normal", label: "ξ", labelShift: "Ξ", shape: "normal", keycode: 36 },
        { keytype: "normal", label: "κ", labelShift: "Κ", shape: "normal", keycode: 37 },
        { keytype: "normal", label: "λ", labelShift: "Λ", shape: "normal", keycode: 38 },
        { keytype: "normal", label: "´", labelShift: "¨", labelAlt: "ͺ", shape: "normal", keycode: 39 }, // dead oxia / dead dialytika / AltGr: iota subscript
        { keytype: "normal", label: "`", labelShift: "`", labelAlt: "'", shape: "normal", keycode: 40 }, // dead varia / AltGr: apostrophe
        { keytype: "normal", label: "Enter", shape: "expand", keycode: 28 }
      ],
      [
        { keytype: "modkey", label: "Shift", labelShift: "Shift", labelCaps: "Caps", shape: "shift", keycode: 42 },
        { keytype: "normal", label: "ζ", labelShift: "Ζ", shape: "normal", keycode: 44 },
        { keytype: "normal", label: "χ", labelShift: "Χ", shape: "normal", keycode: 45 },
        { keytype: "normal", label: "ψ", labelShift: "Ψ", shape: "normal", keycode: 46 },
        { keytype: "normal", label: "ω", labelShift: "Ω", shape: "normal", keycode: 47 },
        { keytype: "normal", label: "β", labelShift: "Β", shape: "normal", keycode: 48 },
        { keytype: "normal", label: "ν", labelShift: "Ν", shape: "normal", keycode: 49 },
        { keytype: "normal", label: "μ", labelShift: "Μ", shape: "normal", keycode: 50 },
        { keytype: "normal", label: ",", labelShift: "<", shape: "normal", keycode: 51 },
        { keytype: "normal", label: ".", labelShift: ">", shape: "normal", keycode: 52 },
        { keytype: "normal", label: "/", labelShift: "?", shape: "normal", keycode: 53 },
        { keytype: "modkey", label: "Shift", labelShift: "Shift", labelCaps: "Caps", shape: "expand", keycode: 54 }
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
  },
  "Arabic": {
    name_short: "AR",
    description: "Arabic Standard - Full",
    comment: "Standard Arabic keyboard layout (XKB ara)",
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
        { keytype: "normal", label: "ذ", labelShift: "ّ", shape: "normal", keycode: 41 }, // Thal / Shadda
        { keytype: "normal", label: "١", labelShift: "!", labelAlt: "1", shape: "normal", keycode: 2 },
        { keytype: "normal", label: "٢", labelShift: "@", labelAlt: "2", shape: "normal", keycode: 3 },
        { keytype: "normal", label: "٣", labelShift: "#", labelAlt: "3", shape: "normal", keycode: 4 },
        { keytype: "normal", label: "٤", labelShift: "$", labelAlt: "4", shape: "normal", keycode: 5 },
        { keytype: "normal", label: "٥", labelShift: "%", labelAlt: "5", shape: "normal", keycode: 6 },
        { keytype: "normal", label: "٦", labelShift: "^", labelAlt: "6", shape: "normal", keycode: 7 },
        { keytype: "normal", label: "٧", labelShift: "&", labelAlt: "7", shape: "normal", keycode: 8 },
        { keytype: "normal", label: "٨", labelShift: "*", labelAlt: "8", shape: "normal", keycode: 9 },
        { keytype: "normal", label: "٩", labelShift: "(", labelAlt: "9", shape: "normal", keycode: 10 },
        { keytype: "normal", label: "٠", labelShift: ")", labelAlt: "0", shape: "normal", keycode: 11 },
        { keytype: "normal", label: "-", labelShift: "_", shape: "normal", keycode: 12 },
        { keytype: "normal", label: "=", labelShift: "+", shape: "normal", keycode: 13 },
        { keytype: "normal", label: "Backspace", shape: "expand", keycode: 14 }
      ],
      [
        { keytype: "normal", label: "Tab", shape: "tab", keycode: 15 },
        { keytype: "normal", label: "ض", labelShift: "َ", shape: "normal", keycode: 16 }, // Dad / Fatha
        { keytype: "normal", label: "ص", labelShift: "ً", shape: "normal", keycode: 17 }, // Sad / Fathatan
        { keytype: "normal", label: "ث", labelShift: "ُ", shape: "normal", keycode: 18 }, // Tha / Damma
        { keytype: "normal", label: "ق", labelShift: "ٌ", shape: "normal", keycode: 19 }, // Qaf / Dammatan
        { keytype: "normal", label: "ف", labelShift: "لإ", shape: "normal", keycode: 20 }, // Fa / Lam-Alef-Hamza-Below
        { keytype: "normal", label: "غ", labelShift: "إ", shape: "normal", keycode: 21 }, // Ghayn / Alef-Hamza-Below
        { keytype: "normal", label: "ع", labelShift: "`", shape: "normal", keycode: 22 }, // Ain / Grave
        { keytype: "normal", label: "ه", labelShift: "÷", shape: "normal", keycode: 23 }, // Ha / Division
        { keytype: "normal", label: "خ", labelShift: "×", shape: "normal", keycode: 24 }, // Kha / Multiplication
        { keytype: "normal", label: "ح", labelShift: "؛", shape: "normal", keycode: 25 }, // Hah / Arabic semicolon
        { keytype: "normal", label: "ج", labelShift: "<", shape: "normal", keycode: 26 }, // Jeem / <
        { keytype: "normal", label: "د", labelShift: ">", shape: "normal", keycode: 27 }, // Dal / >
        { keytype: "normal", label: "\\", labelShift: "|", shape: "expand", keycode: 43 }
      ],
      [
        { keytype: "spacer", label: "", shape: "empty" },
        { keytype: "spacer", label: "", shape: "empty" },
        { keytype: "normal", label: "ش", labelShift: "ِ", shape: "normal", keycode: 30 }, // Sheen / Kasra
        { keytype: "normal", label: "س", labelShift: "ٍ", shape: "normal", keycode: 31 }, // Seen / Kasratan
        { keytype: "normal", label: "ي", labelShift: "]", shape: "normal", keycode: 32 }, // Ya / ]
        { keytype: "normal", label: "ب", labelShift: "[", shape: "normal", keycode: 33 }, // Ba / [
        { keytype: "normal", label: "ل", labelShift: "لأ", shape: "normal", keycode: 34 }, // Lam / Lam-Alef-Hamza-Above
        { keytype: "normal", label: "ا", labelShift: "أ", shape: "normal", keycode: 35 }, // Alef / Alef-Hamza-Above
        { keytype: "normal", label: "ت", labelShift: "ـ", shape: "normal", keycode: 36 }, // Ta / Tatweel
        { keytype: "normal", label: "ن", labelShift: "،", shape: "normal", keycode: 37 }, // Nun / Arabic comma
        { keytype: "normal", label: "م", labelShift: "/", shape: "normal", keycode: 38 }, // Meem / Slash
        { keytype: "normal", label: "ك", labelShift: ":", shape: "normal", keycode: 39 }, // Kaf / Colon
        { keytype: "normal", label: "ط", labelShift: '"', shape: "normal", keycode: 40 }, // Tah / Quote
        { keytype: "normal", label: "Enter", shape: "expand", keycode: 28 }
      ],
      [
        { keytype: "modkey", label: "Shift", labelShift: "Shift", labelCaps: "Caps", shape: "shift", keycode: 42 },
        { keytype: "normal", label: "ئ", labelShift: "~", shape: "normal", keycode: 44 }, // Hamza-on-Ya / Tilde
        { keytype: "normal", label: "ء", labelShift: "ْ", shape: "normal", keycode: 45 }, // Hamza / Sukun
        { keytype: "normal", label: "ؤ", labelShift: "{", shape: "normal", keycode: 46 }, // Hamza-on-Waw / {
        { keytype: "normal", label: "ر", labelShift: "}", shape: "normal", keycode: 47 }, // Ra / }
        { keytype: "normal", label: "لا", labelShift: "لآ", shape: "normal", keycode: 48 }, // Lam-Alef / Lam-Alef-Madda
        { keytype: "normal", label: "ى", labelShift: "آ", shape: "normal", keycode: 49 }, // Alef Maksura / Alef-Madda
        { keytype: "normal", label: "ة", labelShift: "'", shape: "normal", keycode: 50 }, // Ta Marbuta / Apostrophe
        { keytype: "normal", label: "و", labelShift: ",", shape: "normal", keycode: 51 }, // Waw / Comma
        { keytype: "normal", label: "ز", labelShift: ".", shape: "normal", keycode: 52 }, // Zay / Period
        { keytype: "normal", label: "ظ", labelShift: "؟", shape: "normal", keycode: 53 }, // Zha / Arabic question mark
        { keytype: "modkey", label: "Shift", labelShift: "Shift", labelCaps: "Caps", shape: "expand", keycode: 54 }
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
  },
  "Persian": {
    name_short: "FA",
    description: "Persian ISIRI 9147 - Full",
    comment: "Standard Persian keyboard layout (XKB ir(pes), ISIRI 9147)",
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
        { keytype: "normal", label: "ZWJ", labelShift: "÷", labelAlt: "~", shape: "normal", keycode: 41 }, // Zero-Width Joiner / division
        { keytype: "normal", label: "۱", labelShift: "!", labelAlt: "1", shape: "normal", keycode: 2 },
        { keytype: "normal", label: "۲", labelShift: "٬", labelAlt: "2", shape: "normal", keycode: 3 }, // Arabic thousands separator
        { keytype: "normal", label: "۳", labelShift: "٫", labelAlt: "3", shape: "normal", keycode: 4 }, // Arabic decimal separator
        { keytype: "normal", label: "۴", labelShift: "﷼", labelAlt: "4", shape: "normal", keycode: 5 }, // Rial sign
        { keytype: "normal", label: "۵", labelShift: "٪", labelAlt: "5", shape: "normal", keycode: 6 }, // Arabic percent
        { keytype: "normal", label: "۶", labelShift: "×", labelAlt: "6", shape: "normal", keycode: 7 },
        { keytype: "normal", label: "۷", labelShift: "،", labelAlt: "7", shape: "normal", keycode: 8 }, // Arabic comma
        { keytype: "normal", label: "۸", labelShift: "*", labelAlt: "8", shape: "normal", keycode: 9 },
        { keytype: "normal", label: "۹", labelShift: ")", labelAlt: "9", shape: "normal", keycode: 10 }, // RTL-swapped parens
        { keytype: "normal", label: "۰", labelShift: "(", labelAlt: "0", shape: "normal", keycode: 11 }, // RTL-swapped parens
        { keytype: "normal", label: "-", labelShift: "ـ", shape: "normal", keycode: 12 }, // minus / tatweel
        { keytype: "normal", label: "=", labelShift: "+", shape: "normal", keycode: 13 },
        { keytype: "normal", label: "Backspace", shape: "expand", keycode: 14 }
      ],
      [
        { keytype: "normal", label: "Tab", shape: "tab", keycode: 15 },
        { keytype: "normal", label: "ض", labelShift: "ْ", shape: "normal", keycode: 16 }, // Dad / Sukun
        { keytype: "normal", label: "ص", labelShift: "ٌ", shape: "normal", keycode: 17 }, // Sad / Dammatan
        { keytype: "normal", label: "ث", labelShift: "ٍ", labelAlt: "€", shape: "normal", keycode: 18 }, // Theh / Kasratan
        { keytype: "normal", label: "ق", labelShift: "ً", shape: "normal", keycode: 19 }, // Qaf / Fathatan
        { keytype: "normal", label: "ف", labelShift: "ُ", shape: "normal", keycode: 20 }, // Feh / Damma
        { keytype: "normal", label: "غ", labelShift: "ِ", shape: "normal", keycode: 21 }, // Ghain / Kasra
        { keytype: "normal", label: "ع", labelShift: "َ", shape: "normal", keycode: 22 }, // Ain / Fatha
        { keytype: "normal", label: "ه", labelShift: "ّ", shape: "normal", keycode: 23 }, // Heh / Shadda
        { keytype: "normal", label: "خ", labelShift: "]", shape: "normal", keycode: 24 }, // Khah / ]
        { keytype: "normal", label: "ح", labelShift: "[", shape: "normal", keycode: 25 }, // Hah / [
        { keytype: "normal", label: "ج", labelShift: "}", shape: "normal", keycode: 26 }, // Jeem / }
        { keytype: "normal", label: "چ", labelShift: "{", shape: "normal", keycode: 27 }, // Tcheh / {
        { keytype: "normal", label: "\\", labelShift: "|", shape: "expand", keycode: 43 }
      ],
      [
        { keytype: "spacer", label: "", shape: "empty" },
        { keytype: "spacer", label: "", shape: "empty" },
        { keytype: "normal", label: "ش", labelShift: "ؤ", shape: "normal", keycode: 30 }, // Sheen / Hamza-on-Waw
        { keytype: "normal", label: "س", labelShift: "ئ", shape: "normal", keycode: 31 }, // Seen / Hamza-on-Yeh
        { keytype: "normal", label: "ی", labelShift: "ي", shape: "normal", keycode: 32 }, // Farsi Yeh / Arabic Yeh
        { keytype: "normal", label: "ب", labelShift: "إ", shape: "normal", keycode: 33 }, // Beh / Alef-Hamza-Below
        { keytype: "normal", label: "ل", labelShift: "أ", shape: "normal", keycode: 34 }, // Lam / Alef-Hamza-Above
        { keytype: "normal", label: "ا", labelShift: "آ", shape: "normal", keycode: 35 }, // Alef / Alef-Madda
        { keytype: "normal", label: "ت", labelShift: "ة", shape: "normal", keycode: 36 }, // Teh / Teh Marbuta
        { keytype: "normal", label: "ن", labelShift: "»", shape: "normal", keycode: 37 }, // Noon / Right guillemet
        { keytype: "normal", label: "م", labelShift: "«", shape: "normal", keycode: 38 }, // Meem / Left guillemet
        { keytype: "normal", label: "ک", labelShift: ":", shape: "normal", keycode: 39 }, // Keheh / Colon
        { keytype: "normal", label: "گ", labelShift: "؛", shape: "normal", keycode: 40 }, // Gaf / Arabic semicolon
        { keytype: "normal", label: "Enter", shape: "expand", keycode: 28 }
      ],
      [
        { keytype: "modkey", label: "Shift", labelShift: "Shift", labelCaps: "Caps", shape: "shift", keycode: 42 },
        { keytype: "normal", label: "ظ", labelShift: "ك", shape: "normal", keycode: 44 }, // Zah / Arabic Kaf
        { keytype: "normal", label: "ط", labelShift: "ٓ", shape: "normal", keycode: 45 }, // Tah / Maddah above
        { keytype: "normal", label: "ز", labelShift: "ژ", shape: "normal", keycode: 46 }, // Zain / Jeh (Persian Zhe)
        { keytype: "normal", label: "ر", labelShift: "ٰ", shape: "normal", keycode: 47 }, // Ra / Superscript Alef
        { keytype: "normal", label: "ذ", labelShift: "ZWNJ", shape: "normal", keycode: 48 }, // Thal / Zero-Width Non-Joiner
        { keytype: "normal", label: "د", labelShift: "ٔ", shape: "normal", keycode: 49 }, // Dal / Hamza above
        { keytype: "normal", label: "پ", labelShift: "ء", shape: "normal", keycode: 50 }, // Peh / Hamza
        { keytype: "normal", label: "و", labelShift: ">", shape: "normal", keycode: 51 }, // Waw / >
        { keytype: "normal", label: ".", labelShift: "<", shape: "normal", keycode: 52 }, // Period / <
        { keytype: "normal", label: "/", labelShift: "؟", shape: "normal", keycode: 53 }, // Slash / Arabic question mark
        { keytype: "modkey", label: "Shift", labelShift: "Shift", labelCaps: "Caps", shape: "expand", keycode: 54 }
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
