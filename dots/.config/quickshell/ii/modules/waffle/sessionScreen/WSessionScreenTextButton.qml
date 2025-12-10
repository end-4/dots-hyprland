pragma ComponentBehavior: Bound
import QtQuick
import qs
import qs.modules.waffle.looks

WTextButton {
    id: root

    implicitWidth: 135
    implicitHeight: 40
    horizontalPadding: 5

    property bool keyboardDown: false
    property alias focusRingRadius: focusRing.radius
    fgColor: (root.pressed || root.keyboardDown) ? Looks.darkColors.fg1 : Looks.darkColors.fg

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            keyboardDown = true;
            event.accepted = true;
        }
    }
    Keys.onReleased: event => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            keyboardDown = false;
            root.clicked();
            event.accepted = true;
        }
    }

    contentItem: Item {
        id: contentItem
        implicitWidth: buttonText.implicitWidth

        WText {
            id: buttonText
            anchors.fill: parent
            color: root.fgColor
            text: root.text
            font.pixelSize: Looks.font.pixelSize.large
        }
    }

    Rectangle {
        id: focusRing
        visible: root.focus
        anchors {
            fill: parent
            margins: -4
        }
        color: "transparent"
        border.width: 2
        border.color: "#ffffff"
    }
}
