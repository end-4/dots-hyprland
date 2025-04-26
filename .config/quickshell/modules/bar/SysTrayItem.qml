import "root:/modules/common/"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import Qt5Compat.GraphicalEffects

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
            if (item.hasMenu) menu.open();
            event.accepted = true;
            break;
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
        id: trayIcon
        source: root.item.icon
        anchors.centerIn: parent
        width: parent.width
        height: parent.height
    }

    ColorOverlay {
        anchors.fill: trayIcon
        source: trayIcon
        color: Appearance.colors.colOnLayer0
    }

}
