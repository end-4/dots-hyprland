import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    forceWidth: true

    ContentSection {
        icon: "music_note"
        title: Translation.tr("Music")

        ConfigSwitch {
            buttonIcon: "music_note"
            text: Translation.tr("Enable music scratchpad")
            checked: Config.options.scratchpads.music.enable
            onCheckedChanged: {
                Config.options.scratchpads.music.enable = checked;
            }
            StyledToolTip {
                text: Translation.tr("Toggle music app in a floating special workspace with Super+M")
            }
        }

        ContentSubsection {
            enabled: Config.options.scratchpads.music.enable
            title: Translation.tr("Music app")
            tooltip: Translation.tr("The app that will be launched or toggled.\nMake sure the selected app is installed.")

            ConfigSelectionArray {
                currentValue: Config.options.scratchpads.music.app
                onSelected: newValue => {
                    Config.options.scratchpads.music.app = newValue;
                }
                options: [
                    {
                        displayName: "YouTube Music",
                        icon: "smart_display",
                        value: "youtube-music"
                    },
                    {
                        displayName: "Spotify",
                        icon: "queue_music",
                        value: "spotify"
                    }
                ]
            }
        }

        ConfigSwitch {
            enabled: Config.options.scratchpads.music.enable
            buttonIcon: "picture_in_picture"
            text: Translation.tr("Always open in special area")
            checked: Config.options.scratchpads.music.alwaysInSpecial
            onCheckedChanged: {
                Config.options.scratchpads.music.alwaysInSpecial = checked;
            }
            StyledToolTip {
                text: Translation.tr("When disabled, pressing Super+M while the app is open on another workspace\nwill move it to the scratchpad instead of launching a new instance.")
            }
        }
    }

    ContentSection {
        icon: "chat"
        title: Translation.tr("Discord")

        ConfigSwitch {
            buttonIcon: "chat"
            text: Translation.tr("Enable Discord scratchpad")
            checked: Config.options.scratchpads.discord.enable
            onCheckedChanged: {
                Config.options.scratchpads.discord.enable = checked;
            }
            StyledToolTip {
                text: Translation.tr("Toggle Discord in a floating special workspace with Super+D")
            }
        }

        ConfigSwitch {
            enabled: Config.options.scratchpads.discord.enable
            buttonIcon: "picture_in_picture"
            text: Translation.tr("Always open in special area")
            checked: Config.options.scratchpads.discord.alwaysInSpecial
            onCheckedChanged: {
                Config.options.scratchpads.discord.alwaysInSpecial = checked;
            }
            StyledToolTip {
                text: Translation.tr("When disabled, pressing Super+D while Discord is open on another workspace\nwill move it to the scratchpad instead of launching a new instance.")
            }
        }
    }
}
