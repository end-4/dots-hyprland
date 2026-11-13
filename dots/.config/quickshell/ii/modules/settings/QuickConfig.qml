import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

ContentPage {
    forceWidth: true

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
                implicitWidth: 340
                implicitHeight: 200
                
                StyledImage {
                    id: wallpaperPreview
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    source: Config.options.background.wallpaperPath
                    cache: false
                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: 360
                            height: 200
                            radius: Appearance.rounding.normal
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
                        randomWallProc.scriptPath = `${Directories.scriptPath}/colors/random/random_konachan_wall.sh`;
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
                        randomWallProc.scriptPath = `${Directories.scriptPath}/colors/random/random_osu_wall.sh`;
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
                        Quickshell.execDetached(`${Directories.wallpaperSwitchScriptPath}`);
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
        id: themeSlotsSection
        icon: "bookmarks"
        title: Translation.tr("Saved themes")

        property var slots: [null, null, null, null, null, null, null, null, null, null]
        property string slotsScript: `${Directories.scriptPath}/colors/theme-slots.sh`

        function slotAction(cmd, n) {
            Quickshell.execDetached(["bash", "-c", `${FileUtils.trimFileProtocol(themeSlotsSection.slotsScript)} ${cmd} ${n}`]);
        }
        function reparseSlots() {
            try {
                themeSlotsSection.slots = JSON.parse(themeSlotsFile.text());
            } catch (e) { /* index not created yet */ }
        }

        Timer {
            id: themeSlotsReread
            interval: 150
            repeat: false
            onTriggered: themeSlotsSection.reparseSlots()
        }
        FileView {
            id: themeSlotsFile
            path: Qt.resolvedUrl(Quickshell.env("HOME") + "/.local/state/quickshell/user/theme-slots/slots.json")
            watchChanges: true
            // After reload(), `loaded` does not change again: re-parse via the timer.
            onFileChanged: { this.reload(); themeSlotsReread.restart(); }
            onLoadedChanged: themeSlotsSection.reparseSlots()
        }

        RippleButtonWithIcon {
            Layout.fillWidth: true
            materialIcon: "bookmark_add"
            mainText: Translation.tr("Save current theme")
            onClicked: {
                Quickshell.execDetached(["bash", "-c", `${FileUtils.trimFileProtocol(themeSlotsSection.slotsScript)} save`]);
            }
            StyledToolTip {
                text: Translation.tr("Snapshots wallpaper + mode + scheme into the first free slot")
            }
        }

        StyledText {
            Layout.fillWidth: true
            text: Translation.tr("Filled slot: click = restore, X then click again = delete. Empty slot: click = save here.")
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.m3colors.m3outline
            wrapMode: Text.WordWrap
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 5
            rowSpacing: 8
            columnSpacing: 8

            Repeater {
                model: 10
                delegate: Rectangle {
                    id: slotCell
                    required property int index
                    property var slotData: themeSlotsSection.slots[index] ?? null
                    property bool filled: slotData !== null && slotData !== undefined

                    Layout.fillWidth: true
                    implicitHeight: 96
                    radius: Appearance.rounding.small
                    color: filled ? Appearance.colors.colLayer2 : "transparent"
                    border.width: filled ? 0 : 1
                    border.color: Appearance.m3colors.m3outlineVariant

                    Image {
                        id: slotThumb
                        anchors.fill: parent
                        visible: slotCell.filled
                        source: slotCell.filled ? "file://" + slotCell.slotData.file : ""
                        fillMode: Image.PreserveAspectCrop
                        sourceSize.width: 420
                        asynchronous: true
                        layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: Rectangle {
                                width: slotThumb.width
                                height: slotThumb.height
                                radius: Appearance.rounding.small
                            }
                        }
                    }

                    // Dominant color swatches of the saved theme
                    RowLayout {
                        visible: slotCell.filled
                        anchors.left: parent.left
                        anchors.bottom: parent.bottom
                        anchors.margins: 5
                        spacing: 3
                        Repeater {
                            model: slotCell.filled ? (slotCell.slotData.colors ?? []) : []
                            delegate: Rectangle {
                                required property string modelData
                                width: 9
                                height: 9
                                radius: 4.5
                                color: modelData
                                border.width: 1
                                border.color: Qt.rgba(0, 0, 0, 0.35)
                            }
                        }
                    }

                    StyledText {
                        visible: !slotCell.filled
                        anchors.centerIn: parent
                        text: (slotCell.index + 1)
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.m3colors.m3outline
                    }
                    MaterialSymbol {
                        visible: !slotCell.filled && slotMouse.containsMouse
                        anchors.centerIn: parent
                        text: "bookmark_add"
                        iconSize: 20
                        color: Appearance.colors.colOnLayer1
                    }

                    MouseArea {
                        id: slotMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: mouse => {
                            if (mouse.button === Qt.RightButton) {
                                if (slotCell.filled) slotCell.pendingDelete = true;
                                return;
                            }
                            themeSlotsSection.slotAction(slotCell.filled ? "restore" : "save", slotCell.index + 1);
                        }
                    }

                    // Two-step delete: X on hover -> "sure?" for 3 s -> click again deletes
                    property bool pendingDelete: false
                    onPendingDeleteChanged: if (pendingDelete) pendingDeleteReset.restart()
                    Timer {
                        id: pendingDeleteReset
                        interval: 3000
                        onTriggered: slotCell.pendingDelete = false
                    }
                    Rectangle {
                        visible: slotCell.filled && (slotMouse.containsMouse || delMouse.containsMouse || slotCell.pendingDelete)
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 3
                        width: slotCell.pendingDelete ? 34 : 16
                        height: 16
                        radius: 8
                        z: 2
                        color: slotCell.pendingDelete ? "#b3261e" : Qt.rgba(0, 0, 0, 0.55)
                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: slotCell.pendingDelete ? "delete_forever" : "close"
                            iconSize: 12
                            color: "#ffffff"
                        }
                        MouseArea {
                            id: delMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                if (!slotCell.pendingDelete) {
                                    slotCell.pendingDelete = true;
                                    return;
                                }
                                slotCell.pendingDelete = false;
                                themeSlotsSection.slotAction("delete", slotCell.index + 1);
                            }
                        }
                    }
                }
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
