import Service from 'resource:///com/github/Aylur/ags/service.js';
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js';

import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import Soup from 'gi://Soup?version=3.0';
import { fileExists } from '../modules/.miscutils/files.js';

import querystring from '../modules/.miscutils/querystring.js'
import { writable } from '../modules/.miscutils/store.js';

let LANGUAGES = writable ({
    "auto": "Auto",
    "ru": "Russian",
    "en": "English",
    "us": "USA",
    "fr": "French",
    "ja": "Japanese",
    "zh-cn": "Chinese S.",
    "zh-tw": "Chinese T.",
    "tr": "Turkish",
    // "af": "Afrikaans",
    // "sq": "Albanian",
    // "am": "Amharic",
    // "ar": "Arabic",
    // "hy": "Armenian",
    // "az": "Azerbaijani",
    // "eu": "Basque",
    // "be": "Belarusian",
    // "bn": "Bengali",
    // "bs": "Bosnian",
    // "bg": "Bulgarian",
    // "ca": "Catalan",
    // "ceb": "Cebuano",
    // "ny": "Chichewa",
    // "zh-cn": "Chinese Simplified",
    // "zh-tw": "Chinese Traditional",
    // "co": "Corsican",
    // "hr": "Croatian",
    // "cs": "Czech",
    // "da": "Danish",
    // "nl": "Dutch",
    // "en": "English",
    // "eo": "Esperanto",
    // "et": "Estonian",
    // "tl": "Filipino",
    // "fi": "Finnish",
    // "fr": "French",
    // "fy": "Frisian",
    // "gl": "Galician",
    // "ka": "Georgian",
    // "de": "German",
    // "el": "Greek",
    // "gu": "Gujarati",
    // "ht": "Haitian Creole",
    // "ha": "Hausa",
    // "haw": "Hawaiian",
    // "iw": "Hebrew",
    // "hi": "Hindi",
    // "hmn": "Hmong",
    // "hu": "Hungarian",
    // "is": "Icelandic",
    // "ig": "Igbo",
    // "id": "Indonesian",
    // "ga": "Irish",
    // "it": "Italian",
    // "ja": "Japanese",
    // "jw": "Javanese",
    // "kn": "Kannada",
    // "kk": "Kazakh",
    // "km": "Khmer",
    // "ko": "Korean",
    // "ku": "Kurdish (Kurmanji)",
    // "ky": "Kyrgyz",
    // "lo": "Lao",
    // "la": "Latin",
    // "lv": "Latvian",
    // "lt": "Lithuanian",
    // "lb": "Luxembourgish",
    // "mk": "Macedonian",
    // "mg": "Malagasy",
    // "ms": "Malay",
    // "ml": "Malayalam",
    // "mt": "Maltese",
    // "mi": "Maori",
    // "mr": "Marathi",
    // "mn": "Mongolian",
    // "my": "Myanmar (Burmese)",
    // "ne": "Nepali",
    // "no": "Norwegian",
    // "ps": "Pashto",
    // "fa": "Persian",
    // "pl": "Polish",
    // "pt": "Portuguese",
    // "pa": "Punjabi",
    // "ro": "Romanian",
    // "ru": "Russian",
    // "sm": "Samoan",
    // "gd": "Scots Gaelic",
    // "sr": "Serbian",
    // "st": "Sesotho",
    // "sn": "Shona",
    // "sd": "Sindhi",
    // "si": "Sinhala",
    // "sk": "Slovak",
    // "sl": "Slovenian",
    // "so": "Somali",
    // "es": "Spanish",
    // "su": "Sundanese",
    // "sw": "Swahili",
    // "sv": "Swedish",
    // "tg": "Tajik",
    // "ta": "Tamil",
    // "te": "Telugu",
    // "th": "Thai",
    // "tr": "Turkish",
    // "uk": "Ukrainian",
    // "ur": "Urdu",
    // "uz": "Uzbek",
    // "vi": "Vietnamese",
    // "cy": "Welsh",
    // "xh": "Xhosa",
    // "yi": "Yiddish",
    // "yo": "Yoruba",
    // "zu": "Zulu"
}); userOptions.asyncGet().sidebar.translater?.languages;
userOptions.subscribe ((userOptions) => {
    const langs = userOptions.sidebar.translater?.languages;
    if (typeof langs == 'object') { LANGUAGES.set(langs); }
});
/**
 * Last update: 2/11/2018
 * https://translate.google.com/translate/releases/twsfe_w_20160620_RC00/r/js/desktop_module_main.js
 *
 * Everything between 'BEGIN' and 'END' was copied from the script above.
 */

