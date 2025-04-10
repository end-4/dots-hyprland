import QtQuick
import Quickshell
pragma Singleton

Singleton {
    property QtObject bar: QtObject {
        property int workspacesShown: 10
        property int batteryLowThreshold: 20
    }

}
