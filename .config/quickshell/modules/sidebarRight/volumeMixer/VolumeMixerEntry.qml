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
            StyledSlider {
                value: node.audio.volume
                onValueChanged: node.audio.volume = value
            }
        }
    }
}