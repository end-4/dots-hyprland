import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.waffle.looks
import "window-layout.js" as WindowLayout

WMouseAreaButton {
    id: root

    required property var toplevel
    required property int maxHeight
    required property int maxWidth

    property var hyprlandClient: HyprlandData.clientForToplevel(root.toplevel)

    property string iconName: AppSearch.guessIcon(hyprlandClient?.class)

    color: containsMouse ? Looks.colors.bg1Base : Looks.colors.bgPanelFooterBase
    borderColor: Looks.colors.bg2Border
    radius: Looks.radius.xLarge

    property size size: WindowLayout.scaleWindow(hyprlandClient, maxWidth, maxHeight)
    implicitWidth: Math.max(Math.round(contentItem.implicitWidth), 138)
    implicitHeight: Math.round(contentItem.implicitHeight)

    layer.enabled: true
    layer.effect: OpacityMask {
        maskSource: Rectangle {
            width: root.width
            height: root.height
            radius: root.radius
        }
    }
    scale: (root.pressedButtons & Qt.LeftButton) ? 0.95 : 1
    Behavior on scale {
        NumberAnimation {
            id: scaleAnim
            duration: 300
            easing.type: Easing.OutExpo
        }
    }

    function closeWindow() {
        Hyprland.dispatch(`closewindow address:${root.hyprlandClient?.address}`)
    }

    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
    onClicked: (event) => {
        if (event.button === Qt.LeftButton) {
            GlobalStates.overviewOpen = false
            Hyprland.dispatch(`focuswindow address:${root.hyprlandClient?.address}`)
            GlobalStates.overviewOpen = false;
        } else if (event.button === Qt.MiddleButton) {
            root.closeWindow();
            event.accepted = true;
        } else if (event.button === Qt.RightButton) {
            if (!windowMenu.visible) windowMenu.popup();
            else windowMenu.close();
        }
    }

    ColumnLayout {
        id: contentItem
        z: 2
        anchors.fill: parent
        anchors.margins: 1
        spacing: 0

        RowLayout {
            spacing: 8
            WAppIcon {
                Layout.leftMargin: 10
                Layout.alignment: Qt.AlignVCenter
                iconName: root.iconName
                implicitSize: 16
                tryCustomIcon: false
            }
            WText {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                elide: Text.ElideRight
                text: root.hyprlandClient?.title ?? ""
            }
            CloseButton {
                implicitWidth: 38
                implicitHeight: 38
                padding: 8
                onClicked: root.closeWindow()
            }
        }

        ScreencopyView {
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: Math.round(root.size.width)
            implicitHeight: Math.round(root.size.height)

            captureSource: root.toplevel ?? null
            live: true
        }
    }

    WMenu {
        id: windowMenu
        downDirection: true

        Action {
            enabled: root.hyprlandClient?.floating
            property bool isPinned: root.hyprlandClient?.pinned
            icon.name: isPinned ? "checkmark" : "empty"
            text: Translation.tr("Show this window on all desktops")
            onTriggered: {
                Hyprland.dispatch(`pin address:${root.hyprlandClient?.address}`)
            }
        }
        Action {
            icon.name: "empty"
            text: Translation.tr("Close")
            onTriggered: root.closeWindow()
        }
    }
}
