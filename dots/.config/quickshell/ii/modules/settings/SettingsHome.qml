import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    forceWidth: true

    ContentSection {
        icon: "tune"
        title: Translation.tr("Settings")

        StyledText {
            Layout.fillWidth: true
            text: Translation.tr("Choose an area from the sidebar.")
            color: Appearance.colors.colSubtext
            wrapMode: Text.Wrap
        }
    }
}
