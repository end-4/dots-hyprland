import QtQuick
import QtQuick.Layouts
import qs.modules.common

ToolbarButton {
    id: iconBtn
    required property string iconText

    colBackgroundToggled: Appearance.colors.colSecondaryContainer
    colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
    colRippleToggled: Appearance.colors.colSecondaryContainerActive
    property color colText: toggled ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnSurfaceVariant

    contentItem: Row {
        anchors.centerIn: parent
        spacing: 6

        MaterialSymbol {
            anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            iconSize: 22
            text: iconBtn.iconText
            color: iconBtn.colText
        }
        StyledText {
            visible: iconBtn.iconText.length > 0 && iconBtn.text.length > 0
            anchors.verticalCenter: parent.verticalCenter
            color: iconBtn.colText
            text: iconBtn.text
        }
    }
}
