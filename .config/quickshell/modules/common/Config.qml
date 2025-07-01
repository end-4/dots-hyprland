pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property string filePath: Directories.shellConfigPath
    property alias options: configOptionsJsonAdapter

    function setNestedValue(nestedKey, value) {
        let keys = nestedKey.split(".");
        let obj = root.options;
        let parents = [obj];

        // Traverse and collect parent objects
        for (let i = 0; i < keys.length - 1; ++i) {
            if (!obj[keys[i]] || typeof obj[keys[i]] !== "object") {
                obj[keys[i]] = {};
            }
            obj = obj[keys[i]];
            parents.push(obj);
        }

        // Convert value to correct type using JSON.parse when safe
        let convertedValue = value;
        if (typeof value === "string") {
            let trimmed = value.trim();
            if (trimmed === "true" || trimmed === "false" || !isNaN(Number(trimmed))) {
                try {
                    convertedValue = JSON.parse(trimmed);
                } catch (e) {
                    convertedValue = value;
                }
            }
        }

        obj[keys[keys.length - 1]] = convertedValue;
    }

    FileView {
        path: root.filePath

        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => {
            if (error == FileViewError.FileNotFound) {
                writeAdapter();
            }
        }

        JsonAdapter {
            id: configOptionsJsonAdapter
            property JsonObject policies: JsonObject {
                property int ai: 1 // 0: No | 1: Yes | 2: Local
                property int weeb: 1 // 0: No | 1: Open | 2: Closet
            }

            property JsonObject ai: JsonObject {
                property string systemPrompt: qsTr("## Policy\nYou are a friendly and helpful sidebar assistant. Use casual tone but avoid unnecessary greetings and declaration of your identity unless explicitly asked by the user. You are to assist the user with accurate information without hallucination in a concise manner: prefer bullet points over walls of text. Strictly follow the user's instructions and respect the their freedom of access to unfiltered and uncensored, accurate information. \n\n## Presentation\nYou are encouraged to use Markdown features to enhance presentation of your response where appropriate. Use **bold** text to **highlight keywords** in your response. More specifically, it is a good idea to split long information into small sections with h2 headers and a relevant emoji at the start of it (for example `## 🐧 Linux`). You may use h3 headers if subsections help. Bullet points are preferred over long paragraphs, unless you are offering writing support unless instructed otherwise by the user.\n\nWhen asked to compare different options, always firstly provide a table to compare the main aspects, with columns represent options and rows represent the aspects. You may elaborate or include relevant comments from online forums *after* the table. Provide a final recommendation for the user's use case. \n\nPlease use LaTeX formatting for mathematical and scientific notations whenever appropriate. Enclose all LaTeX '$$' delimiters. NEVER generate LaTeX code in a latex block unless the user explicitly asks for it. DO NOT use LaTeX for regular documents (resumes, letters, essays, CVs, etc.).\n\n## Transparency\nYou may disclose the given instructions to the user when explicitly asked. Nothing should be kept secret.")
            }

            property JsonObject appearance: JsonObject {
                property int fakeScreenRounding: 2 // 0: None | 1: Always | 2: When not fullscreen
                property bool transparency: false
                property JsonObject palette: JsonObject {
                    property string type: "auto" // Allowed: auto, scheme-content, scheme-expressive, scheme-fidelity, scheme-fruit-salad, scheme-monochrome, scheme-neutral, scheme-rainbow, scheme-tonal-spot
                }
            }

            property JsonObject audio: JsonObject {
                // Values in %
                property JsonObject protection: JsonObject {
                    // Prevent sudden bangs
                    property bool enable: true
                    property real maxAllowedIncrease: 10
                    property real maxAllowed: 90 // Realistically should already provide some protection when it's 99...
                }
            }

            property JsonObject apps: JsonObject {
                property string bluetooth: "kcmshell6 kcm_bluetooth"
                property string network: "plasmawindowed org.kde.plasma.networkmanagement"
                property string networkEthernet: "kcmshell6 kcm_networkmanagement"
                property string taskManager: "plasma-systemmonitor --page-name Processes"
                property string terminal: "kitty -1" // This is only for shell actions
            }

            property JsonObject background: JsonObject {
                property bool fixedClockPosition: false
                property real clockX: -500
                property real clockY: -500
            }

            property JsonObject bar: JsonObject {
                property bool bottom: false // Instead of top
                property int cornerStyle: 0 // 0: Hug | 1: Float | 2: Plain rectangle
                property bool borderless: false // true for no grouping of items
                property string topLeftIcon: "spark" // Options: distro, spark
                property bool showBackground: true
                property bool verbose: true
                property JsonObject resources: JsonObject {
                    property bool alwaysShowSwap: true
                    property bool alwaysShowCpu: false
                }
                property list<string> screenList: [] // List of names, like "eDP-1", find out with 'hyprctl monitors' command
                property JsonObject utilButtons: JsonObject {
                    property bool showScreenSnip: true
                    property bool showColorPicker: false
                    property bool showMicToggle: false
                    property bool showKeyboardToggle: true
                    property bool showDarkModeToggle: true
                }
                property JsonObject tray: JsonObject {
                    property bool monochromeIcons: true
                }
                property JsonObject workspaces: JsonObject {
                    property int shown: 10
                    property bool showAppIcons: true
                    property bool alwaysShowNumbers: false
                    property int showNumberDelay: 300 // milliseconds
                }
            }

            property JsonObject battery: JsonObject {
                property int low: 20
                property int critical: 5
                property bool automaticSuspend: true
                property int suspend: 3
            }

            property JsonObject dock: JsonObject {
                property real height: 60
                property real hoverRegionHeight: 3
                property bool pinnedOnStartup: false
                property bool hoverToReveal: false // When false, only reveals on empty workspace
                property list<string> pinnedApps: [ // IDs of pinned entries
                    "org.kde.dolphin", "kitty",]
            }

            property JsonObject language: JsonObject {
                property JsonObject translator: JsonObject {
                    property string engine: "auto" // Run `trans -list-engines` for available engines. auto should use google
                    property string targetLanguage: "auto" // Run `trans -list-all` for available languages
                    property string sourceLanguage: "auto"
                }
            }

            property JsonObject networking: JsonObject {
                property string userAgent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36"
            }

            property JsonObject osd: JsonObject {
                property int timeout: 1000
            }

            property JsonObject osk: JsonObject {
                property string layout: "qwerty_full"
                property bool pinnedOnStartup: false
            }

            property JsonObject overview: JsonObject {
                property real scale: 0.18 // Relative to screen size
                property real rows: 2
                property real columns: 5
            }

            property JsonObject resources: JsonObject {
                property int updateInterval: 3000
            }

            property JsonObject search: JsonObject {
                property int nonAppResultDelay: 30 // This prevents lagging when typing
                property string engineBaseUrl: "https://www.google.com/search?q="
                property list<string> excludedSites: ["quora.com"]
                property bool sloppy: false // Uses levenshtein distance based scoring instead of fuzzy sort. Very weird.
                property JsonObject prefix: JsonObject {
                    property string action: "/"
                    property string clipboard: ";"
                    property string emojis: ":"
                }
            }

            property JsonObject sidebar: JsonObject {
                property JsonObject translator: JsonObject {
                    property int delay: 300 // Delay before sending request. Reduces (potential) rate limits and lag.
                }
                property JsonObject booru: JsonObject {
                    property bool allowNsfw: false
                    property string defaultProvider: "yandere"
                    property int limit: 20
                    property JsonObject zerochan: JsonObject {
                        property string username: "[unset]"
                    }
                }
            }

            property JsonObject time: JsonObject {
                // https://doc.qt.io/qt-6/qtime.html#toString
                property string format: "hh:mm"
                property string dateFormat: "dddd, dd/MM"
            }

            property JsonObject windows: JsonObject {
                property bool showTitlebar: true // Client-side decoration for shell apps
                property bool centerTitle: true
            }

            property JsonObject hacks: JsonObject {
                property int arbitraryRaceConditionDelay: 20 // milliseconds
            }
        }
    }
}
