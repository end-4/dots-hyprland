pragma ComponentBehavior: Bound
import QtQuick

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import ".."

HBarWidgetWithPopout {
    id: root

    property bool showPing: false

    Connections {
        target: Ai
        function onResponseFinished() {
            if (GlobalStates.sidebarLeftOpen) return;
            root.showPing = true;
        }
    }

    Connections {
        target: Booru
        function onResponseFinished() {
            if (GlobalStates.sidebarLeftOpen) return;
            root.showPing = true;
        }
    }

    Connections {
        target: GlobalStates
        function onSidebarLeftOpenChanged() {
            root.showPing = false;
        }
    }

    HBarWidgetContent {
        id: contentRoot
        vertical: root.vertical
        atBottom: root.atBottom
        contentImplicitWidth: 14
        contentImplicitHeight: 18
        showPopup: false
        onClicked: GlobalStates.sidebarLeftOpen = !GlobalStates.sidebarLeftOpen;

        CustomIcon {
            id: distroIcon
            anchors.centerIn: parent
            width: 20
            height: 20
            source: Config.options.bar.topLeftIcon == 'distro' ? SystemInfo.distroIcon : `${Config.options.bar.topLeftIcon}-symbolic`
            colorize: true
            color: Appearance.colors.colOnLayer0

            Rectangle {
                opacity: root.showPing ? 1 : 0
                visible: opacity > 0
                anchors {
                    bottom: parent.bottom
                    right: parent.right
                    bottomMargin: -2
                    rightMargin: -2
                }
                implicitWidth: 8
                implicitHeight: 8
                radius: Appearance.rounding.full
                color: Appearance.colors.colTertiary

                Behavior on opacity {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
            }
        }
    }
}
