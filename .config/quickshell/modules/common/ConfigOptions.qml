import QtQuick
import Quickshell
pragma Singleton

Singleton {
    property QtObject appearance: QtObject {
        property int fakeScreenRounding: 1 // 0: None | 1: Always | 2: When not fullscreen
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

}
