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
    
    contentItem: Column {
        // This somewhat sophisticated anchoring is needed to make opening anim not jump abruptly when stuff appear
        anchors {
            left: parent.left
            right: parent.right
            top: root.barAtBottom ? undefined : parent.top
            bottom: root.barAtBottom ? parent.bottom : undefined
            margins: root.visualMargin
        }
        spacing: 12

        WPane {
            visible: MprisController.activePlayer != null && MprisController.isRealPlayer(MprisController.activePlayer)
            anchors {
                left: parent.left
                right: parent.right
            }
            contentItem: MediaPaneContent {}
        }
        WPane {
            contentItem: WStackView {
                id: stackView
                anchors.fill: parent
                implicitWidth: initItem.implicitWidth
                implicitHeight: initItem.implicitHeight

                initialItem: PageColumn {
                    id: initItem
                    MainPageBody {}
                    Separator {}
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
