import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

MouseArea {
    id: root
    property bool borderless: Config.options.bar.borderless

    implicitWidth: rowLayout.implicitWidth + rowLayout.anchors.leftMargin + rowLayout.anchors.rightMargin
    implicitHeight: Appearance.sizes.barHeight
    hoverEnabled: !Config.options.bar.tooltips.clickToShow
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton

    // Which window the single gauge shows; toggled by clicking.
    property bool showingWeekly: Config.options.bar.claudeUsage.defaultWeekly

    onPressed: event => {
        if (event.button === Qt.MiddleButton)
            ClaudeUsage.getData(); // middle-click to refresh now
        else
            root.showingWeekly = !root.showingWeekly; // click to switch session <-> week
    }

    // A single Claude-usage gauge: icon inside a ring + percentage number.
    component UsageGauge: Item {
        id: gauge
        required property string iconName
        required property real percentage // 0..1
        property string label: "" // short window identifier, e.g. "5h" / "7d"
        property int warningThreshold: Config.options.bar.claudeUsage.warningThreshold
        property bool warning: percentage * 100 >= warningThreshold

        implicitWidth: gaugeRow.implicitWidth
        implicitHeight: Appearance.sizes.barHeight

        RowLayout {
            id: gaugeRow
            spacing: 2
            anchors.verticalCenter: parent.verticalCenter

            ClippedFilledCircularProgress {
                Layout.alignment: Qt.AlignVCenter
                lineWidth: Appearance.rounding.unsharpen
                value: Math.max(0, Math.min(1, gauge.percentage))
                implicitSize: 20
                colPrimary: gauge.warning ? Appearance.colors.colError : Appearance.colors.colOnSecondaryContainer
                accountForLightBleeding: !gauge.warning
                enableAnimation: false

                Item {
                    anchors.centerIn: parent
                    width: 20
                    height: 20
                    MaterialSymbol {
                        anchors.centerIn: parent
                        font.weight: Font.DemiBold
                        fill: 1
                        text: gauge.iconName
                        iconSize: Appearance.font.pixelSize.normal
                        color: Appearance.m3colors.m3onSecondaryContainer
                    }
                }
            }

            StyledText {
                Layout.alignment: Qt.AlignVCenter
                color: Appearance.colors.colOnLayer1
                font.pixelSize: Appearance.font.pixelSize.small
                text: ClaudeUsage.available ? `${Math.round(gauge.percentage * 100)}` : "–"
            }

            StyledText { // which window is being shown
                Layout.alignment: Qt.AlignVCenter
                visible: gauge.label.length > 0
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.smaller
                text: gauge.label
            }
        }
    }

    RowLayout {
        id: rowLayout
        spacing: 6
        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: 4

        UsageGauge { // Click the module to switch between the two windows
            iconName: root.showingWeekly ? "calendar_month" : "auto_awesome"
            percentage: (root.showingWeekly ? ClaudeUsage.sevenDay : ClaudeUsage.fiveHour) / 100
            label: root.showingWeekly ? "7d" : "5h"
        }
    }

    StyledPopup {
        hoverTarget: root

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 8

            StyledPopupHeaderRow {
                icon: "auto_awesome"
                label: ClaudeUsage.subscriptionType.length > 0 ? `Claude ${ClaudeUsage.subscriptionType.charAt(0).toUpperCase() + ClaudeUsage.subscriptionType.slice(1)}` : "Claude usage"
            }

            ColumnLayout {
                spacing: 4
                visible: ClaudeUsage.available

                StyledPopupValueRow {
                    icon: "timer"
                    label: Translation.tr("Session (5h):")
                    value: `${Math.round(ClaudeUsage.fiveHour)}%  ·  ${ClaudeUsage.timeUntil(ClaudeUsage.fiveHourReset)}`
                }
                StyledPopupValueRow {
                    icon: "calendar_month"
                    label: Translation.tr("Week (7d):")
                    value: `${Math.round(ClaudeUsage.sevenDay)}%  ·  ${ClaudeUsage.timeUntil(ClaudeUsage.sevenDayReset)}`
                }
                StyledPopupValueRow {
                    visible: ClaudeUsage.sevenDayOpus >= 0
                    icon: "neurology"
                    label: Translation.tr("Week · Opus:")
                    value: `${Math.round(ClaudeUsage.sevenDayOpus)}%`
                }
                StyledPopupValueRow {
                    visible: ClaudeUsage.sevenDaySonnet >= 0
                    icon: "graph_3"
                    label: Translation.tr("Week · Sonnet:")
                    value: `${Math.round(ClaudeUsage.sevenDaySonnet)}%`
                }
                StyledPopupValueRow {
                    visible: ClaudeUsage.extraEnabled && ClaudeUsage.extraMonthlyLimit > 0
                    icon: "paid"
                    label: Translation.tr("Extra credits:")
                    value: `${ClaudeUsage.extraUsedCredits.toFixed(2)} / ${ClaudeUsage.extraMonthlyLimit} ${ClaudeUsage.extraCurrency}`
                }
            }

            StyledText {
                visible: !ClaudeUsage.available
                color: Appearance.colors.colOnSurfaceVariant
                font.pixelSize: Appearance.font.pixelSize.small
                text: ClaudeUsage.lastError.length > 0 ? Translation.tr("Unavailable: %1").arg(ClaudeUsage.lastError) : Translation.tr("Loading…")
            }
        }
    }
}
