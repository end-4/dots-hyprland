// hyprland-settings/qml/Components/KeyCaptureDialog.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import App 1.0
import Controls 1.0

Window {
    id: root
    visible: false
    modality: Qt.ApplicationModal
    width: 450
    height: 200
    color: Theme.surfaceContainerLow
    flags: Qt.Dialog | Qt.FramelessWindowHint

    property var onAcceptCallback: function(key) {}
    property string capturedText: qsTr("Press the keys...")

    FocusScope {
        id: focusArea
        anchors.fill: parent
        focus: true

        Keys.onPressed: (event) => {
            event.accepted = true;
            if (event.key !== Qt.Key_Control && event.key !== Qt.Key_Alt && event.key !== Qt.Key_Shift && event.key !== Qt.Key_Meta) {
                root.capturedText = keyEventToString(event);
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 16

            Label {
                text: qsTr("Capture key combination")
                font.family: Theme.titleFont.family
                font.pixelSize: Theme.titleFont.pixelSize
                font.weight: Theme.titleFont.weight
                color: Theme.text
            }

            Label {
                id: keyDisplay
                text: root.capturedText
                font.family: Theme.monoFont.family
                font.pixelSize: 24
                color: Theme.text
                background: Rectangle {
                    color: Theme.surfaceContainer
                    radius: Theme.radius
                }
                padding: 16
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                horizontalAlignment: Text.AlignHCenter
            }

            RowLayout {
                Layout.alignment: Qt.AlignBottom | Qt.AlignRight
                spacing: 8

                StyledButton { text: qsTr("Cancel"); onClicked: root.close() }
                StyledButton {
                    text: qsTr("OK")
                    highlighted: true
                    enabled: capturedText !== qsTr("Press to record...") && capturedText !== qsTr("Unknown key")
                    onClicked: {
                        // ИЗМЕНЕНИЕ: Передаем строку "как есть"
                        onAcceptCallback(capturedText);
                        root.close();
                    }
                }
            }
        }
    }

    function open(callback) {
        onAcceptCallback = callback;
        capturedText = qsTr("Press to record...");
        visible = true;
        requestActivate();
        focusArea.forceActiveFocus();
    }

    function close() {
        visible = false;
    }

    // --- ИСПРАВЛЕНИЕ: Гарантированный порядок модификаторов ---
    function keyEventToString(event) {
        var parts = [];
        // 1. Добавляем модификаторы в строгом порядке для консистентности
        if (event.modifiers & Qt.MetaModifier) parts.push("SUPER");
        if (event.modifiers & Qt.AltModifier) parts.push("ALT");
        if (event.modifiers & Qt.ControlModifier) parts.push("CTRL");
        if (event.modifiers & Qt.ShiftModifier) parts.push("SHIFT");

        var keyText = "";

        // 2. Проверяем служебные клавиши
        switch (event.key) {
            case Qt.Key_F1: keyText = "F1"; break;
            case Qt.Key_F2: keyText = "F2"; break;
            case Qt.Key_F3: keyText = "F3"; break;
            case Qt.Key_F4: keyText = "F4"; break;
            case Qt.Key_F5: keyText = "F5"; break;
            case Qt.Key_F6: keyText = "F6"; break;
            case Qt.Key_F7: keyText = "F7"; break;
            case Qt.Key_F8: keyText = "F8"; break;
            case Qt.Key_F9: keyText = "F9"; break;
            case Qt.Key_F10: keyText = "F10"; break;
            case Qt.Key_F11: keyText = "F11"; break;
            case Qt.Key_F12: keyText = "F12"; break;
            case Qt.Key_Space: keyText = "SPACE"; break;
            case Qt.Key_Return: keyText = "RETURN"; break;
            case Qt.Key_Enter: keyText = "RETURN"; break;
            case Qt.Key_Escape: keyText = "ESCAPE"; break;
            case Qt.Key_Tab: keyText = "TAB"; break;
            case Qt.Key_Backspace: keyText = "BACKSPACE"; break;
            case Qt.Key_Delete: keyText = "DELETE"; break;
            case Qt.Key_Insert: keyText = "INSERT"; break;
            case Qt.Key_Home: keyText = "HOME"; break;
            case Qt.Key_End: keyText = "END"; break;
            case Qt.Key_PageUp: keyText = "PAGEUP"; break;
            case Qt.Key_PageDown: keyText = "PAGEDOWN"; break;
            case Qt.Key_Left: keyText = "LEFT"; break;
            case Qt.Key_Right: keyText = "RIGHT"; break;
            case Qt.Key_Up: keyText = "UP"; break;
            case Qt.Key_Down: keyText = "DOWN"; break;
        }

        if (keyText !== "") {
            parts.push(keyText);
            return parts.join(" + ");
        }

        // 3. Если это не служебная клавиша, берем введенный символ и переводим его
        var typedChar = event.text.toUpperCase();
        if (!typedChar) return qsTr("Unknown key");

        const translationMap = {
            'Й': 'Q', 'Ц': 'W', 'У': 'E', 'К': 'R', 'Е': 'T', 'Н': 'Y', 'Г': 'U',
            'Ш': 'I', 'Щ': 'O', 'З': 'P', 'Х': '[', 'Ъ': ']', 'Ф': 'A', 'Ы': 'S',
            'В': 'D', 'А': 'F', 'П': 'G', 'Р': 'H', 'О': 'J', 'Л': 'K', 'Д': 'L',
            'Ж': ';', 'Э': "'", 'Я': 'Z', 'Ч': 'X', 'С': 'C', 'М': 'V', 'И': 'B',
            'Т': 'N', 'Ь': 'M', 'Б': ',', 'Ю': '.', 'І': 'S', 'Ї': ']', 'Є': "'",
            'Ґ': '`', 'À': 'A', 'Á': 'A', 'Â': 'A', 'Ã': 'A', 'Ä': 'A', 'Å': 'A',
            'È': 'E', 'É': 'E', 'Ê': 'E', 'Ë': 'E', '€': 'E', 'Ì': 'I', 'Í': 'I',
            'Î': 'I', 'Ï': 'I', 'Ò': 'O', 'Ó': 'O', 'Ô': 'O', 'Õ': 'O', 'Ö': 'O',
            'Ù': 'U', 'Ú': 'U', 'Û': 'U', 'Ü': 'U', 'Ç': 'C', 'Ñ': 'N', '§': 'S'
        };
        var translatedChar = translationMap[typedChar] || typedChar;

        // 4. Преобразуем знаки препинания в их имена для Hyprland
        switch (translatedChar) {
            case ';': keyText = "SEMICOLON"; break;
            case "'": keyText = "APOSTROPHE"; break;
            case '[': keyText = "BRACKETLEFT"; break;
            case ']': keyText = "BRACKETRIGHT"; break;
            case ',': keyText = "COMMA"; break;
            case '.': keyText = "PERIOD"; break;
            case '`': keyText = "GRAVE"; break;
            case '-': keyText = "MINUS"; break;
            case '=': keyText = "EQUAL"; break;
            case '/': keyText = "SLASH"; break;
            case '\\': keyText = "BACKSLASH"; break;
            default: keyText = translatedChar; break;
        }
        
        if (keyText.length > 1 && !(keyText.startsWith("F") && keyText.length <= 3)) {
             parts.push(keyText);
        } else if (keyText.length === 1) {
            parts.push(keyText);
        } else {
            return qsTr("Unknown key");
        }

        return parts.join(" + ");
    }
}