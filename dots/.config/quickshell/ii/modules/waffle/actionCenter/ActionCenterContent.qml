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
            ActionCenterContext.stackView = this
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.BackButton
            onClicked: {
                ActionCenterContext.back()
            }
        }
    }
}
