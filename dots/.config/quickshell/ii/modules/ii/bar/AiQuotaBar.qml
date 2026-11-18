pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

MouseArea {
    id: root
    property bool vertical: false
    property bool hovered: false

    implicitWidth: root.vertical ? Appearance.sizes.verticalBarWidth : (contentRow.implicitWidth + 8 * 2)
    implicitHeight: root.vertical ? (contentColumn.implicitHeight + 6 * 2) : Appearance.sizes.barHeight

    hoverEnabled: !Config.options.bar.tooltips.clickToShow
    acceptedButtons: Qt.LeftButton | Qt.RightButton

    onEntered: root.hovered = true
    onExited: root.hovered = false
    onPressed: mouse => {
        // clickToShow mode: toggle the tooltip on click
        if (Config.options.bar.tooltips.clickToShow) {
            root.hovered = !root.hovered
            mouse.accepted = false
        }
    }

    // Inline entry: provider icon + compact percent, colored by threshold.
    // Horizontal bars lay the pair out in a row; the narrow vertical bar stacks
    // the icon above the percentage to avoid edge clipping.
    component AiQuotaEntry: GridLayout {
        id: entry
        required property var modelData
        Layout.alignment: root.vertical ? Qt.AlignHCenter : Qt.AlignVCenter
        Layout.fillWidth: root.vertical
        flow: root.vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
        rows: root.vertical ? 2 : 1
        columns: root.vertical ? 1 : 2
        rowSpacing: root.vertical ? 0 : 0
        columnSpacing: root.vertical ? 0 : 2

        readonly property int percent: AiQuota.mainPercent(entry.modelData)
        readonly property bool errored: entry.modelData.hasError
        readonly property color entryColor: entry.errored ? Appearance.colors.colError
            : (entry.percent >= 95 ? Appearance.colors.colError
            : (entry.percent >= 80 ? Appearance.colors.colTertiary
            : Appearance.colors.colOnLayer1))
        readonly property real iconSize: root.vertical ? 17 : Appearance.font.pixelSize.normal

        CustomIcon {
            source: entry.modelData.iconSource
            colorize: true
            color: entry.entryColor
            opacity: entry.errored ? 0.6 : 1
            width: entry.iconSize
            height: entry.iconSize
            Layout.preferredWidth: entry.iconSize
            Layout.preferredHeight: entry.iconSize
            Layout.maximumWidth: entry.iconSize
            Layout.maximumHeight: entry.iconSize
            Layout.alignment: root.vertical ? Qt.AlignHCenter : Qt.AlignVCenter
        }

        StyledText {
            visible: !entry.errored && entry.percent >= 0
            font.pixelSize: root.vertical ? Appearance.font.pixelSize.smaller : Appearance.font.pixelSize.small
            color: entry.entryColor
            text: `${entry.percent}%`
            Layout.alignment: root.vertical ? Qt.AlignHCenter : Qt.AlignVCenter
        }
    }

    // Horizontal layout
    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        visible: !root.vertical
        spacing: 6

        Repeater {
            model: AiQuota.providers
            delegate: AiQuotaEntry {}
        }
    }

    // Vertical layout
    ColumnLayout {
        id: contentColumn
        anchors.centerIn: parent
        width: parent.width
        visible: root.vertical
        spacing: 4

        Repeater {
            model: AiQuota.providers
            delegate: AiQuotaEntry {}
        }
    }

    StyledPopup {
        hoverTarget: root
        active: root.hovered && AiQuota.providers.length > 0

        Item {
            implicitWidth: 420
            implicitHeight: detailsText.implicitHeight

            StyledText {
                id: detailsText
                width: parent.width
                text: root.tooltipText
                wrapMode: Text.Wrap
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colOnLayer1
            }
        }
    }

    // Tooltip text, rebuilt on hover and refreshed periodically for live countdowns.
    property string tooltipText: ""

    onHoveredChanged: {
        if (root.hovered) {
            root.tooltipText = root.buildTooltipText()
            tooltipRefreshTimer.restart()
        } else {
            tooltipRefreshTimer.stop()
        }
    }

    Timer {
        id: tooltipRefreshTimer
        interval: 30000
        repeat: true
        onTriggered: root.tooltipText = root.buildTooltipText()
    }

    function buildTooltipText() {
        const providers = AiQuota.providers
        if (providers.length === 0) return ""
        const lines = []
        for (const p of providers) {
            lines.push(p.displayName)
            if (p.hasError) {
                lines.push("  " + (p.errorMessage.length > 0 ? p.errorMessage : "Unavailable"))
            } else {
                appendWindowLine(lines, "Session", p.primary)
                appendWindowLine(lines, "Weekly", p.secondary)
                appendWindowLine(lines, "Monthly", p.tertiary)
                if (p.paceSummary && p.paceSummary.length > 0)
                    lines.push("  Pace: " + p.paceSummary)
                if (p.creditsRemaining > 0)
                    lines.push("  Credits: " + p.creditsRemaining + " remaining")
            }
        }
        return lines.join("\n")
    }

    function appendWindowLine(lines, label, win) {
        if (!win) return
        const pct = Math.round(win.usedPercent) + "%"
        const resets = formatCountdown(win.resetsAt)
        lines.push("  " + label + ": " + pct + (resets.length > 0 ? " (resets " + resets + ")" : ""))
    }

    // "resets in 2h 4m" for future dates, or "Aug 20" fallback / when already past.
    function formatCountdown(resetsAt) {
        if (!resetsAt || resetsAt.length === 0) return ""
        const target = Date.parse(resetsAt)
        if (isNaN(target)) return ""
        const now = Date.now()
        const diffMs = target - now
        if (diffMs <= 0) return "soon"
        const totalMin = Math.floor(diffMs / 60000)
        const days = Math.floor(totalMin / 1440)
        const hours = Math.floor((totalMin % 1440) / 60)
        const mins = totalMin % 60
        if (days > 0) return `in ${days}d ${hours}h`
        if (hours > 0) return `in ${hours}h ${mins}m`
        return `in ${mins}m`
    }
}
