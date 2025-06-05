import QtQuick
import Quickshell
pragma Singleton
pragma ComponentBehavior: Bound

Singleton {
    property QtObject ai: QtObject {
        property string model
        property real temperature: 0.5
    }

    property QtObject sidebar: QtObject {
        property QtObject bottomGroup: QtObject {
            property bool collapsed: false
        }
    }

    property QtObject booru: QtObject {
        property bool allowNsfw: false
        property string provider: "yandere"
    }

}
