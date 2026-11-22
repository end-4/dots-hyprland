import QtQuick
import QtMultimedia
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

ContentPage {
    id: quickPage
    forceWidth: true

    property string selectedWallpaperMonitor: Quickshell.screens.length > 0 ? Quickshell.screens[0].name : ""

    readonly property string previewWallpaperPath: {
        if (Config.options.background.perMonitor && quickPage.selectedWallpaperMonitor !== "") {
            const entry = Config.options.background.monitors?.[quickPage.selectedWallpaperMonitor];
            if (entry && entry.wallpaperPath && entry.wallpaperPath !== "")
                return entry.wallpaperPath;
        }
        return Config.options.background.wallpaperPath;
    }

    Process {
        id: randomWallProc
        property string status: ""
        property string scriptPath: `${Directories.scriptPath}/colors/random/random_konachan_wall.sh`
        command: ["bash", "-c", FileUtils.trimFileProtocol(randomWallProc.scriptPath)]
        stdout: SplitParser {
            onRead: data => {
                randomWallProc.status = data.trim();
            }
        }
    }

    component SmallLightDarkPreferenceButton: RippleButton {
        id: smallLightDarkPreferenceButton
        required property bool dark
        property color colText: toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer2
        padding: 5
        Layout.fillWidth: true
        toggled: Appearance.m3colors.darkmode === dark
        colBackground: Appearance.colors.colLayer2
        onClicked: {
            Quickshell.execDetached(["bash", "-c", `${Directories.wallpaperSwitchScriptPath} --mode ${dark ? "dark" : "light"} --noswitch`]);
        }
        contentItem: Item {
            anchors.centerIn: parent
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 0
                MaterialSymbol {
                    Layout.alignment: Qt.AlignHCenter
                    iconSize: 30
                    text: dark ? "dark_mode" : "light_mode"
                    color: smallLightDarkPreferenceButton.colText
                }
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: dark ? Translation.tr("Dark") : Translation.tr("Light")
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: smallLightDarkPreferenceButton.colText
                }
            }
        }
    }

    // Wallpaper selection
    ContentSection {
        icon: "format_paint"
        title: Translation.tr("Wallpaper & Colors")
        Layout.fillWidth: true

        RowLayout {
            Layout.fillWidth: true

            Item {
                id: previewFadeWrapper
                implicitWidth: 340
                implicitHeight: 200
                readonly property bool previewIsVideo: /\.(mp4|webm|mkv|avi|mov)$/i.test(quickPage.previewWallpaperPath)
                readonly property bool previewIsGif: /\.gif$/i.test(quickPage.previewWallpaperPath)
                NumberAnimation on opacity {
                    id: previewFadeAnim
                    from: 0.25
                    to: 1
                    duration: 180
                    easing.type: Easing.OutCubic
                    running: false
                }
                Connections {
                    target: quickPage
                    function onPreviewWallpaperPathChanged() {
                        previewFadeAnim.restart();
                    }
                }
                Item {
                    anchors.fill: parent
                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: 340
                            height: 200
                            radius: Appearance.rounding.normal
                        }
                    }
                    StyledImage {
                        id: wallpaperPreview
                        anchors.fill: parent
                        visible: !previewFadeWrapper.previewIsVideo && !previewFadeWrapper.previewIsGif
                        fillMode: Image.PreserveAspectCrop
                        source: visible ? quickPage.previewWallpaperPath : ""
                        cache: true
                    }
                    AnimatedImage {
                        anchors.fill: parent
                        visible: previewFadeWrapper.previewIsGif
                        source: visible ? ("file://" + quickPage.previewWallpaperPath.replace(/^file:\/\//, "")) : ""
                        fillMode: Image.PreserveAspectCrop
                        playing: visible && quickPage.visible
                        asynchronous: true
                    }
                    Loader {
                        id: livePreviewVideoLoader
                        anchors.fill: parent
                        // Two-phase teardown: stop + detach the player first, destroy the item
                        // after a short delay so the render thread never samples a deleted video sink.
                        readonly property bool wanted: previewFadeWrapper.previewIsVideo && quickPage.visible && quickPage.previewWallpaperPath !== ""
                        property bool gate: false
                        active: gate
                        visible: active
                        Component.onCompleted: gate = wanted
                        onWantedChanged: {
                            if (wanted) {
                                quickPreviewGateTimer.stop();
                                gate = true;
                                if (item) item.resume();
                            } else {
                                if (item) item.shutdown();
                                quickPreviewGateTimer.restart();
                            }
                        }
                        Timer {
                            id: quickPreviewGateTimer
                            interval: 300
                            onTriggered: livePreviewVideoLoader.gate = livePreviewVideoLoader.wanted
                        }
                        sourceComponent: Item {
                            id: quickPreviewRoot
                            anchors.fill: parent
                            property bool shut: false
                            function shutdown() { shut = true; previewVidPlayer.stop(); }
                            function resume() { shut = false; previewVidPlayer.play(); }
                            MediaPlayer {
                                id: previewVidPlayer
                                source: (quickPreviewRoot.shut || !previewFadeWrapper.previewIsVideo) ? "" : "file://" + quickPage.previewWallpaperPath.replace(/^file:\/\//, "")
                                loops: MediaPlayer.Infinite
                                audioOutput: AudioOutput { muted: true }
                                videoOutput: quickPreviewRoot.shut ? null : previewVidOut
                                Component.onCompleted: if (!quickPreviewRoot.shut && source.toString() !== "") play()
                                onSourceChanged: {
                                    stop();
                                    if (!quickPreviewRoot.shut && source.toString() !== "") play();
                                }
                                onMediaStatusChanged: {
                                    if (mediaStatus === MediaPlayer.LoadedMedia && !quickPreviewRoot.shut && playbackState !== MediaPlayer.PlayingState)
                                        play();
                                }
                                onErrorOccurred: (error, errorString) => console.warn("[QuickConfig] preview MediaPlayer error:", error, errorString)
                            }
                            VideoOutput {
                                id: previewVidOut
                                anchors.fill: parent
                                fillMode: VideoOutput.PreserveAspectCrop
                            }
                        }
                    }
                    Rectangle {
                        visible: previewFadeWrapper.previewIsVideo || previewFadeWrapper.previewIsGif
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.margins: 8
                        radius: Appearance.rounding.full
                        color: Qt.rgba(0, 0, 0, 0.65)
                        implicitWidth: liveBadgeRow.implicitWidth + 14
                        implicitHeight: 24
                        RowLayout {
                            id: liveBadgeRow
                            anchors.centerIn: parent
                            spacing: 4
                            MaterialSymbol {
                                text: "play_circle"
                                iconSize: 14
                                color: "#ffffff"
                            }
                            StyledText {
                                text: previewFadeWrapper.previewIsGif ? "GIF" : "LIVE"
                                color: "#ffffff"
                                font.pixelSize: 11
                                font.weight: Font.Medium
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                RippleButtonWithIcon {
                    enabled: !randomWallProc.running
                    visible: Config.options.policies.weeb === 1
                    Layout.fillWidth: true
                    buttonRadius: Appearance.rounding.small
                    materialIcon: "ifl"
                    mainText: randomWallProc.running ? Translation.tr("Be patient...") : Translation.tr("Random: Konachan")
                    onClicked: {
                        const mon = (Config.options.background.perMonitor && quickPage.selectedWallpaperMonitor !== "") ? quickPage.selectedWallpaperMonitor : "";
                        randomWallProc.command = ["bash", "-c", `II_TARGET_MONITOR="${mon}" "${FileUtils.trimFileProtocol(Directories.scriptPath)}/colors/random/random_konachan_wall.sh"`];
                        randomWallProc.running = true;
                    }
                    StyledToolTip {
                        text: Translation.tr("Random SFW Anime wallpaper from Konachan\nImage is saved to ~/Pictures/Wallpapers")
                    }
                }
                RippleButtonWithIcon {
                    enabled: !randomWallProc.running
                    visible: Config.options.policies.weeb === 1
                    Layout.fillWidth: true
                    buttonRadius: Appearance.rounding.small
                    materialIcon: "ifl"
                    mainText: randomWallProc.running ? Translation.tr("Be patient...") : Translation.tr("Random: osu! seasonal")
                    onClicked: {
                        const mon = (Config.options.background.perMonitor && quickPage.selectedWallpaperMonitor !== "") ? quickPage.selectedWallpaperMonitor : "";
                        randomWallProc.command = ["bash", "-c", `II_TARGET_MONITOR="${mon}" "${FileUtils.trimFileProtocol(Directories.scriptPath)}/colors/random/random_osu_wall.sh"`];
                        randomWallProc.running = true;
                    }
                    StyledToolTip {
                        text: Translation.tr("Random osu! seasonal background\nImage is saved to ~/Pictures/Wallpapers")
                    }
                }
                RippleButtonWithIcon {
                    Layout.fillWidth: true
                    materialIcon: "wallpaper"
                    StyledToolTip {
                        text: Translation.tr("Pick wallpaper image on your system")
                    }
                    onClicked: {
                        if (Config.options.background.perMonitor && quickPage.selectedWallpaperMonitor !== "") {
                            Quickshell.execDetached(["bash", "-c", `${Directories.wallpaperSwitchScriptPath} --monitor "${quickPage.selectedWallpaperMonitor}"`]);
                        } else {
                            Quickshell.execDetached(`${Directories.wallpaperSwitchScriptPath}`);
                        }
                    }
                    mainContentComponent: Component {
                        RowLayout {
                            spacing: 10
                            StyledText {
                                font.pixelSize: Appearance.font.pixelSize.small
                                text: Translation.tr("Choose file")
                                color: Appearance.colors.colOnSecondaryContainer
                            }
                            RowLayout {
                                spacing: 3
                                KeyboardKey {
                                    key: "Ctrl"
                                }
                                KeyboardKey {
                                    key: Config.options.cheatsheet.superKey ?? "󰖳"
                                }
                                StyledText {
                                    Layout.alignment: Qt.AlignVCenter
                                    text: "+"
                                }
                                KeyboardKey {
                                    key: "T"
                                }
                            }
                        }
                    }
                }
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    uniformCellSizes: true

                    SmallLightDarkPreferenceButton {
                        Layout.fillHeight: true
                        dark: false
                    }
                    SmallLightDarkPreferenceButton {
                        Layout.fillHeight: true
                        dark: true
                    }
                }
            }
        }

        ConfigSwitch {
            buttonIcon: "desktop_windows"
            text: Translation.tr("Separate per monitor")
            checked: Config.options.background.perMonitor
            onCheckedChanged: {
                if (Config.options.background.perMonitor !== checked) {
                    Config.options.background.perMonitor = checked;
                }
            }
        }

        MonitorOrderPills {
            visible: Config.options.background.perMonitor
            selectedMonitor: quickPage.selectedWallpaperMonitor
            onMonitorSelected: name => quickPage.selectedWallpaperMonitor = name
        }

        ConfigSelectionArray {
            currentValue: Config.options.appearance.palette.type
            onSelected: newValue => {
                Config.options.appearance.palette.type = newValue;
                Quickshell.execDetached(["bash", "-c", `${Directories.wallpaperSwitchScriptPath} --noswitch`]);
            }
            options: [
                {
                    "value": "auto",
                    "displayName": Translation.tr("Auto")
                },
                {
                    "value": "scheme-content",
                    "displayName": Translation.tr("Content")
                },
                {
                    "value": "scheme-expressive",
                    "displayName": Translation.tr("Expressive")
                },
                {
                    "value": "scheme-fidelity",
                    "displayName": Translation.tr("Fidelity")
                },
                {
                    "value": "scheme-fruit-salad",
                    "displayName": Translation.tr("Fruit Salad")
                },
                {
                    "value": "scheme-monochrome",
                    "displayName": Translation.tr("Monochrome")
                },
                {
                    "value": "scheme-neutral",
                    "displayName": Translation.tr("Neutral")
                },
                {
                    "value": "scheme-rainbow",
                    "displayName": Translation.tr("Rainbow")
                },
                {
                    "value": "scheme-tonal-spot",
                    "displayName": Translation.tr("Tonal Spot")
                }
            ]
        }

        ConfigSwitch {
            buttonIcon: "ev_shadow"
            text: Translation.tr("Transparency")
            checked: Config.options.appearance.transparency.enable
            onCheckedChanged: {
                Config.options.appearance.transparency.enable = checked;
            }
        }
    }

    ContentSection {
        icon: "screenshot_monitor"
        title: Translation.tr("Bar & screen")

        ConfigRow {
            ContentSubsection {
                title: Translation.tr("Bar position")
                ConfigSelectionArray {
                    currentValue: (Config.options.bar.bottom ? 1 : 0) | (Config.options.bar.vertical ? 2 : 0)
                    onSelected: newValue => {
                        Config.options.bar.bottom = (newValue & 1) !== 0;
                        Config.options.bar.vertical = (newValue & 2) !== 0;
                    }
                    options: [
                        {
                            displayName: Translation.tr("Top"),
                            icon: "arrow_upward",
                            value: 0 // bottom: false, vertical: false
                        },
                        {
                            displayName: Translation.tr("Left"),
                            icon: "arrow_back",
                            value: 2 // bottom: false, vertical: true
                        },
                        {
                            displayName: Translation.tr("Bottom"),
                            icon: "arrow_downward",
                            value: 1 // bottom: true, vertical: false
                        },
                        {
                            displayName: Translation.tr("Right"),
                            icon: "arrow_forward",
                            value: 3 // bottom: true, vertical: true
                        }
                    ]
                }
            }
            ContentSubsection {
                title: Translation.tr("Bar style")

                ConfigSelectionArray {
                    currentValue: Config.options.bar.cornerStyle
                    onSelected: newValue => {
                        Config.options.bar.cornerStyle = newValue; // Update local copy
                    }
                    options: [
                        {
                            displayName: Translation.tr("Hug"),
                            icon: "line_curve",
                            value: 0
                        },
                        {
                            displayName: Translation.tr("Float"),
                            icon: "page_header",
                            value: 1
                        },
                        {
                            displayName: Translation.tr("Rect"),
                            icon: "toolbar",
                            value: 2
                        }
                    ]
                }
            }
        }

        ConfigRow {
            ContentSubsection {
                title: Translation.tr("Screen round corner")

                ConfigSelectionArray {
                    currentValue: Config.options.appearance.fakeScreenRounding
                    onSelected: newValue => {
                        Config.options.appearance.fakeScreenRounding = newValue;
                    }
                    options: [
                        {
                            displayName: Translation.tr("No"),
                            icon: "close",
                            value: 0
                        },
                        {
                            displayName: Translation.tr("Yes"),
                            icon: "check",
                            value: 1
                        },
                        {
                            displayName: Translation.tr("When not fullscreen"),
                            icon: "fullscreen_exit",
                            value: 2
                        }
                    ]
                }
            }
            
        }
    }

    NoticeBox {
        Layout.fillWidth: true
        text: Translation.tr('Not all options are available in this app. You should also check the config file by hitting the "Config file" button on the topleft corner or opening %1 manually.').arg(Directories.shellConfigPath)

        Item {
            Layout.fillWidth: true
        }
        RippleButtonWithIcon {
            id: copyPathButton
            property bool justCopied: false
            Layout.fillWidth: false
            buttonRadius: Appearance.rounding.small
            materialIcon: justCopied ? "check" : "content_copy"
            mainText: justCopied ? Translation.tr("Path copied") : Translation.tr("Copy path")
            onClicked: {
                copyPathButton.justCopied = true
                Quickshell.clipboardText = FileUtils.trimFileProtocol(`${Directories.config}/illogical-impulse/config.json`);
                revertTextTimer.restart();
            }
            colBackground: ColorUtils.transparentize(Appearance.colors.colPrimaryContainer)
            colBackgroundHover: Appearance.colors.colPrimaryContainerHover
            colRipple: Appearance.colors.colPrimaryContainerActive

            Timer {
                id: revertTextTimer
                interval: 1500
                onTriggered: {
                    copyPathButton.justCopied = false
                }
            }
        }
    }
}
