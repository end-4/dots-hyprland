import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import Qt5Compat.GraphicalEffects
import Quickshell.Services.Mpris

RowLayout {
    id: mediaPlayerRoot

    property MprisPlayer activePlayer 

    Layout.fillHeight: true
    Layout.fillWidth: true
    Layout.margins: parent.implicitHeight / 10
    spacing: 20

    Component.onCompleted: {
        if (MprisController.activePlayer.trackTitle !== ""){
            activePlayer = MprisController.activePlayer
        }else {
            if (mediaControls.meaningfulPlayers.length > 0)
                activePlayer = mediaControls.meaningfulPlayers[0]
        }
    }

    function cycleActivePlayer() {
        var filteredPlayers = mediaControls.meaningfulPlayers
        var currentIndex = filteredPlayers.indexOf(activePlayer);
        var nextIndex = (currentIndex + 1) % filteredPlayers.length;
        activePlayer = filteredPlayers[nextIndex];
    }

    Rectangle { // Art background
        id: artBackground
        Layout.fillHeight: true
        
        implicitWidth: height
        radius: Appearance.rounding.normal

        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: artBackground.width
                height: artBackground.height
                radius: artBackground.radius
            }
        }

        StyledImage { // Art image
            id: mediaArt
            property int size: parent.height
            anchors.fill: parent

            source: mediaPlayerRoot.activePlayer.trackArtUrl
            fillMode: Image.PreserveAspectCrop
            cache: false
            antialiasing: true

            width: size
            height: size
            sourceSize.width: size
            sourceSize.height: size
        }
    }

    ColumnLayout {
        RowLayout {
            
            ColumnLayout { // Track Info Texts
                Layout.fillWidth: true
                Layout.maximumWidth: parent.width
                StyledText {
                    Layout.fillWidth: true
                    text: mediaPlayerRoot.activePlayer.trackTitle

                    font {
                        family: Appearance.font.family.reading
                        pixelSize: Appearance.font.pixelSize.large
                        weight: Appearance.font.weight.bold
                    }
                    elide: Text.ElideRight
                    animateChange: true
                }
                StyledText {
                    text: mediaPlayerRoot.activePlayer.trackArtist
                    color: Appearance.colors.colSubtext
                    font {
                        family: Appearance.font.family.reading
                        pixelSize: Appearance.font.pixelSize.medium
                        weight: Appearance.font.weight.normal
                    }
                    elide: Text.ElideRight
                    animateChange: true
                }
            }   

            Item { Layout.fillWidth: true }


            ColumnLayout { // Player Controls
                Layout.alignment: Qt.AlignRight
                Item {
                    Layout.fillHeight: true
                }
                RowLayout {
                    IconToolbarButton {
                        id: skippreviousButton
                        onClicked: mediaPlayerRoot.activePlayer.previous()
                        text: "skip_previous"
                        iconSize: 18
                    }
                    IconToolbarButton {
                        colBackground: mediaPlayerRoot.activePlayer.isPlaying ? Appearance.colors.colPrimaryContainer : Appearance.colors.colSecondaryContainer
                        colBackgroundHover: mediaPlayerRoot.activePlayer.isPlaying ? Appearance.colors.colPrimaryContainerHover : Appearance.colors.colSecondaryContainerHover
                        id: playpauseButton
                        onClicked: mediaPlayerRoot.activePlayer.togglePlaying();
                        text: mediaPlayerRoot.activePlayer.isPlaying ? "pause" : "play_arrow" 
                        iconSize: 18
                    }
                    IconToolbarButton {
                        id: skipnextButton
                        onClicked: mediaPlayerRoot.activePlayer.next()
                        text: "skip_next"
                        iconSize: 18
                    }
                    IconToolbarButton {
                        visible: mediaControls.meaningfulPlayers.length > 1
                        colBackground: Appearance.colors.colTertiaryContainer
                        colBackgroundHover: Appearance.colors.colTertiaryContainerHover
                        id: cycleButton
                        onClicked: cycleActivePlayer()
                        text: "360"
                        iconSize: 18
                    }
                    
                }
                Item {
                    Layout.fillHeight: true
                }
            }
        }
        
        
        StyledSlider { 
            configuration: StyledSlider.Configuration.Wavy
            highlightColor: Appearance.colors.colPrimary
            trackColor: Appearance.colors.colSecondaryContainer
            handleColor: Appearance.colors.colPrimary
            value: mediaPlayerRoot.activePlayer.position / mediaPlayerRoot.activePlayer.length
            onMoved: {
                mediaPlayerRoot.activePlayer.position = value * mediaPlayerRoot.activePlayer.length;
            }
        }
    }


}
