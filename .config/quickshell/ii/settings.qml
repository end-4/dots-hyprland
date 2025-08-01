//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

// Adjust this to make the app smaller or larger
//@ pragma Env QT_SCALE_FACTOR=1

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions as CF

ApplicationWindow {
    id: root
    property string firstRunFilePath: CF.FileUtils.trimFileProtocol(`${Directories.state}/user/first_run.txt`)
    property string firstRunFileContent: "This file is just here to confirm you've been greeted :>"
    property real contentPadding: 8
    property bool showNextTime: false
    property var pages: [
        {
            name: Translation.tr("Style"),
            icon: "palette",
            component: "modules/settings/StyleConfig.qml",
            type: "item"
        },
        {
            name: Translation.tr("Interface"),
            icon: "cards",
            component: "modules/settings/InterfaceConfig.qml",
            type: "item"
        },
        {
            name: Translation.tr("Services"),
            icon: "settings",
            component: "modules/settings/ServicesConfig.qml",
            type: "item"
        },
        {
            type: "divider"
        },
        {
            name: Translation.tr("Advanced"),
            icon: "construction",
            component: "modules/settings/AdvancedConfig.qml",
            type: "item"
        },
        {
            name: Translation.tr("About"),
            icon: "info",
            component: "modules/settings/About.qml",
            type: "item"
        }
    ]
    property int currentPage: 0

    visible: true
    onClosing: Qt.quit()
    title: "illogical-impulse Settings"

    Component.onCompleted: {
        MaterialThemeLoader.reapplyTheme()
    }

    minimumWidth: 600
    minimumHeight: 400
    width: 1100
    height: 750
    color: Appearance.m3colors.m3background

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 0

        Keys.onPressed: (event) => {
            if (event.modifiers === Qt.ControlModifier) {
                if (event.key === Qt.Key_PageDown) {
                    root.currentPage = Math.min(root.currentPage + 1, root.pages.length - 1)
                    event.accepted = true;
                } 
                else if (event.key === Qt.Key_PageUp) {
                    root.currentPage = Math.max(root.currentPage - 1, 0)
                    event.accepted = true;
                }
                else if (event.key === Qt.Key_Tab) {
                    root.currentPage = (root.currentPage + 1) % root.pages.length;
                    event.accepted = true;
                }
                else if (event.key === Qt.Key_Backtab) {
                    root.currentPage = (root.currentPage - 1 + root.pages.length) % root.pages.length;
                    event.accepted = true;
                }
            }
        }

        Item { // Titlebar
            visible: Config.options?.windows.showTitlebar
            Layout.fillWidth: true
            Layout.fillHeight: false
            implicitHeight: Math.max(titleText.implicitHeight, windowControlsRow.implicitHeight)
            StyledText {
                id: titleText
                anchors {
                    left: Config.options.windows.centerTitle ? undefined : parent.left
                    horizontalCenter: Config.options.windows.centerTitle ? parent.horizontalCenter : undefined
                    verticalCenter: parent.verticalCenter
                    leftMargin: 12
                }
                color: Appearance.colors.colOnLayer0
                text: Translation.tr("Settings")
                font.pixelSize: Appearance.font.pixelSize.title
                font.family: Appearance.font.family.title
            }
            RowLayout { // Window controls row
                id: windowControlsRow
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                RippleButton {
                    buttonRadius: Appearance.rounding.full
                    implicitWidth: 35
                    implicitHeight: 35
                    onClicked: root.close()
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        text: "close"
                        iconSize: 20
                    }
                }
            }
        }

        Rectangle { // Window content with navigation rail and content pane
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Appearance.m3colors.m3background

            Item {
                id: menuContainer
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                implicitWidth: 200
                ColumnLayout {
                    id: menuLayout
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 10

                    ListView {
                        id: sidebar
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        spacing: 8
                        clip: true
                        model: root.pages
                        currentIndex: root.currentPage
                        onCurrentIndexChanged: root.currentPage = currentIndex

                        highlight: Rectangle {
                            color: Appearance.m3colors.m3primaryContainer
                            radius: Appearance.rounding.small
                            visible: modelData.type !== "divider"
                        }
                        highlightMoveDuration: 0

                        delegate: Item {
                            id: row
                            width: ListView.view.width
                            height: modelData.type === "divider" ? 1 : 44

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: sidebar.width
                                height: 1
                                color: Appearance.m3colors.m3outline
                                visible: modelData.type === "divider"
                            }

                            RowLayout {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: 24
                                spacing: 12
                                visible: modelData.type !== "divider"

                                MaterialSymbol { text: modelData.icon; iconSize: 20 }
                                Label {
                                    text: modelData.name
                                    color: Appearance.colors.colOnLayer0
                                }
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: Appearance.rounding.small
                                color: ma.containsMouse && sidebar.currentIndex !== index ? Appearance.m3colors.m3surfaceContainerHigh : "transparent"
                                z: -1
                                visible: modelData.type !== "divider"
                            }

                            MouseArea {
                                id: ma
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: sidebar.currentIndex = index
                                enabled: modelData.type !== "divider"
                            }
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                    }

                    Item { // Edit config button
                        Layout.fillWidth: true
                        implicitHeight: 44

                        RowLayout {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: 24
                            spacing: 12

                            MaterialSymbol { text: "edit"; iconSize: 20 }
                            Label {
                                text: Translation.tr("Edit config")
                                color: Appearance.colors.colOnLayer0
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: Appearance.rounding.small
                            color: ma_edit.containsMouse ? Appearance.m3colors.m3surfaceContainerHigh : "transparent"
                            z: -1
                        }

                        MouseArea {
                            id: ma_edit
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: Qt.openUrlExternally(`${Directories.config}/illogical-impulse/config.json`)
                        }
                    }
                }
            }
            Rectangle { // Content container
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.left: menuContainer.right
                anchors.right: parent.right
                anchors.leftMargin: 6
                color: Appearance.m3colors.m3surfaceContainerLow
                radius: Appearance.rounding.windowRounding - root.contentPadding

                Loader {
                    id: pageLoader
                    anchors.fill: parent
                    opacity: 1.0
                    source: root.pages[0].component
                    Connections {
                        target: root
                        function onCurrentPageChanged() {
                            if (pageLoader.sourceComponent !== root.pages[root.currentPage].component) {
                                switchAnim.complete();
                                switchAnim.start();
                            }
                        }
                    }

                    SequentialAnimation {
                        id: switchAnim

                        NumberAnimation {
                            target: pageLoader
                            properties: "opacity"
                            from: 1
                            to: 0
                            duration: 100
                            easing.type: Appearance.animation.elementMoveExit.type
                            easing.bezierCurve: Appearance.animationCurves.emphasizedFirstHalf
                        }
                        PropertyAction {
                            target: pageLoader
                            property: "source"
                            value: root.pages[root.currentPage].component
                        }
                        NumberAnimation {
                            target: pageLoader
                            properties: "opacity"
                            from: 0
                            to: 1
                            duration: 200
                            easing.type: Appearance.animation.elementMoveEnter.type
                            easing.bezierCurve: Appearance.animationCurves.emphasizedLastHalf
                        }
                    }
                }
            }
        }
    }
}
