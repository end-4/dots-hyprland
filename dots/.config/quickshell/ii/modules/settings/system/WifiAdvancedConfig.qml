import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    forceWidth: true

    ContentSection {
        icon: "tune"
        title: Translation.tr("Advanced")

        DialogButton {
            buttonText: Translation.tr("Open KDE network settings")
            onClicked: Quickshell.execDetached(["bash", "-c", "systemsettings kcm_networkmanagement || plasmawindowed kcm_networkmanagement"])
        }

        DialogButton {
            buttonText: Translation.tr("Open NetworkManager editor")
            onClicked: Quickshell.execDetached(["bash", "-c", "nm-connection-editor || plasmawindowed kcm_networkmanagement || systemsettings kcm_networkmanagement"])
        }
    }
}
