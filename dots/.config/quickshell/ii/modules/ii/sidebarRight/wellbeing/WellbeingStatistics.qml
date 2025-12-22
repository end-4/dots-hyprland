import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.ii.sidebarRight.calendar
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

ScrollView {
    id: root
    contentWidth: availableWidth
    contentHeight: contentColumn.implicitHeight
    clip: true
    
    ScrollBar.vertical.policy: ScrollBar.AsNeeded
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
    
    property bool isLoading: false
    property string accumulatedOutput: ""
    
    // Screen time data - loaded from tracking service
    property var screenTimeData: {
        "dailyAverage": "0h 0m",
        "percentChange": 0,
        "weekData": [],
        "mostUsedApps": [],
        "insights": "Loading your screen time data..."
    }
    
    // Integer font sizes to avoid type conversion warnings
    readonly property int fontSizeTiny: Math.floor(Appearance.font.pixelSize.tiny)
    readonly property int fontSizeTinyMinus1: Math.floor(Appearance.font.pixelSize.tiny - 1)
    readonly property int fontSizeLargerX2: Math.floor(Appearance.font.pixelSize.larger * 2)
    
    function formatTime(seconds) {
        var hours = Math.floor(seconds / 3600);
        var minutes = Math.floor((seconds % 3600) / 60);
        if (hours > 0) {
            return hours + "h " + minutes + "m";
        }
        return minutes + "m";
    }
    
    ColumnLayout {
        id: contentColumn
        width: parent.width
        spacing: 12
        
        // Header with title
        RowLayout {
            Layout.fillWidth: true
            Layout.margins: 16
            Layout.bottomMargin: 8
            spacing: 8

            MaterialSymbol {
                text: "schedule"
                iconSize: 20
                color: Appearance.colors.colPrimary
            }

            StyledText {
                text: "SCREEN TIME"
                font.pixelSize: Appearance.font.pixelSize.small
                font.weight: Font.Bold
                color: Appearance.colors.colPrimary
            }
            
            Item { Layout.fillWidth: true }
            
            // Refresh button
            Rectangle {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                radius: Appearance.rounding.full
                color: Appearance.colors.colLayer2
                visible: !root.isLoading
                
                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "refresh"
                    iconSize: 18
                    color: Appearance.colors.colOnLayer2
                }
                
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.loadData()
                    hoverEnabled: true
                    
                    onEntered: parent.color = Appearance.colors.colLayer3
                    onExited: parent.color = Appearance.colors.colLayer2
                }
            }
            
            // Loading spinner
            MaterialSymbol {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                text: "sync"
                iconSize: 18
                color: Appearance.colors.colPrimary
                visible: root.isLoading
                
                RotationAnimator on rotation {
                    running: root.isLoading
                    from: 0
                    to: 360
                    duration: 1000
                    loops: Animation.Infinite
                }
            }
        }
        
        // Loading state
        Rectangle {
            Layout.fillWidth: true
            Layout.margins: 16
            Layout.topMargin: 8
            Layout.preferredHeight: 200
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer2
            visible: root.isLoading && root.screenTimeData.weekData.length === 0
            
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 12
                
                MaterialSymbol {
                    Layout.alignment: Qt.AlignHCenter
                    text: "hourglass_empty"
                    iconSize: 48
                    color: Appearance.colors.colOnLayer2
                    opacity: 0.5
                }
                
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Loading screen time data..."
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnLayer2
                    opacity: 0.7
                }
            }
        }
        
        // Empty state
        Rectangle {
            Layout.fillWidth: true
            Layout.margins: 16
            Layout.topMargin: 8
            Layout.preferredHeight: 200
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer2
            visible: !root.isLoading && root.screenTimeData.weekData.length === 0
            
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 12
                
                MaterialSymbol {
                    Layout.alignment: Qt.AlignHCenter
                    text: "insights"
                    iconSize: 48
                    color: Appearance.colors.colOnLayer2
                    opacity: 0.5
                }
                
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: "No tracking data available yet"
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnLayer2
                    opacity: 0.7
                }
                
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Enable tracking in the Settings tab"
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnLayer2
                    opacity: 0.5
                }
            }
        }
        
        // Today's Screen Time Section
        Rectangle {
            Layout.fillWidth: true
            Layout.margins: 16
            Layout.topMargin: 0
            Layout.preferredHeight: todayTimeLayout.implicitHeight + 24
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer2
            visible: !root.isLoading && root.screenTimeData.weekData.length > 0
            
            ColumnLayout {
                id: todayTimeLayout
                anchors.fill: parent
                anchors.margins: 16
                spacing: 8

                StyledText {
                    text: "Today's Screen Time"
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnLayer2
                    opacity: 0.7
                }

                RowLayout {
                    spacing: 16

                    StyledText {
                        text: {
                            // Get today's total from weekData
                            if (root.screenTimeData.weekData.length > 0) {
                                var todayData = root.screenTimeData.weekData[root.screenTimeData.weekData.length - 1];
                                return todayData.total;
                            }
                            return "0h 0m";
                        }
                        font.pixelSize: root.fontSizeLargerX2
                        font.weight: Font.Bold
                        color: Appearance.colors.colOnLayer2
                    }

                    Rectangle {
                        Layout.preferredWidth: Math.floor(weekAvgText.implicitWidth + 12)
                        Layout.preferredHeight: Math.floor(weekAvgText.implicitHeight + 6)
                        radius: Appearance.rounding.full
                        color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.85)
                        border.width: 1
                        border.color: Appearance.colors.colPrimary

                        StyledText {
                            id: weekAvgText
                            anchors.centerIn: parent
                            text: "Week avg: " + (root.screenTimeData.dailyAverage || "0m")
                            font.pixelSize: root.fontSizeTiny
                            color: Appearance.colors.colPrimary
                        }
                    }
                }
            }
        }
        
        // Bar Chart Section
        Rectangle {
            Layout.fillWidth: true
            Layout.margins: 8
            Layout.topMargin: 8
            Layout.preferredHeight: 280
            radius: Appearance.rounding.normal
            color: Appearance.m3colors.m3surfaceContainerLow
            border.width: 1
            border.color: ColorUtils.transparentize(Appearance.m3colors.m3outline, 0.85)
            visible: !root.isLoading && root.screenTimeData.weekData.length > 0
            
            // Subtle gradient overlay for M3 depth
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                gradient: Gradient {
                    GradientStop { position: 0.0; color: ColorUtils.transparentize(Appearance.m3colors.m3surface, 0.97) }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }
            property real maxWeekTime: {
                var max = 0;
                for (var i = 0; i < root.screenTimeData.weekData.length; i++) {
                    var dayTotal = 0;
                    var apps = root.screenTimeData.weekData[i].apps;
                    for (var j = 0; j < apps.length; j++) {
                        dayTotal += apps[j].time;
                    }
                    if (dayTotal > max) max = dayTotal;
                }
                // Round up to nearest hour for cleaner scale, minimum 1 hour
                return Math.max(3600, Math.ceil(max / 3600) * 3600);
            }
            
            property var yAxisLabels: {
                var maxHours = Math.ceil(maxWeekTime / 3600);
                if (maxHours <= 1) return ["1h", "0"];
                if (maxHours <= 2) return ["2h", "1h", "0"];
                if (maxHours <= 4) return ["4h", "3h", "2h", "1h", "0"];
                if (maxHours <= 6) return ["6h", "4h", "3h", "2h", "0"];
                if (maxHours <= 8) return ["8h", "6h", "4h", "2h", "0"];
                if (maxHours <= 12) return ["12h", "9h", "6h", "3h", "0"];
                return ["16h", "12h", "8h", "4h", "0"];
            }
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 16
                
                // Bar Chart with Y-axis
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 180
                    spacing: 2
                    
                    // Y-axis labels
                    ColumnLayout {
                        Layout.preferredWidth: 1
                        Layout.fillHeight: true
                        spacing: 0
                        
                        Repeater {
                            model: parent.parent.parent.parent.yAxisLabels
                            delegate: Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                
                                StyledText {
                                    anchors.right: parent.right
                                    anchors.rightMargin: 4
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData
                                    font.pixelSize: root.fontSizeTinyMinus1
                                    color: Appearance.colors.colOnLayer2
                                    opacity: 0.5
                                }
                            }
                        }
                    }

                    // Bars
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 4
                        
                        property real maxTime: parent.parent.parent.maxWeekTime

                        Repeater {
                            model: root.screenTimeData.weekData
                            delegate: Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                property var dayData: modelData

                                ColumnLayout {
                                    anchors.fill: parent
                                    spacing: 8

                                    Item {
                                        id: chartItem
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        
                                        // Store maxTime locally so bars can access it easily
                                        // parent = ColumnLayout, parent.parent = delegate Item, parent.parent.parent = RowLayout
                                        property real maxTime: parent.parent.parent.maxTime

                                        Column {
                                            anchors.bottom: parent.bottom
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            width: Math.min(parent.width * 0.8, 32)
                                            spacing: 0

                                            Repeater {
                                                model: dayData.apps
                                                delegate: Item {
                                                    width: parent.width
                                                    height: {
                                                        if (!chartItem.maxTime || chartItem.maxTime === 0 || !chartItem.height) return 4;
                                                        var ratio = modelData.time / chartItem.maxTime;
                                                        return Math.max(Math.floor(ratio * chartItem.height), 4);
                                                    }
                                                    visible: height > 0
                                                    
                                                    // Shadow/elevation effect
                                                    Rectangle {
                                                        anchors.fill: barRect
                                                        anchors.leftMargin: -1
                                                        anchors.rightMargin: -1
                                                        anchors.topMargin: -0.5
                                                        anchors.bottomMargin: -0.5
                                                        radius: barRect.radius
                                                        color: Appearance.m3colors.m3shadow
                                                        opacity: 0.15
                                                        visible: barRect.height > 6
                                                    }
                                                    
                                                    // Main bar with M3 styling
                                                    Rectangle {
                                                        id: barRect
                                                        anchors.fill: parent
                                                        color: modelData.color
                                                        radius: 0
                                                        
                                                        // M3 surface tint overlay for depth
                                                        Rectangle {
                                                            anchors.fill: parent
                                                            radius: parent.radius
                                                            color: Appearance.m3colors.m3surfaceTint
                                                            opacity: 0.08
                                                        }
                                                    }

                                                    MouseArea {
                                                        anchors.fill: barRect
                                                        hoverEnabled: true
                                                        
                                                        onEntered: {
                                                            // M3 hover state - brighten the bar
                                                            barRect.opacity = 0.85;
                                                            
                                                            // Pass the day index to help position the tooltip
                                                            var dayIndex = parent.parent.parent.parent.parent.parent.parent.parent.index;
                                                            tooltipPopup.show(
                                                                modelData.name + ": " + root.formatTime(modelData.time),
                                                                barRect,
                                                                modelData.color,
                                                                dayIndex
                                                            );
                                                        }
                                                        
                                                        onExited: {
                                                            // Restore normal opacity
                                                            barRect.opacity = 1.0;
                                                            tooltipPopup.hide();
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    // Only day name at bottom
                                    StyledText {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: dayData.day
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        color: Appearance.colors.colOnLayer2
                                        opacity: 0.7
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            // Tooltip popup with M3 styling - inside chart area
            Rectangle {
                id: tooltipPopup
                visible: false
                z: 1000
                width: Math.min(tooltipContent.implicitWidth + 20, parent.width / 2.5)
                height: tooltipContent.implicitHeight + 16
                
                property string tooltipText: ""
                property string tooltipColor: Appearance.colors.colPrimary
                property Item targetItem: null
                property int dayIndex: -1
                
                color: Appearance.m3colors.m3surfaceContainerHighest
                radius: Appearance.rounding.normal
                border.width: 1
                border.color: ColorUtils.transparentize(tooltipColor, 0.5)
                
                // M3 elevation effect
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -2
                    radius: parent.radius + 1
                    color: Appearance.m3colors.m3shadow
                    opacity: 0.2
                    z: -1
                }

                function show(text, target, color, index) {
                    tooltipText = text;
                    tooltipColor = color || Appearance.colors.colPrimary;
                    targetItem = target;
                    dayIndex = index !== undefined ? index : -1;
                    visible = true;
                    updatePosition();
                }

                function hide() {
                    visible = false;
                    targetItem = null;
                    dayIndex = -1;
                }
                
                function updatePosition() {
                    if (targetItem) {
                        var globalPos = targetItem.mapToItem(parent, 0, 0);
                        
                        // Calculate bar center for comparison
                        var barCenterX = globalPos.x + targetItem.width / 2;
                        
                        // Smart positioning based on day position
                        // First 3 days (Sun, Mon, Tue) -> prefer right
                        // Last 4 days (Wed, Thu, Fri, Today) -> prefer left
                        var preferRight = dayIndex < 3;
                        
                        // Ensure tooltip doesn't overlap the bar by adding extra spacing
                        var spacing = 12; // Gap between bar and tooltip
                        var rightX = globalPos.x + targetItem.width + spacing;
                        var leftX = globalPos.x - width - spacing;
                        
                        if (preferRight) {
                            // Try right first
                            if (rightX + width < parent.width - 16) {
                                x = rightX;
                            } else {
                                // Fall back to left
                                x = Math.max(16, leftX);
                            }
                        } else {
                            // Try left first
                            if (leftX >= 16) {
                                x = leftX;
                            } else {
                                // Fall back to right
                                x = Math.min(rightX, parent.width - width - 16);
                            }
                        }
                        
                        // Vertically align with the bar segment - center of the actual segment
                        var centerY = globalPos.y + (targetItem.height / 2) - (height / 2);
                        
                        // Keep within chart bounds
                        y = Math.max(16, Math.min(centerY, parent.height - height - 16));
                    }
                }

                RowLayout {
                    id: tooltipContent
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8
                    
                    Rectangle {
                        Layout.preferredWidth: 10
                        Layout.preferredHeight: 10
                        Layout.alignment: Qt.AlignVCenter
                        radius: 5
                        color: tooltipPopup.tooltipColor
                    }

                    StyledText {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        text: tooltipPopup.tooltipText
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: Font.Medium
                        color: Appearance.m3colors.m3onSurface
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }
                }
            }
        }
        
        // Insights Section
        Rectangle {
            Layout.fillWidth: true
            Layout.margins: 16
            Layout.topMargin: 8
            Layout.preferredHeight: insightsText.implicitHeight + 32
            radius: Appearance.rounding.normal
            color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.9)
            border.width: 1
            border.color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.7)
            visible: !root.isLoading && root.screenTimeData.weekData.length > 0
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12
                
                MaterialSymbol {
                    text: "lightbulb"
                    iconSize: Appearance.font.pixelSize.large
                    color: Appearance.colors.colPrimary
                }
                
                StyledText {
                    id: insightsText
                    Layout.fillWidth: true
                    text: root.screenTimeData.insights
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnLayer0
                    wrapMode: Text.WordWrap
                }
            }
        }
        
        // Most Used Apps Section
        Rectangle {
            Layout.fillWidth: true
            Layout.margins: 8
            Layout.topMargin: 4
            Layout.preferredHeight: mostUsedColumn.implicitHeight + 32
            radius: Appearance.rounding.normal
            color: Appearance.m3colors.m3surfaceContainerLow
            border.width: 1
            border.color: ColorUtils.transparentize(Appearance.m3colors.m3outline, 0.85)
            visible: !root.isLoading && root.screenTimeData.mostUsedApps.length > 0
            
            ColumnLayout {
                id: mostUsedColumn
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                StyledText {
                    text: "Most Used"
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer2
                    opacity: 0.7
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: 10

                    Repeater {
                        model: root.screenTimeData.mostUsedApps
                        delegate: Rectangle {
                            width: appNameLabel.implicitWidth + 24
                            height: 32
                            radius: Appearance.rounding.normal
                            color: ColorUtils.transparentize(modelData.color, 0.88)
                            border.width: 1
                            border.color: ColorUtils.transparentize(modelData.color, 0.5)
                            
                            // M3 state layer for interaction
                            Rectangle {
                                anchors.fill: parent
                                radius: parent.radius
                                color: modelData.color
                                opacity: 0.05
                            }

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 8
                                
                                Rectangle {
                                    width: 8
                                    height: 8
                                    radius: 4
                                    color: modelData.color
                                }

                                StyledText {
                                    id: appNameLabel
                                    text: modelData.name
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    color: Appearance.colors.colOnLayer2
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                
                                onEntered: {
                                    parent.color = ColorUtils.transparentize(modelData.color, 0.75)
                                }
                                onExited: {
                                    parent.color = ColorUtils.transparentize(modelData.color, 0.85)
                                }
                            }
                        }
                    }
                }
            }
        }
        
        Item { Layout.fillHeight: true; Layout.preferredHeight: 20 }
    }
    
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
        accumulatedOutput = "";
        statsProcess.running = true;
    }
    
    // Auto-refresh timer - updates every 5 minutes when visible
    Timer {
        id: autoRefreshTimer
        interval: 300000  // 5 minutes
        running: root.visible && !root.isLoading
        repeat: true
        onTriggered: {
            console.log("[Wellbeing] Auto-refresh triggered");
            loadData();
        }
    }
    
    Process {
        id: statsProcess
        command: ["python3", Quickshell.env("HOME") + "/.config/hypr/productivity/digital-wellbeing.py", "stats", "week-json"]
        running: false
        
        stdout: SplitParser {
            onRead: data => {
                root.accumulatedOutput += data;
            }
        }
        
        onExited: code => {
            console.log("[Wellbeing] Process exited with code:", code);
            
            if (code === 0 && root.accumulatedOutput.trim().length > 0) {
                try {
                    const jsonData = JSON.parse(root.accumulatedOutput.trim());
                    console.log("[Wellbeing] Successfully parsed JSON data");
                    root.screenTimeData = jsonData;
                } catch (e) {
                    console.error("[Wellbeing] Failed to parse JSON:", e);
                    console.error("[Wellbeing] Output was:", root.accumulatedOutput);
                }
            } else {
                console.log("[Wellbeing] No data or error occurred");
            }
            
            root.isLoading = false;
            statsProcess.running = false;
        }
    }
}
