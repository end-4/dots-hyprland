import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell.Services.Pipewire


RowLayout {
    id: root
    required property PwNode node;
	PwObjectTracker { objects: [ node ] }

    spacing: 10

    Image {
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        visible: source != ""
        sourceSize.width: 50
        sourceSize.height: 50
        source: {
            const icon = node.properties["application.icon-name"] ?? "audio-volume-high-symbolic";
            return `image://icon/${icon}`;
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        RowLayout {
            StyledText {
                Layout.fillWidth: true
                font.pixelSize: Appearance.font.pixelSize.normal
                elide: Text.ElideRight
                text: {
                    // application.name -> description -> name
                    const app = node.properties["application.name"] ?? (node.description != "" ? node.description : node.name);
                    const media = node.properties["media.name"];
                    return media != undefined ? `${app} • ${media}` : app;
                }
            }
        }

        RowLayout {
            Slider {
                id: slider
                property real backgroundDotSize: 4
                property real backgroundDotMargins: 4
                property real handleMargins: slider.pressed ? 3 : 6
                property real handleWidth: slider.pressed ? 3 : 5
                property real handleHeight: 44
                property real handleLimit: slider.backgroundDotMargins
                property real limitedHandleWidth: (slider.availableWidth - handleWidth - slider.handleLimit * 2)
                Layout.fillWidth: true
                value: node.audio.volume
                onValueChanged: node.audio.volume = value
                from: 0
                to: 1

                Behavior on value { // This makes the volume shift smoothly
                    SmoothedAnimation {
                        velocity: Appearance.animation.elementDecel.velocity
                    }
                }

                Behavior on handleMargins {
                    NumberAnimation {
                        duration: Appearance.animation.elementDecel.duration
                        easing.type: Appearance.animation.elementDecel.type
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onPressed: (mouse) => mouse.accepted = false
                    cursorShape: slider.pressed ? Qt.ClosedHandCursor : Qt.PointingHandCursor 
                }

                background: Item {
                    anchors.verticalCenter: parent.verticalCenter
                    implicitHeight: 16
                    
                    // Fill left
                    Rectangle {
                        anchors.left: parent.left
                        width: slider.handleLimit + slider.visualPosition * slider.limitedHandleWidth - (slider.handleMargins + slider.handleWidth / 2)
                        height: parent.height
                        color: Appearance.m3colors.m3primary
                        topLeftRadius: Appearance.rounding.full
                        bottomLeftRadius: Appearance.rounding.full
                        topRightRadius: Appearance.rounding.unsharpen
                        bottomRightRadius: Appearance.rounding.unsharpen
                    }

                    // Fill right
                    Rectangle {
                        anchors.right: parent.right
                        width: slider.handleLimit + (1 - slider.visualPosition) * slider.limitedHandleWidth - (slider.handleMargins + slider.handleWidth / 2)
                        height: parent.height
                        color: Appearance.m3colors.m3secondaryContainer
                        topLeftRadius: Appearance.rounding.unsharpen
                        bottomLeftRadius: Appearance.rounding.unsharpen
                        topRightRadius: Appearance.rounding.full
                        bottomRightRadius: Appearance.rounding.full
                    }

                    // Dot at the end
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: slider.backgroundDotMargins
                        width: slider.backgroundDotSize
                        height: slider.backgroundDotSize
                        radius: Appearance.rounding.full
                        color: Appearance.m3colors.m3onSecondaryContainer
                    }
                }

                handle: Rectangle {
                    id: handle
                    x: slider.leftPadding + slider.handleLimit + slider.visualPosition * slider.limitedHandleWidth
                    y: slider.topPadding + slider.availableHeight / 2 - height / 2
                    implicitWidth: slider.handleWidth
                    implicitHeight: slider.handleHeight
                    radius: Appearance.rounding.full
                    color: Appearance.m3colors.m3onSecondaryContainer

                    Behavior on implicitWidth {
                        NumberAnimation {
                            duration: Appearance.animation.elementDecel.duration
                            easing.type: Appearance.animation.elementDecel.type
                        }
                    }

                    StyledToolTip {
                        extraVisibleCondition: slider.pressed
                        content: `${Math.round(slider.value * 100)}%`
                    }
                }
            }
        }
    }
}