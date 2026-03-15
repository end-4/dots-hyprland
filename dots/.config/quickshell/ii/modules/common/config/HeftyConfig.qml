import QtQuick
import Quickshell
import Quickshell.Io

JsonObject {
    property JsonObject bar: JsonObject {
        property list<var> leftWidgets: ["HLeftSidebarButton"]
        property list<var> centerLeftWidgets: ["HTime"]
        property list<var> centerWidgets: ["HWorkspaces"]
        property list<var> centerRightWidgets: ["HResources"]
        property list<var> rightWidgets: ["HSystemIndicators"]
        property bool m3ExpressiveGrouping: true

        property JsonObject resources: JsonObject {
            property bool showMemory: false
            property bool showRam: false
            property bool showSwap: false
            property bool showCpu: false
        }
    }
}
