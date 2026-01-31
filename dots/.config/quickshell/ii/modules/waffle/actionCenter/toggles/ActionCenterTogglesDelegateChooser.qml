pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.models.quickToggles
import qs.modules.common.widgets
import qs.modules.waffle.looks
import qs.modules.waffle.actionCenter.bluetooth
import qs.modules.waffle.actionCenter.nightLight
import qs.modules.waffle.actionCenter.volumeControl
import qs.modules.waffle.actionCenter.wifi

DelegateChooser {
    id: root

    // role: "type" is implied by usage

    DelegateChoice {
        roleValue: "antiFlashbang"
        ActionCenterToggleButton {
            toggleModel: AntiFlashbangToggle {}
            icon: "flash-off"
            menu: Component {
                NightLightControl {}
            }
        }
    }
    DelegateChoice {
        roleValue: "bluetooth"
        ActionCenterToggleButton {
            toggleModel: BluetoothToggle {}
            name: toggleModel.statusText
            icon: WIcons.bluetoothIcon
            menu: Component {
                BluetoothControl {}
            }
        }
    }
    DelegateChoice {
        roleValue: "cloudflareWarp"
        ActionCenterToggleButton {
            toggleModel: CloudflareWarpToggle {}
            icon: "cloudflare"
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
            icon: "dark-theme"
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
            menu: Component {
                VolumeControl {
                    output: false
                }
            }
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
            name: toggleModel.statusText
            icon: WIcons.internetIcon
            menu: Component {
                WifiControl {}
            }
        }
    }
    DelegateChoice {
        roleValue: "nightLight"
        ActionCenterToggleButton {
            toggleModel: NightLightToggle {}
            icon: WIcons.nightLightIcon
            menu: Component {
                NightLightControl {}
            }
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
            name: toggleModel.statusText
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
