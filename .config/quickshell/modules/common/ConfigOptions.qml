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
        property int workspacesShown: 10
        property int batteryLowThreshold: 20
        property QtObject resources: QtObject {
            property bool alwaysShowSwap: true
            property bool alwaysShowCpu: false
        }
    }

    property QtObject resources: QtObject {
        property int updateInterval: 3000
    }

    property QtObject hacks: QtObject {
        property int arbitraryRaceConditionDelay: 10
    }

}
