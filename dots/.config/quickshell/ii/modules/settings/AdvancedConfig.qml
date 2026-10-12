import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    forceWidth: true

    NoticeBox {
        Layout.fillWidth: true
        materialIcon: "info"
        text: Translation.tr("Color settings have moved to the Color tab.")
    }
}
