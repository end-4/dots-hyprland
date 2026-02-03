import QtQuick
import Quickshell
import Quickshell.Io

JsonObject {
    // Some spots are kinda janky/awkward. Setting the following to
    // false will make (some) stuff also be like that for accuracy. 
    // Example: the right-click menu of the Start button
    property JsonObject tweaks: JsonObject {
        property bool switchHandlePositionFix: true
        property bool smootherMenuAnimations: true
        property bool smootherSearchBar: true
    }
    property JsonObject bar: JsonObject {
        property bool bottom: true
        property bool leftAlignApps: false
    }
    property JsonObject actionCenter: JsonObject {
        property list<string> toggles: [ "network", "bluetooth", "easyEffects", "powerProfile", "idleInhibitor", "nightLight", "darkMode", "antiFlashbang", "cloudflareWarp", "mic", "musicRecognition", "notifications", "onScreenKeyboard", "gameMode", "screenSnip", "colorPicker" ]
    }
    property JsonObject calendar: JsonObject {
        property bool force2CharDayOfWeek: true
    }
}
