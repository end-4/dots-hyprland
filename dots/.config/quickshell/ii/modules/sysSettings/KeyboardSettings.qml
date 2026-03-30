import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets

/**
 * Keyboard settings — layout info via HyprlandXkb, on-screen keyboard config.
 */
ContentPage {
    forceWidth: true

    ContentSection {
        icon: "keyboard"
        title: Translation.tr("Keyboard Layout")

        StyledText {
            text: Translation.tr("Active layout: %1 (%2)").arg(HyprlandXkb.currentLayoutName).arg(HyprlandXkb.currentLayoutCode)
            font.pixelSize: Appearance.font.pixelSize.normal
            color: Appearance.colors.colOnLayer0
        }

        ContentSubsection {
            title: Translation.tr("Available layouts")
            visible: HyprlandXkb.layoutCodes.length > 0

            Repeater {
                model: HyprlandXkb.layoutCodes
                delegate: StyledText {
                    required property string modelData
                    required property int index
                    text: (index + 1) + ". " + modelData
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                }
            }
        }

        NoticeBox {
            Layout.fillWidth: true
            text: Translation.tr("To add/remove keyboard layouts, edit your Hyprland config:\n~/.config/hypr/hyprland/input.conf")
        }
    }

    ContentSection {
        icon: "keyboard_alt"
        title: Translation.tr("On-Screen Keyboard")

        MaterialTextArea {
            Layout.fillWidth: true
            placeholderText: Translation.tr("Layout (e.g. qwerty_full)")
            text: Config.options.osk.layout
            onTextChanged: { Qt.callLater(() => { Config.options.osk.layout = text; Config.save() }) }
        }

        ConfigSwitch {
            buttonIcon: "push_pin"
            text: Translation.tr("Pinned on startup")
            checked: Config.options.osk.pinnedOnStartup
            onCheckedChanged: { Config.options.osk.pinnedOnStartup = checked; Config.save() }
        }
    }
}
