import QtQuick
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.waffle.looks

BarButton {
    id: root

    visible: Updates.available && Updates.updateAdvised
    padding: 4

    onClicked: {
        Quickshell.execDetached(["bash", "-c", Config.options.apps.update]);
    }

    contentItem: Item {
        anchors.centerIn: parent
        implicitWidth: iconContent.implicitWidth
        implicitHeight: iconContent.implicitHeight

        FluentIcon {
            id: iconContent
            anchors.centerIn: parent
            icon: "arrow-sync"

            Rectangle {
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
    }

    BarToolTip {
        extraVisibleCondition: root.shouldShowTooltip
        text: Translation.tr("Get the latest features and security improvements with\nthe newest feature update.\n\n%1 packages").arg(Updates.count)
    }
}
