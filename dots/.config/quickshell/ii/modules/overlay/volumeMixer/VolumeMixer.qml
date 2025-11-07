import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.overlay
import qs.modules.sidebarRight.volumeMixer

StyledOverlayWidget {
    id: root
    contentItem: Rectangle {
        anchors.centerIn: parent
        color: Appearance.m3colors.m3surfaceContainer
        radius: root.contentRadius
        property real padding: 16
        implicitHeight: 600
        implicitWidth: 350

        ColumnLayout {
            id: contentColumn
            anchors {
                fill: parent
                margins: parent.padding
            }
            spacing: 8

            SecondaryTabBar {
                id: tabBar

                currentIndex: Persistent.states.overlay.volumeMixer.tabIndex
                onCurrentIndexChanged: {
                    Persistent.states.overlay.volumeMixer.tabIndex = tabBar.currentIndex;
                }

                SecondaryTabButton {
                    buttonIcon: "media_output"
                    buttonText: Translation.tr("Output")
                }
                SecondaryTabButton {
                    buttonIcon: "mic"
                    buttonText: Translation.tr("Input")
                }
            }
            SwipeView {
                id: swipeView
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: Persistent.states.overlay.volumeMixer.tabIndex
                onCurrentIndexChanged: {
                    Persistent.states.overlay.volumeMixer.tabIndex = swipeView.currentIndex;
                }
                clip: true

                VolumeDialogContent { isSink: true }
                VolumeDialogContent { isSink: false }
            }
        }
    }
}
