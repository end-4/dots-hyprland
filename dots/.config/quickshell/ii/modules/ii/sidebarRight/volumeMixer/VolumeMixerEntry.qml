import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Qt5Compat.GraphicalEffects

Item {
    id: root
    required property PwNode node
    PwObjectTracker {
        objects: [root.node]
    }

    implicitHeight: rowLayout.implicitHeight

    RowLayout {
        id: rowLayout
        anchors.fill: parent
        spacing: 6

        Item {
            property real size: 36
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            Layout.preferredWidth: size
            Layout.preferredHeight: size

            Image {
                id: iconImg
                anchors.fill: parent
                visible: false
                sourceSize.width: parent.size
                sourceSize.height: parent.size
                source: {
                    let icon;
                    icon = AppSearch.guessIcon(root.node?.properties["application.icon-name"] ?? "");
                    if (AppSearch.iconExists(icon))
                        return Quickshell.iconPath(icon, "image-missing");
                    icon = AppSearch.guessIcon(root.node?.properties["node.name"] ?? "");
                    return Quickshell.iconPath(icon, "image-missing");
                }
            }

            Desaturate {
                anchors.fill: iconImg
                source: iconImg
                desaturation: root.node?.audio.muted ? 1.0 : 0.0
                visible: iconImg.source != ""
                opacity: root.node?.audio.muted ? 0.4 : 1.0
                
                Behavior on opacity { NumberAnimation { duration: 150 } }
                Behavior on desaturation { NumberAnimation { duration: 150 } }
            }

            MaterialSymbol {
                anchors.centerIn: parent
                visible: root.node?.audio.muted ?? false
                text: root.node?.isSink ? "volume_off" : "mic_off"
                font.pixelSize: 22
                color: Appearance.colors.colError
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.node.audio.muted = !root.node.audio.muted
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: -4

            StyledText {
                Layout.fillWidth: true
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colSubtext
                elide: Text.ElideRight
                text: {
                    // application.name -> description -> name
                    const app = Audio.appNodeDisplayName(root.node);
                    const media = root.node.properties["media.name"];
                    return media != undefined ? `${app} • ${media}` : app;
                }
            }

            StyledSlider {
                id: slider
                value: root.node?.audio.volume ?? 0
                onMoved: root.node.audio.volume = value
                configuration: StyledSlider.Configuration.S
            }
        }
    }
}
