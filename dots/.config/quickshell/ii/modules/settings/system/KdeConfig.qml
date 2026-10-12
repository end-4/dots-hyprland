import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    forceWidth: true

    ContentSection {
        icon: "palette"
        title: Translation.tr("KDE")

        StyledText {
            Layout.fillWidth: true
            text: Translation.tr("KDE personalization shortcuts will live here.")
            color: Appearance.colors.colSubtext
            wrapMode: Text.Wrap
        }
    }
}
