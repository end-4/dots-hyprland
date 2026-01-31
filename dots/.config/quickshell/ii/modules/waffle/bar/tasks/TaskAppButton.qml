import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.functions
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
    signal hoverPreviewDismissed()

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

    middleClickAction: () => {
        if (root.desktopEntry) {
            desktopEntry.execute()
        }
    }

    altAction: () => {
        root.hoverPreviewDismissed()
        root.hoverTimer.stop()
        contextMenu.active = true;
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

    BarMenu {
        id: contextMenu
        noSmoothClosing: false // On the real thing this is always smooth

        model: [
            ...((root.desktopEntry?.actions.length > 0) ? root.desktopEntry.actions.map(action =>({
                iconName: action.icon,
                text: action.name,
                action: () => {
                    action.execute()
                }
            })).concat({ type: "separator" }) : []),
            {
                iconName: root.iconName,
                text: root.desktopEntry ? root.desktopEntry.name : StringUtils.toTitleCase(appEntry.appId),
                monochromeIcon: false,
                action: () => {
                    if (root.desktopEntry) {
                        root.desktopEntry.execute()
                    }
                }
            },
            {
                iconName: root.appEntry.pinned ? "pin-off" : "pin",
                text: root.appEntry.pinned ? Translation.tr("Unpin from taskbar") : Translation.tr("Pin to taskbar"),
                action: () => {
                    TaskbarApps.togglePin(root.appEntry.appId);
                }
            },
            ...(root.appEntry.toplevels.length > 0 ? [{
                iconName: "dismiss",
                text: root.multiple ? Translation.tr("Close all windows") : Translation.tr("Close window"),
                action: () => {
                    for (let toplevel of root.appEntry.toplevels) {
                        toplevel.close();
                    }
                }
            }] : []),
        ]
    }
}
