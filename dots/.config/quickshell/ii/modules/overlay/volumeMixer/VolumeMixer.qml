import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.overlay
import qs.modules.sidebarRight.volumeMixer

StyledOverlayWidget {
    id: root
    contentItem: Rectangle {
        anchors.centerIn: parent
        color: Appearance.m3colors.m3surfaceContainer
        property real padding: 16
        implicitHeight: 600
        implicitWidth: 350

        VolumeDialogContent {
            anchors.fill: parent
            anchors.margins: parent.padding
            isSink: true
        }

    }
}
