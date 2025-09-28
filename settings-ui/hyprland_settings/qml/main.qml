// hyprland-settings/qml/main.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import App 1.0
import Components 1.0
import Controls 1.0

ApplicationWindow {
    id: root
    visible: true
    title: (LanguageManager.retranslateDummy, qsTr("Hyprland Advanced Settings"))

    minimumWidth: 800
    minimumHeight: 600
    width: 1100
    height: 750

    color: Theme.background ? Theme.background : "#111"

    property int currentPageIndex: 0

    Component {
        id: navModelComp
        ListModel {
            ListElement { name: qsTr("Keybinds"); icon: "keyboard"; page: "KeybindsPage.qml" }
            ListElement { name: qsTr("Autostart"); icon: "rocket_launch"; page: "AutostartPage.qml" }
            ListElement { name: qsTr("Window Rules"); icon: "view_quilt"; page: "WindowRulesPage.qml" }
            ListElement { name: qsTr("Displays"); icon: "desktop_windows"; page: "DisplaysPage.qml" }
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            id: sidebar
            Layout.preferredWidth: 220
            Layout.fillHeight: true
            color: Theme.surfaceContainer

            ScrollView {
                anchors {
                    left: parent.left
                    top: parent.top
                    right: parent.right
                    bottom: parent.bottom
                    bottomMargin: 100
                }
                clip: true

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
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                Item {
                    width: parent.width
                    height: navView.contentHeight + 48

                    Item {
                        anchors.top: parent.top
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.topMargin: 24
                        width: 196
                        height: navView.contentHeight

                        Rectangle {
                            id: highlight
                            width: 196
                            height: 56
                            radius: 28
                            color: Theme.secondaryContainer
                            y: navView.currentItem ? navView.currentItem.y : 0

                            Behavior on y {
                                SpringAnimation {
                                    spring: 4.5
                                    damping: 0.25
                                }
                            }
                        }

                        ListView {
                            id: navView
                            anchors.fill: parent
                            interactive: false
                            spacing: 8
                            currentIndex: root.currentPageIndex
                            
                            delegate: NavigationButton {
                                text: model.name
                                iconName: model.icon
                                highlighted: root.currentPageIndex === index
                                
                                onClicked: {
                                    root.currentPageIndex = index
                                    pageLoader.source = model.page
                                }
                            }
                        }
                    }
                }
            }
            StyledComboBox {
                id: languageSelector
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottomMargin: 24
                width: 196
                textRole: "display"
                // --- СТРОКА НИЖЕ УДАЛЕНА ---
                // popupY: -244 
                model: ListModel { id: languageModel }

                function populateModel() {
                    languageModel.clear()
                    if (LanguageManager && LanguageManager.availableTranslations) {
                        for (var j = 0; j < LanguageManager.availableTranslations.length; ++j) {
                            var trans = LanguageManager.availableTranslations[j]
                            languageModel.append({display: trans.display, locale: trans.locale})
                        }
                    }
                }

                function updateCurrentIndex() {
                    if (!LanguageManager) return;
                    var current = LanguageManager.currentLocale
                    for (var i = 0; i < languageModel.count; ++i) {
                        if (languageModel.get(i).locale === current) {
                            currentIndex = i
                            return
                        }
                    }
                    currentIndex = 0
                }

                onCurrentIndexChanged: {
                    if (LanguageManager && currentIndex >= 0 && currentIndex < languageModel.count) {
                        var selectedLocale = languageModel.get(currentIndex).locale
                        LanguageManager.setLanguage(selectedLocale)
                    }
                }
            }
        }

        Loader {
            id: pageLoader
            Layout.fillWidth: true
            Layout.fillHeight: true
            source: navView.model ? navView.model.get(root.currentPageIndex).page : ""
        }
    }

    Component.onCompleted: {
        navView.model = navModelComp.createObject(navView);
        languageSelector.populateModel();
        languageSelector.updateCurrentIndex();
    }

    Connections {
        target: LanguageManager
        function onLanguageChanged() {
            if (navView.model) {
                navView.model.destroy();
            }
            navView.model = navModelComp.createObject(navView);
            languageSelector.populateModel();
            languageSelector.updateCurrentIndex();
            var currentPageFile = pageLoader.source;
            pageLoader.source = ""; 
            pageLoader.source = currentPageFile;
        }
    }

    // --- ГЛОБАЛЬНЫЕ ДИАЛОГИ ---
    KeyCaptureDialog { id: keyCaptureDialog }
    ConfirmationDialog { id: confirmDeleteDialog }
    ConfirmationDialog { id: confirmSystemEditDialog }
    AutostartEditDialog { id: autostartEditDialog }
    ConfirmationDialog { id: confirmOverwriteDialog }
    WindowRuleEditDialog { id: windowRuleEditDialog }
}