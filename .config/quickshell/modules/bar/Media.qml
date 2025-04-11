import "../common"
import "../common/widgets"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Rectangle {
    readonly property MprisPlayer activePlayer: MprisController.activePlayer
    readonly property string cleanedTitle: activePlayer?.trackTitle.replace(/【[^】]*】/, "") || "No media"

    Layout.fillHeight: true
    implicitWidth: rowLayout.implicitWidth + rowLayout.spacing * 2
    implicitHeight: 40
    color: "transparent"

    // Background
    Rectangle {
        anchors.centerIn: parent
        width: parent.width
        implicitHeight: 32
        color: Appearance.colors.colLayer1
        radius: Appearance.rounding.small
    }

    Timer {
        running: activePlayer?.playbackState == MprisPlaybackState.Playing
        interval: 1000
        repeat: true
        onTriggered: activePlayer.positionChanged()
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.MiddleButton | Qt.BackButton | Qt.ForwardButton | Qt.RightButton
        onPressed: (event) => {
            if (event.button === Qt.MiddleButton) {
                activePlayer.togglePlaying();
            } else if (event.button === Qt.BackButton) {
                activePlayer.previous();
            } else if (event.button === Qt.ForwardButton || event.button === Qt.RightButton) {
                activePlayer.next();
            } 
        }
    }

    RowLayout {
        id: rowLayout

        spacing: 4
        anchors.fill: parent

        CircularProgress {
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: rowLayout.spacing
            lineWidth: 2
            value: activePlayer?.position / activePlayer?.length
            size: 26
            secondaryColor: Appearance.m3colors.m3secondaryContainer
            primaryColor: Appearance.m3colors.m3onSecondaryContainer

            MaterialSymbol {
                anchors.centerIn: parent
                text: activePlayer?.isPlaying ? "pause" : "play_arrow"
                font.pointSize: Appearance.font.pointSize.normal
                color: Appearance.m3colors.m3onSecondaryContainer
            }

        }

        StyledText {
            width: rowLayout.width - (CircularProgress.size + rowLayout.spacing * 2) // TODO ADJUST THIS
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true // Ensures the text takes up available space
            Layout.rightMargin: rowLayout.spacing
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight // Truncates the text on the right
            color: Appearance.colors.colOnLayer1
            text: `${cleanedTitle}${activePlayer?.trackArtist ? ' • ' + activePlayer.trackArtist : ''}`
        }

    }

}
