import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
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
        icon: "search"
        title: Translation.tr("Search")

        ConfigSwitch {
            text: Translation.tr("Use Levenshtein distance-based algorithm instead of fuzzy")
            checked: Config.options.search.sloppy
            onCheckedChanged: {
                Config.options.search.sloppy = checked;
            }
            StyledToolTip {
                text: Translation.tr("Could be better if you make a ton of typos,\nbut results can be weird and might not work with acronyms\n(e.g. \"GIMP\" might not give you the paint program)")
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

    ContentSection {
        icon: "image_search"
        title: Translation.tr("Booru")

        ContentSubsection {
            title: Translation.tr("Zerochan")

            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("Username")
                text: Config.options.sidebar.booru.zerochan.username === "[unset]"
                    ? "" : Config.options.sidebar.booru.zerochan.username
                wrapMode: TextEdit.NoWrap
                onTextChanged: {
                    Config.options.sidebar.booru.zerochan.username =
                        text.length > 0 ? text : "[unset]"
                }
                StyledToolTip {
                    text: Translation.tr("Your Zerochan username. Required to avoid being banned from the API.\nSee: https://www.zerochan.net/api")
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Gelbooru")

            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("User ID")
                text: Config.options.sidebar.booru.gelbooru.userId
                wrapMode: TextEdit.NoWrap
                onTextChanged: {
                    Config.options.sidebar.booru.gelbooru.userId = text
                }
                StyledToolTip {
                    text: Translation.tr("Your Gelbooru numeric user ID.\nFind it at: gelbooru.com → Account → My Account")
                }
            }

            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("API Key")
                text: Config.options.sidebar.booru.gelbooru.apiKey
                wrapMode: TextEdit.NoWrap
                onTextChanged: {
                    Config.options.sidebar.booru.gelbooru.apiKey = text
                }
                StyledToolTip {
                    text: Translation.tr("Your Gelbooru API key.\nFind it at: gelbooru.com → Account → My Account → API Access Credentials")
                }
            }
        }
    }

    ContentSection {
        icon: "water"
        title: "Fluid Simulation"

        ConfigSwitch {
            text: Translation.tr("Enable fluid simulation")
            checked: Config.options.fluid.enabled
            onCheckedChanged: Config.options.fluid.enabled = checked
            StyledToolTip {
                text: Translation.tr("Disable to use plain dark background instead of the fluid simulation")
            }
        }

        ConfigSpinBox {
            text: Translation.tr("Idle timeout before fluid (s)")
            value: Config.options.fluid.idleTimeout
            from: 5; to: 300; stepSize: 5
            onValueChanged: Config.options.fluid.idleTimeout = value
            MouseArea {
                id: idleHover
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
            }
            StyledToolTip {
                extraVisibleCondition: idleHover.containsMouse
                text: Translation.tr("How long of inactivity before the fluid simulation starts showing")
            }
        }

        ConfigSpinBox {
            text: Translation.tr("Widget auto-hide delay (s)")
            value: Config.options.fluid.widgetAutoHideTimeout
            from: 3; to: 120; stepSize: 5
            onValueChanged: Config.options.fluid.widgetAutoHideTimeout = value
            MouseArea {
                id: autoHideHover
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
            }
            StyledToolTip {
                extraVisibleCondition: autoHideHover.containsMouse
                text: Translation.tr("How long after fluid appears before toolbar/clock fade out")
            }
        }

        ContentSubsection {
            title: "Display"

            StyledComboBox {
                buttonIcon: "palette"
                textRole: "displayName"
                model: [
                    { displayName: "Original", value: 0 },
                    { displayName: "Plasma", value: 1 },
                    { displayName: "Poolside", value: 2 },
                    { displayName: "Gumdrop", value: 3 },
                    { displayName: "Silver", value: 4 },
                    { displayName: "Freedom", value: 5 }
                ]
                currentIndex: Config.options.fluid.colorPreset
                onCurrentIndexChanged: {
                    Config.options.fluid.colorPreset = currentIndex
                }
            StyledToolTip {
                    text: Translation.tr("Line coloring preset: Original (velocity-mapped), Plasma (warm color wheel), Poolside (cool blue wheel), Gumdrop (purple-pink gradient), Silver (grayscale noise), Freedom (blue-gold)")
            }
        }

        ConfigSpinBox {
            text: Translation.tr("Fade duration (ms)")
            value: Config.options.fluid.fadeDuration
            from: 100; to: 3000; stepSize: 100
            onValueChanged: Config.options.fluid.fadeDuration = value
            MouseArea {
                id: fadeHover
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
            }
            StyledToolTip {
                extraVisibleCondition: fadeHover.containsMouse
                text: Translation.tr("Fade in/out duration for the fluid simulation background")
            }
        }
    }

        ContentSubsection {
            title: "Physics"
            ConfigSpinBox {
                icon: "water_drop"
                text: "Viscosity (×10)"
                value: Config.options.fluid.viscosity * 10
                from: 1; to: 200; stepSize: 5
                onValueChanged: Config.options.fluid.viscosity = value / 10
                MouseArea {
                    id: viscHover
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                }
                StyledToolTip {
                    extraVisibleCondition: viscHover.containsMouse
                    text: Translation.tr("Fluid viscosity. Higher values make the fluid thicker, slowing diffusion")
                }
            }
            ConfigSpinBox {
                icon: "grain"
                text: "Noise (×100)"
                value: Config.options.fluid.noiseMultiplier * 100
                from: 0; to: 200; stepSize: 5
                onValueChanged: Config.options.fluid.noiseMultiplier = value / 100
                MouseArea {
                    id: noiseHover
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                }
                StyledToolTip {
                    extraVisibleCondition: noiseHover.containsMouse
                    text: Translation.tr("Turbulence driving force. Higher = more turbulent, lower = calmer")
                }
            }
            ConfigSpinBox {
                icon: "speed"
                text: "Timestep (×1000)"
                value: Config.options.fluid.timestep * 1000
                from: 1; to: 100; stepSize: 1
                onValueChanged: Config.options.fluid.timestep = value / 1000
                MouseArea {
                    id: timeHover
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                }
                StyledToolTip {
                    extraVisibleCondition: timeHover.containsMouse
                    text: Translation.tr("Simulation speed per frame. Default 0.0167 (1/60s) — best left as-is")
                }
            }
            ConfigSpinBox {
                icon: "blur_on"
                text: "Dissipation (×100)"
                value: Config.options.fluid.dissipation * 100
                from: 0; to: 100; stepSize: 5
                onValueChanged: Config.options.fluid.dissipation = value / 100
                MouseArea {
                    id: dissHover
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                }
                StyledToolTip {
                    extraVisibleCondition: dissHover.containsMouse
                    text: Translation.tr("Energy loss per frame. 0 = no loss (conserves energy), higher = faster decay")
                }
            }
            ConfigSpinBox {
                icon: "compress"
                text: "Pressure Iterations"
                value: Config.options.fluid.pressureIterations
                from: 1; to: 50; stepSize: 1
                onValueChanged: Config.options.fluid.pressureIterations = value
                MouseArea {
                    id: pressHover
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                }
                StyledToolTip {
                    extraVisibleCondition: pressHover.containsMouse
                    text: Translation.tr("Pressure solver accuracy. Higher = more physically accurate but more GPU intensive. Default 19")
                }
            }
        }

        ContentSubsection {
            title: "Lines"

            ConfigSpinBox {
                icon: "straighten"
                text: "Variance (×100)"
                value: Config.options.fluid.lineVariance * 100
                from: 0; to: 200; stepSize: 5
                onValueChanged: Config.options.fluid.lineVariance = value / 100
                MouseArea {
                    id: varHover
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                }
                StyledToolTip {
                    extraVisibleCondition: varHover.containsMouse
                    text: Translation.tr("How wiggly the flow lines are. Higher = more winding and chaotic")
                }
            }
            ConfigSpinBox {
                icon: "line_weight"
                text: "Width (×10)"
                value: Config.options.fluid.lineWidthMultiplier * 10
                from: 1; to: 50; stepSize: 1
                onValueChanged: Config.options.fluid.lineWidthMultiplier = value / 10
                MouseArea {
                    id: widthHover
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                }
                StyledToolTip {
                    extraVisibleCondition: widthHover.containsMouse
                    text: Translation.tr("Line thickness multiplier. Higher = thicker lines")
                }
            }
            ConfigSpinBox {
                icon: "zoom_in"
                text: "Zoom (×10)"
                value: Config.options.fluid.zoom * 10
                from: 5; to: 50; stepSize: 1
                onValueChanged: Config.options.fluid.zoom = value / 10
                MouseArea {
                    id: zoomHover
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                }
                StyledToolTip {
                    extraVisibleCondition: zoomHover.containsMouse
                    text: Translation.tr("Zoom level of the fluid display")
                }
            }
        }

        ContentSubsection {
            title: "Quality"

            ConfigSpinBox {
                icon: "speed"
                text: "FPS Limit"
                value: Config.options.fluid.fpsLimit
                from: 0; to: 240; stepSize: 10
                onValueChanged: Config.options.fluid.fpsLimit = value
                MouseArea {
                    id: fpsHover
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                }
                StyledToolTip {
                    extraVisibleCondition: fpsHover.containsMouse
                    text: Translation.tr("Maximum frames per second. 0 = unlimited (runs as fast as your GPU can)")
                }
            }
        }
    }

}
