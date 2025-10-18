import qs
import qs.modules.common
import qs.services
import QtQuick
import Quickshell

AndroidQuickToggleButton {
    id: root

    name: Translation.tr("Notifications")
    statusText: toggled ? Translation.tr("Show") : Translation.tr("Silent")
    toggled: !Notifications.silent
    buttonIcon: toggled ? "notifications_active" : "notifications_paused"

    onClicked: {
        Notifications.silent = !Notifications.silent;
    }
}
