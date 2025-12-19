import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.sidebarRight.calendar
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

ScrollView {
    id: root
    contentWidth: availableWidth
    clip: true
    
    property bool focusModeActive: false
    
    Component.onCompleted: {
        checkFocusMode();
    }
    
    function checkFocusMode() {
        focusCheckProcess.running = true;
    }
    
    Process {
        id: focusCheckProcess
        command: ["bash", "-c", "pgrep -f 'focus-mode.sh' > /dev/null && echo 'active' || echo 'inactive'"]
        running: false
        
        stdout: SplitParser {
            onRead: data => {
                root.focusModeActive = data.trim() === 'active';
            }
        }
    }
    
    ColumnLayout {
        width: parent.width
        spacing: 15
        
        // Header
        CalendarHeaderButton {
            Layout.fillWidth: true
            Layout.margins: 15
            buttonText: Translation.tr("Digital Wellbeing Settings")
        }
        
        Rectangle {
            Layout.fillWidth: true
            Layout.margins: 15
            Layout.topMargin: 5
            Layout.preferredHeight: focusModeColumn.implicitHeight + 24
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer2
            
            ColumnLayout {
                id: focusModeColumn
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10
                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    
                    MaterialSymbol {
                        text: "do_not_disturb_on"
                        iconSize: Appearance.font.pixelSize.larger
                        color: Appearance.colors.colPrimary
                    }
                    
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        
                        StyledText {
                            text: Translation.tr("Focus Mode")
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.DemiBold
                            color: Appearance.colors.colOnLayer2
                        }
                        
                        StyledText {
                            text: Translation.tr("Block distracting apps")
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colOnLayer2
                            opacity: 0.7
                        }
                    }
                    
                    Switch {
                        checked: root.focusModeActive
                        onToggled: {
                            Quickshell.execDetached(["bash", "-c", Quickshell.env("HOME") + "/.config/hypr/productivity/focus-mode.sh toggle"]);
                            // Update status after toggle
                            Qt.callLater(root.checkFocusMode);
                        }
                    }
                }
            }
        }
        
        Rectangle {
            Layout.fillWidth: true
            Layout.margins: 15
            Layout.topMargin: 5
            Layout.preferredHeight: trackingColumn.implicitHeight + 24
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer2
            
            ColumnLayout {
                id: trackingColumn
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10
                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    
                    MaterialSymbol {
                        text: "monitoring"
                        iconSize: Appearance.font.pixelSize.larger
                        color: Appearance.colors.colPrimary
                    }
                    
                    StyledText {
                        Layout.fillWidth: true
                        text: Translation.tr("Usage Tracking")
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colOnLayer2
                    }
                }
                
                StyledText {
                    Layout.fillWidth: true
                    text: Translation.tr("Track your application usage and get insights")
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnLayer2
                    opacity: 0.7
                    wrapMode: Text.WordWrap
                }
                
                CalendarHeaderButton {
                    Layout.fillWidth: true
                    buttonText: Translation.tr("Start Tracking")
                    onClicked: {
                        Quickshell.execDetached(["python3", Quickshell.env("HOME") + "/.config/hypr/productivity/digital-wellbeing.py", "start"]);
                    }
                }
            }
        }
        
        Rectangle {
            Layout.fillWidth: true
            Layout.margins: 15
            Layout.topMargin: 5
            Layout.preferredHeight: eyeCareColumn.implicitHeight + 24
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer2
            
            ColumnLayout {
                id: eyeCareColumn
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10
                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    
                    MaterialSymbol {
                        text: "visibility"
                        iconSize: Appearance.font.pixelSize.larger
                        color: Appearance.colors.colPrimary
                    }
                    
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        
                        StyledText {
                            text: Translation.tr("Eye Care Reminders")
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.DemiBold
                            color: Appearance.colors.colOnLayer2
                        }
                        
                        StyledText {
                            text: Translation.tr("20-20-20 rule reminders")
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colOnLayer2
                            opacity: 0.7
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }
        }
        
        // Open Dashboard Button
        CalendarHeaderButton {
            Layout.fillWidth: true
            Layout.margins: 15
            Layout.topMargin: 10
            buttonText: Translation.tr("📊 Open Full Dashboard")
            onClicked: {
                Quickshell.execDetached(["python3", Quickshell.env("HOME") + "/.config/hypr/productivity/productivity-dashboard.py"]);
            }
        }
        
        Item { Layout.fillHeight: true }
    }
}
