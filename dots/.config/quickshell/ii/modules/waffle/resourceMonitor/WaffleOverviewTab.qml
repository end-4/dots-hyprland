import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.resourceMonitor
import "../../common/models" as Models
import "../../common/functions/ResourceMonitorUtils.js" as Utils

Item {
    id: root
    
    Models.ResourceBackend {
        id: backend
        active: root.visible
        selectedGpuIndex: root.selectedGpuIndex
        processMonitorActive: true
    }

    // Data properties
    property real cpuUsage: backend.cpuUsage
    property real memoryUsed: backend.memoryUsed
    property real memoryTotal: backend.memoryTotal

    property real gpuUsage: backend.gpuUsage
    property real gpuMemoryUsed: backend.gpuMemoryUsed
    property real gpuMemoryTotal: backend.gpuMemoryTotal
    property string gpuName: backend.gpuName
    
    property real diskUsed: backend.diskUsed
    property real diskTotal: backend.diskTotal
    
    property real networkDownSpeed: backend.networkDownSpeed
    property real networkUpSpeed: backend.networkUpSpeed
    
    property int cpuCores: backend.cpuCores
    property string cpuName: backend.cpuName
    property string cpuSpeed: backend.cpuSpeed
    property string cpuBaseSpeed: backend.cpuBaseSpeed
    property int cpuSockets: backend.cpuSockets
    property int cpuLogicalProcessors: backend.cpuLogicalProcessors
    property string cpuVirtualization: backend.cpuVirtualization
    property string cpuL1Cache: backend.cpuL1Cache
    property string cpuL2Cache: backend.cpuL2Cache
    property string cpuL3Cache: backend.cpuL3Cache
    property int cpuThreads: backend.cpuThreads
    property int cpuHandles: backend.cpuHandles
    property string uptime: backend.uptime
    property string processCount: backend.processList.length > 0 ? backend.processList.length.toString() : "---"

    // GPU properties
    property var gpuList: backend.gpuList
    property int selectedGpuIndex: 0
    
    readonly property int historyLength: 60
    property list<real> cpuHistory: []
    property list<real> memHistory: []
    property list<real> gpuHistory: []
    property list<real> netHistory: []
    property list<real> diskHistory: []
    property real maxNetSpeed: 1024 * 1024

    property int selectedComponent: 0 // 0: CPU, 1: Memory, 2: Disk, 3: Wi-Fi, 4: GPU

    Timer {
        interval: 1000
        running: root.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.cpuHistory = [...root.cpuHistory.slice(-(root.historyLength - 1)), root.cpuUsage]
            root.memHistory = [...root.memHistory.slice(-(root.historyLength - 1)), root.memoryUsed / root.memoryTotal]
            root.gpuHistory = [...root.gpuHistory.slice(-(root.historyLength - 1)), root.gpuUsage / 100]
            root.diskHistory = [...root.diskHistory.slice(-(root.historyLength - 1)), Math.random() * 0.1] 

            var currentNetSpeed = root.networkDownSpeed + root.networkUpSpeed
            if (currentNetSpeed > root.maxNetSpeed) root.maxNetSpeed = currentNetSpeed
            var netUsage = root.maxNetSpeed > 0 ? currentNetSpeed / root.maxNetSpeed : 0
            root.netHistory = [...root.netHistory.slice(-(root.historyLength - 1)), Math.min(1, netUsage)]
        }
    }

    // --- UI Components ---

    component MiniChart: RippleButton {
        id: miniChart
        property string title
        property string subtitle
        property var historyData
        property bool isSelected: false
        property color graphColor: Appearance.m3colors.m3primary

        Layout.fillWidth: true
        Layout.preferredHeight: 60
        buttonRadius: Appearance.rounding.small
        colBackground: isSelected ? Appearance.m3colors.m3surfaceContainerHighest : "transparent"
        
        contentItem: RowLayout {
            anchors.fill: parent
            anchors.margins: 4
            spacing: 8

            Rectangle {
                Layout.preferredWidth: 3
                Layout.preferredHeight: 24
                Layout.alignment: Qt.AlignVCenter
                radius: 1.5
                color: miniChart.isSelected ? Appearance.m3colors.m3primary : "transparent"
                visible: false
            }

            Rectangle {
                Layout.preferredWidth: 80
                Layout.fillHeight: true
                color: "transparent"
                
                Graph {
                    anchors.fill: parent
                    values: miniChart.historyData
                    color: miniChart.graphColor
                    fillOpacity: 0.3
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                
                StyledText {
                    text: miniChart.title
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer0
                }
                
                StyledText {
                    text: miniChart.subtitle
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }
        }
    }

    component DetailView: ColumnLayout {
        property string title
        property string subtitle
        property var historyData
        property color graphColor: Appearance.m3colors.m3primary
        
        spacing: 16

        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            
            StyledText {
                text: title
                font.pixelSize: Appearance.font.pixelSize.huge
                font.weight: Font.Bold
                color: Appearance.colors.colOnLayer0
            }
            
            Item { Layout.fillWidth: true }
            
            StyledText {
                text: subtitle
                font.pixelSize: Appearance.font.pixelSize.large
                color: Appearance.colors.colSubtext
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 280
            color: Appearance.colors.colLayer1
            radius: Appearance.rounding.small
            border.width: 1
            border.color: Appearance.m3colors.m3outlineVariant
            
            Graph {
                anchors.fill: parent
                anchors.margins: 1
                values: historyData
                color: graphColor
                fillOpacity: 0.3
            }
            
            StyledText {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 8
                text: "100%"
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
            }
             StyledText {
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.margins: 8
                text: "0%"
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
            }
            StyledText {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.margins: 8
                text: "60 seconds"
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 16

        ColumnLayout {
            Layout.preferredWidth: 220
            Layout.fillHeight: true
            spacing: 4

            MiniChart {
                title: "CPU"
                subtitle: (root.cpuUsage * 100).toFixed(0) + "% " + root.cpuSpeed
                historyData: root.cpuHistory
                isSelected: root.selectedComponent === 0
                onClicked: root.selectedComponent = 0
            }

            MiniChart {
                title: "Memory"
                subtitle: (root.memoryUsed / (1024*1024*1024)).toFixed(1) + "/" + (root.memoryTotal / (1024*1024*1024)).toFixed(1) + " GB (" + ((root.memoryUsed / root.memoryTotal) * 100).toFixed(0) + "%)"
                historyData: root.memHistory
                isSelected: root.selectedComponent === 1
                onClicked: root.selectedComponent = 1
                graphColor: "#8E24AA"
            }

            MiniChart {
                title: "Disk 0 (C:)"
                subtitle: ((root.diskUsed / root.diskTotal) * 100).toFixed(0) + "%"
                historyData: root.diskHistory
                isSelected: root.selectedComponent === 2
                onClicked: root.selectedComponent = 2
                graphColor: "#43A047"
            }

            MiniChart {
                title: "Wi-Fi"
                subtitle: "S: " + Utils.formatSpeed(root.networkUpSpeed) + " R: " + Utils.formatSpeed(root.networkDownSpeed)
                historyData: root.netHistory
                isSelected: root.selectedComponent === 3
                onClicked: root.selectedComponent = 3
                graphColor: "#D81B60"
            }

            MiniChart {
                title: "GPU 0"
                subtitle: root.gpuUsage.toFixed(0) + "%"
                historyData: root.gpuHistory
                isSelected: root.selectedComponent === 4
                onClicked: root.selectedComponent = 4
            }

            Item { Layout.fillHeight: true }
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: root.selectedComponent

            DetailView {
                title: "CPU"
                subtitle: root.cpuName
                historyData: root.cpuHistory
                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 40

                    GridLayout {
                        Layout.alignment: Qt.AlignTop
                        flow: GridLayout.TopToBottom
                        rows: 3
                        columnSpacing: 40
                        rowSpacing: 10
                        
                        ColumnLayout {
                            StyledText { text: "Utilization"; color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.smaller }
                            StyledText { text: (root.cpuUsage * 100).toFixed(0) + "%"; font.pixelSize: Appearance.font.pixelSize.large }
                        }
                        ColumnLayout {
                            StyledText { text: "Processes"; color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.smaller }
                            StyledText { text: root.processCount; font.pixelSize: Appearance.font.pixelSize.large }
                        }
                        ColumnLayout {
                            StyledText { text: "Up time"; color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.smaller }
                            StyledText { text: root.uptime; font.pixelSize: Appearance.font.pixelSize.large }
                        }
                        ColumnLayout {
                            StyledText { text: "Speed"; color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.smaller }
                            StyledText { text: root.cpuSpeed; font.pixelSize: Appearance.font.pixelSize.large }
                        }
                        ColumnLayout {
                            StyledText { text: "Threads"; color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.smaller }
                            StyledText { text: root.cpuThreads.toString(); font.pixelSize: Appearance.font.pixelSize.large }
                        }
                        ColumnLayout {
                            StyledText { text: "Handles"; color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.smaller }
                            StyledText { text: root.cpuHandles.toString(); font.pixelSize: Appearance.font.pixelSize.large }
                        }
                    }

                    GridLayout {
                        Layout.alignment: Qt.AlignTop
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: 20
                        rowSpacing: 4

                        StyledText { text: "Base speed:"; color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.smaller }
                        StyledText { text: root.cpuBaseSpeed; font.pixelSize: Appearance.font.pixelSize.smaller; Layout.alignment: Qt.AlignRight }

                        StyledText { text: "Sockets:"; color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.smaller }
                        StyledText { text: root.cpuSockets.toString(); font.pixelSize: Appearance.font.pixelSize.smaller; Layout.alignment: Qt.AlignRight }

                        StyledText { text: "Cores:"; color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.smaller }
                        StyledText { text: root.cpuCores.toString(); font.pixelSize: Appearance.font.pixelSize.smaller; Layout.alignment: Qt.AlignRight }

                        StyledText { text: "Logical processors:"; color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.smaller }
                        StyledText { text: root.cpuLogicalProcessors.toString(); font.pixelSize: Appearance.font.pixelSize.smaller; Layout.alignment: Qt.AlignRight }

                        StyledText { text: "Virtualization:"; color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.smaller }
                        StyledText { text: root.cpuVirtualization; font.pixelSize: Appearance.font.pixelSize.smaller; Layout.alignment: Qt.AlignRight }

                        StyledText { text: "L1 cache:"; color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.smaller }
                        StyledText { text: root.cpuL1Cache; font.pixelSize: Appearance.font.pixelSize.smaller; Layout.alignment: Qt.AlignRight }

                        StyledText { text: "L2 cache:"; color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.smaller }
                        StyledText { text: root.cpuL2Cache; font.pixelSize: Appearance.font.pixelSize.smaller; Layout.alignment: Qt.AlignRight }

                        StyledText { text: "L3 cache:"; color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.smaller }
                        StyledText { text: root.cpuL3Cache; font.pixelSize: Appearance.font.pixelSize.smaller; Layout.alignment: Qt.AlignRight }
                    }
                }
            }

            DetailView {
                title: "Memory"
                subtitle: Utils.formatBytes(root.memoryTotal)
                historyData: root.memHistory
                graphColor: "#8E24AA"
                
                GridLayout {
                    Layout.fillWidth: true
                    flow: GridLayout.TopToBottom
                    rows: 3
                    columnSpacing: 40
                    rowSpacing: 10
                    
                    ColumnLayout {
                        StyledText { text: "In use (Compressed)"; color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.smaller }
                        StyledText { text: Utils.formatBytes(root.memoryUsed); font.pixelSize: Appearance.font.pixelSize.large }
                    }
                    ColumnLayout {
                        StyledText { text: "Available"; color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.smaller }
                        StyledText { text: Utils.formatBytes(root.memoryTotal - root.memoryUsed); font.pixelSize: Appearance.font.pixelSize.large }
                    }
                }
            }

            DetailView {
                title: "Disk 0 (C:)"
                subtitle: "SSD"
                historyData: root.diskHistory
                graphColor: "#43A047"
                
                GridLayout {
                    Layout.fillWidth: true
                    flow: GridLayout.TopToBottom
                    rows: 3
                    columnSpacing: 40
                    rowSpacing: 10
                    
                    ColumnLayout {
                        StyledText { text: "Active time"; color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.smaller }
                        StyledText { text: "0%"; font.pixelSize: Appearance.font.pixelSize.large }
                    }
                    ColumnLayout {
                        StyledText { text: "Capacity"; color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.smaller }
                        StyledText { text: Utils.formatBytes(root.diskTotal); font.pixelSize: Appearance.font.pixelSize.large }
                    }
                }
            }

            DetailView {
                title: "Wi-Fi"
                subtitle: "Wi-Fi"
                historyData: root.netHistory
                graphColor: "#D81B60"
                
                GridLayout {
                    Layout.fillWidth: true
                    flow: GridLayout.TopToBottom
                    rows: 3
                    columnSpacing: 40
                    rowSpacing: 10
                    
                    ColumnLayout {
                        StyledText { text: "Send"; color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.smaller }
                        StyledText { text: Utils.formatSpeed(root.networkUpSpeed); font.pixelSize: Appearance.font.pixelSize.large }
                    }
                    ColumnLayout {
                        StyledText { text: "Receive"; color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.smaller }
                        StyledText { text: Utils.formatSpeed(root.networkDownSpeed); font.pixelSize: Appearance.font.pixelSize.large }
                    }
                }
            }

            DetailView {
                title: "GPU 0"
                subtitle: root.gpuName
                historyData: root.gpuHistory
                
                GridLayout {
                    Layout.fillWidth: true
                    flow: GridLayout.TopToBottom
                    rows: 3
                    columnSpacing: 40
                    rowSpacing: 10
                    
                    ColumnLayout {
                        StyledText { text: "Utilization"; color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.smaller }
                        StyledText { text: root.gpuUsage.toFixed(0) + "%"; font.pixelSize: Appearance.font.pixelSize.large }
                    }
                    ColumnLayout {
                        StyledText { text: "GPU Memory"; color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.smaller }
                        StyledText { text: root.gpuMemoryUsed.toFixed(0) + " / " + root.gpuMemoryTotal.toFixed(0) + " MB"; font.pixelSize: Appearance.font.pixelSize.large }
                    }
                }
            }
        }
    }
}
