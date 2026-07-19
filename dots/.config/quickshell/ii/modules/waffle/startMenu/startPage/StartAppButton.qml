pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.waffle.looks

WButton {
    id: root
    required property DesktopEntry desktopEntry

    property bool pinnedStart: LauncherApps.isPinned(root.desktopEntry.id);
    property bool pinnedTaskbar: TaskbarApps.isPinned(root.desktopEntry.id);

    implicitWidth: 96
    implicitHeight: 84
    horizontalPadding: 0
    verticalPadding: 0
    contentItem: ColumnLayout {
        spacing: 3
        WAppIcon {
            Layout.topMargin: 12
            Layout.alignment: Qt.AlignHCenter
            iconName: root.desktopEntry.icon
            implicitSize: 34
            tryCustomIcon: false
        }
        WText {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            text: root.desktopEntry.name
            wrapMode: Text.Wrap
            elide: Text.ElideRight
            maximumLineCount: 2
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignTop
        }
    }
    WToolTip {
        text: root.desktopEntry.name
    }

    altAction: () => {
        appMenu.popup()
    }

    WMenu {
        id: appMenu
        downDirection: true
        
        WMenuItem {
            visible: root.pinnedStart
            icon.name: "arrow-up-left"
            text: Translation.tr("Move to front")
            onTriggered: {
                LauncherApps.moveToFront(root.desktopEntry.id);
            }
        }
        WMenuItem {
            visible: root.pinnedStart
            icon.name: "arrow-left"
            text: Translation.tr("Move left")
            onTriggered: {
                LauncherApps.moveLeft(root.desktopEntry.id);
            }
        }
        WMenuItem {
            visible: root.pinnedStart
            icon.name: "arrow-right"
            text: Translation.tr("Move right")
            onTriggered: {
                LauncherApps.moveRight(root.desktopEntry.id);
            }
        }
        WMenuItem {
            icon.name: root.pinnedStart ? "pin-off" : "pin"
            text: root.pinnedStart ? Translation.tr("Unpin from Start") : Translation.tr("Pin to Start")
            onTriggered: {
                LauncherApps.togglePin(root.desktopEntry.id);
            }
        }
        WMenuItem {
            icon.name: root.pinnedTaskbar ? "pin-off" : "pin"
            text: root.pinnedTaskbar ? Translation.tr("Unpin from taskbar") : Translation.tr("Pin to taskbar")
            onTriggered: {
                TaskbarApps.togglePin(root.desktopEntry.id);
            }
        }
    }
}
