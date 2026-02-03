import QtQuick
import Quickshell
import Quickshell.Io

JsonObject {
    property JsonObject bar: JsonObject {
        property list<var> leftWidgets: []
        property list<var> centerWidgets: [["Workspaces"]]
        property list<var> rightWidgets: []
        property bool m3ExpressiveGrouping: true
    }
}
