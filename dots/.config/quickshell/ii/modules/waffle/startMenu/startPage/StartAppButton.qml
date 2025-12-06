pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.waffle.looks

WButton {
    id: root
    required property DesktopEntry desktopEntry
    implicitWidth: 96
    implicitHeight: 84
    horizontalPadding: 0
    verticalPadding: 0
    contentItem: ColumnLayout {
        spacing: 3
        WAppIcon {
            Layout.topMargin: 12
            Layout.alignment: Qt.AlignHCenter
            iconName: root.desktopEntry.icon
            implicitSize: 34
            tryCustomIcon: false
        }
        WText {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            text: root.desktopEntry.name
            wrapMode: Text.Wrap
            elide: Text.ElideRight
            maximumLineCount: 2
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignTop
        }
    }
    WToolTip {
        text: root.desktopEntry.name
    }
}
