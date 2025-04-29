import QtQuick
import Quickshell
pragma Singleton
pragma ComponentBehavior: Bound

Singleton {
    property QtObject appearance: QtObject {
        property int fakeScreenRounding: 1 // 0: None | 1: Always | 2: When not fullscreen
    }

    property QtObject apps: QtObject {
        property string bluetooth: "blueberry"
        property string imageViewer: "loupe"
        property string network: "XDG_CURRENT_DESKTOP=\"gnome\" gnome-control-center wifi"
        property string settings: "XDG_CURRENT_DESKTOP=\"gnome\" gnome-control-center"
        property string taskManager: "gnome-usage"
        property string terminal: "foot" // This is only for shell actions
    }

    property QtObject bar: QtObject {
        property int batteryLowThreshold: 20
        property string topLeftIcon: "spark" // Options: distro, spark
        property QtObject resources: QtObject {
            property bool alwaysShowSwap: true
            property bool alwaysShowCpu: false
        }
        property QtObject workspaces: QtObject {
            property int shown: 10
            property bool alwaysShowNumbers: false
            property int showNumberDelay: 150 // milliseconds
        }
    }

    property QtObject osd: QtObject {
        property int timeout: 1000
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
        property QtObject prefix: QtObject {
            property string action: "/"
        }
    }

    property QtObject sidebar: QtObject {
        property QtObject booru: QtObject {
            property bool allowNsfw: false
            property string defaultProvider: "yandere"
            property int limit: 20 // Images per page
            property QtObject zerochan: QtObject {
                // property string username
            }
        }
    }

    property QtObject hacks: QtObject {
        property int arbitraryRaceConditionDelay: 10 // milliseconds
    }

}
