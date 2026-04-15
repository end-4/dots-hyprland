import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

MouseArea {
    id: root
    property bool borderless: Config.options.bar.borderless
    property bool alwaysShowAllResources: false
    implicitWidth: rowLayout.implicitWidth + rowLayout.anchors.leftMargin + rowLayout.anchors.rightMargin
    implicitHeight: Appearance.sizes.barHeight
    hoverEnabled: !Config.options.bar.tooltips.clickToShow

    RowLayout {
        id: rowLayout

        spacing: 0
        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: 4

        Item {
            visible: NetworkTraffic.available
            implicitWidth: speedMeasure.implicitWidth
            implicitHeight: Appearance.sizes.barHeight
            Layout.rightMargin: visible ? 16 : 0
            clip: true

            TextMetrics {
                id: speedTextMetrics
                text: "8888G/s"
                font.pixelSize: Appearance.font.pixelSize.small
                font.family: Appearance.font.family.main
                font.variableAxes: Appearance.font.variableAxes.main
            }

            RowLayout {
                id: speedMeasure
                visible: false

                MaterialSymbol {
                    text: "south"
                    iconSize: Appearance.font.pixelSize.normal
                }

                Item {
                    implicitWidth: speedTextMetrics.width
                    implicitHeight: 1
                }

                Item {
                    implicitWidth: 2
                    implicitHeight: 1
                }

                MaterialSymbol {
                    text: "north"
                    iconSize: Appearance.font.pixelSize.normal
                }

                Item {
                    implicitWidth: speedTextMetrics.width
                    implicitHeight: 1
                }
            }

            RowLayout {
                id: speedRow
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                MaterialSymbol {
                    text: "south"
                    iconSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnLayer1
                }

                StyledText {
                    width: speedTextMetrics.width
                    text: NetworkTraffic.downloadSpeedCompactText
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnLayer1
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideLeft
                }

                MaterialSymbol {
                    text: "north"
                    iconSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnLayer1
                    Layout.leftMargin: 2
                }

                StyledText {
                    width: speedTextMetrics.width
                    text: NetworkTraffic.uploadSpeedCompactText
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnLayer1
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideLeft
                }
            }
        }

        Resource {
            iconName: "memory"
            percentage: ResourceUsage.memoryUsedPercentage
            warningThreshold: Config.options.bar.resources.memoryWarningThreshold
        }

        Resource {
            iconName: "swap_horiz"
            percentage: ResourceUsage.swapUsedPercentage
            shown: (Config.options.bar.resources.alwaysShowSwap && percentage > 0) || 
                (MprisController.activePlayer?.trackTitle == null) ||
                root.alwaysShowAllResources
            Layout.leftMargin: shown ? 6 : 0
            warningThreshold: Config.options.bar.resources.swapWarningThreshold
        }

        Resource {
            iconName: "planner_review"
            percentage: ResourceUsage.cpuUsage
            shown: Config.options.bar.resources.alwaysShowCpu || 
                !(MprisController.activePlayer?.trackTitle?.length > 0) ||
                root.alwaysShowAllResources
            Layout.leftMargin: shown ? 6 : 0
            warningThreshold: Config.options.bar.resources.cpuWarningThreshold
        }

    }

    ResourcesPopup {
        hoverTarget: root
    }
}
