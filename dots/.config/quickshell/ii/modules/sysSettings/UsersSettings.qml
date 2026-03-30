import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets

/**
 * Users & Accounts settings — shows current user and links to system tools.
 */
ContentPage {
    forceWidth: true

    ContentSection {
        icon: "account_circle"
        title: Translation.tr("Current User")

        RowLayout {
            Layout.fillWidth: true
            spacing: 14

            MaterialSymbol {
                text: "account_circle"
                iconSize: 48
                color: Appearance.colors.colPrimary
            }

            ColumnLayout {
                spacing: 2
                StyledText {
                    text: SystemInfo.username
                    font { pixelSize: Appearance.font.pixelSize.larger; family: Appearance.font.family.title }
                    color: Appearance.colors.colOnLayer0
                }
                StyledText {
                    text: SystemInfo.distroName + " — " + SystemInfo.windowingSystem
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                }
            }
        }
    }

    ContentSection {
        icon: "manage_accounts"
        title: Translation.tr("Actions")

        RippleButtonWithIcon {
            Layout.fillWidth: true
            materialIcon: "lock"
            mainText: Translation.tr("Change password")
            buttonRadius: Appearance.rounding.small
            onClicked: Quickshell.execDetached(["bash", "-c", Config.options.apps.changePassword])
        }
        RippleButtonWithIcon {
            Layout.fillWidth: true
            materialIcon: "manage_accounts"
            mainText: Translation.tr("Manage users (KDE)")
            buttonRadius: Appearance.rounding.small
            onClicked: Quickshell.execDetached(["bash", "-c", Config.options.apps.manageUser])
        }
    }
}
