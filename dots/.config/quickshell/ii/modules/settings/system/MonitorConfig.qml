import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    forceWidth: true

    ContentSection {
        icon: "monitor"
        title: Translation.tr("Monitor")

        StyledText {
            Layout.fillWidth: true
            text: Translation.tr("Monitor settings will live here.")
            color: Appearance.colors.colSubtext
            wrapMode: Text.Wrap
        }

        DialogButton {
            buttonText: Translation.tr("Open KDE display settings")
            onClicked: Quickshell.execDetached(["bash", "-c", "systemsettings kcm_kscreen || plasmawindowed kcm_kscreen"])
        }
    }
}
