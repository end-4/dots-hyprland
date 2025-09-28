// hyprland-settings/qml/AutostartPage.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import App 1.0
import Components 1.0
import Controls 1.0

Rectangle {
    color: Theme.surfaceContainerLow

    property bool systemEditWarningShown: false

    ListModel { id: allEntriesModel }
    ListModel { id: filteredEntriesModel }

    function filterEntries() {
        filteredEntriesModel.clear();
        var searchText = searchField.text.toLowerCase();
        var showSystem = systemCheckBox.checked;

        for (var i = 0; i < allEntriesModel.count; i++) {
            var entry = allEntriesModel.get(i);
            if (!showSystem && entry.is_system) {
                continue;
            }

            if (searchText === "" ||
                entry.title.toLowerCase().includes(searchText) ||
                entry.command.toLowerCase().includes(searchText)) {
                filteredEntriesModel.append(entry);
            }
        }
    }

    Connections {
        target: AutostartBridge
        function onAutostartChanged() {
            allEntriesModel.clear()
            var entries = AutostartBridge.getAutostartEntries()
            for (var i = 0; i < entries.length; i++) {
                allEntriesModel.append(entries[i])
            }
            filterEntries()
        }
    }

    Component.onCompleted: {
        AutostartBridge.load_autostart_entries()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 80
            color: Theme.surfaceContainer
            
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 16

                StyledTextField {
                    id: searchField
                    Layout.fillWidth: true
                    placeholderText: qsTr("Search by commands and titles...")
                    onTextChanged: filterEntries()
                }

                CheckBox {
                    id: systemCheckBox
                    text: qsTr("System")
                    checked: false
                    onCheckedChanged: filterEntries()
                    indicator: Rectangle {
                        implicitWidth: 20
                        implicitHeight: 20
                        x: systemCheckBox.leftPadding
                        y: parent.height / 2 - height / 2
                        radius: 4
                        border.color: Theme.outline
                        color: systemCheckBox.checked ? Theme.primary : "transparent"

                        Text {
                            text: "✔"
                            visible: systemCheckBox.checked
                            anchors.centerIn: parent
                            color: Theme.surfaceContainer
                            font.pixelSize: 14
                        }
                    }
                    contentItem: Text {
                        text: systemCheckBox.text
                        font: systemCheckBox.font
                        color: Theme.text
                        leftPadding: systemCheckBox.indicator.width + systemCheckBox.spacing
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }

        ListView {
            id: entriesView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: filteredEntriesModel
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

            delegate: Rectangle {
                id: delegateRoot // Даем имя корневому элементу
                width: entriesView.width - 32
                implicitHeight: textColumn.implicitHeight + 32
                color: mouseArea.containsMouse ? Theme.surfaceContainerHigh : Theme.surfaceContainer
                radius: Theme.radius
                border.width: 1
                border.color: Theme.outline

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    propagateComposedEvents: true
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
                            text: model.title || qsTr("No title")
                            color: Theme.text
                            font.pixelSize: 16
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                        }
                        Label {
                            text: model.command
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

                        // --- Кнопка Изменить ---
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
                                onClicked: {
                                    if (model.is_system && !systemEditWarningShown) {
                                        confirmSystemEditDialog.text = qsTr("You are about to change a system autostart entry. This may break some components. Are you sure you want to continue?\n\nThis warning will not be shown again in this session.")
                                        confirmSystemEditDialog.openWithCallback(function() {
                                            systemEditWarningShown = true
                                            autostartEditDialog.openForEdit(model)
                                        })
                                    } else {
                                        autostartEditDialog.openForEdit(model)
                                    }
                                }
                            }
                        }

                        // --- Кнопка Удалить ---
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
                                    var performDelete = function() {
                                        confirmDeleteDialog.text = qsTr("Delete \"%1\"?").arg(model.title || model.command)
                                        confirmDeleteDialog.openWithCallback(function() {
                                            AutostartBridge.removeAutostart(model.original_line)
                                        })
                                    }
    
                                    if (model.is_system && !systemEditWarningShown) {
                                        confirmSystemEditDialog.text = qsTr("You are about to delete a system autostart entry. This may break some components. Are you sure you want to continue?\n\nThis warning will not be shown again in this session.")
                                        confirmSystemEditDialog.openWithCallback(function() {
                                            systemEditWarningShown = true
                                            performDelete()
                                        })
                                    } else {
                                        performDelete()
                                    }
                                }
                            }
                        }
                    }
                }
                
                // --- ИСПРАВЛЕНО: Затемняющий Rectangle вынесен из RowLayout ---
                Rectangle {
                    anchors.fill: parent // Теперь он привязан к delegateRoot, а не к Layout
                    color: Theme.surfaceContainer
                    opacity: 0.5
                    visible: model.is_system && !mouseArea.containsMouse
                    radius: Theme.radius
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
            }
        }
    }

    Button {
        id: fab
        anchors { right: parent.right; bottom: parent.bottom; margins: 24 }
        width: 56; height: 56
        text: "+"
        font.pixelSize: 28
        background: Rectangle { color: Theme.primary; radius: 28 }
        onClicked: autostartEditDialog.openForNew()
    }
}