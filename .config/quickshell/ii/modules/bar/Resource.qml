import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    id: root
    required property string iconName
    required property double percentage
    property var tooltipData: [
        {
            icon: "info",
            label: "System resource",
            value: ""
        }
    ]
    property var tooltipHeaderIcon
    property var tooltipHeaderText
    property bool shown: true
    clip: true
    visible: width > 0 && height > 0
    implicitWidth: resourceRowLayout.x < 0 ? 0 : resourceRowLayout.implicitWidth
    implicitHeight: Appearance.sizes.barHeight

    // Helper function to format KB to GB
    function formatKB(kb) {
        return (kb / (1024 * 1024)).toFixed(1) + " GB";
    }

    RowLayout {
        id: resourceRowLayout
        spacing: 2
        x: shown ? 0 : -resourceRowLayout.width
        anchors {
            verticalCenter: parent.verticalCenter
        }

        ClippedFilledCircularProgress {
            id: resourceCircProg
            Layout.alignment: Qt.AlignVCenter
            lineWidth: Appearance.rounding.unsharpen
            value: percentage
            implicitSize: 20
            colPrimary: Appearance.colors.colOnSecondaryContainer
            enableAnimation: false

            Item {
                anchors.centerIn: parent
                width: resourceCircProg.implicitSize
                height: resourceCircProg.implicitSize
                
                MaterialSymbol {
                    anchors.centerIn: parent
                    font.weight: Font.DemiBold
                    fill: 1
                    text: iconName
                    iconSize: Appearance.font.pixelSize.normal
                    color: Appearance.m3colors.m3onSecondaryContainer
                }
            }
        }

        Item {
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: fullPercentageTextMetrics.width
            implicitHeight: percentageText.implicitHeight

            TextMetrics {
                id: fullPercentageTextMetrics
                text: "100"
                font.pixelSize: Appearance.font.pixelSize.small
            }

            StyledText {
                id: percentageText
                anchors.centerIn: parent
                color: Appearance.colors.colOnLayer1
                font.pixelSize: Appearance.font.pixelSize.small
                text: `${Math.round(percentage * 100).toString()}`
            }
        }

        Behavior on x {
            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        enabled: resourceRowLayout.x >= 0 && root.width > 0 && root.visible
    }

    StyledPopup {
        hoverTarget: mouseArea

        ColumnLayout {
            id: columnLayout
            anchors.centerIn: parent
            spacing: 4

            // Header
            RowLayout {
                id: header
                spacing: 5

                MaterialSymbol {
                    fill: 0
                    font.weight: Font.Medium
                    text: root.tooltipHeaderIcon
                    iconSize: Appearance.font.pixelSize.large
                    color: Appearance.colors.colOnSurfaceVariant
                }

                StyledText {
                    text: root.tooltipHeaderText
                    font {
                        weight: Font.Medium
                        pixelSize: Appearance.font.pixelSize.normal
                    }
                    color: Appearance.colors.colOnSurfaceVariant
                }
            }

            // Info rows
            Repeater {
                model: root.tooltipData
                delegate: RowLayout {
                    spacing: 5
                    Layout.fillWidth: true

                    MaterialSymbol {
                        text: modelData.icon
                        color: Appearance.colors.colOnSurfaceVariant
                        iconSize: Appearance.font.pixelSize.large
                    }
                    StyledText {
                        text: modelData.label
                        color: Appearance.colors.colOnSurfaceVariant
                    }
                    StyledText {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignRight
                        visible: modelData.value !== ""
                        color: Appearance.colors.colOnSurfaceVariant
                        text: modelData.value
                    }
                }
            }
        }
    }

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Appearance.animation.elementMove.duration
            easing.type: Appearance.animation.elementMove.type
            easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
        }
    }
}
