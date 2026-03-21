import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: rootPage
    forceWidth: true

    ContentSection {
        icon: "neurology"
        title: Translation.tr("AI")

        MaterialTextArea {
            Layout.fillWidth: true
            placeholderText: Translation.tr("System prompt")
            text: Config.options.ai.systemPrompt
            wrapMode: TextEdit.Wrap
            onTextChanged: {
                Qt.callLater(() => {
                    Config.options.ai.systemPrompt = text;
                });
            }
        }
    }

    ContentSection {
        icon: "music_cast"
        title: Translation.tr("Music Recognition")

        ConfigSpinBox {
            icon: "timer_off"
            text: Translation.tr("Total duration timeout (s)")
            value: Config.options.musicRecognition.timeout
            from: 10
            to: 100
            stepSize: 2
            onValueChanged: {
                Config.options.musicRecognition.timeout = value;
            }
        }
        ConfigSpinBox {
            icon: "av_timer"
            text: Translation.tr("Polling interval (s)")
            value: Config.options.musicRecognition.interval
            from: 2
            to: 10
            stepSize: 1
            onValueChanged: {
                Config.options.musicRecognition.interval = value;
            }
        }
    }

    ContentSection {
        icon: "cell_tower"
        title: Translation.tr("Networking")

        MaterialTextArea {
            Layout.fillWidth: true
            placeholderText: Translation.tr("User agent (for services that require it)")
            text: Config.options.networking.userAgent
            wrapMode: TextEdit.Wrap
            onTextChanged: {
                Config.options.networking.userAgent = text;
            }
        }
    }

    ContentSection {
        icon: "memory"
        title: Translation.tr("Resources")

        ConfigSpinBox {
            icon: "av_timer"
            text: Translation.tr("Polling interval (ms)")
            value: Config.options.resources.updateInterval
            from: 100
            to: 10000
            stepSize: 100
            onValueChanged: {
                Config.options.resources.updateInterval = value;
            }
        }
        
    }

    ContentSection {
        icon: "file_open"
        title: Translation.tr("Save paths")

        MaterialTextArea {
            Layout.fillWidth: true
            placeholderText: Translation.tr("Video Recording Path")
            text: Config.options.screenRecord.savePath
            wrapMode: TextEdit.Wrap
            onTextChanged: {
                Config.options.screenRecord.savePath = text;
            }
        }
        
        MaterialTextArea {
            Layout.fillWidth: true
            placeholderText: Translation.tr("Screenshot Path (leave empty to just copy)")
            text: Config.options.screenSnip.savePath
            wrapMode: TextEdit.Wrap
            onTextChanged: {
                Config.options.screenSnip.savePath = text;
            }
        }
    }

    ContentSection {
        icon: "videocam"
        title: Translation.tr("Screen recording")

        ContentSubsection {
            id: audioDevicesSubsection
            title: Translation.tr("Audio")

            property var desktopSources: []
            property var micSources: []

            Process {
                id: pactlSourcesProc
                running: true
                command: ["pactl", "list", "sources"]
                stdout: StdioCollector {
                    id: pactlCollector
                    onStreamFinished: {
                        const output = pactlCollector.text || "";
                        const blocks = output.split(/Source #\d+/).slice(1);
                        let monitors = [];
                        let inputs = [];
                        for (const block of blocks) {
                            let name = "";
                            let description = "";
                            for (const line of block.split("\n")) {
                                const mName = line.match(/^\s+Name:\s+(.+)/);
                                const mDesc = line.match(/^\s+Description:\s+(.+)/);
                                if (mName) name = mName[1].trim();
                                if (mDesc) description = mDesc[1].trim();
                            }
                            if (!name) continue;
                            let displayName = description || name;
                            displayName = displayName.replace(/^Monitor of\s+/i, "");
                            const entry = { displayName: displayName, value: name };
                            if (name.includes(".monitor")) {
                                monitors.push(entry);
                            } else {
                                inputs.push(entry);
                            }
                        }
                        const defaultOpt = { displayName: Translation.tr("Default (auto)"), value: "" };
                        audioDevicesSubsection.desktopSources = [defaultOpt].concat(monitors);
                        audioDevicesSubsection.micSources = [defaultOpt].concat(inputs);
                    }
                }
            }

            ConfigRow {
                uniform: true
                Layout.fillWidth: true
                ConfigSwitch {
                    buttonIcon: "speaker"
                    text: Translation.tr("Record desktop audio")
                    checked: Config.options.screenRecord.recordDesktopAudio ?? true
                    onCheckedChanged: Config.options.screenRecord.recordDesktopAudio = checked
                }
                ConfigSwitch {
                    buttonIcon: "mic"
                    text: Translation.tr("Record microphone")
                    checked: Config.options.screenRecord.recordMicAudio ?? false
                    onCheckedChanged: Config.options.screenRecord.recordMicAudio = checked
                }
            }
            StyledText {
                text: Translation.tr("Desktop audio (system output)")
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colOnSecondaryContainer
            }
            StyledComboBox {
                Layout.fillWidth: true
                buttonIcon: "speaker"
                textRole: "displayName"
                model: audioDevicesSubsection.desktopSources
                currentIndex: {
                    if (!model || model.length === 0) return 0;
                    const val = Config.options.screenRecord.desktopAudioSource ?? "";
                    const idx = model.findIndex(item => item.value === val);
                    return idx >= 0 ? idx : 0;
                }
                onActivated: index => {
                    Config.options.screenRecord.desktopAudioSource = model[index].value;
                }
            }
            StyledText {
                text: Translation.tr("Microphone (input)")
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colOnSecondaryContainer
            }
            StyledComboBox {
                Layout.fillWidth: true
                buttonIcon: "mic"
                textRole: "displayName"
                model: audioDevicesSubsection.micSources
                currentIndex: {
                    if (!model || model.length === 0) return 0;
                    const val = Config.options.screenRecord.micAudioSource ?? "";
                    const idx = model.findIndex(item => item.value === val);
                    return idx >= 0 ? idx : 0;
                }
                onActivated: index => {
                    Config.options.screenRecord.micAudioSource = model[index].value;
                }
            }
        }
        // Video encoder, framerate, bitrate, presets: use gpu-screen-recorder defaults (negligible perf impact)
        // ContentSubsection {
        //     title: Translation.tr("Video")
        //     ...
        // }
    }

    ContentSection {
        icon: "search"
        title: Translation.tr("Search")

        ContentSubsection {
            title: Translation.tr("App launcher")
            tooltip: Translation.tr("Exact: name only. Normal: name + genericName + comment. Sloppy: + keywords + categories")
            ConfigSelectionArray {
                Layout.fillWidth: false
                currentValue: Config.options?.search?.mode ?? "exact"
                onSelected: newValue => {
                    if (Config.options && Config.options.search)
                        Config.options.search.mode = newValue;
                }
                options: [
                    { icon: "filter_alt", value: "exact", displayName: Translation.tr("Exact") },
                    { icon: "search", value: "normal", displayName: Translation.tr("Normal") },
                    { icon: "manage_search", value: "sloppy", displayName: Translation.tr("Sloppy") }
                ]
            }
            ConfigRow {
                uniform: false
                Layout.fillWidth: false
                ConfigSwitch {
                    buttonIcon: "linear_scale"
                    text: Translation.tr("Use Levenshtein algorithm")
                    checked: Config.options.search.sloppy
                    onCheckedChanged: Config.options.search.sloppy = checked
                    StyledToolTip {
                        text: Translation.tr("Better for typos, but may give odd results with acronyms (e.g. \"GIMP\")")
                    }
                }
                Item {
                    implicitWidth: fuzzySpinBox.implicitWidth
                    implicitHeight: fuzzySpinBox.implicitHeight
                    ConfigSpinBox {
                        id: fuzzySpinBox
                        anchors.fill: parent
                        icon: "percent"
                        text: Translation.tr("Fuzzy threshold")
                        value: Config.options.search.fuzzyThreshold ?? 25
                        from: 0
                        to: 100
                        stepSize: 5
                        onValueChanged: Config.options.search.fuzzyThreshold = value
                    }
                    MouseArea {
                        id: fuzzyHoverArea
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton
                        StyledToolTip {
                            extraVisibleCondition: false
                            alternativeVisibleCondition: fuzzyHoverArea.containsMouse
                            text: Translation.tr("Minimum match score for Normal and Sloppy (0-100). Higher = stricter, fewer false positives.")
                        }
                    }
                }
            }
            ConfigSwitch {
                buttonIcon: "auto_awesome"
                text: Translation.tr("Smart Search")
                checked: Config.options.search.smartSearch ?? false
                onCheckedChanged: Config.options.search.smartSearch = checked
                StyledToolTip {
                    text: Translation.tr("Learns which app you open for similar queries/result sets and promotes it in future searches.")
                }
            }
            RippleButtonWithIcon {
                materialIcon: "restart_alt"
                materialIconFill: false
                mainText: Translation.tr("Reset Smart Search History")
                buttonRadius: Appearance.rounding.normal
                implicitHeight: 40
                horizontalPadding: 14
                colBackground: Appearance.colors.colSurfaceContainerHigh
                colBackgroundHover: Appearance.colors.colSurfaceContainerHighest
                colRipple: Appearance.colors.colSurfaceContainerHighest
                onClicked: resetSmartSearchPopup.open()
            }
        }

        ContentSubsection {
            title: Translation.tr("Prefixes")
            ConfigRow {
                uniform: true
                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Action")
                    text: Config.options.search.prefix.action
                    wrapMode: TextEdit.Wrap
                    onTextChanged: {
                        Config.options.search.prefix.action = text;
                    }
                }
                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Clipboard")
                    text: Config.options.search.prefix.clipboard
                    wrapMode: TextEdit.Wrap
                    onTextChanged: {
                        Config.options.search.prefix.clipboard = text;
                    }
                }
                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Emojis")
                    text: Config.options.search.prefix.emojis
                    wrapMode: TextEdit.Wrap
                    onTextChanged: {
                        Config.options.search.prefix.emojis = text;
                    }
                }
            }

            ConfigRow {
                uniform: true
                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Math")
                    text: Config.options.search.prefix.math
                    wrapMode: TextEdit.Wrap
                    onTextChanged: {
                        Config.options.search.prefix.math = text;
                    }
                }
                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Shell command")
                    text: Config.options.search.prefix.shellCommand
                    wrapMode: TextEdit.Wrap
                    onTextChanged: {
                        Config.options.search.prefix.shellCommand = text;
                    }
                }
                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Web search")
                    text: Config.options.search.prefix.webSearch
                    wrapMode: TextEdit.Wrap
                    onTextChanged: {
                        Config.options.search.prefix.webSearch = text;
                    }
                }
                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("All apps")
                    text: Config.options.search.prefix.allApps
                    wrapMode: TextEdit.Wrap
                    onTextChanged: {
                        Config.options.search.prefix.allApps = text;
                    }
                }
            }
        }
        ContentSubsection {
            title: Translation.tr("Web search")
            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("Base URL")
                text: Config.options.search.engineBaseUrl
                wrapMode: TextEdit.Wrap
                onTextChanged: {
                    Config.options.search.engineBaseUrl = text;
                }
            }
        }
    }

    // There's no update indicator in ii for now so we shouldn't show this yet
    // ContentSection {
    //     icon: "deployed_code_update"
    //     title: Translation.tr("System updates (Arch only)")

    //     ConfigSwitch {
    //         text: Translation.tr("Enable update checks")
    //         checked: Config.options.updates.enableCheck
    //         onCheckedChanged: {
    //             Config.options.updates.enableCheck = checked;
    //         }
    //     }

    //     ConfigSpinBox {
    //         icon: "av_timer"
    //         text: Translation.tr("Check interval (mins)")
    //         value: Config.options.updates.checkInterval
    //         from: 60
    //         to: 1440
    //         stepSize: 60
    //         onValueChanged: {
    //             Config.options.updates.checkInterval = value;
    //         }
    //     }
    // }

    ContentSection {
        icon: "weather_mix"
        title: Translation.tr("Weather")
        ConfigSelectionArray {
            Layout.fillWidth: false
            currentValue: Config.options?.bar?.weather?.provider || "wttr"
            onSelected: newValue => {
                if (Config.options && Config.options.bar && Config.options.bar.weather)
                    Config.options.bar.weather.provider = newValue;
            }
            options: [
                {
                    displayName: "wttr.in",
                    icon: "cloud",
                    value: "wttr"
                },
                {
                    displayName: "Open-Meteo",
                    icon: "wb_sunny",
                    value: "open"
                }
            ]
        }
        ConfigRow {
            ConfigSwitch {
                buttonIcon: "assistant_navigation"
                text: Translation.tr("Enable GPS based location")
                checked: Config.options.bar.weather.enableGPS
                onCheckedChanged: {
                    Config.options.bar.weather.enableGPS = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "thermometer"
                text: Translation.tr("Fahrenheit unit")
                checked: Config.options.bar.weather.useUSCS
                onCheckedChanged: {
                    Config.options.bar.weather.useUSCS = checked;
                }
                StyledToolTip {
                    text: Translation.tr("It may take a few seconds to update")
                }
            }
        }
        
        MaterialTextArea {
            Layout.fillWidth: true
            placeholderText: Translation.tr("City name")
            text: Config.options.bar.weather.city
            wrapMode: TextEdit.Wrap
            onTextChanged: {
                Config.options.bar.weather.city = text;
            }
        }
        ConfigSpinBox {
            icon: "av_timer"
            text: Translation.tr("Polling interval (m)")
            value: Config.options.bar.weather.fetchInterval
            from: 5
            to: 50
            stepSize: 5
            onValueChanged: {
                Config.options.bar.weather.fetchInterval = value;
            }
        }
    }

    Popup {
        id: resetSmartSearchPopup
        parent: rootPage.Window?.contentItem ?? rootPage
        modal: true
        dim: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        width: 420
        padding: 20
        x: parent ? Math.max(0, (parent.width - width) / 2) : 100
        y: parent ? Math.max(0, (parent.height - height) / 2) : 100

        Overlay.modal: Rectangle {
            color: "#CC000000"
        }

        background: Rectangle {
            color: Appearance.colors.colLayer1
            radius: Appearance.rounding.large
            border.width: 1
            border.color: Appearance.colors.colOutline
        }

        contentItem: ColumnLayout {
            spacing: 14

            StyledText {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: Translation.tr("Are you sure you want to reset Smart Search history?")
                font.pixelSize: Appearance.font.pixelSize.large
                color: Appearance.colors.colOnSecondaryContainer
            }

            StyledText {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: Translation.tr("This will clear all learned app ranking preferences.")
                color: Appearance.colors.colSubtext
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Item {
                    Layout.fillWidth: true
                }
                RippleButton {
                    Layout.preferredWidth: 90
                    buttonRadius: Appearance.rounding.small
                    onClicked: resetSmartSearchPopup.close()
                    contentItem: StyledText {
                        anchors.centerIn: parent
                        text: Translation.tr("No")
                        color: Appearance.colors.colOnSecondaryContainer
                    }
                }
                RippleButton {
                    Layout.preferredWidth: 90
                    buttonRadius: Appearance.rounding.small
                    colBackground: Appearance.colors.colPrimary
                    colBackgroundHover: Appearance.colors.colPrimaryHover
                    onClicked: {
                        Persistent.states.search.appClickStats = [];
                        resetSmartSearchPopup.close();
                        var q = LauncherSearch.query;
                        LauncherSearch.query = q + "\u200B";
                        LauncherSearch.query = q;
                    }
                    contentItem: StyledText {
                        anchors.centerIn: parent
                        text: Translation.tr("Yes")
                        color: Appearance.colors.colOnPrimary
                    }
                }
            }
        }
    }
}
