// hyprland-settings/qml/WindowRulesPage.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import App 1.0
import Components 1.0
import Controls 1.0

Rectangle {
    color: Theme.surfaceContainerLow

    ListModel { id: allRulesModel }
    ListModel { id: filteredRulesModel }

    function filterRules() {
        filteredRulesModel.clear();
        var searchText = searchField.text.toLowerCase();
        for (var i = 0; i < allRulesModel.count; i++) {
            var rule = allRulesModel.get(i);
            if (searchText === "" ||
                rule.description.toLowerCase().includes(searchText) ||
                rule.comment.toLowerCase().includes(searchText) ||
                rule.target.toLowerCase().includes(searchText)) {
                filteredRulesModel.append(rule);
            }
        }
    }

    Connections {
        target: WindowRulesBridge
        function onRulesChanged() {
            allRulesModel.clear()
            var rules = WindowRulesBridge.getRules()
            for (var i = 0; i < rules.length; i++) {
                allRulesModel.append(rules[i])
            }
            filterRules()
        }
    }

    Component.onCompleted: {
        WindowRulesBridge.load_rules()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 80
            color: Theme.surfaceContainer
            
            StyledTextField {
                id: searchField
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                placeholderText: qsTr("Search by rules, windows and comments...")
                onTextChanged: filterRules()
            }
        }

        ListView {
            id: rulesView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: filteredRulesModel
            spacing: 12
            topMargin: 16
            leftMargin: 16
            rightMargin: 16
            bottomMargin: 16
            footer: Item { width: 1; height: 64 }

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
                background: Rectangle { color: "transparent" }
                contentItem: Rectangle {
                    implicitWidth: 8
                    color: Theme.surfaceContainerHigh
                    radius: 4
                    opacity: parent.active ? 0.8 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }
            }
            
            // ИСПРАВЛЕНО: Удалена строка ниже, вызывавшая ошибку
            // ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            delegate: Rectangle {
                width: rulesView.width - 32
                implicitHeight: textColumn.implicitHeight + 32
                color: mouseArea.containsMouse ? Theme.surfaceContainerHigh : Theme.surfaceContainer
                radius: Theme.radius
                border.width: 1
                border.color: Theme.outline

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    propagateComposedEvents: true // ИСПРАВЛЕНО: Добавлено для работы прокрутки
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 8

                    ColumnLayout {
                        id: textColumn
                        Layout.maximumWidth: parent.width - 150
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 4

                        Label {
                            text: model.comment || qsTr("Rule without title")
                            color: Theme.text
                            font.pixelSize: 16
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                        }

                        Text {
                            text: model.target
                            color: Theme.primary
                            font.family: Theme.monoFont.family
                            font.pixelSize: 14
                            elide: Text.ElideRight
                        }

                        Label {
                            text: model.description
                            color: Theme.subtext
                            font.pixelSize: 12
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                    }
                    
                    Item {
                        Layout.fillWidth: true
                    }

                    RowLayout {
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 4

                        Rectangle {
                            width: 40; height: 40; radius: 20
                            color: "transparent"
                            border.width: 2
                            border.color: editMouseArea.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.4) : "transparent"
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "edit"
                                color: Theme.primary
                            }
                            MouseArea {
                                id: editMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: windowRuleEditDialog.openForEdit(model)
                            }
                        }

                        Rectangle {
                            width: 40; height: 40; radius: 20
                            color: "transparent"
                            border.width: 2
                            border.color: deleteMouseArea.containsMouse ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.4) : "transparent"
                            Behavior on border.color { ColorAnimation { duration: 150 } }
                            
                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "delete"
                                color: Theme.error
                            }
                            MouseArea {
                                id: deleteMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    confirmDeleteDialog.text = qsTr("Delete \"%1\"?").arg(model.comment || model.target)
                                    confirmDeleteDialog.openWithCallback(function() {
                                        WindowRulesBridge.removeRule(model.original_line)
                                    })
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Button {
        id: fab
        anchors {
            right: parent.right
            bottom: parent.bottom
            margins: 24
        }
        width: 56; height: 56
        text: "+"
        font.pixelSize: 28
        background: Rectangle {
            color: Theme.primary
            radius: 28
        }
        onClicked: windowRuleEditDialog.openForNew()
    }
}