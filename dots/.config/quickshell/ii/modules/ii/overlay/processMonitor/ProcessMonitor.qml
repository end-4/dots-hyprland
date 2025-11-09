import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.overlay

StyledOverlayWidget {
    id: root
    minimumWidth: 300
    minimumHeight: 300

    property string searchText: ""
    property string expandedPid: ""

    // Sorting states: 0 = none, 1 = ascending, 2 = descending; could be done with just one state variable? 🤔
    property int sortStateProcess: 0
    property int sortStateCpu: 0
    property int sortStateRam: 0

    function applySorting(procs) {
        let sorted = procs.slice()

        if (sortStateProcess !== 0) {
            sorted.sort((a, b) => {
                const nameA = a.name.toLowerCase()
                const nameB = b.name.toLowerCase()
                return sortStateProcess === 1 ?
                    nameA.localeCompare(nameB) :
                    nameB.localeCompare(nameA)
            })
        } else if (sortStateCpu !== 0) {
            sorted.sort((a, b) => {
                return sortStateCpu === 1 ?
                    b.cpuPercent - a.cpuPercent :
                    a.cpuPercent - b.cpuPercent
            })
        } else if (sortStateRam !== 0) {
            sorted.sort((a, b) => {
                return sortStateRam === 1 ?
                    b.memoryKb - a.memoryKb :
                    a.memoryKb - b.memoryKb
            })
        }

        return sorted
    }

    property var filteredProcesses: {
        const search = searchText.trim().toLowerCase()

        if (search === "") {
            return ProcessMonitor.processes
        }

        return ProcessMonitor.processes.filter(proc =>
        proc.name.toLowerCase().includes(search) ||
        proc.fullCommand.toLowerCase().includes(search) ||
        proc.pid.toString().includes(search)
        )
    }

    property var displayedProcesses: applySorting(filteredProcesses)

    Timer {
        id: modelRefreshTimer
        interval: 130
        repeat: false
        onTriggered: {
            displayedProcesses = applySorting(filteredProcesses)
        }
    } // since i dont know how to prevent overlapping smartly, this will avoid most of it when searching

    onSearchTextChanged: {
        if (expandedPid !== "") {
            expandedPid = ""
        }

        displayedProcesses = []
        modelRefreshTimer.restart()
    }

    onExpandedPidChanged: {
        if (expandedPid === "") {
            displayedProcesses = applySorting(filteredProcesses)
        }
    }

    onFilteredProcessesChanged: {
        if (expandedPid === "") {
            modelRefreshTimer.restart()
        }
    }

    onSortStateProcessChanged: { displayedProcesses = applySorting(filteredProcesses) }
    onSortStateCpuChanged: { displayedProcesses = applySorting(filteredProcesses) }
    onSortStateRamChanged: { displayedProcesses = applySorting(filteredProcesses) }

    contentItem: OverlayBackground {
        radius: root.contentRadius
        property real padding: 6
        implicitWidth: 550
        implicitHeight: 600

        ColumnLayout {
            anchors {
                fill: parent
                margins: parent.padding
            }
            spacing: 8

            // Seach bar
            RowLayout {
                Layout.fillWidth: true
                Layout.margins: 4
                spacing: 6

                MaterialSymbol {
                    text: "search"
                    color: Appearance.colors.colOnSurfaceVariant
                    iconSize: Appearance.font.pixelSize.large
                }

                ToolbarTextField {
                    Layout.fillWidth: true
                    Layout.fillHeight: false
                    Layout.preferredHeight: 36
                    placeholderText: Translation.tr("Search processes...")
                    text: root.searchText
                    onTextChanged: root.searchText = text
                }

                Loader {
                    Layout.preferredWidth: 50
                    Layout.preferredHeight: 24
                    active: root.searchText.trim() !== ""
                    sourceComponent: Rectangle {
                        width: 50
                        height: 24
                        radius: Appearance.rounding.full
                        color: Appearance.colors.colSecondaryContainer

                        StyledText {
                            anchors.centerIn: parent
                            text: root.filteredProcesses.length
                            color: Appearance.colors.colOnSecondaryContainer
                            font.pixelSize: Appearance.font.pixelSize.small
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true

                            StyledToolTip {
                                text: Translation.tr("%1 processes found").arg(root.filteredProcesses.length)
                            }
                        }
                    }
                }
            }

            // Header
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                Layout.margins: 4
                color: Appearance.colors.colSecondaryContainer
                radius: Appearance.rounding.small

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 6

                    // Process slabel
                    Item {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 50
                        Layout.preferredHeight: parent.height

                        StyledText {
                            id: processLabel
                            anchors.verticalCenter: parent.verticalCenter
                            text: Translation.tr("Process")
                            font.bold: true
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: root.sortStateProcess !== 0 ?
                                   Appearance.colors.colPrimary :
                                   processMouseArea.containsMouse ?
                                   Appearance.colors.colPrimary :
                                   Appearance.colors.colOnSecondaryContainer
                            opacity: processMouseArea.containsMouse ? 0.7 : 1.0
                        }

                        MaterialSymbol {
                            visible: root.sortStateProcess !== 0
                            anchors.left: processLabel.right
                            anchors.leftMargin: 3
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.sortStateProcess === 1 ? "arrow_downward" : "arrow_upward"
                            color: Appearance.colors.colPrimary
                            iconSize: 14
                        }

                        MouseArea {
                            id: processMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.sortStateCpu = 0
                                root.sortStateRam = 0
                                root.sortStateProcess = (root.sortStateProcess + 1) % 3
                            }
                        }
                    }

                    // CPU Label
                    Item {
                        Layout.preferredWidth: 70
                        Layout.minimumWidth: 70
                        Layout.maximumWidth: 70
                        Layout.preferredHeight: parent.height

                        StyledText {
                            id: cpuLabel
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: Translation.tr("CPU")
                            font.bold: true
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: root.sortStateCpu !== 0 ?
                                   Appearance.colors.colPrimary :
                                   cpuMouseArea.containsMouse ?
                                   Appearance.colors.colPrimary :
                                   Appearance.colors.colOnSecondaryContainer
                            opacity: cpuMouseArea.containsMouse ? 0.7 : 1.0
                        }

                        MaterialSymbol {
                            visible: root.sortStateCpu !== 0
                            anchors.right: cpuLabel.left
                            anchors.rightMargin: 3
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.sortStateCpu === 1 ? "arrow_downward" : "arrow_upward"
                            color: Appearance.colors.colPrimary
                            iconSize: 14
                        }

                        MouseArea {
                            id: cpuMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.sortStateProcess = 0
                                root.sortStateRam = 0
                                root.sortStateCpu = (root.sortStateCpu + 1) % 3
                            }
                        }
                    }

                    // RAM label
                    Item {
                        Layout.preferredWidth: 90
                        Layout.minimumWidth: 90
                        Layout.maximumWidth: 90
                        Layout.preferredHeight: parent.height

                        StyledText {
                            id: ramLabel
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: Translation.tr("RAM")
                            font.bold: true
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: root.sortStateRam !== 0 ?
                                   Appearance.colors.colPrimary :
                                   ramMouseArea.containsMouse ?
                                   Appearance.colors.colPrimary :
                                   Appearance.colors.colOnSecondaryContainer
                            opacity: ramMouseArea.containsMouse ? 0.7 : 1.0
                        }

                        MaterialSymbol {
                            visible: root.sortStateRam !== 0
                            anchors.right: ramLabel.left
                            anchors.rightMargin: 3
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.sortStateRam === 1 ? "arrow_downward" : "arrow_upward"
                            color: Appearance.colors.colPrimary
                            iconSize: 14
                        }

                        MouseArea {
                            id: ramMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.sortStateProcess = 0
                                root.sortStateCpu = 0
                                root.sortStateRam = (root.sortStateRam + 1) % 3
                            }
                        }
                    }

                    Item {
                        Layout.preferredWidth: 36
                        Layout.minimumWidth: 36
                        Layout.maximumWidth: 36
                    }
                }
            }

            // Process list or empty state
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                // Empty state message
                ColumnLayout {
                    anchors.centerIn: parent
                    visible: root.displayedProcesses.length === 0
                    spacing: 12

                    MaterialSymbol {
                        Layout.alignment: Qt.AlignHCenter
                        text: "search_off"
                        color: Appearance.colors.colOnSurfaceVariant
                        iconSize: 48
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: Translation.tr("No processes found")
                        color: Appearance.colors.colOnSurfaceVariant
                        font.pixelSize: Appearance.font.pixelSize.large
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: Translation.tr("Try a different query")
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.small
                    }
                }

                // Process list
                ScrollView {
                    anchors.fill: parent
                    visible: root.displayedProcesses.length > 0
                    clip: true

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                        contentItem: Rectangle {
                            implicitWidth: 6
                            radius: 3
                            color: Appearance.colors.colOnSurfaceVariant
                            opacity: parent.active ? 0.7 : 0.3
                        }
                    }

                    StyledListView {
                        id: listView
                        animateAppearance: true
                        animateMovement: true
                        clip: true

                        model: ScriptModel {
                            objectProp: "pid"
                            values: root.displayedProcesses
                        }

                        delegate: Item {
                            required property var modelData
                            width: listView.width
                            height: delegateColumn.implicitHeight + 8
                            clip: true

                            Behavior on height {
                                enabled: !ProcessMonitor.updating && !modelRefreshTimer.running
                                NumberAnimation {
                                    easing.type: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                                }
                            }

                            property bool isExpanded: root.expandedPid === modelData.pid

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 2
                                color: mouseArea.containsMouse ? Appearance.colors.colSecondaryContainer : "transparent"
                                radius: Appearance.rounding.small

                                Behavior on color {
                                    ColorAnimation { duration: 150 }
                                }
                            }

                            MouseArea {
                                id: mouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton
                                onClicked: {
                                    if (isExpanded) {
                                        root.expandedPid = ""
                                    } else {
                                        root.expandedPid = modelData.pid
                                    }
                                }
                            }

                            Column {
                                id: delegateColumn
                                width: parent.width
                                spacing: isExpanded ? 8 : 0

                                // Main row
                                Item {
                                    id: mainRow
                                    width: parent.width
                                    height: 40

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 12
                                        anchors.rightMargin: 12
                                        spacing: 6

                                        StyledText {
                                            Layout.fillWidth: true
                                            Layout.minimumWidth: 50
                                            text: modelData.name
                                            elide: Text.ElideRight
                                            color: Appearance.colors.colOnSurface
                                            font.pixelSize: Appearance.font.pixelSize.small
                                        }

                                        StyledText {
                                            Layout.preferredWidth: 70
                                            Layout.minimumWidth: 70
                                            Layout.maximumWidth: 70
                                            horizontalAlignment: Text.AlignRight
                                            text: (modelData.cpuPercent || 0.0).toFixed(1) + "%"
                                            color: modelData.cpuPercent > 50 ?
                                            Appearance.colors.colError :
                                            modelData.cpuPercent > 25 ?
                                            '#d8ffc374' :
                                            Appearance.colors.colOnSurfaceVariant
                                            font {
                                                family: Appearance.font.family.numbers
                                                variableAxes: Appearance.font.variableAxes.numbers
                                                pixelSize: Appearance.font.pixelSize.small
                                            }
                                        }

                                        StyledText {
                                            Layout.preferredWidth: 90
                                            Layout.minimumWidth: 90
                                            Layout.maximumWidth: 90
                                            horizontalAlignment: Text.AlignRight
                                            text: modelData.memoryFormatted
                                            color: Appearance.colors.colOnSurfaceVariant
                                            font {
                                                family: Appearance.font.family.numbers
                                                variableAxes: Appearance.font.variableAxes.numbers
                                                pixelSize: Appearance.font.pixelSize.small
                                            }
                                        }

                                        Item {
                                            Layout.preferredWidth: 36
                                            Layout.minimumWidth: 36
                                            Layout.maximumWidth: 36
                                            Layout.preferredHeight: 36
                                            Layout.alignment: Qt.AlignVCenter

                                            RippleButton {
                                                anchors.centerIn: parent
                                                implicitWidth: 32
                                                implicitHeight: 32
                                                colBackground: "transparent"
                                                colBackgroundHover: Appearance.colors.colErrorContainer
                                                buttonRadius: Appearance.rounding.full

                                                contentItem: MaterialSymbol {
                                                    anchors.centerIn: parent
                                                    text: "close"
                                                    color: Appearance.colors.colError
                                                    iconSize: Appearance.font.pixelSize.medium
                                                }

                                                onClicked: {
                                                    // If this process is expanded, close it first
                                                    if (root.expandedPid === modelData.pid) {
                                                        root.expandedPid = ""
                                                    }
                                                    // Kill the processs
                                                    ProcessMonitor.killProcess(modelData.pid)
                                                }

                                                // The pause prevents flickering due the refreshing.

                                                StyledToolTip {
                                                    text: Translation.tr("Kill (PID: %1)").arg(modelData.pid)
                                                }
                                            }
                                        }
                                    }
                                }

                                // Expanded details
                                Rectangle {
                                    id: detailsBox
                                    width: parent.width - 32
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    height: detailsLayout.implicitHeight + 16
                                    visible: isExpanded
                                    color: Appearance.colors.colLayer1
                                    radius: Appearance.rounding.small

                                    ColumnLayout {
                                        id: detailsLayout
                                        anchors {
                                            left: parent.left
                                            right: parent.right
                                            top: parent.top
                                            margins: 8
                                        }
                                        spacing: 4

                                        RowLayout {
                                            spacing: 4
                                            MaterialSymbol {
                                                text: "badge"
                                                color: Appearance.colors.colOnSurfaceVariant
                                                iconSize: Appearance.font.pixelSize.small
                                            }
                                            StyledText {
                                                text: Translation.tr("PID:")
                                                color: Appearance.colors.colSubtext
                                                font.pixelSize: Appearance.font.pixelSize.smallie
                                            }
                                            StyledText {
                                                Layout.fillWidth: true
                                                horizontalAlignment: Text.AlignRight
                                                text: modelData.pid
                                                color: Appearance.colors.colOnSurface
                                                font.pixelSize: Appearance.font.pixelSize.smallie
                                            }
                                        }

                                        RowLayout {
                                            spacing: 4
                                            MaterialSymbol {
                                                text: "person"
                                                color: Appearance.colors.colOnSurfaceVariant
                                                iconSize: Appearance.font.pixelSize.small
                                            }
                                            StyledText {
                                                text: Translation.tr("User:")
                                                color: Appearance.colors.colSubtext
                                                font.pixelSize: Appearance.font.pixelSize.smallie
                                            }
                                            StyledText {
                                                Layout.fillWidth: true
                                                horizontalAlignment: Text.AlignRight
                                                text: modelData.user
                                                color: Appearance.colors.colOnSurface
                                                font.pixelSize: Appearance.font.pixelSize.smallie
                                            }
                                        }

                                        RowLayout {
                                            spacing: 4
                                            MaterialSymbol {
                                                text: "memory"
                                                color: Appearance.colors.colOnSurfaceVariant
                                                iconSize: Appearance.font.pixelSize.small
                                            }
                                            StyledText {
                                                text: Translation.tr("Memory:")
                                                color: Appearance.colors.colSubtext
                                                font.pixelSize: Appearance.font.pixelSize.smallie
                                            }
                                            StyledText {
                                                Layout.fillWidth: true
                                                horizontalAlignment: Text.AlignRight
                                                text: modelData.memPercent.toFixed(1) + "% (" + modelData.memoryFormatted + ")"
                                                color: Appearance.colors.colOnSurface
                                                font.pixelSize: Appearance.font.pixelSize.smallie
                                            }
                                        }

                                        RowLayout {
                                            Layout.topMargin: 2
                                            spacing: 4
                                            MaterialSymbol {
                                                Layout.alignment: Qt.AlignTop
                                                text: "terminal"
                                                color: Appearance.colors.colOnSurfaceVariant
                                                iconSize: Appearance.font.pixelSize.small
                                            }
                                            StyledText {
                                                Layout.alignment: Qt.AlignTop
                                                text: Translation.tr("Command:")
                                                color: Appearance.colors.colSubtext
                                                font.pixelSize: Appearance.font.pixelSize.smallie
                                            }
                                            StyledText {
                                                Layout.fillWidth: true
                                                text: modelData.fullCommand
                                                wrapMode: Text.Wrap
                                                color: Appearance.colors.colOnSurface
                                                font.pixelSize: Appearance.font.pixelSize.smallie
                                                font.family: "monospace"
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Footer
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 28
                Layout.margins: 4
                color: Appearance.colors.colSecondaryContainer
                radius: Appearance.rounding.small

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 6

                    MaterialSymbol {
                        text: "list"
                        color: Appearance.colors.colOnSecondaryContainer
                        iconSize: Appearance.font.pixelSize.small
                    }

                    StyledText {
                        text: root.searchText.trim() !== "" ?
                        Translation.tr("Showing %1 of %2").arg(root.filteredProcesses.length).arg(ProcessMonitor.processes.length) :
                        Translation.tr("Total: %1").arg(ProcessMonitor.processes.length)
                        color: Appearance.colors.colOnSecondaryContainer
                        font.pixelSize: Appearance.font.pixelSize.smallie
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        visible: root.expandedPid == ""
                        width: 6
                        height: 6
                        radius: 3
                        color: ProcessMonitor.updating ?
                        Appearance.colors.colWarning :
                        Appearance.colors.colPrimary
                    }

                    Rectangle { 
                        visible: root.expandedPid !== ""
                        width: 6
                        height: 6
                        radius: 1
                        color: ProcessMonitor.updating ?
                        Appearance.colors.colWarning :
                        Appearance.colors.colPrimary
                    }

                    StyledText {
                        text: ProcessMonitor.updating ? Translation.tr("Updating...") : root.expandedPid !== "" ? Translation.tr("Paused") : Translation.tr("Live")
                        color: ProcessMonitor.updating ?
                        Appearance.colors.colOnSecondaryContainer :
                        Appearance.colors.colPrimary
                        font.pixelSize: Appearance.font.pixelSize.smallie
                    }
                }
            }
        }
    }
}
