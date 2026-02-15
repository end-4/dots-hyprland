import QtQuick
import Quickshell
import Quickshell.Io

JsonObject {
    property JsonObject bar: JsonObject {
        property list<var> leftWidgets: ["HWindowInfo"]
        property list<var> centerLeftWidgets: ["HTime"]
        property list<var> centerWidgets: ["HWorkspaces"]
        property list<var> centerRightWidgets: ["HBattery"]
        property list<var> rightWidgets: []
        property bool m3ExpressiveGrouping: true
    }
}
