// hyprland-settings/qml/Components/WindowRuleEditDialog.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import App 1.0
import Controls 1.0

Window {
    id: root
    visible: false
    modality: Qt.ApplicationModal
    width: 600
    height: 550
    color: Theme.surfaceContainerLow
    flags: Qt.Dialog | Qt.FramelessWindowHint

    property bool isNew: false
    property var originalLine: ""

    // --- Модели данных для ComboBox ---
    readonly property var targetModel: ["class", "initialClass", "title", "initialTitle", "pid", "address", "floating", "tiled", "pinned", "fullscreen", "xwayland", "onworkspace"]
    readonly property var actionModel: [
        "workspace", "movetoworkspace", "float", "tile", "fullscreen", "maximize", "pin", "move", "size",
        "minsize", "maxsize", "center", "pseudo", "rounding", "opacity", "animation",
        "bordercolor", "bordersize", "noborder", "nofocus", "noshadow", "nobur",
        "noinitialfocus", "nomaximizerequest", "suppressevent", "idleinhibit", "group"
    ]

    function getAction() { return actionCombo.currentValue }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        Label {
            text: isNew ? qsTr("New window rule") : qsTr("Edit rule")
            font.family: Theme.titleFont.family
            font.pixelSize: Theme.titleFont.pixelSize
            font.weight: Theme.titleFont.weight
            color: Theme.text
            Layout.bottomMargin: 8
        }

        // --- Секция: Идентификация Окна ---
        Label { text: qsTr("If the window matches:"); color: Theme.subtext; }
        RowLayout {
            StyledComboBox {
                id: targetCombo
                Layout.preferredWidth: 150
                model: root.targetModel
            }
            StyledTextField {
                id: targetValueField
                Layout.fillWidth: true
                placeholderText: qsTr("Value (e.g., kitty)")
                // Поля для boolean-типов не требуют значения
                enabled: !["floating", "tiled", "pinned", "fullscreen", "xwayland"].includes(targetCombo.currentValue)
            }
            CheckBox {
                id: exactMatchCheck
                text: qsTr("Exact")
                checked: true
                // Видно только для текстовых критериев
                visible: ["class", "initialClass", "title", "initialTitle"].includes(targetCombo.currentValue)
            }
        }

        // --- Секция: Действие ---
        Label { text: qsTr("Then do the following:"); color: Theme.subtext; topPadding: 8 }
        StyledComboBox {
            id: actionCombo
            Layout.fillWidth: true
            model: root.actionModel
        }

        // --- Динамические поля для параметров ---
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 80 // Резервируем место

            // Для 'workspace' и 'movetoworkspace'
            RowLayout {
                anchors.fill: parent
                visible: getAction() === 'workspace' || getAction() === 'movetoworkspace'
                StyledTextField { id: wsParam1; Layout.fillWidth: true; placeholderText: qsTr("Number, name or special") }
                CheckBox { id: wsSilentCheck; text: qsTr("Silent (silent)") }
            }
            // Для 'move'
            RowLayout {
                anchors.fill: parent
                visible: getAction() === 'move'
                StyledTextField { id: moveParam1; Layout.fillWidth: true; placeholderText: qsTr("X (e.g. 100 or 50%)")}
                StyledTextField { id: moveParam2; Layout.fillWidth: true; placeholderText: qsTr("Y (e.g. 200 or 50%)")}
            }
            // Для 'size', 'minsize', 'maxsize'
            RowLayout {
                anchors.fill: parent
                visible: ['size', 'minsize', 'maxsize'].includes(getAction())
                StyledTextField { id: sizeParam1; Layout.fillWidth: true; placeholderText: qsTr("Width (e.g. 800 or 80%)") }
                StyledTextField { id: sizeParam2; Layout.fillWidth: true; placeholderText: qsTr("Height (e.g. 600 or 60%)") }
            }
            // Для 'center'
            StyledComboBox {
                id: centerParam; anchors.fill: parent; visible: getAction() === 'center'; model: [qsTr("1 (Enable)"), qsTr("0 (Disable)")]
            }
            // Для 'opacity'
            RowLayout {
                anchors.fill: parent
                visible: getAction() === 'opacity'
                StyledTextField { id: opacityParam1; Layout.fillWidth: true; placeholderText: qsTr("Opacity (0.0-1.0)")}
                StyledTextField { id: opacityParam2; Layout.fillWidth: true; placeholderText: qsTr("For inactive (opt.)")}
                CheckBox { id: opacityOverrideCheck; text: qsTr("Override") }
            }
            // Для 'bordercolor'
            RowLayout {
                anchors.fill: parent
                visible: getAction() === 'bordercolor'
                StyledTextField { id: borderColorParam1; Layout.fillWidth: true; placeholderText: qsTr("Active color (hex)")}
                StyledTextField { id: borderColorParam2; Layout.fillWidth: true; placeholderText: qsTr("Inactive (hex)")}
            }
             // Для 'idleinhibit'
            StyledComboBox {
                id: idleParam; anchors.fill: parent; visible: getAction() === 'idleinhibit'; model: [qsTr("none"), qsTr("focus"), qsTr("fullscreen"), qsTr("always")]
            }
            // Для простых полей с одним параметром
            StyledTextField {
                id: singleParamField
                anchors.fill: parent
                placeholderText: qsTr("Parameter...")
                visible: ['rounding', 'bordersize', 'animation', 'suppressevent', 'group'].includes(getAction())
            }
        }

        // --- Секция: Комментарий ---
        Label { text: qsTr("Comment (optional):"); color: Theme.subtext; topPadding: 8 }
        StyledTextField {
            id: commentField
            Layout.fillWidth: true
            placeholderText: qsTr("For example, To always center the terminal")
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
                    var ruleData = collectData()
                    if (isNew) {
                        windowRulesBridge.addRule(ruleData)
                    } else {
                        windowRulesBridge.updateRule(originalLine, ruleData)
                    }
                    root.close()
                }
            }
        }
    }

    function collectData() {
        var data = {
            "target_type": targetCombo.currentValue,
            "target_value": targetValueField.text,
            "exact_match": exactMatchCheck.checked,
            "action": actionCombo.currentValue,
            "comment": commentField.text,
            "params": []
        };

        var action = data.action;
        if (action === 'workspace' || action === 'movetoworkspace') {
            if(wsParam1.text) data.params.push(wsParam1.text);
            if(wsSilentCheck.checked) data.params.push('silent');
        } else if (action === 'move') {
            if(moveParam1.text) data.params.push(moveParam1.text);
            if(moveParam2.text) data.params.push(moveParam2.text);
        } else if (['size', 'minsize', 'maxsize'].includes(action)) {
            if(sizeParam1.text) data.params.push(sizeParam1.text);
            if(sizeParam2.text) data.params.push(sizeParam2.text);
        } else if (action === 'center') {
            data.params.push(centerParam.currentValue.startsWith('1') ? '1' : '0');
        } else if (action === 'opacity') {
            if(opacityOverrideCheck.checked) data.params.push('override');
            if(opacityParam1.text) data.params.push(opacityParam1.text);
            if(opacityParam2.text) data.params.push(opacityParam2.text);
        } else if (action === 'bordercolor') {
            if(borderColorParam1.text) data.params.push(borderColorParam1.text);
            if(borderColorParam2.text) data.params.push(borderColorParam2.text);
        } else if (action === 'idleinhibit') {
            data.params.push(idleParam.currentValue);
        } else if (['rounding', 'bordersize', 'animation', 'suppressevent', 'group'].includes(action)) {
            if(singleParamField.text) data.params.push(singleParamField.text);
        }
        // Для действий без параметров ничего не добавляем

        return data;
    }

    function openForNew() {
        isNew = true
        originalLine = ""
        // Сброс всех полей
        targetCombo.currentIndex = 0
        targetValueField.text = ""
        exactMatchCheck.checked = true
        actionCombo.currentIndex = 0
        wsParam1.text = ""
        wsSilentCheck.checked = false
        moveParam1.text = ""
        moveParam2.text = ""
        sizeParam1.text = ""
        sizeParam2.text = ""
        centerParam.currentIndex = 0
        opacityParam1.text = ""
        opacityParam2.text = ""
        opacityOverrideCheck.checked = false
        borderColorParam1.text = ""
        borderColorParam2.text = ""
        idleParam.currentIndex = 0
        singleParamField.text = ""
        commentField.text = ""

        visible = true
        requestActivate()
    }

    function openForEdit(model) {
        openForNew(); // Сначала сбрасываем все
        isNew = false
        originalLine = model.original_line

        // Заполняем на основе данных из Python
        targetCombo.currentIndex = targetModel.indexOf(model.parsed.target_type)
        targetValueField.text = model.parsed.target_value
        exactMatchCheck.checked = model.parsed.exact_match
        actionCombo.currentIndex = actionModel.indexOf(model.parsed.action)
        commentField.text = model.comment

        // Заполняем параметры
        var action = model.parsed.action;
        var params = model.parsed.params;

        if (action === 'workspace' || action === 'movetoworkspace') {
            wsParam1.text = params[0] || ""
            wsSilentCheck.checked = params.includes('silent')
        } else if (action === 'move') {
            moveParam1.text = params[0] || ""
            moveParam2.text = params[1] || ""
        } else if (['size', 'minsize', 'maxsize'].includes(action)) {
            sizeParam1.text = params[0] || ""
            sizeParam2.text = params[1] || ""
        } else if (action === 'center') {
            centerParam.currentIndex = (params[0] === '1') ? 0 : 1
        } else if (action === 'opacity') {
            opacityOverrideCheck.checked = params[0] === 'override'
            var values = opacityOverrideCheck.checked ? params.slice(1) : params
            opacityParam1.text = values[0] || ""
            opacityParam2.text = values[1] || ""
        } else if (action === 'bordercolor') {
            borderColorParam1.text = params[0] || ""
            borderColorParam2.text = params[1] || ""
        } else if (action === 'idleinhibit') {
            idleParam.currentIndex = idleParam.model.indexOf(params[0] || "none")
        } else if (['rounding', 'bordersize', 'animation', 'suppressevent', 'group'].includes(action)) {
            singleParamField.text = params.join(' ')
        }
    }

    function close() { visible = false }
}