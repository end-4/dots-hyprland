pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Services.UPower

import qs.services as S
import qs.modules.common as C
import qs.modules.common.functions as F
import qs.modules.common.widgets as W
import ".."

HBarWidgetWithPopout {
    id: root

    property bool chargingAndNotFull: S.Battery.isCharging && S.Battery.percentage < 1
    property bool powerSaving: PowerProfiles.profile == PowerProfile.PowerSaver

    popupContentWidth: popupContent.implicitWidth
    popupContentHeight: popupContent.implicitHeight

    HBarWidgetContent {
        id: contentRoot
        vertical: root.vertical
        atBottom: root.atBottom
        showPopup: root.showPopup
        contentImplicitWidth: activeItem.implicitWidth
        contentImplicitHeight: activeItem.implicitHeight
        onClicked: root.showPopup = !root.showPopup
        property var activeItem: sysInfoContent

        SysInfoContent {
            id: sysInfoContent
            anchors.fill: parent
        }

        SysInfoPopupContent {
            id: popupContent
            anchors {
                top: root.vertical ? contentRoot.activeItem.top : contentRoot.activeItem.top
                topMargin: root.popupContentOffsetY
                left: root.vertical ? contentRoot.activeItem.left : contentRoot.activeItem.left
                leftMargin: root.popupContentOffsetX
            }

            shown: root.showPopup
        }
    }

    component SysInfoContent: Item {
        implicitWidth: contentGrid.implicitWidth + contentGrid.anchors.leftMargin + contentGrid.anchors.rightMargin
        implicitHeight: contentGrid.implicitHeight + contentGrid.anchors.topMargin + contentGrid.anchors.bottomMargin

        W.BoxLayout {
            id: contentGrid
            vertical: root.vertical
            property int visibleChildren: children.filter(child => child.shown).length
            property bool hasResourceIndicators: visibleChildren > 1 || (visibleChildren > 0 && !S.Battery.available)
            anchors {
                fill: parent
                leftMargin: !root.vertical ? (hasResourceIndicators ? 1 : 4) : 0
                topMargin: root.vertical ? 2 : 0
                rightMargin: !root.vertical ? (root.endSide ? 1 : (battLoader.visible ? 0 : -3)) : 0
                bottomMargin: root.vertical ? (root.endSide ? 4 : 2) : 0
            }
            spacing: 4

            AlignedFadeLoader {
                shown: C.Config.options.hefty.bar.resources.showMemory || (
                    !battLoader.visible
                    && !C.Config.options.hefty.bar.resources.showRam
                    && !C.Config.options.hefty.bar.resources.showSwap
                    && !C.Config.options.hefty.bar.resources.showCpu
                )
                sourceComponent: Memory {}
            }

            AlignedFadeLoader {
                shown: C.Config.options.hefty.bar.resources.showRam
                sourceComponent: RamOnly {}
            }

            AlignedFadeLoader {
                shown: C.Config.options.hefty.bar.resources.showSwap
                sourceComponent: SwapOnly {}
            }

            AlignedFadeLoader {
                shown: C.Config.options.hefty.bar.resources.showCpu
                sourceComponent: Cpu {}
            }

            AlignedFadeLoader {
                id: battLoader
                shown: S.Battery.available
                Layout.fillWidth: root.vertical
                Layout.fillHeight: !root.vertical
                sourceComponent: Battery {}
            }
        }
    }

    component AlignedFadeLoader: W.FadeLoader {
        Layout.alignment: root.vertical ? Qt.AlignHCenter : Qt.AlignVCenter
    }

    component Memory: SysResourceProgress {
        valueWeights: [S.ResourceUsage.memoryTotal, S.ResourceUsage.swapTotal]
        values: [S.ResourceUsage.memoryUsedPercentage, S.ResourceUsage.swapUsedPercentage]
        centerChar: S.Translation.tr("Memory")[0]
    }

    component RamOnly: SysResourceProgress {
        values: [S.ResourceUsage.memoryUsedPercentage]
        centerChar: S.Translation.tr("RAM")[0]
    }

    component SwapOnly: SysResourceProgress {
        values: [S.ResourceUsage.swapUsedPercentage]
        centerChar: S.Translation.tr("Swap")[0]
    }

    component Cpu: SysResourceProgress {
        values: [S.ResourceUsage.cpuUsage]
        centerChar: S.Translation.tr("CPU")[0]
    }

    component SysResourceProgress: W.CombinedCircularProgress {
        id: sysResProg
        implicitSize: 22
        valueHighlights: [C.Appearance.colors.colPrimary]
        valueTroughs: [C.Appearance.colors.colSecondaryContainer]
        property string centerChar: ""

        W.StyledText {
            renderType: Text.QtRendering
            anchors.centerIn: parent
            text: sysResProg.centerChar
            font.pixelSize: 9
        }
    }

    component Battery: Item {
        implicitWidth: !root.vertical ? battShape.implicitWidth : battShape.implicitHeight
        implicitHeight: !root.vertical ? battShape.implicitHeight : battShape.implicitWidth

        BatteryShape {
            id: battShape
            anchors.centerIn: parent
        }
    }

    component BatteryShape: Row {
        Layout.fillHeight: true
        spacing: 1.5
        rotation: -90 * root.vertical

        W.ClippedProgressBar {
            id: batteryProgress
            anchors.verticalCenter: parent.verticalCenter
            valueBarWidth: 28
            valueBarHeight: 16
            radius: 4
            progressRadius: 0
            value: S.Battery.percentage
            highlightColor: (S.Battery.isLow && !S.Battery.isCharging) ? C.Appearance.m3colors.m3error : C.Appearance.colors.colOnSecondaryContainer
            font.pixelSize: boltIcon.visible ? 13 : 14

            Item {
                layer.enabled: true
                width: batteryProgress.valueBarWidth
                height: batteryProgress.valueBarHeight

                RowLayout {
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        bottom: parent.bottom
                        bottomMargin: (parent.height - height) / 2
                    }
                    rotation: 180 * root.vertical
                    spacing: 4

                    W.MaterialSymbol {
                        id: boltIcon
                        Layout.alignment: Qt.AlignVCenter
                        Layout.leftMargin: -2
                        Layout.rightMargin: -2
                        rotation: -90 * root.vertical
                        fill: 1 * (text == "bolt")
                        fillAnimation: null
                        text: {
                            if (batteryProgress.value == 1)
                                return "check";
                            if (root.chargingAndNotFull)
                                return "bolt";
                            if (root.powerSaving)
                                return "nest_eco_leaf";
                            return "";
                        }
                        iconSize: C.Appearance.font.pixelSize.small
                        font.weight: Font.DemiBold
                        visible: text != ""
                    }
                    W.VisuallyCenteredStyledText {
                        visible: batteryProgress.value < 1
                        Layout.fillHeight: true
                        rotation: -90 * root.vertical
                        font: batteryProgress.font
                        text: batteryProgress.text
                    }
                }
            }
        }
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            color: batteryProgress.trackColor
            topRightRadius: width
            bottomRightRadius: width
            implicitWidth: 2.5
            implicitHeight: 8
        }
    }

    component SysInfoPopupContent: W.ChoreographerLoader {
        id: sysInfoPopupContent

        sourceComponent: W.ChoreographerGridLayout {
            id: popupRoot
            rowSpacing: 10
            property bool showSettings: false

            onShownChanged: {
                if (shown) {
                    powerProfileSelection.focusSelectedChild();
                }
            }

            W.FlyFadeEnterChoreographable {
                z: 1
                Layout.fillWidth: true
                Item {
                    anchors {
                        left: parent.left
                        right: parent.right
                    }
                    implicitHeight: popupHeaderLayout.implicitHeight
                    ColumnLayout {
                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                        }
                        spacing: 10

                        RowLayout {
                            id: popupHeaderLayout
                            Layout.fillWidth: true
                            W.StyledText {
                                Layout.fillWidth: true
                                text: S.Translation.tr("Resources")
                                elide: Text.ElideRight
                                font.pixelSize: C.Appearance.font.pixelSize.title
                            }

                            W.StyledIconButton {
                                implicitSize: C.Appearance.rounding.normal * 2
                                text: "settings"
                                iconSize: 20
                                onClicked: popupRoot.showSettings = !popupRoot.showSettings;
                                checked: popupRoot.showSettings
                            }
                        }

                        W.FadeLoader {
                            shown: popupRoot.showSettings
                            Layout.fillWidth: true
                            sourceComponent: SysInfoPopupConfig {}
                        }
                    }
                }
            }

            W.FlyFadeEnterChoreographable {
                Layout.fillWidth: true

                Column {
                    anchors {
                        left: parent.left
                        right: parent.right
                    }

                    spacing: 2

                    Item {
                        anchors {
                            left: parent.left
                            right: parent.right
                        }
                        implicitHeight: memUsed.implicitHeight

                        BigSmallTextPair {
                            id: memUsed
                            materialSymbol: "memory"
                            bigText: S.ResourceUsage.kbToGbString(S.ResourceUsage.memoryUsed, false)
                            smallText: {
                                const total = S.ResourceUsage.kbToGbString(S.ResourceUsage.memoryTotal, false);
                                return S.Translation.tr("%1").arg(`/ ${total}`)
                            }
                            W.StyledText {
                                Layout.alignment: Qt.AlignBaseline
                                text: S.Translation.tr("Memory")
                                color: C.Appearance.colors.colOutline
                            }
                        }
                        BigSmallTextPair {
                            id: swapUsed
                            TextMetrics {
                                id: plusTextMetric
                                font: swapUsed.bigFont
                                text: "+"
                            }
                            property real halfWidthOfAPlus: plusTextMetric.width / 2
                            x: Math.min(memProg.availableWidth * memProg.visualEnds[0] - halfWidthOfAPlus, parent.width - width)
                            bigText: "+ " + S.ResourceUsage.kbToGbString(S.ResourceUsage.swapUsed, false)
                            smallText: {
                                const total = S.ResourceUsage.kbToGbString(S.ResourceUsage.swapTotal, false);
                                return `/ ${total} GB`
                            }
                        }
                        
                    }
                    W.StyledCombinedProgressBar {
                        id: memProg
                        anchors {
                            left: parent.left
                            right: parent.right
                        }
                        valueWeights: [S.ResourceUsage.memoryTotal, S.ResourceUsage.swapTotal]
                        values: [S.ResourceUsage.memoryUsedPercentage, S.ResourceUsage.swapUsedPercentage]
                    }
                }
            }

            W.FlyFadeEnterChoreographable {
                Layout.fillWidth: true

                Column {
                    anchors {
                        left: parent.left
                        right: parent.right
                    }

                    spacing: 2

                    BigSmallTextPair {
                        spacing: 0
                        materialSymbol: "developer_board"
                        bigText: Math.round(S.ResourceUsage.cpuUsage * 100)
                        smallText: "%"
                        W.StyledText {
                            Layout.alignment: Qt.AlignBaseline
                            text: " " + S.Translation.tr("CPU")
                            color: C.Appearance.colors.colOutline
                        }
                    }
                    W.StyledCombinedProgressBar {
                        anchors {
                            left: parent.left
                            right: parent.right
                        }
                        property bool useSingleAggregate: S.ResourceUsage.cpuCoreUsages.length > 8
                        valueWeights: useSingleAggregate ? [1] : S.ResourceUsage.cpuCoreFreqCaps
                        values: useSingleAggregate ? [S.ResourceUsage.cpuUsage] : S.ResourceUsage.cpuCoreUsages
                    }
                }
            }

            W.FlyFadeEnterChoreographable {
                Layout.topMargin: 8
                Layout.fillWidth: true

                RowLayout {
                    spacing: 10
                    width: parent.width

                    W.CircularProgress {
                        id: battCircProg
                        implicitSize: 44
                        lineWidth: 3
                        value: S.Battery.percentage
                        W.MaterialSymbol {
                            anchors.centerIn: parent
                            iconSize: 22
                            fill: 1
                            animateChange: true
                            text: {
                                if (battCircProg.value == 1)
                                    return "check";
                                if (root.chargingAndNotFull)
                                    return "bolt";
                                if (root.powerSaving)
                                    return "energy_savings_leaf";
                                if (PowerProfiles.profile == PowerProfile.Performance)
                                    return "local_fire_department";
                                return C.Icons.getBatteryIcon(battCircProg.value * 100);
                            }
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: false
                        spacing: 4
                        W.StyledText {
                            Layout.alignment: Qt.AlignBaseline
                            visible: S.Battery.knownEnergyRate
                            text: F.DateUtils.formatDuration(S.Battery.isCharging ? S.Battery.timeToFull : S.Battery.timeToEmpty)
                            font.pixelSize: C.Appearance.font.pixelSize.title
                        }
                        W.StyledText {
                            Layout.alignment: Qt.AlignBaseline
                            text: {
                                if (!S.Battery.knownEnergyRate)
                                    return S.Battery.isCharging ? S.Translation.tr("Charging") : S.Translation.tr("Discharging");
                                return S.Battery.isCharging ? S.Translation.tr("to full") : S.Translation.tr("remaining");
                            }
                        }
                    }
                    Item {
                        Layout.fillWidth: true
                    }
                    ColumnLayout {
                        id: notSoImportantBatteryStats
                        Layout.fillWidth: false
                        spacing: 4
                        StatWithIcon {
                            visible: S.Battery.knownEnergyRate
                            Layout.alignment: Qt.AlignLeft
                            icon: "bolt"
                            value: `${S.Battery.energyRate.toFixed(1)}W`
                            longestValueString: "69.0W"
                        }
                        StatWithIcon {
                            Layout.alignment: Qt.AlignLeft
                            icon: "favorite"
                            value: `${(S.Battery.health).toFixed(1 * (S.Battery.health < 100))}%`
                            longestValueString: "69.0%"
                        }
                    }
                }
            }

            W.FlyFadeEnterChoreographable {
                Layout.fillWidth: true
                W.ConfigSelectionArray {
                    id: powerProfileSelection
                    currentValue: PowerProfiles.profile
                    onSelected: newValue => {
                        PowerProfiles.profile = newValue;
                    }
                    options: [
                        {
                            displayName: S.Translation.tr("Power saver"),
                            value: PowerProfile.PowerSaver
                        },
                        {
                            displayName: S.Translation.tr("Balanced"),
                            value: PowerProfile.Balanced
                        },
                        {
                            displayName: S.Translation.tr("Performance"),
                            value: PowerProfile.Performance
                        }
                    ]
                }
            }
        }
    }

    component SysInfoPopupConfig: Rectangle {
        implicitWidth: sysConfLayout.implicitWidth
        implicitHeight: sysConfLayout.implicitHeight
        radius: C.Appearance.rounding.normal
        color: C.Appearance.colors.colLayer4Base

        W.StyledRectangularShadow {
            target: parent
            z: -1
        }

        ColumnLayout {
            id: sysConfLayout
            anchors.fill: parent
            W.ConfigSwitch {
                buttonIcon: "pie_chart"
                text: S.Translation.tr("Show memory usage")
                checked: C.Config.options.hefty.bar.resources.showMemory
                onCheckedChanged: {
                    C.Config.options.hefty.bar.resources.showMemory = checked;
                }
            }
            W.ConfigSwitch {
                buttonIcon: "memory"
                text: S.Translation.tr("Show physical memory usage")
                checked: C.Config.options.hefty.bar.resources.showRam
                onCheckedChanged: {
                    C.Config.options.hefty.bar.resources.showRam = checked;
                }
            }
            W.ConfigSwitch {
                buttonIcon: "swap_horiz"
                text: S.Translation.tr("Show swap")
                checked: C.Config.options.hefty.bar.resources.showSwap
                onCheckedChanged: {
                    C.Config.options.hefty.bar.resources.showSwap = checked;
                }
            }
            W.ConfigSwitch {
                buttonIcon: "planner_review"
                text: S.Translation.tr("Show CPU usage")
                checked: C.Config.options.hefty.bar.resources.showCpu
                onCheckedChanged: {
                    C.Config.options.hefty.bar.resources.showCpu = checked;
                }
            }
        }
    }

    component BigSmallTextPair: RowLayout {
        id: txtPair
        property string materialSymbol: ""
        property string bigText: ""
        property string smallText: ""
        property alias bigFont: bigTxt.font
        property alias smallFont: smallTxt.font
        spacing: 6

        W.MaterialSymbol {
            Layout.rightMargin: 6 - spacing
            visible: text.length > 0
            Layout.alignment: Qt.AlignVCenter
            text: txtPair.materialSymbol
            fill: 1
            iconSize: 24
        }
        W.StyledText {
            id: bigTxt
            Layout.alignment: Qt.AlignBaseline
            font.pixelSize: C.Appearance.font.pixelSize.title
            text: txtPair.bigText
        }
        W.StyledText {
            id: smallTxt
            Layout.alignment: Qt.AlignBaseline
            text: txtPair.smallText
        }
    }

    component StatWithIcon: Item {
        id: statItem
        required property string icon
        required property string value
        property string longestValueString
        implicitWidth: statRow.implicitWidth
        implicitHeight: statRow.implicitHeight
        RowLayout {
            id: statRow
            anchors.fill: parent
            spacing: 4
            W.MaterialSymbol {
                Layout.fillWidth: false
                Layout.alignment: Qt.AlignVCenter
                text: statItem.icon
                fill: 1
                iconSize: 16
            }
            W.FixedWidthTextContainer {
                longestText: statItem.longestValueString
                W.VisuallyCenteredStyledText {
                    anchors.fill: parent
                    horizontalAlignment: Text.AlignLeft
                    text: statItem.value
                }
            }
            Item {
                Layout.fillWidth: true
            }
        }
    }
}
