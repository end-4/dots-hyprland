pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.bar
import ".."

HBarWidgetWithPopout {
    id: root

    property list<var> pinnedItems: TrayService.pinnedItems
    property list<var> unpinnedItems: TrayService.unpinnedItems

    popupContentWidth: popupContent.implicitWidth
    popupContentHeight: popupContent.implicitHeight

    Layout.maximumWidth: vertical ? -1 : implicitWidth
    Layout.maximumHeight: vertical ? implicitHeight : -1
    Layout.fillWidth: true
    Layout.fillHeight: true

    HBarWidgetContent {
        id: contentRoot

        vertical: root.vertical
        atBottom: root.atBottom
        showPopup: root.showPopup

        contentImplicitWidth: trayContent.implicitWidth
        contentImplicitHeight: trayContent.implicitHeight

        hoverEnabled: false
        parentRadiusToPaddingRatio: 0.45

        hover: trayContent.moreHovered
        press: trayContent.morePressed

        TrayContent {
            id: trayContent
            anchors.fill: parent
            vertical: root.vertical
        }

        UnpinnedItemsPopup {
            id: popupContent
            anchors {
                top: parent.top
                topMargin: root.popupContentOffsetY
                left: parent.left
                leftMargin: root.popupContentOffsetX
            }
            shown: root.showPopup
        }
    }

    component TrayContent: BoxLayout {
        spacing: 4
        property alias moreHovered: moreBtn.containsMouse
        property alias morePressed: moreBtn.containsPress
        
        ButtonMouseArea {
            id: moreBtn
            visible: TrayService.unpinnedItems.length > 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: 4 * root.vertical
            Layout.leftMargin: 4 * !root.vertical
            hoverEnabled: true
            acceptedButtons: Qt.AllButtons

            implicitWidth: 20 - parent.spacing
            implicitHeight: 20 - parent.spacing

            onClicked: root.showPopup = !root.showPopup

            MaterialSymbol {
                anchors.centerIn: parent
                iconSize: 20
                text: "expand_more"
                horizontalAlignment: Text.AlignHCenter
                color: root.showPopup ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer2
                rotation: (root.showPopup ? 180 : 0) - (90 * root.vertical) + (180 * root.atBottom)
                Behavior on rotation {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
            }
        }
        Repeater {
            model: root.pinnedItems
            delegate: StyledTrayItem {
                Layout.fillWidth: true
                Layout.fillHeight: true
                required property var modelData
                item: modelData
            }
        }
    }

    component UnpinnedItemsPopup: ChoreographerLoader {
        sourceComponent: ChoreographerGridLayout {
            id: popupRoot
            totalDuration: 70
            columns: root.vertical ? 1 : -1
            columnSpacing: 8
            rowSpacing: 8

            Repeater {
                model: root.unpinnedItems
                delegate: FlyFadeEnterChoreographable {
                    id: unpinnedTrayItem
                    required property var modelData
                    StyledTrayItem {
                        item: unpinnedTrayItem.modelData
                    }
                }
            }
        }
    }

    component StyledTrayItem: SysTrayItem {
        iconSize: 18
        propagateComposedEvents: false

        property var menuWindow
        onMenuClosed: {
            if (menuWindow)
                GlobalFocusGrab.removeDismissable(menuWindow);
        }
        onMenuOpened: (qsWindow) => {
            menuWindow = qsWindow;
            GlobalFocusGrab.addDismissable(qsWindow)
        }
    }
}
