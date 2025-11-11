import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.waffle.looks
import Quickshell

AppButton {
    id: root

    required property var appEntry
    readonly property bool isSeparator: appEntry.appId === "SEPARATOR"
    readonly property var desktopEntry: DesktopEntries.heuristicLookup(appEntry.appId)

    signal hoverPreviewRequested()

    iconName: AppSearch.guessIcon(appEntry.appId)
    Timer {
        running: root.hovered
        interval: 250
        onTriggered: {
            root.hoverPreviewRequested()
        }
    }
}
