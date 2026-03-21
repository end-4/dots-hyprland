import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.functions
import qs.modules.ten.looks

Rectangle {
    id: root

    property alias text: label.text
    property alias iconSource: icon.source
    property var clicked: () => {}
    property var altAction: () => {}
    property var middleClickAction: () => {}
    property bool down: false
    property bool checked: false
    property bool hovered: false
    property real horizontalPadding: 12
    property real topInset: 4
    property real bottomInset: 4
    property string iconName: ""
    property int iconSize: 20

    // Windows 10 flat style - solid colors, no acrylic
    color: {
        if (root.down || root.checked) return TenLooks.colors.bg1Active
        if (root.hovered) return TenLooks.colors.bg1Hover
        return "transparent"
    }

    implicitHeight: 40 - topInset - bottomInset
    implicitWidth: contentLayout.implicitWidth + horizontalPadding * 2

    Row {
        id: contentLayout
        anchors.centerIn: parent
        spacing: 8
    }

    Label {
        id: label
        visible: text !== ""
        anchors.verticalCenter: parent.verticalCenter
        font.pixelSize: TenLooks.font.pixelSize.normal
        font.family: TenLooks.font.family.ui
        color: TenLooks.colors.fg
    }

    Item {
        id: icon
        visible: iconName !== ""
        width: iconSize
        height: iconSize
        anchors.verticalCenter: parent.verticalCenter

        // Simple colored rectangle as icon placeholder
        // In real implementation, would use actual icon
        Rectangle {
            anchors.centerIn: parent
            width: iconSize - 4
            height: iconSize - 4
            color: TenLooks.colors.fg
            radius: 2
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

        onPressed: (event) => {
            root.down = true;
        }
        onReleased: (event) => {
            root.down = false;
        }
        onEntered: {
            root.hovered = true;
        }
        onExited: {
            root.hovered = false;
        }
        onClicked: (event) => {
            if (event.button === Qt.LeftButton) root.clicked();
            if (event.button === Qt.RightButton) root.altAction();
            if (event.button === Qt.MiddleButton) root.middleClickAction();
        }
    }
}
