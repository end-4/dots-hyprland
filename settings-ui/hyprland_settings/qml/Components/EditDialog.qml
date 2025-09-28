// hyprland-settings/qml/components/EditDialog.qml
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
    height: 400
    color: Theme.surfaceContainerLow
    flags: Qt.Dialog | Qt.FramelessWindowHint

    property bool isNew: false
    property var originalLine: ""

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        Label {
            text: isNew ? qsTr("New keybind") : qsTr("Edit keybind")
            font.family: Theme.titleFont.family
            font.pixelSize: Theme.titleFont.pixelSize
            font.weight: Theme.titleFont.weight
            color: Theme.text
            Layout.bottomMargin: 8
        }
        
        Label { text: qsTr("Key combination:"); color: Theme.subtext; }
        RowLayout {
            StyledTextField {
                id: keyField
                Layout.fillWidth: true
                placeholderText: qsTr("Press 'Record'...")
                readOnly: true
                font.family: Theme.monoFont.family
                font.pixelSize: Theme.monoFont.pixelSize
            }
            StyledButton {
                text: qsTr("Record")
                onClicked: keyCaptureDialog.open(function(capturedKey) {
                    keyField.text = capturedKey
                })
            }
        }

        Label { text: qsTr("Command:"); color: Theme.subtext; topPadding: 8 }
        StyledTextField {
            id: commandField
            Layout.fillWidth: true
            placeholderText: qsTr("For example, kitty or workspace 5")
        }

        Label { text: qsTr("Title (optional):"); color: Theme.subtext; topPadding: 8 }
        StyledTextField {
            id: titleField
            Layout.fillWidth: true
            placeholderText: qsTr("For example, Open terminal")
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
                    // --- ИСПРАВЛЕНИЕ: Новая логика форматирования ---
                    var capturedString = keyField.text;
                    if (capturedString === "" || commandField.text.trim() === "") return;

                    var parts = capturedString.split(" + ");
                    var mainKey = parts.pop();
                    var modifiers = parts.join("+"); // Модификаторы объединяются через "+"
                    
                    // Финальная строка имеет вид "MOD+MOD,KEY"
                    var finalKeyString = modifiers ? (modifiers + "," + mainKey) : mainKey;

                    // Вызываем функцию проверки из Python
                    var conflict = hyprlandBridge.checkIfKeybindExists(finalKeyString, originalLine);

                    if (conflict && conflict.command_raw) { // Добавлена проверка на conflict.command_raw
                        confirmOverwriteDialog.text = qsTr("The combination \"%1\" is already used for the command:\n%2\n\nOverwrite?").arg(keyField.text).arg(conflict.command_raw)
                        confirmOverwriteDialog.openWithCallback(function() {
                            hyprlandBridge.removeKeybind(conflict.original_line);
                            saveKeybind(finalKeyString);
                        })
                    } else {
                        saveKeybind(finalKeyString);
                    }
                }
            }
        }
    }

    function saveKeybind(formattedKey) {
        if (isNew) {
            hyprlandBridge.addKeybind(formattedKey, commandField.text, titleField.text)
        } else {
            hyprlandBridge.updateKeybind(originalLine, formattedKey, commandField.text, titleField.text)
        }
        root.close()
    }

    function openForNew() {
        isNew = true
        originalLine = ""
        keyField.text = ""
        commandField.text = ""
        titleField.text = ""
        visible = true
        requestActivate()
    }

    function openForEdit(model) {
        isNew = false
        originalLine = model.original_line
        keyField.text = model.key_display // Для отображения используется " + "
        commandField.text = model.command_raw
        titleField.text = model.title
        visible = true
        requestActivate()
    }
     
    function close() { visible = false }
}