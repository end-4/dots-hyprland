import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    forceWidth: true

    ContentSection {
        icon: "colors"
        title: Translation.tr("Color generation")

        ConfigRow {
            uniform: true
            ConfigSwitch {
                text: Translation.tr("Shell & utilities")
                checked: Config.options.appearance.wallpaperTheming.enableAppsAndShell
                onCheckedChanged: {
                    Config.options.appearance.wallpaperTheming.enableAppsAndShell = checked;
                }
            }
            ConfigSwitch {
                text: Translation.tr("Qt apps")
                checked: Config.options.appearance.wallpaperTheming.enableQtApps
                onCheckedChanged: {
                    Config.options.appearance.wallpaperTheming.enableQtApps = checked;
                }
                StyledToolTip {
                    content: Translation.tr("Shell & utilities theming must also be enabled")
                }
            }
            ConfigSwitch {
                text: Translation.tr("Terminal")
                checked: Config.options.appearance.wallpaperTheming.enableTerminal
                onCheckedChanged: {
                    Config.options.appearance.wallpaperTheming.enableTerminal = checked;
                }
                StyledToolTip {
                    content: Translation.tr("Shell & utilities theming must also be enabled")
                }
            }

        }
        
        ConfigRow {
            uniform: true
            ConfigSpinBox {
                text: Translation.tr("Max image pixels (millions)")
                value: Math.round((Config.options.appearance.wallpaperTheming.maxImagePixels || 200000000) / 1000000)
                onValueChanged: {
                    Config.options.appearance.wallpaperTheming.maxImagePixels = value === 0 ? 0 : value * 1000000;
                }
                from: 0
                to: 1000
                stepSize: 50
                StyledToolTip {
                    content: Translation.tr("Maximum pixels allowed for wallpaper images. 0 = unlimited. Default 200MP for security.")
                }
            }
        }
    }
}
