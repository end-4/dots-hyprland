import QtQuick
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.waffle.looks
import qs.modules.waffle.bar.tray

BarIconButton {
    id: root

    visible: Updates.updateAdvised || Updates.updateStronglyAdvised
    padding: 4
    iconName: "arrow-sync"
    iconSize: 20 // Needed because the icon appears to have some padding
    iconMonochrome: true
    tooltipText: Translation.tr("Get the latest features and security improvements with\nthe newest feature update.\n\n%1 packages").arg(Updates.count)

    onClicked: {
        Quickshell.execDetached(["bash", "-c", Config.options.apps.update]);
    }

    overlayingItems: Rectangle {
        anchors {
            right: parent.right
            bottom: parent.bottom
            margins: 1
        }
        implicitWidth: 8
        implicitHeight: implicitWidth
        radius: height / 2
        color: Updates.updateStronglyAdvised ? Looks.colors.warning : Looks.colors.accent
    }
}
