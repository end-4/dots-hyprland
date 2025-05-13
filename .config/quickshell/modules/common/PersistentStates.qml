import QtQuick
import Quickshell
pragma Singleton
pragma ComponentBehavior: Bound

Singleton {
    property QtObject ai: QtObject {
        property string model: "gemini-2.0-flash-search"
    }

    property QtObject sidebar: QtObject {
        property QtObject leftSide: QtObject {
            property int selectedTab: 0
        }
        property QtObject centerGroup: QtObject {
            property int selectedTab: 0
        }
        property QtObject bottomGroup: QtObject {
            property bool collapsed: false
            property int selectedTab: 0
        }
    }

    property QtObject booru: QtObject {
        property bool allowNsfw: false
        property string provider: "yandere"
    }

}
