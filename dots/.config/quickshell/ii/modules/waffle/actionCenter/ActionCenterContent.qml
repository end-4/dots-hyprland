pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.waffle.looks
import qs.modules.waffle.actionCenter.mainPage

WBarAttachedPanelContent {
    id: root

    readonly property bool barAtBottom: Config.options.waffles.bar.bottom
    
    contentItem: ColumnLayout {
        // This somewhat sophisticated anchoring is needed to make opening anim not jump abruptly when stuff appear
        anchors {
            left: parent.left
            right: parent.right
            top: root.barAtBottom ? undefined : parent.top
            bottom: root.barAtBottom ? parent.bottom : undefined
            margins: root.visualMargin
            bottomMargin: 0
        }
        spacing: 12

        WPane {
            opacity: (MprisController.activePlayer != null && MprisController.isRealPlayer(MprisController.activePlayer)) ? 1 : 0
            Layout.fillWidth: true
            contentItem: MediaPaneContent {}
        }
        WPane {
            Layout.fillWidth: true
            contentItem: WStackView {
                id: stackView
                implicitWidth: initItem.implicitWidth
                implicitHeight: initItem.implicitHeight

                initialItem: WPanelPageColumn {
                    id: initItem
                    MainPageBody {}
                    WPanelSeparator {}
                    MainPageFooter {}
                }

                Component.onCompleted: {
                    ActionCenterContext.stackView = this;
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.BackButton
                    onClicked: {
                        ActionCenterContext.back();
                    }
                }
            }
        }
    }
}
