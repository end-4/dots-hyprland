import QtQuick
import qs.modules.common
import qs.services

// Music shrunk to a bubble beside the card while something else has the island.
Rectangle {
    width: 36
    height: 36
    radius: 18
    color: Appearance.colors.colLayer1Base
    AlbumArt {
        anchors.centerIn: parent
        size: 26
        radius: 13
        source: MprisController.activeTrack?.artUrl ?? ""
    }
    MouseArea {
        anchors.fill: parent
        onClicked: MprisController.togglePlaying()
    }
}
