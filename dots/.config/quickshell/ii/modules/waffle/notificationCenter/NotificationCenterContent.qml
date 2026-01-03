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

    contentItem: ColumnLayout {
        id: contentLayout
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            bottom: parent.bottom
        }
        spacing: 12

        Item {
            id: notificationArea
            Layout.fillHeight: true
            implicitWidth: notificationPane.implicitWidth

            WPane {
                id: notificationPane
                anchors {
                    bottom: parent.bottom
                    left: parent.left
                    right: parent.right
                }
                contentItem: NotificationPaneContent {
                    implicitWidth: calendarColumnLayout.implicitWidth
                    implicitHeight: {
                        if (Notifications.list.length > 0) {
                            return ((contentLayout.height - calendarPane.height - contentLayout.spacing) - notificationPane.borderWidth * 2)
                        }
                        return 230;
                    }
                    
                    Timer {
                        id: enableTimer
                        interval: Config.options.hacks.arbitraryRaceConditionDelay
                        onTriggered: heightBehavior.enabled = true;
                    }
                    Behavior on implicitHeight {
                        id: heightBehavior
                        enabled: false
                        Component.onCompleted: {
                            enableTimer.restart();
                        }
                        animation: Looks.transition.enter.createObject(this)
                    }
                }
            }
        }

        WPane {
            id: calendarPane
            contentItem: WPanelPageColumn {
                id: calendarColumnLayout
                DateHeader {
                    Layout.fillWidth: true
                    Synchronizer on collapsed {
                        property alias source: root.collapsed
                    }
                }

                WPanelSeparator {
                    visible: !root.collapsed
                }

                CalendarWidget {
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
