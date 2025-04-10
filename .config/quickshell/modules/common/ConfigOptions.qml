import QtQuick
import Quickshell
pragma Singleton

Singleton {
    property QtObject bar: QtObject {
        property int workspacesShown: 10
    }

}
