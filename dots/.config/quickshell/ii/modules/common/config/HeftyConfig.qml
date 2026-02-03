import QtQuick
import Quickshell
import Quickshell.Io

JsonObject {
    property JsonObject bar: JsonObject {
        property list<var> leftWidgets: []
        property list<var> centerWidgets: []
        property list<var> rightWidgets: []
    }
}
