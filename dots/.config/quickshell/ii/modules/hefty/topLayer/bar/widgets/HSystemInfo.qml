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
        property var activeItem: vertical ? verticalContent : horizontalContent

        W.FadeLoader {
            id: horizontalContent
            anchors.fill: parent
            shown: !contentRoot.vertical

            sourceComponent: HorizontalSysInfo {}
        }

        W.FadeLoader {
            id: verticalContent
            anchors.fill: parent
            shown: contentRoot.vertical

            sourceComponent: HorizontalSysInfo {}
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

    component HorizontalSysInfo: Item {
        implicitWidth: row.implicitWidth + row.anchors.leftMargin + row.anchors.rightMargin
        implicitHeight: row.implicitHeight + row.anchors.topMargin + row.anchors.bottomMargin

        RowLayout {
            id: row
            anchors.fill: parent
            anchors.leftMargin: root.startSide ? 8 : 6
            anchors.rightMargin: root.endSide ? 0 : -3

            Battery {}
        }
    }

    component Battery: Row {
        spacing: 1.5
        Layout.fillHeight: true

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
                    spacing: 0

                    W.MaterialSymbol {
                        id: boltIcon
                        Layout.alignment: Qt.AlignVCenter
                        Layout.leftMargin: -2
                        Layout.rightMargin: -2
                        fill: 1 * (text == "bolt")
                        fillAnimation: null
                        text: {
                            if (root.chargingAndNotFull)
                                return "bolt";
                            if (root.powerSaving)
                                return "nest_eco_leaf";
                            return "circle";
                        }
                        iconSize: C.Appearance.font.pixelSize.small
                        font.weight: Font.DemiBold
                        visible: root.chargingAndNotFull || root.powerSaving
                    }
                    W.VisuallyCenteredStyledText {
                        Layout.fillHeight: true
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

    component SysInfoPopupContent: W.ChoreographerGridLayout {
        id: popupRoot
        rowSpacing: 8

        onShownChanged: {
            if (shown) {
                powerProfileSelection.focusSelectedChild()
            }
        }

        W.FlyFadeEnterChoreographable {
            Layout.fillWidth: true

            RowLayout {
                spacing: 10

                W.CircularProgress {
                    implicitSize: 46
                    lineWidth: 3
                    value: S.Battery.percentage
                    W.MaterialSymbol {
                        anchors.centerIn: parent
                        iconSize: 22
                        text: {
                            if (root.chargingAndNotFull)
                                return "battery_android_plus";
                            if (root.powerSaving)
                                return "energy_savings_leaf";
                            return "battery_android_full";
                        }
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    RowLayout {
                        Layout.fillWidth: true
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
                    RowLayout {
                        Layout.fillWidth: true
                        StatWithIcon {
                            visible: S.Battery.knownEnergyRate
                            Layout.fillWidth: true
                            icon: "bolt"
                            value: `${S.Battery.energyRate.toFixed(2)}W`
                        }
                        StatWithIcon {
                            Layout.fillWidth: true
                            icon: "heart_check"
                            value: `${(S.Battery.health).toFixed(1)}%`
                        }
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
                    PowerProfiles.profile = newValue
                }
                options: [
                    {
                        displayName: S.Translation.tr("Power saver"),
                        // icon: "line_curve",
                        value: PowerProfile.PowerSaver
                    },
                    {
                        displayName: S.Translation.tr("Balanced"),
                        // icon: "page_header",
                        value: PowerProfile.Balanced
                    },
                    {
                        displayName: S.Translation.tr("Performance"),
                        // icon: "toolbar",
                        value: PowerProfile.Performance
                    }
                ]
            }
        }
    }

    component StatWithIcon: Item {
        id: statItem
        required property string icon
        required property string value
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
            }
            W.VisuallyCenteredStyledText {
                Layout.fillWidth: false
                Layout.fillHeight: true
                text: statItem.value
            }
            Item {
                Layout.fillWidth: true
            }
        }
    }
}
