import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import "root:/modules/common/functions/string_utils.js" as StringUtils
import "root:/modules/common/functions/file_utils.js" as FileUtils
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root
    required property var bar
    property bool visible: false
    readonly property MprisPlayer activePlayer: MprisController.activePlayer
    readonly property real osdWidth: Appearance.sizes.osdWidth
    readonly property real widgetWidth: Appearance.sizes.mediaControlsWidth
    readonly property real widgetHeight: Appearance.sizes.mediaControlsHeight
    property real contentPadding: 13
    property real popupRounding: Appearance.rounding.screenRounding - Appearance.sizes.elevationMargin + 1
    property real artRounding: Appearance.rounding.verysmall
    property string baseCoverArtDir: FileUtils.trimFileProtocol(`${XdgDirectories.cache}/media/coverart`)

    // property bool hasPlasmaIntegration: true
    function isRealPlayer(player) {
        // return true
        return (
            // Remove unecessary native buses from browsers if there's plasma integration
            // !(hasPlasmaIntegration && player.busName.startsWith('org.mpris.MediaPlayer2.firefox')) &&
            // !(hasPlasmaIntegration && player.busName.startsWith('org.mpris.MediaPlayer2.chromium')) &&
            // playerctld just copies other buses and we don't need duplicates
            !player.dbusName?.startsWith('org.mpris.MediaPlayer2.playerctld') &&
            // Non-instance mpd bus
            !(player.dbusName?.endsWith('.mpd') && !player.busName.endsWith('MediaPlayer2.mpd'))
        );
    }

    Component.onCompleted: {
        Hyprland.dispatch(`exec rm -rf ${baseCoverArtDir} && mkdir -p ${baseCoverArtDir}`)
    }

    Loader {
        id: mediaControlsLoader
        active: false

        PanelWindow {
            id: mediaControlsRoot
            visible: mediaControlsLoader.active

            exclusiveZone: 0
            implicitWidth: (
                (mediaControlsRoot.screen.width / 2) // Middle of screen
                    - (osdWidth / 2)                 // Dodge OSD
                    - (widgetWidth / 2)              // Account for widget width
            ) * 2
            implicitHeight: playerColumnLayout.implicitHeight
            color: "transparent"
            WlrLayershell.namespace: "quickshell:mediaControls"

            anchors {
                top: true
                left: true
            }
            mask: Region {
                item: playerColumnLayout
            }

            ColumnLayout {
                id: playerColumnLayout
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                x: (mediaControlsRoot.screen.width / 2)  // Middle of screen
                    - (osdWidth / 2)                     // Dodge OSD
                    - (widgetWidth)                      // Account for widget width
                    + (Appearance.sizes.elevationMargin) // It's fine for shadows to overlap
                spacing: -Appearance.sizes.elevationMargin // Shadow overlap okay

                Repeater {
                    model: {
                        // console.log(JSON.stringify(Mpris.players, null, 2))
                        return Mpris.players.values.filter(player => isRealPlayer(player))
                    }
                    delegate: PlayerControl {
                        required property MprisPlayer modelData
                        player: modelData
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "mediaControls"

        function toggle(): void {
            mediaControlsLoader.active = !mediaControlsLoader.active;
            if(mediaControlsLoader.active) Notifications.timeoutAll();
        }

        function close(): void {
            mediaControlsLoader.active = false;
        }

        function open(): void {
            mediaControlsLoader.active = true;
            Notifications.timeoutAll();
        }
    }

    GlobalShortcut {
        name: "mediaControlsToggle"
        description: "Toggles media controls on press"

        onPressed: {
            mediaControlsLoader.active = !mediaControlsLoader.active;
            if(mediaControlsLoader.active) Notifications.timeoutAll();
        }
    }
    GlobalShortcut {
        name: "mediaControlsOpen"
        description: "Opens media controls on press"

        onPressed: {
            mediaControlsLoader.active = true;
            Notifications.timeoutAll();
        }
    }
    GlobalShortcut {
        name: "mediaControlsClose"
        description: "Closes media controls on press"

        onPressed: {
            mediaControlsLoader.active = false;
        }
    }

}