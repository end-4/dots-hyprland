import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets

MouseArea {
    id: root

    required property var bar
    required property SystemTrayItem item
    property bool targetMenuOpen: false
    property int trayItemWidth: 16

    acceptedButtons: Qt.LeftButton | Qt.RightButton
    Layout.fillHeight: true
    implicitWidth: trayItemWidth
    onClicked: (event) => {
        switch (event.button) {
        case Qt.LeftButton:
            item.activate();
            break;
        case Qt.RightButton:
            if (item.hasMenu)
                menu.open();

        }
    }

    QsMenuAnchor {
        id: menu

        menu: root.item.menu
        anchor.window: bar
        anchor.rect.x: root.x + bar.width
        anchor.rect.y: root.y
        anchor.rect.height: root.height
        anchor.edges: Edges.Bottom
    }

    IconImage {
        source: root.item.icon
        anchors.centerIn: parent
        width: parent.width
        height: parent.height
    }

}
