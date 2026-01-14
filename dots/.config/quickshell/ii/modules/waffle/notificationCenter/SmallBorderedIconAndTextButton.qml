import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.waffle.looks

AcrylicButton {
    id: root

    property bool iconVisible: true
    property string iconName: ""
    property bool iconFilled: true

    colBackground: Looks.colors.bg2
    colBackgroundHover: Looks.colors.bg2Hover
    colBackgroundActive: Looks.colors.bg2Active
    property color colBorder: Looks.colors.bg2Border
    property color colBorderToggled: Looks.colors.accent
    border.color: checked ? colBorderToggled : colBorder

    leftPadding: 12
    rightPadding: 12
    implicitWidth: focusButtonContent.implicitWidth + leftPadding + rightPadding
    implicitHeight: 24

    contentItem: Row {
        id: focusButtonContent
        spacing: 4

        FluentIcon {
            visible: root.iconVisible
            icon: root.iconName
            filled: root.iconFilled
            implicitSize: 14
            anchors.verticalCenter: parent.verticalCenter
        }
        WText {
            anchors.verticalCenter: parent.verticalCenter
            text: root.text
        }
    }
}
