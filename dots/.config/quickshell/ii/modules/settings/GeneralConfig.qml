import QtQuick
import Quickshell
import Quickshell.Io
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

ContentPage {
    id: generalRoot
    forceWidth: true

    property int mixerUiEpoch: 0
    /** 0 playback streams, 1 record streams, 2 output devices, 3 input devices */
    property int mixerPanelTab: 0

    readonly property list<var> mixerPanelMainNodes: {
        mixerUiEpoch
        mixerPanelTab
        switch (mixerPanelTab) {
        case 0:
            return Audio.outputAppNodes
        case 1:
            return Audio.inputAppNodes
        case 2:
            return Audio.outputDevices
        case 3:
            return Audio.inputDevices
        default:
            return []
        }
    }
    readonly property list<string> mixerPanelOrphans: {
        mixerUiEpoch
        mixerPanelTab
        Config.options.audio.volumeMixer.hiddenMixerPlaybackStreamKeys
        Config.options.audio.volumeMixer.hiddenMixerRecordStreamKeys
        Config.options.audio.volumeMixer.hiddenMixerOutputDeviceKeys
        Config.options.audio.volumeMixer.hiddenMixerInputDeviceKeys
        switch (mixerPanelTab) {
        case 0:
            return Audio.orphanStreamHideKeys(true)
        case 1:
            return Audio.orphanStreamHideKeys(false)
        case 2:
            return Audio.orphanDeviceHideKeys(true)
        case 3:
            return Audio.orphanDeviceHideKeys(false)
        default:
            return []
        }
    }

    Process {
        id: translationProc
        property string locale: ""
        command: [Directories.aiTranslationScriptPath, translationProc.locale]
    }

    ContentSection {
        icon: "volume_up"
        title: Translation.tr("Audio")

        ConfigSwitch {
            buttonIcon: "hearing"
            text: Translation.tr("Earbang protection")
            checked: Config.options.audio.protection.enable
            onCheckedChanged: {
                Config.options.audio.protection.enable = checked;
            }
            StyledToolTip {
                text: Translation.tr("Prevents abrupt increments and restricts volume limit")
            }
        }
        ConfigRow {
            enabled: Config.options.audio.protection.enable
            ConfigSpinBox {
                icon: "arrow_warm_up"
                text: Translation.tr("Max allowed increase")
                value: Config.options.audio.protection.maxAllowedIncrease
                from: 0
                to: 100
                stepSize: 2
                onValueChanged: {
                    Config.options.audio.protection.maxAllowedIncrease = value;
                }
            }
            ConfigSpinBox {
                icon: "vertical_align_top"
                text: Translation.tr("Volume limit")
                value: Config.options.audio.protection.maxAllowed
                from: 0
                to: 154 // pavucontrol allows up to 153%
                stepSize: 2
                onValueChanged: {
                    Config.options.audio.protection.maxAllowed = value;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Volume mixer")
            tooltip: Translation.tr("Hide streams or devices from the bar and quick-panel mixers. Stream rules use app/binary identity; devices use PipeWire serial or node name so they survive restarts. The default output/input device always stays visible.")

            ConfigSwitch {
                buttonIcon: "subtitles"
                text: Translation.tr("Show application name with media title")
                checked: Config.options.audio.volumeMixer.showAppNameWithMedia ?? true
                onCheckedChanged: {
                    Config.options.audio.volumeMixer.showAppNameWithMedia = checked;
                }
                StyledToolTip {
                    text: Translation.tr("When off, stream rows show only the media title (e.g. \"Spotify\") instead of \"spotify • Spotify\".")
                }
            }
            ConfigSwitch {
                buttonIcon: "compare_arrows"
                text: Translation.tr("Omit app name when it matches the media title")
                checked: Config.options.audio.volumeMixer.hideAppNameWhenSameAsMedia ?? true
                onCheckedChanged: {
                    Config.options.audio.volumeMixer.hideAppNameWhenSameAsMedia = checked;
                }
                StyledToolTip {
                    text: Translation.tr("When showing app + media, use a single label if both are the same (e.g. only \"Spotify\" instead of \"Spotify • Spotify\").")
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: streamMixerCardCol.implicitHeight + 24
                color: Appearance.colors.colLayer1
                radius: Appearance.rounding.small
                border.width: 1
                border.color: Appearance.m3colors.m3outlineVariant

                ColumnLayout {
                    id: streamMixerCardCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 12
                    spacing: 12

                    // Row 1: mode + refresh (single horizontal strip)
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        ConfigSelectionArray {
                            Layout.fillWidth: true
                            currentValue: generalRoot.mixerPanelTab
                            onSelected: newValue => {
                                generalRoot.mixerPanelTab = newValue;
                            }
                            options: [
                                {
                                    displayName: Translation.tr("Playback"),
                                    icon: "media_output",
                                    value: 0
                                },
                                {
                                    displayName: Translation.tr("Recording"),
                                    icon: "mic",
                                    value: 1
                                },
                                {
                                    displayName: Translation.tr("Output devices"),
                                    icon: "speaker",
                                    value: 2
                                },
                                {
                                    displayName: Translation.tr("Input devices"),
                                    icon: "mic_external_on",
                                    value: 3
                                }
                            ]
                        }

                        RippleButton {
                            Layout.alignment: Qt.AlignVCenter
                            implicitWidth: 40
                            implicitHeight: 40
                            buttonRadius: Appearance.rounding.full
                            colBackground: Appearance.colors.colLayer2
                            onClicked: generalRoot.mixerUiEpoch++
                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                text: "sync"
                                iconSize: 22
                                color: Appearance.colors.colOnLayer2
                            }
                            StyledToolTip {
                                text: Translation.tr("Refresh list")
                            }
                        }
                    }

                    // Row 2: list OR empty (never stacked - no overlay)
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 280
                        color: Appearance.colors.colLayer0
                        radius: Appearance.rounding.small
                        border.width: 1
                        border.color: Appearance.m3colors.m3outlineVariant

                        StackLayout {
                            anchors.fill: parent
                            anchors.margins: 6
                            currentIndex: generalRoot.mixerPanelMainNodes.length > 0 ? 0 : 1

                            ListView {
                                id: streamListView
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true
                                spacing: 0
                                model: ScriptModel {
                                    values: generalRoot.mixerPanelMainNodes
                                }
                                delegate: Column {
                                    required property int index
                                    required property var modelData
                                    width: streamListView.width
                                    spacing: 0

                                    Loader {
                                        width: parent.width
                                        active: generalRoot.mixerPanelTab < 2
                                        sourceComponent: StreamMixerHideRow {
                                            node: modelData
                                            isPlayback: generalRoot.mixerPanelTab === 0
                                        }
                                    }
                                    Loader {
                                        width: parent.width
                                        active: generalRoot.mixerPanelTab >= 2
                                        sourceComponent: DeviceMixerHideRow {
                                            node: modelData
                                            isOutputDevice: generalRoot.mixerPanelTab === 2
                                        }
                                    }
                                    Rectangle {
                                        width: parent.width
                                        height: 1
                                        visible: index < streamListView.count - 1
                                        color: Appearance.m3colors.m3outlineVariant
                                    }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                spacing: 10

                                Item {
                                    Layout.fillHeight: true
                                    Layout.minimumHeight: 8
                                }
                                MaterialSymbol {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: generalRoot.mixerPanelTab < 2 ? "graphic_eq" : "speaker_group"
                                    iconSize: 36
                                    color: Appearance.colors.colSubtext
                                    opacity: 0.45
                                }
                                StyledText {
                                    Layout.fillWidth: true
                                    horizontalAlignment: Text.AlignHCenter
                                    wrapMode: Text.Wrap
                                    text: generalRoot.mixerPanelTab < 2 ? Translation.tr("No streams right now - start audio and tap refresh.") : Translation.tr("No devices listed - check PipeWire and tap refresh.")
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    color: Appearance.colors.colSubtext
                                }
                                Item {
                                    Layout.fillHeight: true
                                    Layout.minimumHeight: 8
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: generalRoot.mixerPanelOrphans.length > 0
                        spacing: 6
                        StyledText {
                            Layout.fillWidth: true
                            text: Translation.tr("Still hidden (not connected) - remove if you change your mind:")
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                            wrapMode: Text.Wrap
                        }
                        Repeater {
                            model: ScriptModel {
                                values: generalRoot.mixerPanelOrphans
                            }
                            delegate: RowLayout {
                                required property var modelData
                                spacing: 6
                                Layout.fillWidth: true
                                StyledText {
                                    Layout.fillWidth: true
                                    text: String(modelData)
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    color: Appearance.colors.colOnLayer1
                                    elide: Text.ElideMiddle
                                }
                                RippleButton {
                                    implicitHeight: 32
                                    implicitWidth: 32
                                    buttonRadius: Appearance.rounding.full
                                    colBackground: Appearance.colors.colLayer2
                                    onClicked: {
                                        const k = String(modelData);
                                        const t = generalRoot.mixerPanelTab;
                                        if (t < 2)
                                            Audio.removeStreamHideKey(k, t === 0);
                                        else
                                            Audio.removeDeviceHideKey(k, t === 2);
                                    }
                                    contentItem: MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: "close"
                                        iconSize: 18
                                        color: Appearance.colors.colOnLayer2
                                    }
                                    StyledToolTip {
                                        text: Translation.tr("Stop hiding this entry")
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    component StreamMixerHideRow: ColumnLayout {
        required property var node
        required property bool isPlayback
        property int _hideSwitchGuard: 0
        spacing: 6
        Layout.fillWidth: true
        Layout.leftMargin: 4
        Layout.rightMargin: 4
        Layout.topMargin: 6
        Layout.bottomMargin: 6

        readonly property string streamPersistKey: Audio.streamPersistHideKey(node)

        readonly property string streamSubline: {
            const m = node?.properties?.["media.name"];
            if (m !== undefined && m !== null && String(m).length > 0)
                return String(m);
            return streamPersistKey.length > 0 ? streamPersistKey : "";
        }

        PwObjectTracker {
            objects: [node]
        }

        StyledText {
            Layout.fillWidth: true
            text: Audio.appNodeDisplayName(node)
            font.pixelSize: Appearance.font.pixelSize.normal
            elide: Text.ElideRight
            color: Appearance.colors.colOnLayer1
        }

        StyledText {
            Layout.fillWidth: true
            visible: streamSubline.length > 0
            text: streamSubline
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
            elide: Text.ElideRight
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            MaterialSymbol {
                Layout.alignment: Qt.AlignVCenter
                text: "visibility_off"
                iconSize: 20
                color: Appearance.colors.colSubtext
            }

            StyledText {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                text: Translation.tr("Hide from mixer")
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
                wrapMode: Text.Wrap
            }

            Item {
                Layout.preferredWidth: 52
                Layout.preferredHeight: 34
                Layout.alignment: Qt.AlignVCenter
                StyledSwitch {
                    anchors.centerIn: parent
                    enabled: streamPersistKey.length > 0
                    checked: Audio.streamMixerIsHidden(node, isPlayback, true, streamPersistKey)
                    onCheckedChanged: {
                        if (_hideSwitchGuard > 0)
                            return;
                        const wantHidden = checked;
                        const curHidden = Audio.streamMixerIsHidden(node, isPlayback, true, streamPersistKey);
                        if (wantHidden === curHidden)
                            return;
                        _hideSwitchGuard++;
                        Audio.setStreamHiddenForMixer(node, isPlayback, wantHidden);
                        Qt.callLater(() => {
                            _hideSwitchGuard--;
                        });
                    }
                }
            }
        }
    }

    component DeviceMixerHideRow: ColumnLayout {
        required property var node
        required property bool isOutputDevice
        property int _hideSwitchGuard: 0
        spacing: 6
        Layout.fillWidth: true
        Layout.leftMargin: 4
        Layout.rightMargin: 4
        Layout.topMargin: 6
        Layout.bottomMargin: 6

        readonly property var devKeys: Audio.collectDeviceHideKeys(node)
        readonly property string devKey: devKeys.length > 0 ? devKeys[0] : Audio.mixerDeviceStableId(node)
        readonly property bool isDefaultDevice: {
            const def = isOutputDevice ? Pipewire.defaultAudioSink : Pipewire.defaultAudioSource;
            return !!(def && node && def.id !== undefined && node.id !== undefined && String(def.id) === String(node.id));
        }

        PwObjectTracker {
            objects: [node]
        }

        StyledText {
            Layout.fillWidth: true
            text: Audio.friendlyDeviceName(node)
            font.pixelSize: Appearance.font.pixelSize.normal
            elide: Text.ElideRight
            color: Appearance.colors.colOnLayer1
        }

        StyledText {
            Layout.fillWidth: true
            visible: devKey.length > 0
            text: isDefaultDevice ? Translation.tr("Default device - always shown in mixers") : devKey
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
            elide: Text.ElideRight
            wrapMode: Text.Wrap
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            MaterialSymbol {
                Layout.alignment: Qt.AlignVCenter
                text: "visibility_off"
                iconSize: 20
                color: Appearance.colors.colSubtext
            }

            StyledText {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                text: Translation.tr("Hide from mixer")
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
                wrapMode: Text.Wrap
            }

            Item {
                Layout.preferredWidth: 52
                Layout.preferredHeight: 34
                Layout.alignment: Qt.AlignVCenter
                StyledSwitch {
                    anchors.centerIn: parent
                    enabled: devKeys.length > 0 && !isDefaultDevice
                    checked: Audio.deviceMixerIsHidden(node, isOutputDevice)
                    onCheckedChanged: {
                        if (_hideSwitchGuard > 0)
                            return;
                        const wantHidden = checked;
                        const curHidden = Audio.deviceMixerIsHidden(node, isOutputDevice);
                        if (wantHidden === curHidden)
                            return;
                        _hideSwitchGuard++;
                        Audio.setDeviceHiddenForMixer(node, isOutputDevice, wantHidden);
                        Qt.callLater(() => {
                            _hideSwitchGuard--;
                        });
                    }
                }
            }
        }
    }

    ContentSection {
        icon: "battery_android_full"
        title: Translation.tr("Battery")

        ConfigRow {
            uniform: true
            ConfigSpinBox {
                icon: "warning"
                text: Translation.tr("Low warning")
                value: Config.options.battery.low
                from: 0
                to: 100
                stepSize: 5
                onValueChanged: {
                    Config.options.battery.low = value;
                }
            }
            ConfigSpinBox {
                icon: "dangerous"
                text: Translation.tr("Critical warning")
                value: Config.options.battery.critical
                from: 0
                to: 100
                stepSize: 5
                onValueChanged: {
                    Config.options.battery.critical = value;
                }
            }
        }
        ConfigRow {
            uniform: false
            Layout.fillWidth: false
            ConfigSwitch {
                buttonIcon: "pause"
                text: Translation.tr("Automatic suspend")
                checked: Config.options.battery.automaticSuspend
                onCheckedChanged: {
                    Config.options.battery.automaticSuspend = checked;
                }
                StyledToolTip {
                    text: Translation.tr("Automatically suspends the system when battery is low")
                }
            }
            ConfigSpinBox {
                enabled: Config.options.battery.automaticSuspend
                text: Translation.tr("at")
                value: Config.options.battery.suspend
                from: 0
                to: 100
                stepSize: 5
                onValueChanged: {
                    Config.options.battery.suspend = value;
                }
            }
        }
        ConfigRow {
            uniform: true
            ConfigSpinBox {
                icon: "charger"
                text: Translation.tr("Full warning")
                value: Config.options.battery.full
                from: 0
                to: 101
                stepSize: 5
                onValueChanged: {
                    Config.options.battery.full = value;
                }
            }
        }
    }

    ContentSection {
        icon: "language"
        title: Translation.tr("Language")

        ContentSubsection {
            title: Translation.tr("Interface Language")
            tooltip: Translation.tr("Select the language for the user interface.\n\"Auto\" will use your system's locale.")

            StyledComboBox {
                id: languageSelector
                buttonIcon: "language"
                textRole: "displayName"

                model: [
                    {
                        displayName: Translation.tr("Auto (System)"),
                        value: "auto"
                    },
                    ...Translation.allAvailableLanguages.map(lang => {
                        return {
                            displayName: lang,
                            value: lang
                        };
                    })]

                currentIndex: {
                    const index = model.findIndex(item => item.value === Config.options.language.ui);
                    return index !== -1 ? index : 0;
                }

                onActivated: index => {
                    Config.options.language.ui = model[index].value;
                }
            }
        }
        ContentSubsection {
            title: Translation.tr("Generate translation with Gemini")
            tooltip: Translation.tr("You'll need to enter your Gemini API key first.\nType /key on the sidebar for instructions.")

            ConfigRow {
                MaterialTextArea {
                    id: localeInput
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Locale code, e.g. fr_FR, de_DE, zh_CN...")
                    text: Config.options.language.ui === "auto" ? Qt.locale().name : Config.options.language.ui
                }
                RippleButtonWithIcon {
                    id: generateTranslationBtn
                    Layout.fillHeight: true
                    nerdIcon: ""
                    enabled: !translationProc.running || (translationProc.locale !== localeInput.text.trim())
                    mainText: enabled ? Translation.tr("Generate\nTypically takes 2 minutes") : Translation.tr("Generating...\nDon't close this window!")
                    onClicked: {
                        translationProc.locale = localeInput.text.trim();
                        translationProc.running = false;
                        translationProc.running = true;
                    }
                }
            }
        }
    }

    ContentSection {
        icon: "rule"
        title: Translation.tr("Policies")

        ConfigRow {

            // AI policy
            ColumnLayout {
                ContentSubsectionLabel {
                    text: Translation.tr("AI")
                }

                ConfigSelectionArray {
                    currentValue: Config.options.policies.ai
                    onSelected: newValue => {
                        Config.options.policies.ai = newValue;
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
                            displayName: Translation.tr("Local only"),
                            icon: "sync_saved_locally",
                            value: 2
                        }
                    ]
                }
            }

            // Weeb policy
            ColumnLayout {

                ContentSubsectionLabel {
                    text: Translation.tr("Weeb")
                }

                ConfigSelectionArray {
                    currentValue: Config.options.policies.weeb
                    onSelected: newValue => {
                        Config.options.policies.weeb = newValue;
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
                            displayName: Translation.tr("Closet"),
                            icon: "ev_shadow",
                            value: 2
                        }
                    ]
                }
            }
        }
    }

    ContentSection {
        icon: "notification_sound"
        title: Translation.tr("Sounds")
        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "battery_android_full"
                text: Translation.tr("Battery")
                checked: Config.options.sounds.battery
                onCheckedChanged: {
                    Config.options.sounds.battery = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "av_timer"
                text: Translation.tr("Pomodoro")
                checked: Config.options.sounds.pomodoro
                onCheckedChanged: {
                    Config.options.sounds.pomodoro = checked;
                }
            }
        }
        ContentSubsection {
            title: Translation.tr("Startup sound")

            ConfigSwitch {
                buttonIcon: "play_circle"
                text: Translation.tr("Enable startup sound")
                checked: Config.options.sounds.startup.enable ?? true
                onCheckedChanged: {
                    Config.options.sounds.startup.enable = checked;
                }
            }

            MaterialTextArea {
                Layout.fillWidth: true
                enabled: Config.options.sounds.startup.enable ?? true
                placeholderText: Translation.tr("Startup sound file path")
                text: Config.options.sounds.startup.path ?? "~/.local/share/sounds/ii/stereo/startup.oga"
                wrapMode: TextEdit.Wrap
                onTextChanged: {
                    Config.options.sounds.startup.path = text;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Notification sound")

            ConfigSwitch {
                buttonIcon: "notifications_active"
                text: Translation.tr("Enable notification sound")
                checked: Config.options.sounds.notification.enable ?? true
                onCheckedChanged: {
                    Config.options.sounds.notification.enable = checked;
                }
            }

            MaterialTextArea {
                Layout.fillWidth: true
                enabled: Config.options.sounds.notification.enable ?? true
                placeholderText: Translation.tr("Notification sound file path")
                text: Config.options.sounds.notification.path ?? "~/.local/share/sounds/ii/stereo/notify.oga"
                wrapMode: TextEdit.Wrap
                onTextChanged: {
                    Config.options.sounds.notification.path = text;
                }
            }

            MaterialTextArea {
                id: mutedNotificationAppsField
                Layout.fillWidth: true
                enabled: Config.options.sounds.notification.enable ?? true
                placeholderText: Translation.tr("Muted apps (one per line)")
                property bool _skipSync: false
                text: mutedNotificationAppsText
                wrapMode: TextEdit.Wrap
                onTextChanged: {
                    if (_skipSync) return
                    _skipSync = true
                    const lines = text.split(/\n|,/)
                    const newList = []
                    const seen = {}
                    for (let i = 0; i < lines.length; i++) {
                        const app = lines[i].trim()
                        const key = app.toLowerCase()
                        if (app.length > 0 && !seen[key]) {
                            seen[key] = true
                            newList.push(app)
                        }
                    }
                    Config.options.sounds.notification.mutedApps = newList
                    Qt.callLater(function() { _skipSync = false })
                }
            }
        }
    }

    ContentSection {
        icon: "nest_clock_farsight_analog"
        title: Translation.tr("Time")

        ConfigSwitch {
            buttonIcon: "pace"
            text: Translation.tr("Second precision")
            checked: Config.options.time.secondPrecision
            onCheckedChanged: {
                Config.options.time.secondPrecision = checked;
            }
            StyledToolTip {
                text: Translation.tr("Enable if you want clocks to show seconds accurately")
            }
        }

        ContentSubsection {
            title: Translation.tr("Format")
            tooltip: ""

            ConfigSelectionArray {
                currentValue: Config.options.time.format
                onSelected: newValue => {
                    if (newValue === "hh:mm") {
                        Quickshell.execDetached(["bash", "-c", `sed -i 's/\\TIME12\\b/TIME/' '${FileUtils.trimFileProtocol(Directories.config)}/hypr/hyprlock.conf'`]);
                    } else {
                        Quickshell.execDetached(["bash", "-c", `sed -i 's/\\TIME\\b/TIME12/' '${FileUtils.trimFileProtocol(Directories.config)}/hypr/hyprlock.conf'`]);
                    }

                    Config.options.time.format = newValue;
                }
                options: [
                    {
                        displayName: Translation.tr("24h"),
                        value: "hh:mm"
                    },
                    {
                        displayName: Translation.tr("12h am/pm"),
                        value: "h:mm ap"
                    },
                    {
                        displayName: Translation.tr("12h AM/PM"),
                        value: "h:mm AP"
                    },
                ]
            }
        }
    }

    property string mutedNotificationAppsText: {
        try {
            const apps = Config.options?.sounds?.notification?.mutedApps ?? []
            const out = []
            for (let i = 0; i < apps.length; i++) {
                const app = (apps[i] ?? "").toString().trim()
                if (app.length > 0) out.push(app)
            }
            return out.join("\n")
        } catch (e) {
            return ""
        }
    }

    ContentSection {
        icon: "work_alert"
        title: Translation.tr("Work safety")

        ConfigSwitch {
            buttonIcon: "assignment"
            text: Translation.tr("Hide clipboard images copied from sussy sources")
            checked: Config.options.workSafety.enable.clipboard
            onCheckedChanged: {
                Config.options.workSafety.enable.clipboard = checked;
            }
        }
        ConfigSwitch {
            buttonIcon: "wallpaper"
            text: Translation.tr("Hide sussy/anime wallpapers")
            checked: Config.options.workSafety.enable.wallpaper
            onCheckedChanged: {
                Config.options.workSafety.enable.wallpaper = checked;
            }
        }
    }
}