/* eslint-disable */
// BEGIN
function zr(a) {
    let b;
    if (null !== yr) b = yr;
    else {
        b = wr(String.fromCharCode(84));
        let c = wr(String.fromCharCode(75));
        b = [ b(), b() ];
        b[1] = c();
        b = (yr = window[b.join(c())] || "") || "";
    }
    let d = wr(String.fromCharCode(116));
    let c = wr(String.fromCharCode(107));
    d = [ d(), d() ];
    d[1] = c();
    c = "&" + d.join("") + "=";
    d = b.split(".");
    b = Number(d[0]) || 0;
    // eslint-disable-next-line no-var
    for (var e = [], f = 0, g = 0; g < a.length; g++) {
        let l = a.charCodeAt(g);
        128 > l ? e[f++] = l : (2048 > l ? e[f++] = l >> 6 | 192 : ((l & 64512) == 55296 && g + 1 < a.length && (a.charCodeAt(g + 1) & 64512) == 56320 ? (l = 65536 + ((l & 1023) << 10) + (a.charCodeAt(++g) & 1023), e[f++] = l >> 18 | 240, e[f++] = l >> 12 & 63 | 128) : e[f++] = l >> 12 | 224, e[f++] = l >> 6 & 63 | 128), e[f++] = l & 63 | 128);
    }
    a = b;
    for (let f = 0; f < e.length; f++) a += e[f], a = xr(a, "+-a^+6");
    a = xr(a, "+-3^+b+-f");
    a ^= Number(d[1]) || 0;
    0 > a && (a = (a & 2147483647) + 2147483648);
    a %= 1E6;
    return c + (a.toString() + "." + (a ^ b));
}

let yr = null;
let wr = function(a) {
    return function() {
        return a;
    };
};
let xr = function(a, b) {
    for (let c = 0; c < b.length - 2; c += 3) {
        let d = b.charAt(c + 2);
        d = d >= "a" ? d.charCodeAt(0) - 87 : Number(d);
        d = b.charAt(c + 1) == "+" ? a >>> d : a << d;
        a = b.charAt(c) == "+" ? a + d & 4294967295 : a ^ d;
    }
    return a;
};
// END
/* eslint-enable */

const config = new Map();

const window = {
    TKK: config.get("TKK") || "0"
};

