import "root:/modules/common"
import "root:/modules/common/widgets"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

Rectangle {
    id: root
    readonly property var chargeState: UPower.displayDevice.state
    readonly property bool isCharging: chargeState == UPowerDeviceState.Charging
    readonly property bool isPluggedIn: isCharging || chargeState == UPowerDeviceState.PendingCharge
    readonly property real percentage: UPower.displayDevice.percentage
    readonly property bool isLow: percentage <= ConfigOptions.bar.batteryLowThreshold / 100
    readonly property color batteryLowBackground: Appearance.m3colors.darkmode ? Appearance.m3colors.m3error : Appearance.m3colors.m3errorContainer
    readonly property color batteryLowOnBackground: Appearance.m3colors.darkmode ? Appearance.m3colors.m3errorContainer : Appearance.m3colors.m3error

    implicitWidth: rowLayout.implicitWidth + rowLayout.spacing * 2
    implicitHeight: 32
    color: Appearance.colors.colLayer1
    radius: Appearance.rounding.small

    RowLayout {
        id: rowLayout

        spacing: 4
        anchors.centerIn: parent

        Rectangle {
            implicitWidth: (isCharging ? (boltIconLoader?.item?.width ?? 0) : 0)

            Behavior on implicitWidth {
                NumberAnimation {
                    duration: Appearance.animation.elementMove.duration
                    easing.type: Appearance.animation.elementMove.type
                    easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
                }
            }
        }

        StyledText {
            Layout.alignment: Qt.AlignVCenter
            color: Appearance.colors.colOnLayer1
            text: `${Math.round(percentage * 100)}%`
        }

        CircularProgress {
            Layout.alignment: Qt.AlignVCenter
            lineWidth: 2
            value: percentage
            size: 26
            secondaryColor: (isLow && !isCharging) ? batteryLowBackground : Appearance.m3colors.m3secondaryContainer
            primaryColor: (isLow && !isCharging) ? batteryLowOnBackground : Appearance.m3colors.m3onSecondaryContainer
            fill: (isLow && !isCharging)

            MaterialSymbol {
                anchors.centerIn: parent
                text: "battery_full"
                iconSize: Appearance.font.pixelSize.normal
                color: (isLow && !isCharging) ? batteryLowOnBackground : Appearance.m3colors.m3onSecondaryContainer
            }

        }

    }

    Loader {
        id: boltIconLoader
        active: true
        anchors.left: rowLayout.left
        anchors.verticalCenter: rowLayout.verticalCenter

        Connections {
            target: root
            function onIsChargingChanged() {
                if (isCharging) boltIconLoader.active = true
            }
        }

        sourceComponent: MaterialSymbol {
            id: boltIcon

            text: "bolt"
            iconSize: Appearance.font.pixelSize.large
            color: Appearance.m3colors.m3onSecondaryContainer
            visible: opacity > 0 // Only show when charging
            opacity: isCharging ? 1 : 0 // Keep opacity for visibility
            onVisibleChanged: {
                if (!visible) boltIconLoader.active = false
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: Appearance.animation.elementMove.duration
                    easing.type: Appearance.animation.elementMove.type
                    easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
                }

            }

        }
    }

}
