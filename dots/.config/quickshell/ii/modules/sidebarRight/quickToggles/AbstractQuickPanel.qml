import QtQuick
import qs.modules.common

Rectangle {
    id: root

    radius: Appearance.rounding.normal
    color: Appearance.colors.colLayer1

    signal openWifiDialog()
    signal openBluetoothDialog()
    signal openAudioOutputDialog()
    signal openAudioInputDialog()
}
