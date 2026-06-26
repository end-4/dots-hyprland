import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    forceWidth: true

    ContentSection {
        icon: "bluetooth"
        title: Translation.tr("Bluetooth")

        StyledText {
            Layout.fillWidth: true
            text: Translation.tr("Bluetooth controls will live here.")
            color: Appearance.colors.colSubtext
            wrapMode: Text.Wrap
        }
    }
}
