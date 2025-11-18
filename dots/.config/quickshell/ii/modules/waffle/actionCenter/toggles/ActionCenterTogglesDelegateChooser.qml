pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.models.quickToggles
import qs.modules.common.widgets
import qs.modules.waffle.looks
import QtQuick
import QtQuick.Layouts
import Quickshell

DelegateChooser {
    id: root

    // role: "type" is implied by usage

    DelegateChoice {
        roleValue: "antiFlashbang"
        ActionCenterToggleButton {
            toggleModel: AntiFlashbangToggle {}
            icon: "flash-off"
        }
    }
    DelegateChoice {
        roleValue: "audio"
        ActionCenterToggleButton {
            toggleModel: AudioToggle {}
            icon: "speaker-2"
        }
    }
    DelegateChoice {
        roleValue: "bluetooth"
        ActionCenterToggleButton {
            toggleModel: BluetoothToggle {}
            icon: WIcons.bluetoothIcon
        }
    }
    DelegateChoice {
        roleValue: "cloudflareWarp"
        ActionCenterToggleButton {
            toggleModel: CloudflareWarpToggle {}
            icon: "globe-shield"
        }
    }
    DelegateChoice {
        roleValue: "colorPicker"
        ActionCenterToggleButton {
            toggleModel: ColorPickerToggle {}
            icon: "eyedropper"
        }
    }
    DelegateChoice {
        roleValue: "darkMode"
        ActionCenterToggleButton {
            toggleModel: DarkModeToggle {}
            icon: "dark-theme*"
        }
    }
    DelegateChoice {
        roleValue: "easyEffects"
        ActionCenterToggleButton {
            toggleModel: EasyEffectsToggle {}
            icon: "device-eq"
        }
    }
    DelegateChoice {
        roleValue: "gameMode"
        ActionCenterToggleButton {
            toggleModel: GameModeToggle {}
            icon: "games"
        }
    }
    DelegateChoice {
        roleValue: "idleInhibitor"
        ActionCenterToggleButton {
            toggleModel: IdleInhibitorToggle {}
            icon: "drink-coffee"
        }
    }
    DelegateChoice {
        roleValue: "mic"
        ActionCenterToggleButton {
            toggleModel: MicToggle {}
            icon: WIcons.micIcon
        }
    }
    DelegateChoice {
        roleValue: "musicRecognition"
        ActionCenterToggleButton {
            toggleModel: MusicRecognitionToggle {}
            icon: "music-note-2"
        }
    }
    DelegateChoice {
        roleValue: "network"
        ActionCenterToggleButton {
            toggleModel: NetworkToggle {}
            icon: WIcons.internetIcon
        }
    }
    DelegateChoice {
        roleValue: "nightLight"
        ActionCenterToggleButton {
            toggleModel: NightLightToggle {}
            icon: WIcons.nightLightIcon
        }
    }
    DelegateChoice {
        roleValue: "notifications"
        ActionCenterToggleButton {
            toggleModel: NotificationToggle {}
            icon: WIcons.notificationsIcon
        }
    }
    DelegateChoice {
        roleValue: "onScreenKeyboard"
        ActionCenterToggleButton {
            toggleModel: OnScreenKeyboardToggle {}
            icon: GlobalStates.oskOpen ? "keyboard-dock" : "keyboard"
        }
    }
    DelegateChoice {
        roleValue: "powerProfile"
        ActionCenterToggleButton {
            toggleModel: PowerProfilesToggle {}
            icon: WIcons.powerProfileIcon
        }
    }
    DelegateChoice {
        roleValue: "screenSnip"
        ActionCenterToggleButton {
            toggleModel: ScreenSnipToggle {}
            icon: "cut"
        }
    }
}
