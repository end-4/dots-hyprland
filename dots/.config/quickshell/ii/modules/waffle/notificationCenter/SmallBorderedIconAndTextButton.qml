import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.waffle.looks

SmallBorderedIconButton {
    id: root

    property bool iconVisible: true
    property string iconName: ""
    property bool iconFilled: true

    leftPadding: 12
    rightPadding: 12
    implicitWidth: focusButtonContent.implicitWidth + leftPadding + rightPadding

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
