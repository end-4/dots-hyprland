// Файл: quickshell/ii/modules/settings/AddLayoutDialog.qml
import QtQuick
import Quickshell
import qs.modules.common.widgets

// Простое диалоговое окно для ввода новой раскладки
AppDialog {
    id: root

    // Сигнал, который отправляет введённую раскладку наверх
    signal addLayout(string newLayout)

    modal: true
    title: "Add Keyboard Layout"
    
    property string inputText: ""

    onAccepted: {
        if (inputText.trim() !== "") {
            addLayout(inputText.trim());
        }
        close();
    }

    content: [
        ConfigRow {
            TextField {
                id: layoutInput
                Layout.fillWidth: true
                placeholderText: "e.g. de, fr, ua"
                focus: true // Автофокус на поле ввода
                onTextChanged: root.inputText = text
                
                // Позволяет нажать Enter для подтверждения
                Keys.onReturnPressed: root.accept()
                Keys.onEnterPressed: root.accept()
            }
        }
    ]
}