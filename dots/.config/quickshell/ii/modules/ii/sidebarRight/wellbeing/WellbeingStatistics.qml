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
    
    property string totalTime: "0h 0m"
    property var appUsageList: []
    property bool serviceRunning: false
    property bool isLoading: false
    property string accumulatedOutput: ""
    
    // Auto-refresh when becoming visible
    onVisibleChanged: {
        if (visible) {
            console.log("[Wellbeing] Statistics tab became visible, refreshing data...");
            loadData();
        }
    }
    
    Component.onCompleted: {
        console.log("[Wellbeing] Component completed, loading data...");
        loadData();
    }
    
    function loadData() {
        console.log("[Wellbeing] loadData() called");
        isLoading = true;
        accumulatedOutput = ""; // Reset accumulated data
        console.log("[Wellbeing] Setting statsProcess.running to true");
        statsProcess.running = true;
    }
    
    // Auto-refresh timer - updates every 60 seconds when visible
    Timer {
        id: autoRefreshTimer
        interval: 60000  // 60 seconds
        running: root.visible && !root.isLoading
        repeat: true
        onTriggered: {
            console.log("[Wellbeing] Auto-refresh triggered");
            loadData();
        }
    }
    
    Process {
        id: statsProcess
        command: ["python3", Quickshell.env("HOME") + "/.config/hypr/productivity/digital-wellbeing.py", "stats", "today"]
        running: false
        
        stdout: SplitParser {
            onRead: data => {
                // Accumulate all output lines
                root.accumulatedOutput += data + "\n";
            }
        }
        
        onExited: code => {
            console.log("[Wellbeing] Process exited with code:", code);
            
            if (code === 0) {
                // Parse the accumulated output
                const fullOutput = root.accumulatedOutput.trim();
                console.log("[Wellbeing] Full output received, parsing...");
                const lines = fullOutput.split('\n');
                console.log("[Wellbeing] Total lines:", lines.length);
                
                // Parse total usage line
                for (let i = 0; i < lines.length; i++) {
                    const line = lines[i].trim();
                    if (line.startsWith('Total usage:')) {
                        root.totalTime = line.replace('Total usage:', '').trim();
                        root.serviceRunning = true;
                        console.log("[Wellbeing] Found total time:", root.totalTime);
                        break;
                    }
                }
                
                // Parse app usage data (lines starting with •)
                const apps = [];
                let inAppsSection = false;
                for (let i = 0; i < lines.length; i++) {
                    const line = lines[i].trim();
                    if (line.startsWith('Top Applications:')) {
                        inAppsSection = true;
                        console.log("[Wellbeing] Found apps section");
                        continue;
                    }
                    if (inAppsSection && line.startsWith('•')) {
                        // Parse lines like "  • code                 0h 36m"
                        const parts = line.substring(1).trim().split(/\s+/);
                        if (parts.length >= 2) {
                            const appName = parts[0];
                            const timeStr = parts.slice(-2).join(' '); // Last two elements are time
                            apps.push({ name: appName, time: timeStr });
                            console.log("[Wellbeing] Added app:", appName, "-", timeStr);
                        }
                    }
                }
                root.appUsageList = apps;
                console.log("[Wellbeing] Final app count:", apps.length);
            } else {
                console.log("[Wellbeing] ERROR: Non-zero exit code");
                root.serviceRunning = false;
                root.totalTime = "0h 0m";
                root.appUsageList = [];
            }
            
            root.isLoading = false;
            statsProcess.running = false;
        }
    }
    
    ColumnLayout {
        width: parent.width
        spacing: 15
        
        // Header
        RowLayout {
            Layout.fillWidth: true
            Layout.margins: 15
            Layout.bottomMargin: 10
            spacing: 10
            
            CalendarHeaderButton {
                Layout.fillWidth: true
                buttonText: Translation.tr("Today's Usage")
            }
            
            CalendarHeaderButton {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                forceCircle: true
                buttonText: ""
                tooltipText: Translation.tr("Refresh")
                enabled: !root.isLoading
                
                contentItem: MaterialSymbol {
                    text: "refresh"
                    iconSize: Appearance.font.pixelSize.large
                    color: Appearance.colors.colOnLayer1
                    
                    RotationAnimator on rotation {
                        running: root.isLoading
                        from: 0
                        to: 360
                        duration: 1000
                        loops: Animation.Infinite
                    }
                }
                
                onClicked: {
                    root.loadData();
                }
            }
        }
        
        // Service Status - Only show when service is NOT running AND not loading
        Rectangle {
            Layout.fillWidth: true
            Layout.margins: 15
            Layout.topMargin: 5
            Layout.preferredHeight: 60
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer2
            visible: !root.serviceRunning && !root.isLoading
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10
                
                MaterialSymbol {
                    text: "info"
                    iconSize: Appearance.font.pixelSize.large
                    color: Appearance.colors.colPrimary
                }
                
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    
                    StyledText {
                        id: statusText
                        text: Translation.tr("Tracking Service")
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colOnLayer2
                    }
                    
                    StyledText {
                        text: Translation.tr("Enable in Settings tab to start tracking")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnLayer2
                        opacity: 0.7
                    }
                }
            }
        }
        
        // Total Screen Time Card
        Rectangle {
            Layout.fillWidth: true
            Layout.margins: 15
            Layout.topMargin: 10
            Layout.preferredHeight: 140
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer2
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 8
                
                StyledText {
                    text: Translation.tr("Total Screen Time")
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnLayer2
                    opacity: 0.8
                }
                
                StyledText {
                    Layout.fillHeight: true
                    text: root.totalTime
                    font.pixelSize: Appearance.font.pixelSize.larger * 2.5
                    font.weight: Font.Bold
                    color: Appearance.colors.colOnLayer2
                    verticalAlignment: Text.AlignVCenter
                }
                
                StyledText {
                    text: Translation.tr("Today")
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnLayer2
                    opacity: 0.6
                }
            }
        }
        
        // App Usage Examples
        Rectangle {
            Layout.fillWidth: true
            Layout.margins: 15
            Layout.topMargin: 5
            Layout.preferredHeight: appUsageColumn.implicitHeight + 24
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer2
            visible: root.appUsageList.length > 0
            
            ColumnLayout {
                id: appUsageColumn
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10
                
                StyledText {
                    text: Translation.tr("Most Used Apps")
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer2
                }
                
                Repeater {
                    model: root.appUsageList
                    
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        
                        MaterialSymbol {
                            text: "apps"
                            iconSize: Appearance.font.pixelSize.large
                            color: Appearance.colors.colOnLayer2
                            opacity: 0.7
                        }
                        
                        StyledText {
                            Layout.fillWidth: true
                            text: modelData.name
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnLayer2
                        }
                        
                        StyledText {
                            text: modelData.time
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colOnLayer2
                            opacity: 0.7
                        }
                    }
                }
            }
        }
        
        // Loading Indicator - Only show while actually loading
        Rectangle {
            Layout.fillWidth: true
            Layout.margins: 15
            Layout.topMargin: 5
            Layout.preferredHeight: 70
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer2
            visible: root.isLoading
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10
                
                MaterialSymbol {
                    text: "sync"
                    iconSize: Appearance.font.pixelSize.large
                    color: Appearance.colors.colPrimary
                    
                    RotationAnimator on rotation {
                        running: root.isLoading
                        from: 0
                        to: 360
                        duration: 1000
                        loops: Animation.Infinite
                    }
                }
                
                StyledText {
                    Layout.fillWidth: true
                    text: Translation.tr("Loading...")
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnLayer2
                    wrapMode: Text.WordWrap
                }
            }
        }
        
        Item { Layout.fillHeight: true }
    }
}
