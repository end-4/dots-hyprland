import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.waffle.looks

AppButton {
    id: root

    required property var toplevel
    readonly property bool isSeparator: toplevel.appId === "SEPARATOR"
    readonly property var desktopEntry: DesktopEntries.heuristicLookup(toplevel.appId)

    Layout.fillHeight: true

    iconName: toplevel.appId
}
