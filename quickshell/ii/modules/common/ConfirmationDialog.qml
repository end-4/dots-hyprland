import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

AppDialog {
    id: dialog
    property string message: "Are you sure?"

    titleText: "Confirm Action"

    contentComponent: StyledText {
        width: 350
        wrapMode: Text.WordWrap
        text: dialog.message
        color: Appearance.colors.colOnLayer2
    }

    footerComponent: RowLayout {
        Layout.fillWidth: true
        spacing: 10

        DialogButton {
            text: "OK"
            isDefault: true
            Layout.fillWidth: true
            onClicked: dialog.accept()
        }
        DialogButton {
            text: "Cancel"
            Layout.fillWidth: true
            onClicked: dialog.reject()
        }
    }
}