// eslint-disable-next-line require-jsdoc
async function updateTKK() {
    let now = Math.floor(Date.now() / 3600000);

    if (Number(window.TKK.split(".")[0]) !== now) {
        const response = await request("https://translate.google.com");
        const body = await response.body.text();

        // code will extract something like tkk:'1232135.131231321312', we need only value
        const code = body.match(/tkk:'\d+.\d+'/g);

        if (code.length > 0) {
            // extracting value tkk:'1232135.131231321312', this will extract only token: 1232135.131231321312
            const xt = code[0].split(":")[1].replace(/'/g, "");

            window.TKK = xt;
            config.set("TKK", xt);
        }
    }
}

async function generate(text) {
    try {
        await updateTKK();

        let tk = zr(text);
        tk = tk.replace("&tk=", "");
        return { name: "tk", value: tk };
    }
    catch (error) {
        return error;
    }
}

class GoogleTranslater extends Service {
    static {
        Service.register (this, {
            'initialized': [],
            'clear': [],
            'newMsg': ['int'],
            'languagesChanged': [],
            'languagesUpdated': []
        });
    }

    _decoder = new TextDecoder();
    _messages = []
    _languages = {'from': '', 'to': ''}

    constructor () {
        super();

        this._languages = {
            'from': 'auto',
            'to': 'en'
        };
        this._messages = [];
        this.emit ('initialized');

        LANGUAGES.subscribe ((n) => {
            this.emit ('languagesUpdated');
            this.emit ('languagesChanged');
        });
    }

    get messages () {
        return this._messages;
    }

    get languages () {
        return this._languages;
    }

    get allLanguages () {
        return LANGUAGES.asyncGet();
    }

    set languages (languages) {
        this._languages = languages;
        for (let [key, value] in this._languages) { 
            if (!(value in LANGUAGES.asyncGet())) {
                value = 'auto';
            }
        }
        this.emit ('languagesChanged');
    }

    set toLanguage (language) {
        this._languages.to = language;
        this.emit ('languagesChanged');
    }

    set fromLanguage (language) {
        this._languages.from = language;
        this.emit ('languagesChanged');
    }

    get toLanguage () {
        return this._languages.to;
    }

    get fromLanguage () {
        return this._languages.from;
    }

    clear () {
        this._messages = [];
        this.emit ('clear');
    }

    addMessage (text, type, original, from, to) {
        this._messages.push ({type, text, original, from, to});
        this.emit ('newMsg', this._messages.length - 1);
    }

    /**
     * Returns the ISO 639-1 code of the desiredLang – if it is supported by
     * Google Translate
     * @param {string} language The name or the code of the desired language
     * @returns {string|boolean} The ISO 639-1 code of the language or null if the
     * language is not supported
     */
    getISOCode(language) {
        const languages = LANGUAGES.asyncGet();
        if (!language) return false;
        language = language.toLowerCase();
        if (language in languages) return language;

        let keys = Object.keys(languages).filter((key) => {
            if (typeof languages[key] !== "string") return false;

            return languages[key].toLowerCase() === language;
        });

        return keys[0] || false;
    }

    /**
     * Returns true if the desiredLang is supported by Google Translate and false otherwise
     * @param {String} language The ISO 639-1 code or the name of the desired language.
     * @returns {boolean} If the language is supported or not.
     */
    isSupported(language) {
        return Boolean(this.getISOCode(language));
    }

    async read_next (stream) {
        return await new Promise ( (resolve, reject) => {
            let body = '';
            stream.read_line_async (0, null, async (stream, res) => {
                if (!stream) { return resolve (''); }
                
                const [bytes] = stream.read_line_finish(res);
                if (bytes === null) { return resolve (''); }
                body += this._decoder.decode(bytes);
                body += await this.read_next (stream);
                resolve (body);
            });
        });
    }

    async send (text, options) {
        if (typeof options !== "object") options = {};
        options.from = this.fromLanguage;
        options.to = this.toLanguage;

        text = String(text);

        // Check if a lanugage is in supported; if not, throw an error object.
        let error;
        [ options.from, options.to ].forEach((lang) => {
            if (lang && !this.isSupported(lang)) {
                error = new Error();
                error.code = 400;
                error.message = `The language '${lang}' is not supported.`;
            }
        });
        if (error) {
            return;
        }

        // If options object doesn"t have "from" language, set it to "auto".
        if (!Object.prototype.hasOwnProperty.call(options, "from")) options.from = "auto";
        // If options object doesn"t have "to" language, set it to "en".
        if (!Object.prototype.hasOwnProperty.call(options, "to")) options.to = "en";
        // If options object has a "raw" property evaluating to true, set it to true.
        options.raw = Boolean(options.raw);

        // Get ISO 639-1 codes for the languages.
        options.from = this.getISOCode(options.from);
        options.to = this.getISOCode(options.to);

        // Generate Google Translate token for the text to be translated.
        let token = await generate(text);

        // URL & query string required by Google Translate.
        let baseUrl = "https://translate.google.com/translate_a/single";
        let data = {
            client: "gtx",
            sl: options.from,
            tl: options.to,
            hl: options.to,
            dt: [ "at", "bd", "ex", "ld", "md", "qca", "rw", "rm", "ss", "t" ],
            ie: "UTF-8",
            oe: "UTF-8",
            otf: 1,
            ssel: 0,
            tsel: 0,
            kc: 7,
            q: text,
            [token.name]: token.value
        };
        // Append query string to the request URL.
        let url = `${baseUrl}?${querystring.stringify(data)}`;

        let requestOptions;
        // If request URL is greater than 2048 characters, use POST method.
        if (url.length > 2048 || true) {
            delete data.q;
            requestOptions = [
                {
                    uri: `${baseUrl}?${querystring.stringify(data)}`,
                    method: "POST",
                },
                {

                },
                {
                    body: querystring.stringify({ q: text }),
                    mime: 'application/x-www-form-urlencoded;charset=UTF-8'
                }
            ];
        }
        else {
            requestOptions = [ { uri: url, method: "GET" } ];
        }
        requestOptions[0].uri = GLib.Uri.parse(requestOptions[0].uri||'', GLib.UriFlags.NONE);
        try {
            // Request translation from Google Translate.
            const plainText = await new Promise ((resolve, reject) => {
                try {
                    const session = new Soup.Session();
                    const message = new Soup.Message (requestOptions[0]);
                    if (requestOptions.length > 1) {
                        for (const [key, value] of Object.entries (requestOptions[1])) {
                            message.request_headers.append (key, value);
                        }
                    }
                    if (requestOptions.length > 2) {
                        message.set_request_body_from_bytes (requestOptions[2].mime, new GLib.Bytes(requestOptions[2].body));
                    }
                    
                    session.send_async (message, GLib.DEFAULT_PRIORITY, null, (_, result) => {
                        try {
                            const stream = session.send_finish(result);
                            const msg = session.get_async_result_message (result);
                            if (msg?.get_status() != 200) {
                                reject (new Error ('bad status'));
                                return;
                            }
                
                            this.read_next (new Gio.DataInputStream ({
                                close_base_stream: true,
                                base_stream: stream
                            })).then (n => {
                                resolve (n);
                            });
                        }
                        catch (e) {
                            reject (e);
                        }
                    });
                }
                catch (e) {
                    reject (e);
                }
            });
            if (plainText) {
                let body = JSON.parse (plainText);
                let result = {
                    text: "",
                    from: {
                        language: {
                            didYouMean: false,
                            iso: ""
                        },
                        text: {
                            autoCorrected: false,
                            value: "",
                            didYouMean: false
                        }
                    },
                    raw: ""
                };

                // If user requested a raw output, add the raw response to the result
                if (options.raw) {
                    result.raw = body;
                }

                // Parse body and add it to the result object.
                body[0].forEach((obj) => {
                    if (obj[0]) {
                        result.text += obj[0];
                    }
                });

                if (body[2] === body[8][0][0]) {
                    result.from.language.iso = body[2];
                }
                else {
                    result.from.language.didYouMean = true;
                    result.from.language.iso = body[8][0][0];
                }

                if (body[7] && body[7][0]) {
                    let str = body[7][0];

                    str = str.replace(/<b><i>/g, "[");
                    str = str.replace(/<\/i><\/b>/g, "]");

                    result.from.text.value = str;

                    if (body[7][5] === true) {
                        result.from.text.autoCorrected = true;
                    }
                    else {
                        result.from.text.didYouMean = true;
                    }
                }
                this.addMessage (result.text, 'Translater', text, this.allLanguages[options.from], this.allLanguages[options.to]);
            }
        } catch (e) {
            this.addMessage (e.message, 'System')
        }
    }
}

const gtranslaterService = new GoogleTranslater ();
userOptions.subscribe ((n) => {
    gtranslaterService.languages = {
        from: n.sidebar.translater?.from ?? gtranslaterService.fromLanguage,
        to: n.sidebar.translater?.to ?? gtranslaterService.toLanguage
    };
});

export default gtranslaterService;