import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.resourceMonitor

Item {
    id: root
    anchors.fill: parent
    
    signal closeRequested()
    
    property int currentTab: 1 // Default to Performance as per screenshot
    property bool isSidebarCollapsed: false

    component SidebarButton: RippleButton {
        id: sidebarBtn
        property string iconName
        property string label
        property bool isActive: false
        
        buttonText: label

        Layout.fillWidth: true
        Layout.preferredHeight: 40
        Layout.leftMargin: 4
        Layout.rightMargin: 4
        buttonRadius: Appearance.rounding.small
        colBackground: isActive ? Appearance.m3colors.m3surfaceContainerHighest : "transparent"
        
        contentItem: RowLayout {
            spacing: root.isSidebarCollapsed ? 0 : 12
            anchors.fill: parent
            anchors.leftMargin: root.isSidebarCollapsed ? 0 : 12
            anchors.rightMargin: root.isSidebarCollapsed ? 0 : 12
            
            // Active Indicator
            Rectangle {
                visible: sidebarBtn.isActive && !root.isSidebarCollapsed
                width: 3
                height: 16
                radius: 1.5
                color: Appearance.m3colors.m3primary
                Layout.alignment: Qt.AlignVCenter
            }
            
            // Placeholder for alignment if not active
            Item { 
                visible: !sidebarBtn.isActive && !root.isSidebarCollapsed
                width: 3 
                height: 16 
            }

            MaterialSymbol {
                text: sidebarBtn.iconName
                iconSize: 20
                color: sidebarBtn.isActive ? Appearance.m3colors.m3primary : Appearance.colors.colOnLayer1
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                Layout.fillWidth: root.isSidebarCollapsed
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            
            StyledText {
                visible: !root.isSidebarCollapsed
                text: sidebarBtn.label
                Layout.fillWidth: true
                color: sidebarBtn.isActive ? Appearance.colors.colOnLayer0 : Appearance.colors.colOnLayer1
                font.weight: sidebarBtn.isActive ? Font.DemiBold : Font.Normal
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // Sidebar
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: root.isSidebarCollapsed ? 60 : 240
            Behavior on Layout.preferredWidth { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
            color: Appearance.colors.colLayer1
            
            ColumnLayout {
                anchors.fill: parent
                anchors.topMargin: 8
                spacing: 4

                // Hamburger / Menu button
                RippleButton {
                    Layout.alignment: root.isSidebarCollapsed ? Qt.AlignHCenter : Qt.AlignLeft
                    Layout.leftMargin: root.isSidebarCollapsed ? 0 : 12
                    implicitWidth: 40
                    implicitHeight: 40
                    buttonRadius: Appearance.rounding.small
                    onClicked: root.isSidebarCollapsed = !root.isSidebarCollapsed
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: "menu"
                        iconSize: 20
                        color: Appearance.colors.colOnLayer1
                    }
                }

                Item { Layout.preferredHeight: 12 }

                SidebarButton {
                    label: Translation.tr("Processes")
                    iconName: "grid_view"
                    isActive: root.currentTab === 0
                    onClicked: root.currentTab = 0
                }

                SidebarButton {
                    label: Translation.tr("Performance")
                    iconName: "monitoring"
                    isActive: root.currentTab === 1
                    onClicked: root.currentTab = 1
                }

                SidebarButton {
                    label: Translation.tr("App history")
                    iconName: "history"
                    isActive: root.currentTab === 2
                    onClicked: root.currentTab = 2
                }

                SidebarButton {
                    label: Translation.tr("Startup apps")
                    iconName: "speed"
                    isActive: root.currentTab === 3
                    onClicked: root.currentTab = 3
                }

                SidebarButton {
                    label: Translation.tr("Users")
                    iconName: "group"
                    isActive: root.currentTab === 4
                    onClicked: root.currentTab = 4
                }

                SidebarButton {
                    label: Translation.tr("Details")
                    iconName: "list"
                    isActive: root.currentTab === 5
                    onClicked: root.currentTab = 5
                }

                SidebarButton {
                    label: Translation.tr("Services")
                    iconName: "settings_applications"
                    isActive: root.currentTab === 6
                    onClicked: root.currentTab = 6
                }

                Item { Layout.fillHeight: true }
                
                SidebarButton {
                    label: Translation.tr("Settings")
                    iconName: "settings"
                    isActive: false
                    onClicked: {}
                }
                
                Item { Layout.preferredHeight: 12 }
            }
        }

        // Main Content
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // Top Bar (Title)
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                color: "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 24
                    anchors.rightMargin: 24
                    spacing: 12

                    StyledText {
                        text: {
                            switch(root.currentTab) {
                                case 0: return Translation.tr("Processes")
                                case 1: return Translation.tr("Performance")
                                case 2: return Translation.tr("App history")
                                case 3: return Translation.tr("Startup apps")
                                case 4: return Translation.tr("Users")
                                case 5: return Translation.tr("Details")
                                case 6: return Translation.tr("Services")
                                default: return ""
                            }
                        }
                        font.pixelSize: Appearance.font.pixelSize.larger
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colOnLayer0
                    }

                    Item { Layout.fillWidth: true }
                    
                    // Header Actions
                    RippleButton {
                        implicitHeight: 36
                        implicitWidth: 140
                        buttonRadius: Appearance.rounding.small
                        colBackground: "transparent" // Or slightly lighter
                        contentItem: RowLayout {
                            spacing: 8
                            anchors.centerIn: parent
                            MaterialSymbol {
                                text: "add_task"
                                iconSize: 18
                                color: Appearance.m3colors.m3primary
                            }
                            StyledText {
                                text: Translation.tr("Run new task")
                                color: Appearance.m3colors.m3primary
                                font.weight: Font.Medium
                            }
                        }
                    }

                    RippleButton {
                        implicitHeight: 36
                        implicitWidth: 36
                        buttonRadius: Appearance.rounding.small
                        contentItem: MaterialSymbol {
                            anchors.centerIn: parent
                            text: "more_horiz"
                            iconSize: 20
                            color: Appearance.colors.colOnLayer1
                        }
                    }
                }
            }

            // Content
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Appearance.m3colors.m3surfaceContainerLow
                radius: Appearance.rounding.medium
                // Windows 11 style usually has rounded top-left corner for the content area if sidebar is dark
                // But here we just round the whole thing or top-left
                
                clip: true
                
                StackLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    currentIndex: root.currentTab

                    // Processes Tab
                    ProcessesTab {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: root.currentTab === 0
                    }

                    // Performance Tab (Overview)
                    WaffleOverviewTab {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: root.currentTab === 1
                    }
                    
                    // Placeholders for other tabs
                    Repeater {
                        model: 5
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            visible: root.currentTab === (index + 2)
                            
                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 16
                                
                                MaterialSymbol {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "construction"
                                    iconSize: 48
                                    color: Appearance.colors.colSubtext
                                }
                                
                                StyledText {
                                    text: Translation.tr("This page is under construction")
                                    color: Appearance.colors.colSubtext
                                    font.pixelSize: Appearance.font.pixelSize.large
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
