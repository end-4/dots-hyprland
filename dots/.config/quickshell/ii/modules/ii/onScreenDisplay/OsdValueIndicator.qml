import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

Item {
    id: root
    required property real value
    required property string icon
    required property string name
    property bool rotateIcon: false
    property bool scaleIcon: false
    property alias from: valueProgressBar.from
    property alias to: valueProgressBar.to

    property real valueIndicatorVerticalPadding: 9
    property real valueIndicatorLeftPadding: 10
    property real valueIndicatorRightPadding: 20

    implicitWidth: Appearance.sizes.osdWidth + 2 * Appearance.sizes.elevationMargin
    implicitHeight: valueIndicator.implicitHeight + 2 * Appearance.sizes.elevationMargin

    StyledRectangularShadow {
        target: valueIndicator
    }
    Rectangle {
        id: valueIndicator
        anchors {
            fill: parent
            margins: Appearance.sizes.elevationMargin
        }
        radius: Appearance.rounding.full
        color: Appearance.colors.colLayer0

        implicitWidth: valueRow.implicitWidth
        implicitHeight: valueRow.implicitHeight

        RowLayout {
            id: valueRow
            Layout.margins: 10
            anchors.fill: parent
            spacing: 10

            Item {
                implicitWidth: 30
                implicitHeight: 30
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: valueIndicatorLeftPadding
                Layout.topMargin: valueIndicatorVerticalPadding
                Layout.bottomMargin: valueIndicatorVerticalPadding

                MaterialSymbol {
                    anchors {
                        centerIn: parent
                        alignWhenCentered: !root.rotateIcon
                    }
                    color: Appearance.colors.colOnLayer0
                    renderType: Text.QtRendering

                    text: root.icon
                    iconSize: 20 + 10 * (root.scaleIcon ? value : 1)
                    rotation: 180 * (root.rotateIcon ? value : 0)

                    // snappy m3 spring curves for tactile feedback
                    Behavior on iconSize {
                        NumberAnimation { duration: 320; easing.type: Easing.OutBack; easing.overshoot: 1.15 }
                    }
                    Behavior on rotation {
                        NumberAnimation { duration: 380; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
                    }
                }
            }
            ColumnLayout {
                Layout.alignment: Qt.AlignVCenter
                Layout.rightMargin: valueIndicatorRightPadding
                spacing: 5

                RowLayout {
                    Layout.leftMargin: valueProgressBar.height / 2
                    Layout.rightMargin: valueProgressBar.height / 2

                    StyledText {
                        color: Appearance.colors.colOnLayer0
                        font.pixelSize: Appearance.font.pixelSize.small
                        Layout.fillWidth: true
                        text: root.name
                    }

                    StyledText {
                        color: Appearance.colors.colOnLayer0
                        font.pixelSize: Appearance.font.pixelSize.small
                        Layout.fillWidth: false
                        text: Math.round(root.value * 100)
                    }
                }

                StyledProgressBar {
                    id: valueProgressBar
                    Layout.fillWidth: true
                    value: root.value
                }
            }
        }
    }
}
