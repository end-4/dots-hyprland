import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: barConfigPage
    forceWidth: true
    readonly property int monitorCount: Quickshell.screens.length
    readonly property bool hasMultipleMonitors: monitorCount > 1

    function getMonitorSplits() {
        const needed = Math.max(0, monitorCount - 1);
        if (needed === 0) return [];
        let arr = Array.from(Config.options.bar.workspaces.monitorSplits ?? []);
        if (arr.length !== needed) {
            arr = [];
            for (let i = 0; i < needed; i++) {
                arr.push(Math.round(10 * (i + 1) / monitorCount));
            }
        }
        return arr;
    }

    function updateSplit(idx, val) {
        const needed = Math.max(0, monitorCount - 1);
        if (idx < 0 || idx >= needed) return;
        const arr = getMonitorSplits().slice();
        const minV = idx + 1;
        const maxV = 10 - (needed - idx);
        arr[idx] = Math.max(minV, Math.min(maxV, Math.round(val)));
        for (let j = idx - 1; j >= 0; j--) {
            if (arr[j] >= arr[j + 1]) arr[j] = arr[j + 1] - 1;
        }
        for (let j = idx + 1; j < needed; j++) {
            if (arr[j] <= arr[j - 1]) arr[j] = arr[j - 1] + 1;
        }
        Config.options.bar.workspaces.monitorSplits = arr;
        Config.options.bar.workspaces.leftMonitorCount = arr[0];
        wsSplitApplyTimer.restart();
    }

    Timer {
        id: wsSplitApplyTimer
        interval: 120
        repeat: false
        onTriggered: {
            wsSplitProc.running = false;
            wsSplitProc.running = true;
        }
    }

    Process {
        id: wsSplitProc
        command: [
            "python3",
            Quickshell.shellPath("scripts/apply-workspace-split.py"),
            (barConfigPage.hasMultipleMonitors && Config.options.bar.workspaces.splitByMonitor)
                ? barConfigPage.getMonitorSplits().join(",")
                : "0"
        ]
    }

    ContentSection {
        icon: "notifications"
        title: Translation.tr("Notifications")
        ConfigSwitch {
            buttonIcon: "counter_2"
            text: Translation.tr("Unread indicator: show count")
            checked: Config.options.bar.indicators.notifications.showUnreadCount
            onCheckedChanged: {
                Config.options.bar.indicators.notifications.showUnreadCount = checked;
            }
        }
    }
    
    ContentSection {
        icon: "spoke"
        title: Translation.tr("Positioning")

        ConfigRow {
            ContentSubsection {
                title: Translation.tr("Bar position")
                Layout.fillWidth: true

                ConfigSelectionArray {
                    currentValue: (Config.options.bar.bottom ? 1 : 0) | (Config.options.bar.vertical ? 2 : 0)
                    onSelected: newValue => {
                        Config.options.bar.bottom = (newValue & 1) !== 0;
                        Config.options.bar.vertical = (newValue & 2) !== 0;
                    }
                    options: [
                        {
                            displayName: Translation.tr("Top"),
                            icon: "arrow_upward",
                            value: 0 // bottom: false, vertical: false
                        },
                        {
                            displayName: Translation.tr("Left"),
                            icon: "arrow_back",
                            value: 2 // bottom: false, vertical: true
                        },
                        {
                            displayName: Translation.tr("Bottom"),
                            icon: "arrow_downward",
                            value: 1 // bottom: true, vertical: false
                        },
                        {
                            displayName: Translation.tr("Right"),
                            icon: "arrow_forward",
                            value: 3 // bottom: true, vertical: true
                        }
                    ]
                }
            }
            ContentSubsection {
                title: Translation.tr("Automatically hide")
                Layout.fillWidth: false

                ConfigSelectionArray {
                    currentValue: Config.options.bar.autoHide.enable
                    onSelected: newValue => {
                        Config.options.bar.autoHide.enable = newValue; // Update local copy
                    }
                    options: [
                        {
                            displayName: Translation.tr("No"),
                            icon: "close",
                            value: false
                        },
                        {
                            displayName: Translation.tr("Yes"),
                            icon: "check",
                            value: true
                        }
                    ]
                }
            }
        }

        ConfigRow {
            
            ContentSubsection {
                title: Translation.tr("Corner style")
                Layout.fillWidth: true

                ConfigSelectionArray {
                    currentValue: Config.options.bar.cornerStyle
                    onSelected: newValue => {
                        Config.options.bar.cornerStyle = newValue; // Update local copy
                    }
                    options: [
                        {
                            displayName: Translation.tr("Hug"),
                            icon: "line_curve",
                            value: 0
                        },
                        {
                            displayName: Translation.tr("Float"),
                            icon: "page_header",
                            value: 1
                        },
                        {
                            displayName: Translation.tr("Rect"),
                            icon: "toolbar",
                            value: 2
                        }
                    ]
                }
            }

            ContentSubsection {
                title: Translation.tr("Group style")
                Layout.fillWidth: false

                ConfigSelectionArray {
                    currentValue: Config.options.bar.borderless
                    onSelected: newValue => {
                        Config.options.bar.borderless = newValue; // Update local copy
                    }
                    options: [
                        {
                            displayName: Translation.tr("Pills"),
                            icon: "location_chip",
                            value: false
                        },
                        {
                            displayName: Translation.tr("Line-separated"),
                            icon: "split_scene",
                            value: true
                        }
                    ]
                }
            }
        }
    }

    ContentSection {
        icon: "shelf_auto_hide"
        title: Translation.tr("Tray")

        ConfigSwitch {
            buttonIcon: "keep"
            text: Translation.tr('Make icons pinned by default')
            checked: Config.options.tray.invertPinnedItems
            onCheckedChanged: {
                Config.options.tray.invertPinnedItems = checked;
            }
        }
        
        ConfigSwitch {
            buttonIcon: "colors"
            text: Translation.tr('Tint icons')
            checked: Config.options.tray.monochromeIcons
            onCheckedChanged: {
                Config.options.tray.monochromeIcons = checked;
            }
        }
    }

    ContentSection {
        icon: "widgets"
        title: Translation.tr("Utility buttons")

        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "content_cut"
                text: Translation.tr("Screen snip")
                checked: Config.options.bar.utilButtons.showScreenSnip
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showScreenSnip = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "colorize"
                text: Translation.tr("Color picker")
                checked: Config.options.bar.utilButtons.showColorPicker
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showColorPicker = checked;
                }
            }
        }
        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "keyboard"
                text: Translation.tr("Keyboard toggle")
                checked: Config.options.bar.utilButtons.showKeyboardToggle
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showKeyboardToggle = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "mic"
                text: Translation.tr("Mic toggle")
                checked: Config.options.bar.utilButtons.showMicToggle
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showMicToggle = checked;
                }
            }
        }
        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "dark_mode"
                text: Translation.tr("Dark/Light toggle")
                checked: Config.options.bar.utilButtons.showDarkModeToggle
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showDarkModeToggle = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "speed"
                text: Translation.tr("Performance Profile toggle")
                checked: Config.options.bar.utilButtons.showPerformanceProfileToggle
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showPerformanceProfileToggle = checked;
                }
            }
        }
        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "videocam"
                text: Translation.tr("Record")
                checked: Config.options.bar.utilButtons.showScreenRecord
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showScreenRecord = checked;
                }
            }
        }
    }

    ContentSection {
        icon: "cloud"
        title: Translation.tr("Weather")
        ConfigSwitch {
            buttonIcon: "check"
            text: Translation.tr("Enable")
            checked: Config.options.bar.weather.enable
            onCheckedChanged: {
                Config.options.bar.weather.enable = checked;
            }
        }
    }

    ContentSection {
        icon: "workspaces"
        title: Translation.tr("Workspaces")

        ConfigSwitch {
            buttonIcon: "counter_1"
            text: Translation.tr('Always show numbers')
            checked: Config.options.bar.workspaces.alwaysShowNumbers
            onCheckedChanged: {
                Config.options.bar.workspaces.alwaysShowNumbers = checked;
            }
        }

        ConfigSwitch {
            buttonIcon: "award_star"
            text: Translation.tr('Show app icons')
            checked: Config.options.bar.workspaces.showAppIcons
            onCheckedChanged: {
                Config.options.bar.workspaces.showAppIcons = checked;
            }
        }

        ConfigSwitch {
            buttonIcon: "colors"
            text: Translation.tr('Tint app icons')
            checked: Config.options.bar.workspaces.monochromeIcons
            onCheckedChanged: {
                Config.options.bar.workspaces.monochromeIcons = checked;
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            ConfigSwitch {
                Layout.fillWidth: true
                buttonIcon: "splitscreen_left"
                text: Translation.tr("Split workspaces by monitor")
                enabled: barConfigPage.hasMultipleMonitors
                checked: barConfigPage.hasMultipleMonitors && Config.options.bar.workspaces.splitByMonitor
                onCheckedChanged: {
                    if (barConfigPage.hasMultipleMonitors && Config.options.bar.workspaces.splitByMonitor !== checked) {
                        Config.options.bar.workspaces.splitByMonitor = checked;
                        wsSplitApplyTimer.restart();
                    }
                }
            }
            RowLayout {
                visible: !barConfigPage.hasMultipleMonitors
                spacing: 4
                MaterialSymbol {
                    text: "error"
                    iconSize: 18
                    color: Appearance.colors.colError
                }
                StyledText {
                    text: Translation.tr("No 2nd monitor")
                    color: Appearance.colors.colError
                    font.pixelSize: Appearance.font.pixelSize.small
                }
            }
        }

        Repeater {
            model: (barConfigPage.hasMultipleMonitors && Config.options.bar.workspaces.splitByMonitor)
                ? Math.max(0, barConfigPage.monitorCount - 1) : 0
            delegate: ConfigSlider {
                required property int index
                readonly property var splits: barConfigPage.getMonitorSplits()
                readonly property int prevEnd: index === 0 ? 0 : splits[index - 1]
                readonly property int curEnd: splits[index] ?? 5
                readonly property int nextEnd: (index + 1 < splits.length) ? splits[index + 1] : 10
                text: Translation.tr("M%1 %2–%3 | M%4 %5–%6")
                    .arg(index + 1).arg(prevEnd + 1).arg(curEnd)
                    .arg(index + 2).arg(curEnd + 1).arg(nextEnd)
                value: curEnd
                usePercentTooltip: false
                buttonIcon: "tune"
                from: index + 1
                to: 10 - (barConfigPage.monitorCount - 1 - index)
                stopIndicatorValues: [Math.round(10 * (index + 1) / barConfigPage.monitorCount)]
                onValueChanged: {
                    const v = Math.round(value);
                    if (v !== curEnd) {
                        barConfigPage.updateSplit(index, v);
                    }
                }
            }
        }

        ContentSubsection {
            visible: barConfigPage.hasMultipleMonitors
            title: Translation.tr("Default monitor on startup")
            ConfigSelectionArray {
                currentValue: Config.options.bar.workspaces.defaultMonitor ?? ""
                onSelected: newValue => Config.options.bar.workspaces.defaultMonitor = newValue
                options: [({ displayName: Translation.tr("Auto (Largest)"), icon: "auto_awesome", value: "" })].concat(
                    Quickshell.screens.map((s, idx) => ({
                        displayName: "%1 · %2".arg(idx + 1).arg(s.name),
                        icon: "desktop_windows",
                        value: s.name
                    }))
                )
            }
        }

        ConfigSpinBox {
            icon: "view_column"
            text: Translation.tr("Workspaces shown")
            value: Config.options.bar.workspaces.shown
            from: 1
            to: 30
            stepSize: 1
            onValueChanged: {
                Config.options.bar.workspaces.shown = value;
            }
        }

        ConfigSpinBox {
            icon: "touch_long"
            text: Translation.tr("Number show delay when pressing Super (ms)")
            value: Config.options.bar.workspaces.showNumberDelay
            from: 0
            to: 1000
            stepSize: 50
            onValueChanged: {
                Config.options.bar.workspaces.showNumberDelay = value;
            }
        }

        ContentSubsection {
            title: Translation.tr("Number style")

            ConfigSelectionArray {
                currentValue: JSON.stringify(Config.options.bar.workspaces.numberMap)
                onSelected: newValue => {
                    Config.options.bar.workspaces.numberMap = JSON.parse(newValue)
                }
                options: [
                    {
                        displayName: Translation.tr("Normal"),
                        icon: "timer_10",
                        value: '[]'
                    },
                    {
                        displayName: Translation.tr("Han chars"),
                        icon: "square_dot",
                        value: '["一","二","三","四","五","六","七","八","九","十","十一","十二","十三","十四","十五","十六","十七","十八","十九","二十"]'
                    },
                    {
                        displayName: Translation.tr("Roman"),
                        icon: "account_balance",
                        value: '["I","II","III","IV","V","VI","VII","VIII","IX","X","XI","XII","XIII","XIV","XV","XVI","XVII","XVIII","XIX","XX"]'
                    }
                ]
            }
        }
    }

    ContentSection {
        icon: "tooltip"
        title: Translation.tr("Tooltips")
        ConfigSwitch {
            buttonIcon: "ads_click"
            text: Translation.tr("Click to show")
            checked: Config.options.bar.tooltips.clickToShow
            onCheckedChanged: {
                Config.options.bar.tooltips.clickToShow = checked;
            }
        }
    }
}
