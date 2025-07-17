import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    forceWidth: true

    ContentSection {
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
    }
}
