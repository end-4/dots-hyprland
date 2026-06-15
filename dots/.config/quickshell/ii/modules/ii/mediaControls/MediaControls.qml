pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root
    property bool visible: false
    readonly property MprisPlayer activePlayer: MprisController.activePlayer
    readonly property var realPlayers: MprisController.players
    readonly property var meaningfulPlayers: filterDuplicatePlayers(realPlayers)
    readonly property real osdWidth: Appearance.sizes.osdWidth
    readonly property real widgetWidth: Appearance.sizes.mediaControlsWidth
    readonly property real widgetHeight: Appearance.sizes.mediaControlsHeight
    property real popupRounding: Appearance.rounding.screenRounding - Appearance.sizes.hyprlandGapsOut + 1
    property list<real> visualizerPoints: []

    function filterDuplicatePlayers(players) {
        let filtered = [];
        let used = new Set();

        for (let i = 0; i < players.length; ++i) {
            if (used.has(i))
                continue;
            let p1 = players[i];
            let group = [i];

            for (let j = i + 1; j < players.length; ++j) {
                let p2 = players[j];
                if (p1.trackTitle && p2.trackTitle && (p1.trackTitle.includes(p2.trackTitle) || p2.trackTitle.includes(p1.trackTitle)) || (p1.position - p2.position <= 2 && p1.length - p2.length <= 2)) {
                    group.push(j);
                }
            }

            let chosenIdx = group.find(idx => players[idx].trackArtUrl && players[idx].trackArtUrl.length > 0);
            if (chosenIdx === undefined)
                chosenIdx = group[0];

            filtered.push(players[chosenIdx]);
            group.forEach(idx => used.add(idx));
        }
        return filtered;
    }

    Process {
        id: cavaProc
        running: mediaControlsLoader.active
        onRunningChanged: {
            if (!cavaProc.running) {
                root.visualizerPoints = [];
            }
        }
        command: ["cava", "-p", `${FileUtils.trimFileProtocol(Directories.scriptPath)}/cava/raw_output_config.txt`]
        stdout: SplitParser {
            onRead: data => {
                let points = data.split(";").map(p => parseFloat(p.trim())).filter(p => !isNaN(p));
                root.visualizerPoints = points;
            }
        }
    }

    Loader {
        id: mediaControlsLoader
        active: GlobalStates.mediaControlsOpen
        onActiveChanged: {
            if (!mediaControlsLoader.active && root.realPlayers.length === 0) {
                GlobalStates.mediaControlsOpen = false;
            }
        }

        sourceComponent: PanelWindow {
            id: panelWindow
            visible: true

            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0
            implicitWidth: root.widgetWidth
            implicitHeight: playerColumnLayout.implicitHeight
            color: "transparent"
            WlrLayershell.namespace: "quickshell:mediaControls"

            anchors {
                top: !Config.options.bar.bottom || Config.options.bar.vertical
                bottom: Config.options.bar.bottom && !Config.options.bar.vertical
                left: !(Config.options.bar.vertical && Config.options.bar.bottom)
                right: Config.options.bar.vertical && Config.options.bar.bottom
            }
            margins {
                top: Config.options.bar.vertical ? ((panelWindow.screen.height / 2) - widgetHeight * 1.5) : Appearance.sizes.barHeight
                bottom: Appearance.sizes.barHeight
                left: Config.options.bar.vertical ? Appearance.sizes.barHeight : ((panelWindow.screen.width / 2) - (osdWidth / 2) - widgetWidth)
                right: Appearance.sizes.barHeight
            }

            mask: Region {
                item: playerColumnLayout
            }

            Component.onCompleted: {
                GlobalFocusGrab.addDismissable(panelWindow);
                introAnim.start();
            }
            Component.onDestruction: {
                GlobalFocusGrab.removeDismissable(panelWindow);
            }
            Connections {
                target: GlobalFocusGrab
                function onDismissed() {
                    GlobalStates.mediaControlsOpen = false;
                }
            }

            ParallelAnimation {
                id: introAnim
                NumberAnimation {
                    target: playerColumnLayout
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 180
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: playerColumnLayout
                    property: "scale"
                    from: 0.93
                    to: 1.0
                    duration: 280
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.animationCurves.expressiveFastSpatial
                }
            }

            ColumnLayout {
                id: playerColumnLayout
                anchors.fill: parent
                spacing: 8
                transformOrigin: Item.Top

                Repeater {
                    model: ScriptModel {
                        values: root.meaningfulPlayers
                    }
                    delegate: PlayerControl {
                        id: controlItem
                        required property MprisPlayer modelData
                        player: modelData
                        visualizerPoints: root.visualizerPoints
                        implicitWidth: root.widgetWidth
                        implicitHeight: root.widgetHeight
                        radius: root.popupRounding

                        opacity: 0
                        scale: 0.9

                        Component.onCompleted: {
                            delegateAnim.start();
                        }

                        ParallelAnimation {
                            id: delegateAnim
                            NumberAnimation {
                                target: controlItem
                                property: "opacity"
                                to: 1
                                duration: 200
                                easing.type: Easing.OutCubic
                            }
                            NumberAnimation {
                                target: controlItem
                                property: "scale"
                                to: 1
                                duration: 250
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: Appearance.animationCurves.expressiveFastSpatial
                            }
                        }
                    }
                }

                Item {
                    Layout.alignment: {
                        if (panelWindow.anchors.left)
                            return Qt.AlignLeft;
                        if (panelWindow.anchors.right)
                            return Qt.AlignRight;
                        return Qt.AlignHCenter;
                    }
                    Layout.leftMargin: Appearance.sizes.hyprlandGapsOut
                    Layout.rightMargin: Appearance.sizes.hyprlandGapsOut
                    visible: root.meaningfulPlayers.length === 0
                    implicitWidth: placeholderBackground.implicitWidth + Appearance.sizes.elevationMargin
                    implicitHeight: placeholderBackground.implicitHeight + Appearance.sizes.elevationMargin

                    StyledRectangularShadow {
                        target: placeholderBackground
                    }

                    Rectangle {
                        id: placeholderBackground
                        anchors.centerIn: parent
                        color: Appearance.colors.colLayer0
                        radius: root.popupRounding
                        property real padding: 24
                        implicitWidth: placeholderLayout.implicitWidth + padding * 2
                        implicitHeight: placeholderLayout.implicitHeight + padding * 2

                        ColumnLayout {
                            id: placeholderLayout
                            anchors.centerIn: parent
                            spacing: 8

                            StyledText {
                                text: Translation.tr("No active player")
                                font.pixelSize: Appearance.font.pixelSize.large
                                Layout.alignment: Qt.AlignHCenter
                            }
                            StyledText {
                                color: Appearance.colors.colSubtext
                                text: Translation.tr("Make sure your player has MPRIS support\nor try turning off duplicate player filtering")
                                font.pixelSize: Appearance.font.pixelSize.small
                                Layout.alignment: Qt.AlignHCenter
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "mediaControls"

        function toggle(): void {
            mediaControlsLoader.active = !mediaControlsLoader.active;
            if (mediaControlsLoader.active)
                Notifications.timeoutAll();
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
            GlobalStates.mediaControlsOpen = !GlobalStates.mediaControlsOpen;
        }
    }
    GlobalShortcut {
        name: "mediaControlsOpen"
        description: "Opens media controls on press"

        onPressed: {
            GlobalStates.mediaControlsOpen = true;
        }
    }
    GlobalShortcut {
        name: "mediaControlsClose"
        description: "Closes media controls on press"

        onPressed: {
            GlobalStates.mediaControlsOpen = false;
        }
    }
}
