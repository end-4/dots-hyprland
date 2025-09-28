// hyprland-settings/qml/components/AutostartEditDialog.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import App 1.0
import Controls 1.0

Window {
    id: root
    visible: false
    modality: Qt.ApplicationModal
    width: 500
    height: 320 // Increased height
    color: Theme.surfaceContainerLow
    flags: Qt.Dialog | Qt.FramelessWindowHint

    property bool isNew: false
    property var originalLine: ""

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        Label {
            text: isNew ? qsTr("New autostart entry") : qsTr("Edit entry")
            font.family: Theme.titleFont.family
            font.pixelSize: Theme.titleFont.pixelSize
            font.weight: Theme.titleFont.weight
            color: Theme.text
            Layout.bottomMargin: 8
        }

        Label { text: qsTr("Command:"); color: Theme.subtext; }
        StyledTextField {
            id: commandField
            Layout.fillWidth: true
            placeholderText: qsTr("For example, waybar")
        }

        Label { text: qsTr("Title (optional):"); color: Theme.subtext; topPadding: 8 }
        StyledTextField {
            id: titleField
            Layout.fillWidth: true
            placeholderText: qsTr("For example, Status bar")
        }

        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.alignment: Qt.AlignBottom | Qt.AlignRight
            spacing: 8
            
            StyledButton { text: qsTr("Cancel"); onClicked: root.close() }
            StyledButton {
                text: qsTr("OK")
                highlighted: true
                onClicked: {
                    if (isNew) {
                         autostartBridge.addAutostart(commandField.text, titleField.text)
                    } else {
                        autostartBridge.updateAutostart(originalLine, commandField.text, titleField.text)
                    }
                    root.close()
                }
            }
        }
    }

    function openForNew() {
        isNew = true
        originalLine = ""
        commandField.text = ""
        titleField.text = ""
        visible = true
         requestActivate()
    }

    function openForEdit(model) {
        isNew = false
        originalLine = model.original_line
        commandField.text = model.command
        titleField.text = model.title
        visible = true
        requestActivate()
    }
    
    function close() { visible = false }
}