//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic

// Adjust this to make the app smaller or larger
//@ pragma Env QT_SCALE_FACTOR=1

import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "root:/services/"
import "root:/modules/common/"
import "root:/modules/common/widgets/"
import "root:/modules/common/functions/color_utils.js" as ColorUtils
import "root:/modules/common/functions/file_utils.js" as FileUtils
import "root:/modules/common/functions/string_utils.js" as StringUtils

ApplicationWindow {
    id: root
    property string firstRunFilePath: FileUtils.trimFileProtocol(`${Directories.state}/user/first_run.txt`)
    property string firstRunFileContent: "This file is just here to confirm you've been greeted :>"
    property real contentPadding: 8
    property bool showNextTime: false
    property var pages: [
        {
            name: "Style",
            icon: "palette",
            component: "modules/settings/StyleConfig.qml"
        },
        {
            name: "Interface",
            icon: "cards",
            component: "modules/settings/InterfaceConfig.qml"
        },
        {
            name: "Services",
            icon: "settings",
            component: "modules/settings/ServicesConfig.qml"
        },
        {
            name: "About",
            icon: "info",
            component: "modules/settings/About.qml"
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
        anchors {
            fill: parent
            margins: contentPadding
        }

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
                text: "Settings"
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

        RowLayout { // Window content with navigation rail and content pane
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: contentPadding
            Item {
                id: navRailWrapper
                Layout.fillHeight: true
                Layout.margins: 5
                implicitWidth: navRail.expanded ? 150 : fab.baseSize
                Behavior on implicitWidth {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
                NavigationRail { // Window content with navigation rail and content pane
                    id: navRail
                    anchors {
                        left: parent.left
                        top: parent.top
                        bottom: parent.bottom
                    }
                    spacing: 10
                    expanded: root.width > 900
                    
                    NavigationRailExpandButton {
                        focus: root.visible
                    }

                    FloatingActionButton {
                        id: fab
                        iconText: "edit"
                        buttonText: "Edit config"
                        expanded: navRail.expanded
                        onClicked: {
                            Qt.openUrlExternally(`${Directories.config}/illogical-impulse/config.json`);
                        }

                        StyledToolTip {
                            extraVisibleCondition: !navRail.expanded
                            content: "Edit shell config file"
                        }
                    }

                    NavigationRailTabArray {
                        currentIndex: root.currentPage
                        expanded: navRail.expanded
                        Repeater {
                            model: root.pages
                            NavigationRailButton {
                                required property var index
                                required property var modelData
                                toggled: root.currentPage === index
                                onClicked: root.currentPage = index;
                                expanded: navRail.expanded
                                buttonIcon: modelData.icon
                                buttonText: modelData.name
                                showToggledHighlight: false
                            }
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                    }
                }
            }
            Rectangle { // Content container
                Layout.fillWidth: true
                Layout.fillHeight: true
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
