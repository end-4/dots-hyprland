import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import Qt5Compat.GraphicalEffects



RowLayout {

    property int maxTitleLength: 30

    Layout.fillHeight: true
    Layout.fillWidth: true
    Layout.margins: parent.implicitHeight / 10
    spacing: 20

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

            source: root.activePlayer.trackArtUrl
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
            spacing: 20
            ColumnLayout { // Track Info Texts
                StyledText {
                    text: root.activePlayer.trackTitle.length > maxTitleLength
                          ? root.activePlayer.trackTitle.substring(0, maxTitleLength) + "..."
                          : root.activePlayer.trackTitle

                    font {
                        family: Appearance.font.family.reading
                        pixelSize: Appearance.font.pixelSize.large
                        weight: Appearance.font.weight.bold
                    }
                    elide: Text.ElideRight
                    animateChange: true
                }
                StyledText {
                    text: root.activePlayer.trackArtist
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

            ColumnLayout { // Player Controls
                Item {
                    Layout.preferredHeight: 2
                }
                RowLayout {
                    IconToolbarButton {
                        id: skippreviousButton
                        onClicked: root.activePlayer.previous()
                        text: "skip_previous"
                        iconSize: 18
                    }
                    IconToolbarButton {
                        colBackground: root.activePlayer.isPlaying ? Appearance.colors.colPrimaryContainer : Appearance.colors.colSecondaryContainer
                        colBackgroundHover: root.activePlayer.isPlaying ? Appearance.colors.colPrimaryContainerHover : Appearance.colors.colSecondaryContainerHover
                        id: playpauseButton
                        onClicked: root.activePlayer.togglePlaying();
                        text: root.activePlayer.isPlaying ? "pause" : "play_arrow" 
                        iconSize: 18
                    }
                    IconToolbarButton {
                        id: skipnextButton
                        onClicked: root.activePlayer.next()
                        text: "skip_next"
                        iconSize: 18
                    }
                }
                Item {
                    Layout.preferredHeight: 2
                }
            }
        }
        
        
        StyledSlider { 
            configuration: StyledSlider.Configuration.Wavy
            highlightColor: Appearance.colors.colPrimary
            trackColor: Appearance.colors.colSecondaryContainer
            handleColor: Appearance.colors.colPrimary
            value: root.activePlayer.position / root.activePlayer.length
            onMoved: {
                root.activePlayer.position = value * root.activePlayer.length;
            }
        }
    }
}
