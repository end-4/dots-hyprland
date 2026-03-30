import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets

/**
 * Mouse & Touchpad settings — scroll behavior, dead pixel workaround.
 * Reads/writes Config.options.interactions.
 */
ContentPage {
    forceWidth: true

    ContentSection {
        icon: "mouse"
        title: Translation.tr("Scrolling")

        ConfigSwitch {
            buttonIcon: "swipe_up"
            text: Translation.tr("Faster touchpad scroll")
            checked: Config.options.interactions.scrolling.fasterTouchpadScroll
            onCheckedChanged: { Config.options.interactions.scrolling.fasterTouchpadScroll = checked }
        }

        ConfigSpinBox {
            icon: "straighten"
            text: Translation.tr("Mouse scroll delta threshold")
            value: Config.options.interactions.scrolling.mouseScrollDeltaThreshold
            from: 10; to: 500; stepSize: 10
            onValueChanged: { Config.options.interactions.scrolling.mouseScrollDeltaThreshold = value }
            StyledToolTip { text: Translation.tr("Delta ≥ this value is detected as mouse scroll instead of touchpad") }
        }

        ConfigSpinBox {
            icon: "speed"
            text: Translation.tr("Mouse scroll factor")
            value: Config.options.interactions.scrolling.mouseScrollFactor
            from: 10; to: 500; stepSize: 10
            onValueChanged: { Config.options.interactions.scrolling.mouseScrollFactor = value }
        }

        ConfigSpinBox {
            icon: "speed"
            text: Translation.tr("Touchpad scroll factor")
            value: Config.options.interactions.scrolling.touchpadScrollFactor
            from: 50; to: 1000; stepSize: 50
            onValueChanged: { Config.options.interactions.scrolling.touchpadScrollFactor = value }
        }
    }

    ContentSection {
        icon: "bug_report"
        title: Translation.tr("Workarounds")

        ConfigSwitch {
            buttonIcon: "grid_3x3"
            text: Translation.tr("Dead pixel workaround")
            checked: Config.options.interactions.deadPixelWorkaround.enable
            onCheckedChanged: { Config.options.interactions.deadPixelWorkaround.enable = checked }
            StyledToolTip { text: Translation.tr("Hyprland leaves 1 pixel on the right edge for interactions — enable if you experience this") }
        }
    }

    NoticeBox {
        Layout.fillWidth: true
        text: Translation.tr("For advanced mouse/touchpad settings (sensitivity, acceleration, tap-to-click), edit:\n~/.config/hypr/hyprland/input.conf")
    }
}
