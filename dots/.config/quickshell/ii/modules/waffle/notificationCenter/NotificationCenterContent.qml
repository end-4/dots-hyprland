pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Qt.labs.synchronizer
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.waffle.looks

WBarAttachedPanelContent {
    id: root

    readonly property bool barAtBottom: Config.options.waffles.bar.bottom
    revealFromSides: true
    revealFromLeft: false

    property bool collapsed: false

    contentItem: Column {
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: root.barAtBottom ? undefined : parent.top
            bottom: root.barAtBottom ? parent.bottom : undefined
        }
        spacing: 12

        WPane {
            contentItem: ColumnLayout {
                spacing: 0
                CalendarHeader {
                    Layout.fillWidth: true
                    Synchronizer on collapsed {
                        property alias source: root.collapsed
                    }
                }

                WPanelSeparator { visible: !root.collapsed }

                CalendarView {
                    Layout.fillWidth: true
                    Synchronizer on collapsed {
                        property alias source: root.collapsed
                    }
                }

                WPanelSeparator {}

                FocusFooter {
                    Layout.fillWidth: true
                }
            }
        }
    }
}
