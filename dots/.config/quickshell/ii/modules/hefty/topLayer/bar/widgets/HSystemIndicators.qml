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
        // onClicked: root.showPopup = !root.showPopup
        property var activeItem: content

        SystemIndicatorsContent {
            id: content
            anchors {
                top: !root.vertical ? parent.top : undefined
                bottom: !root.vertical ? parent.bottom : undefined
                left: root.vertical ? parent.left : undefined
                right: root.vertical ? parent.right : undefined
                horizontalCenter: !root.vertical ? parent.horizontalCenter : undefined
                verticalCenter: root.vertical ? parent.verticalCenter : undefined
            }
        }

        SystemPanel {
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

    component SystemIndicatorsContent: W.BoxLayout {
        vertical: root.vertical
        rowSpacing: 2
        columnSpacing: 8

        VolMuteIcon {}
        MicMuteIcon {}
        WifiIcon {}
        BluetoothIcon {}
    }

    component VolMuteIcon: IconIndicator {
        visible: S.Audio.sink?.audio?.muted ?? false
        W.MaterialSymbol {
            anchors.centerIn: parent
            text: "volume_off"
            iconSize: 20
        }
    }

    component MicMuteIcon: IconIndicator {
        visible: S.Audio.source?.audio?.muted ?? false
        W.MaterialSymbol {
            anchors.centerIn: parent
            text: "mic_off"
            iconSize: 20
        }
    }

    component BluetoothIcon: IconIndicator {
        visible: S.BluetoothStatus.available
        child: W.MaterialSymbol {
            anchors.centerIn: parent
            iconSize: 20
            text: S.BluetoothStatus.connected ? "bluetooth_connected" : S.BluetoothStatus.enabled ? "bluetooth" : "bluetooth_disabled"
        }
    }

    component WifiIcon: IconIndicator {
        child: W.MaterialSymbol {
            anchors.centerIn: parent
            text: C.Icons.getNetworkMaterialSymbol()
            iconSize: 20
        }
    }

    component IconIndicator: Item {
        Layout.fillWidth: root.vertical
        Layout.fillHeight: !root.vertical
        default property Item child
        implicitWidth: child.implicitWidth
        implicitHeight: child.implicitHeight
        children: [child]
    }

    component SystemPanel: W.ChoreographerLoader {
        sourceComponent: W.ChoreographerGridLayout {
            id: panelRoot

            W.FlyFadeEnterChoreographable {
                W.StyledText {
                    text: "five little chuddies jumping on da bed"
                }
            }
            W.FlyFadeEnterChoreographable {
                W.StyledText {
                    text: "one fell off and bumped his head"
                }
            }
            W.FlyFadeEnterChoreographable {
                W.StyledText {
                    text: "momma call the doctor and the doctor sez"
                }
            }
        }
    }
}
