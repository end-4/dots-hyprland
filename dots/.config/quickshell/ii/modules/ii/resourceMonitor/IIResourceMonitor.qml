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
    property int currentTab: 0
    
    // Signal to close the window (since we are now inside an Item, not Window)
    signal closeRequested()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            MaterialSymbol {
                text: "monitoring"
                iconSize: 28
                color: Appearance.m3colors.m3primary
            }

            StyledText {
                text: Translation.tr("Resource Monitor")
                font.pixelSize: Appearance.font.pixelSize.larger
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer0
            }

            Item { Layout.fillWidth: true }

            // Tab buttons
            RippleButton {
                id: overviewBtn
                text: Translation.tr("Overview")
                checkable: true
                checked: root.currentTab === 0
                onClicked: root.currentTab = 0
                implicitHeight: 36
                buttonRadius: Appearance.rounding.small
                colBackground: checked ? Appearance.m3colors.m3primaryContainer : Appearance.colors.colLayer1
                contentItem: RowLayout {
                    spacing: 6
                    MaterialSymbol {
                        text: "dashboard"
                        iconSize: 18
                        color: overviewBtn.checked ? Appearance.m3colors.m3onPrimaryContainer : Appearance.colors.colOnLayer1
                    }
                    StyledText {
                        text: overviewBtn.text
                        color: overviewBtn.checked ? Appearance.m3colors.m3onPrimaryContainer : Appearance.colors.colOnLayer1
                    }
                }
            }

            RippleButton {
                id: processesBtn
                text: Translation.tr("Processes")
                checkable: true
                checked: root.currentTab === 1
                onClicked: root.currentTab = 1
                implicitHeight: 36
                buttonRadius: Appearance.rounding.small
                colBackground: checked ? Appearance.m3colors.m3primaryContainer : Appearance.colors.colLayer1
                contentItem: RowLayout {
                    spacing: 6
                    MaterialSymbol {
                        text: "list"
                        iconSize: 18
                        color: processesBtn.checked ? Appearance.m3colors.m3onPrimaryContainer : Appearance.colors.colOnLayer1
                    }
                    StyledText {
                        text: processesBtn.text
                        color: processesBtn.checked ? Appearance.m3colors.m3onPrimaryContainer : Appearance.colors.colOnLayer1
                    }
                }
            }

            RippleButton {
                implicitWidth: 36
                implicitHeight: 36
                buttonRadius: Appearance.rounding.full
                onClicked: root.closeRequested()
                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    text: "close"
                    iconSize: 20
                    color: Appearance.colors.colOnLayer1
                }
            }
        }

        // Content area
        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: root.currentTab

            OverviewTab {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            ProcessesTab {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.currentTab === 1 // Optimization: only run process updates when visible
            }
        }
    }
}
