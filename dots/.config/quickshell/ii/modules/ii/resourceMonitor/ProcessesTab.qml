import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.resourceMonitor
import "../../common/models" as Models
import "../../common/functions/ResourceMonitorUtils.js" as Utils

ColumnLayout {
    id: root
    spacing: 8

    property var expandedGroups: ({})
    property string sortBy: "cpu"
    property bool sortAscending: false
    property string filterText: ""
    property int selectedPid: -1
    property string selectedGroup: ""

    Models.ResourceBackend {
        id: backend
        active: root.visible
        processMonitorActive: true
        onKillFinished: backend.refreshProcesses()
    }

    function toggleGroup(name) {
        var newExpanded = Object.assign({}, expandedGroups)
        if (newExpanded[name]) {
            delete newExpanded[name]
        } else {
            newExpanded[name] = true
        }
        expandedGroups = newExpanded
    }
    
    function killGroup(name) {
        for (var i = 0; i < backend.processList.length; i++) {
            if (backend.processList[i].name === name) {
                backend.killProcess(backend.processList[i].pid)
            }
        }
    }

    // Search and controls
    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 40
            radius: Appearance.rounding.small
            color: Appearance.colors.colLayer1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 8

                MaterialSymbol {
                    text: "search"
                    iconSize: 20
                    color: Appearance.colors.colSubtext
                }

                TextInput {
                    id: searchInput
                    Layout.fillWidth: true
                    color: Appearance.colors.colOnLayer1
                    font.pixelSize: Appearance.font.pixelSize.normal
                    clip: true
                    onTextChanged: root.filterText = text

                    Text {
                        anchors.fill: parent
                        text: Translation.tr("Search processes...")
                        color: Appearance.colors.colSubtext
                        font: parent.font
                        visible: !parent.text && !parent.activeFocus
                    }
                }

                RippleButton {
                    visible: searchInput.text.length > 0
                    implicitWidth: 24
                    implicitHeight: 24
                    buttonRadius: Appearance.rounding.full
                    onClicked: searchInput.text = ""
                    contentItem: MaterialSymbol {
                        text: "close"
                        iconSize: 16
                        color: Appearance.colors.colSubtext
                    }
                }
            }
        }

        RippleButton {
            implicitWidth: 40
            implicitHeight: 40
            buttonRadius: Appearance.rounding.small
            colBackground: Appearance.colors.colLayer1
            onClicked: backend.refreshProcesses()
            StyledToolTip { text: Translation.tr("Refresh") }
            contentItem: MaterialSymbol {
                anchors.centerIn: parent
                text: "refresh"
                iconSize: 20
                color: Appearance.colors.colOnLayer1
            }
        }
    }

    // Header row
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 36
        radius: Appearance.rounding.small
        color: Appearance.colors.colLayer1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 8

            Item { implicitWidth: 24 }  // Space for expand button

            ProcessHeaderButton {
                Layout.preferredWidth: 60
                text: "PID"
                sortKey: "pid"
                currentSort: root.sortBy
                ascending: root.sortAscending
                onClicked: {
                    if (root.sortBy === "pid") root.sortAscending = !root.sortAscending
                    else { root.sortBy = "pid"; root.sortAscending = false }
                }
            }

            ProcessHeaderButton {
                Layout.fillWidth: true
                text: Translation.tr("Name")
                sortKey: "name"
                currentSort: root.sortBy
                ascending: root.sortAscending
                onClicked: {
                    if (root.sortBy === "name") root.sortAscending = !root.sortAscending
                    else { root.sortBy = "name"; root.sortAscending = true }
                }
            }

            ProcessHeaderButton {
                Layout.preferredWidth: 70
                text: "CPU %"
                sortKey: "cpu"
                currentSort: root.sortBy
                ascending: root.sortAscending
                horizontalAlignment: Text.AlignHCenter
                onClicked: {
                    if (root.sortBy === "cpu") root.sortAscending = !root.sortAscending
                    else { root.sortBy = "cpu"; root.sortAscending = false }
                }
            }

            ProcessHeaderButton {
                Layout.preferredWidth: 70
                text: "MEM %"
                sortKey: "mem"
                currentSort: root.sortBy
                ascending: root.sortAscending
                horizontalAlignment: Text.AlignHCenter
                onClicked: {
                    if (root.sortBy === "mem") root.sortAscending = !root.sortAscending
                    else { root.sortBy = "mem"; root.sortAscending = false }
                }
            }

            Item { implicitWidth: 36 }
        }
    }

    // Process list with grouped view
    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true

        ListView {
            id: processListView
            anchors.fill: parent
            clip: true
            spacing: 2
            cacheBuffer: 2000

            // Keep track of the first visible index (delegate height is fixed at 40)
            property int savedFirstIndex: 0
            property bool restoringPosition: false

            onContentYChanged: {
                if (!restoringPosition) savedFirstIndex = Math.max(0, Math.floor(contentY / 40))
            }

            onModelChanged: {
                // Restore position after the model updates. Use callLater to wait for layout.
                restoringPosition = true
                Qt.callLater(function() {
                    var idx = Math.min(savedFirstIndex, Math.max(0, count - 1))
                    if (idx >= 0) positionViewAtIndex(idx, ListView.Beginning)
                    restoringPosition = false
                })
            }
            
            model: Utils.flattenGrouped(
                Utils.filterGroups(Utils.groupByName(backend.processList), root.filterText),
                root.expandedGroups,
                root.filterText,
                root.sortBy,
                root.sortAscending
            )

            delegate: ProcessListItem {
                width: processListView.width
                isExpanded: root.expandedGroups[modelData.name] || false
                isSelected: isGroupItem ? (root.selectedGroup === modelData.name) : (root.selectedPid === modelData.pid)
                filterActive: root.filterText.length > 0
                
                onItemClicked: {
                    if (isGroupItem) {
                        root.selectedGroup = (root.selectedGroup === modelData.name) ? "" : modelData.name
                        root.selectedPid = -1
                    } else {
                        root.selectedPid = (root.selectedPid === modelData.pid) ? -1 : modelData.pid
                        root.selectedGroup = ""
                    }
                }
                
                onToggleGroup: name => root.toggleGroup(name)
                onKillGroup: name => root.killGroup(name)
                onKillProcess: pid => backend.killProcess(pid)
            }
        }

        ColumnLayout {
            anchors.centerIn: parent
            visible: backend.processList.length === 0
            spacing: 10

            IconImage {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 64
                implicitHeight: 64
                source: Quickshell.iconPath("illogical-impulse")
                
                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    running: parent.visible
                    NumberAnimation { from: 1; to: 0.3; duration: 1000; easing.type: Easing.InOutQuad }
                    NumberAnimation { from: 0.3; to: 1; duration: 1000; easing.type: Easing.InOutQuad }
                }
            }

            StyledText {
                text: Translation.tr("Loading processes...")
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.normal
            }
        }
    }

    // Footer
    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        StyledText {
            text: Translation.tr("%1 processes in %2 groups").arg(backend.processList.length).arg(Utils.groupByName(backend.processList).length)
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
        }

        Item { Layout.fillWidth: true }

        StyledText {
            visible: root.filterText
            text: Translation.tr("Showing: %1 groups").arg(Utils.filterGroups(Utils.groupByName(backend.processList), root.filterText).length)
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
        }
    }
}