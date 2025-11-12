import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.waffle.looks
import qs.modules.waffle.bar
import Quickshell

AppButton {
    id: root

    required property var appEntry
    readonly property bool isSeparator: appEntry.appId === "SEPARATOR"
    readonly property var desktopEntry: DesktopEntries.heuristicLookup(appEntry.appId)
    property bool active: root.appEntry.toplevels.some(t => t.activated)
    property bool hasWindows: appEntry.toplevels.length > 0

    signal hoverPreviewRequested()

    multiple: appEntry.toplevels.length > 1
    checked: active
    iconName: AppSearch.guessIcon(appEntry.appId)
    tryCustomIcon: false
    
    onHoverTimedOut: {
        root.hoverPreviewRequested()
    }

    onClicked: {
        root.hoverTimer.stop() // Prevents preview showing up when clicking to focus
        if (root.multiple) {
            root.hoverPreviewRequested()
        } else if (root.appEntry.toplevels.length === 1) {
            root.appEntry.toplevels[0].activate()
        } else {
            root.desktopEntry.execute()
        }
    }

    onMiddleClickAction: {
        if (root.desktopEntry) {
            desktopEntry.execute()
        }
    }

    // Active indicator
    Rectangle {
        id: activeIndicator
        opacity: root.hasWindows ? 1 : 0
        anchors {
            horizontalCenter: root.background.horizontalCenter
            bottom: root.background.bottom
            bottomMargin: 1
        }

        implicitWidth: root.active ? 16 : 6
        implicitHeight: 3
        radius: height / 2

        color: root.active ? Looks.colors.accent : Looks.colors.accentUnfocused

        Behavior on implicitWidth {
            animation: Looks.transition.enter.createObject(this)
        }
        Behavior on color {
            animation: Looks.transition.color.createObject(this)
        }
        Behavior on opacity {
            animation: Looks.transition.opacity.createObject(this)
        }
    }

    BarToolTip {
        extraVisibleCondition: root.shouldShowTooltip && !root.hasWindows
        text: desktopEntry ? desktopEntry.name : appEntry.appId
    }
}
