import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import QtQuick

Item {
    id: root
    required property string iconName
    required property double percentage
    property int warningThreshold: 100
    property bool shown: true
    implicitHeight: shown ? resourceProgress.implicitHeight : 0
    implicitWidth: shown ? Appearance.sizes.verticalBarWidth : 0
    visible: shown

    property bool warning: percentage * 100 >= warningThreshold

    ClippedFilledCircularProgress {
        id: resourceProgress
        anchors.centerIn: parent
        value: percentage
        enableAnimation: false
        colPrimary: root.warning ? Appearance.colors.colError : Appearance.colors.colOnSecondaryContainer
        accountForLightBleeding: !root.warning

        MaterialSymbol {
            font.weight: Font.Medium
            fill: 1
            text: root.iconName
            iconSize: 13
            color: Appearance.colors.colOnSecondaryContainer
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        enabled: root.visible
    }
}
