import QtQuick
import Quickshell
pragma Singleton
pragma ComponentBehavior: Bound

Singleton {
    property QtObject policies: QtObject {
        property int ai: 1 // 0: No | 1: Yes | 2: Local
        property int weeb: 1 // 0: No | 1: Open | 2: Closet
    }

    property QtObject ai: QtObject {
        property string systemPrompt: qsTr("Use casual tone. No user knowledge is to be assumed except basic Linux literacy. Be brief and concise: When explaining concepts, use bullet points (prefer minus sign (-) over asterisk (*)) and highlight keywords in bold to pinpoint the main concepts instead of long paragraphs. You are also encouraged to split your response with h2 headers, each header title beginning with an emoji, like `## 🐧 Linux`. When making changes to the user's config, you must get the config to know what values there are before setting.")
    }

    property QtObject appearance: QtObject {
        property int fakeScreenRounding: 2 // 0: None | 1: Always | 2: When not fullscreen
        property bool transparency: false
    }

    property QtObject audio: QtObject { // Values in %
        property QtObject protection: QtObject { // Prevent sudden bangs
            property bool enable: true
            property real maxAllowedIncrease: 10
            property real maxAllowed: 90 // Realistically should already provide some protection when it's 99...
        }
    }

    property QtObject apps: QtObject {
        property string bluetooth: "kcmshell6 kcm_bluetooth"
        property string imageViewer: "loupe"
        property string network: "plasmawindowed org.kde.plasma.networkmanagement"
        property string networkEthernet: "kcmshell6 kcm_networkmanagement"
        property string settings: "systemsettings"
        property string taskManager: "plasma-systemmonitor --page-name Processes"
        property string terminal: "kitty -1" // This is only for shell actions
    }

    property QtObject battery: QtObject {
        property int low: 20
        property int critical: 5
        property int suspend: 2
    }

    property QtObject bar: QtObject {
        property bool bottom: false // Instead of top
        property bool borderless: false // true for no grouping of items
        property string topLeftIcon: "spark" // Options: distro, spark
        property bool showBackground: true
        property bool verbose: true
        property QtObject resources: QtObject {
            property bool alwaysShowSwap: true
            property bool alwaysShowCpu: false
        }
        property list<string> screenList: [] // List of names, like "eDP-1", find out with 'hyprctl monitors' command
        property QtObject utilButtons: QtObject {
            property bool showScreenSnip: true
            property bool showColorPicker: false
            property bool showMicToggle: false
            property bool showKeyboardToggle: true
        }
        property QtObject workspaces: QtObject {
            property int shown: 10
            property bool showAppIcons: true
            property bool alwaysShowNumbers: false
            property int showNumberDelay: 300 // milliseconds
        }
    }

    property QtObject dock: QtObject {
        property real height: 60
        property real hoverRegionHeight: 3
        property bool pinnedOnStartup: false
        property bool hoverToReveal: false // When false, only reveals on empty workspace
        property list<string> pinnedApps: [ // IDs of pinned entries
            "org.kde.dolphin",
            "kitty",
        ]
    }

    property QtObject language: QtObject {
        property QtObject translator: QtObject {
            property string engine: "auto" // Run `trans -list-engines` for available engines. auto should use google
            property string targetLanguage: "auto" // Run `trans -list-all` for available languages
            property string sourceLanguage: "auto"
        }
    }

    property QtObject networking: QtObject {
        property string userAgent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36"
    }

    property QtObject osd: QtObject {
        property int timeout: 1000
    }

    property QtObject osk: QtObject {
        property string layout: "qwerty_full"
        property bool pinnedOnStartup: false
    }

    property QtObject overview: QtObject {
        property real scale: 0.18 // Relative to screen size
        property real numOfRows: 2
        property real numOfCols: 5
        property bool showXwaylandIndicator: true
    }

    property QtObject resources: QtObject {
        property int updateInterval: 3000
    }

    property QtObject search: QtObject {
        property int nonAppResultDelay: 30 // This prevents lagging when typing
        property string engineBaseUrl: "https://www.google.com/search?q="
        property list<string> excludedSites: [ "quora.com" ]
        property bool sloppy: false // Uses levenshtein distance based scoring instead of fuzzy sort. Very weird.
        property QtObject prefix: QtObject {
            property string action: "/"
            property string clipboard: ";"
            property string emojis: ":"
        }
    }

    property QtObject sidebar: QtObject {
        property QtObject translator: QtObject {
            property int delay: 300 // Delay before sending request. Reduces (potential) rate limits and lag.
        }
        property QtObject booru: QtObject {
            property bool allowNsfw: false
            property string defaultProvider: "yandere"
            property int limit: 20
            property QtObject zerochan: QtObject {
                property string username: "[unset]"
            }
        }
    }

    property QtObject time: QtObject {
        // https://doc.qt.io/qt-6/qtime.html#toString
        property string format: "hh:mm"
        property string dateFormat: "dddd, dd/MM"
    }

    property QtObject hacks: QtObject {
        property int arbitraryRaceConditionDelay: 20 // milliseconds
    }

}
