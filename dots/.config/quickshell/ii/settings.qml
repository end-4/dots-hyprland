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
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions as CF

ApplicationWindow {
    id: root
    property string firstRunFilePath: CF.FileUtils.trimFileProtocol(`${Directories.state}/user/first_run.txt`)
    property string firstRunFileContent: "This file is just here to confirm you've been greeted :>"
    property real contentPadding: 16
    property bool showNextTime: false

    property var sections: [
        {
            title: Translation.tr("Core system"),
            subpages: [
                { name: Translation.tr("Quick settings"), icon: "instant_mix", component: "modules/settings/QuickConfig.qml" },
                { name: Translation.tr("General configuration"), icon: "browse", component: "modules/settings/GeneralConfig.qml" },
                { name: Translation.tr("Advanced settings"), icon: "construction", component: "modules/settings/AdvancedConfig.qml" }
            ]
        },
        {
            title: Translation.tr("Interface & style"),
            subpages: [
                { name: Translation.tr("Desktop bar"), icon: "toast", iconRotation: 180, component: "modules/settings/BarConfig.qml" },
                { name: Translation.tr("Wallpapers"), icon: "texture", component: "modules/settings/BackgroundConfig.qml" },
                { name: Translation.tr("Visual theme"), icon: "bottom_app_bar", component: "modules/settings/InterfaceConfig.qml" }
            ]
        },
        {
            title: Translation.tr("System management"),
            subpages: [
                { name: Translation.tr("Background services"), icon: "settings", component: "modules/settings/ServicesConfig.qml" },
                { name: Translation.tr("About shell"), icon: "info", component: "modules/settings/About.qml" }
            ]
        }
    ]

    property string currentComponent: "modules/settings/QuickConfig.qml"

    property var flatPages: {
        let arr = [];
        for (let i = 0; i < sections.length; i++) {
            for (let j = 0; j < sections[i].subpages.length; j++) {
                arr.push(sections[i].subpages[j].component);
            }
        }
        return arr;
    }
    property int flatIndex: flatPages.indexOf(currentComponent)

    visible: true
    onClosing: Qt.quit()
    title: "illogical-impulse Settings"

    Component.onCompleted: {
        MaterialThemeLoader.reapplyTheme()
        Config.readWriteDelay = 0
    }

    minimumWidth: 850
    minimumHeight: 600
    width: 1150
    height: 800
    color: Appearance.m3colors.m3background

    ColumnLayout {
        anchors {
            fill: parent
            margins: contentPadding
        }
        spacing: 12

        Keys.onPressed: (event) => {
            if (event.modifiers === Qt.ControlModifier) {
                let len = root.flatPages.length;
                if (event.key === Qt.Key_PageDown || event.key === Qt.Key_Tab) {
                    root.currentComponent = root.flatPages[(root.flatIndex + 1) % len];
                    event.accepted = true;
                }
                else if (event.key === Qt.Key_PageUp || event.key === Qt.Key_Backtab) {
                    root.currentComponent = root.flatPages[(root.flatIndex - 1 + len) % len];
                    event.accepted = true;
                }
            }
        }

        Item {
            visible: Config.options?.windows.showTitlebar
            Layout.fillWidth: true
            Layout.fillHeight: false
            implicitHeight: 38

            StyledText {
                id: titleText
                anchors {
                    left: Config.options.windows.centerTitle ? undefined : parent.left
                    horizontalCenter: Config.options.windows.centerTitle ? parent.horizontalCenter : undefined
                    verticalCenter: parent.verticalCenter
                }
                color: Appearance.colors.colOnLayer0
                text: Translation.tr("Settings")
                font {
                    family: Appearance.font.family.title
                    pixelSize: 13
                    weight: Font.Bold
                }
            }
            RowLayout {
                id: windowControlsRow
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                RippleButton {
                    buttonRadius: Appearance.rounding.full
                    implicitWidth: 28
                    implicitHeight: 28
                    onClicked: root.close()
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        text: "close"
                        iconSize: 16
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 16

            Item {
                id: navRailWrapper
                Layout.fillHeight: true
                implicitWidth: navRail.expanded ? 240 : 64

                Behavior on implicitWidth {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutQuint
                    }
                }

                NavigationRail {
                    id: navRail
                    anchors.fill: parent
                    spacing: 16
                    expanded: root.width > 950

                    NavigationRailExpandButton {
                        focus: root.visible
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                    }

                    FloatingActionButton {
                        id: fab
                        property bool justCopied: false
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        iconText: justCopied ? "check" : "edit"
                        buttonText: navRail.expanded ? (justCopied ? Translation.tr("Copied path") : Translation.tr("Source config")) : ""
                        expanded: navRail.expanded
                        downAction: () => {
                            Qt.openUrlExternally(`${Directories.config}/illogical-impulse/config.json`);
                        }
                        altAction: () => {
                            Quickshell.clipboardText = CF.FileUtils.trimFileProtocol(`${Directories.config}/illogical-impulse/config.json`);
                            fab.justCopied = true;
                            revertTextTimer.restart()
                        }

                        Timer {
                            id: revertTextTimer
                            interval: 1500
                            onTriggered: { fab.justCopied = false; }
                        }

                        StyledToolTip {
                            text: Translation.tr("Open raw JSON config")
                        }
                    }

                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        contentWidth: availableWidth
                        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                        ScrollBar.vertical.policy: ScrollBar.AsNeeded

                        ColumnLayout {
                            id: sidebarItemsContainer
                            width: parent.width
                            spacing: 20

                            Repeater {
                                model: root.sections
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    StyledText {
                                        text: modelData.title.toUpperCase()
                                        color: Appearance.colors.colOnLayer0
                                        opacity: navRail.expanded ? 0.5 : 0.0
                                        Layout.fillWidth: true
                                        Layout.leftMargin: 14
                                        Layout.bottomMargin: navRail.expanded ? 4 : 0
                                        Layout.preferredHeight: navRail.expanded ? implicitHeight : 0

                                        font {
                                            pixelSize: 10
                                            weight: Font.Black
                                            letterSpacing: 1.2
                                        }

                                        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                                        Behavior on Layout.preferredHeight { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                                        Behavior on Layout.bottomMargin { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                                    }

                                    Repeater {
                                        model: modelData.subpages
                                        Item {
                                            id: sideBtn
                                            required property var modelData
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 44

                                            property bool isSelected: root.currentComponent === modelData.component

                                            Rectangle {
                                                id: buttonBg
                                                anchors.left: parent.left
                                                anchors.leftMargin: 10
                                                width: navRail.expanded ? parent.width - 20 : 44
                                                height: parent.height
                                                radius: navRail.expanded ? 12 : 22
                                                color: sideBtn.isSelected ? Appearance.m3colors.m3secondaryContainer : "transparent"

                                                Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutQuint } }
                                                Behavior on radius { NumberAnimation { duration: 250; easing.type: Easing.OutQuint } }
                                                Behavior on color { ColorAnimation { duration: 180 } }

                                                transform: Scale {
                                                    id: squishScale
                                                    origin.x: buttonBg.width / 2
                                                    origin.y: buttonBg.height / 2
                                                    yScale: 1.0
                                                    xScale: 1.0
                                                }

                                                Connections {
                                                    target: sideBtn
                                                    function onIsSelectedChanged() {
                                                        if (sideBtn.isSelected) {
                                                            selectAnim.restart();
                                                        }
                                                    }
                                                }

                                                SequentialAnimation {
                                                    id: selectAnim
                                                    ParallelAnimation {
                                                        NumberAnimation { target: squishScale; property: "yScale"; to: 0.75; duration: 90; easing.type: Easing.OutQuad }
                                                        NumberAnimation { target: squishScale; property: "xScale"; to: 1.08; duration: 90; easing.type: Easing.OutQuad }
                                                    }
                                                    ParallelAnimation {
                                                        NumberAnimation { target: squishScale; property: "yScale"; to: 1.0; duration: 240; easing.type: Easing.OutBack }
                                                        NumberAnimation { target: squishScale; property: "xScale"; to: 1.0; duration: 240; easing.type: Easing.OutBack }
                                                    }
                                                }

                                                RippleButton {
                                                    anchors.fill: parent
                                                    buttonRadius: parent.radius
                                                    onClicked: root.currentComponent = modelData.component

                                                    RowLayout {
                                                        anchors.fill: parent
                                                        spacing: 0

                                                        Item {
                                                            Layout.preferredWidth: 44
                                                            Layout.fillHeight: true

                                                            MaterialSymbol {
                                                                anchors.centerIn: parent
                                                                text: modelData.icon
                                                                iconSize: 22
                                                                rotation: modelData.iconRotation || 0
                                                                color: sideBtn.isSelected ? Appearance.m3colors.m3onSecondaryContainer : Appearance.colors.colOnLayer0
                                                            }
                                                        }

                                                        Item {
                                                            Layout.fillWidth: true
                                                            Layout.fillHeight: true
                                                            clip: true
                                                            visible: navRail.expanded

                                                            StyledText {
                                                                text: modelData.name
                                                                anchors.verticalCenter: parent.verticalCenter
                                                                anchors.left: parent.left
                                                                anchors.right: parent.right
                                                                anchors.rightMargin: 16
                                                                color: sideBtn.isSelected ? Appearance.m3colors.m3onSecondaryContainer : Appearance.colors.colOnLayer0
                                                                font.weight: sideBtn.isSelected ? Font.Bold : Font.Normal
                                                                font.pixelSize: 13
                                                                wrapMode: Text.NoWrap
                                                                elide: Text.ElideRight

                                                                opacity: navRail.expanded ? 1.0 : 0.0
                                                                Behavior on opacity { NumberAnimation { duration: 200 } }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Appearance.m3colors.m3surfaceContainer
                radius: Appearance.rounding.windowRounding

                Item {
                    id: containerWrapper
                    anchors.fill: parent
                    anchors.margins: 16

                    Loader {
                        id: pageLoader
                        anchors.fill: parent
                        opacity: 1.0
                        scale: 1.0
                        active: Config.ready

                        transform: Translate {
                            id: loaderTranslate
                            y: 0
                        }

                        Component.onCompleted: {
                            source = root.currentComponent
                        }

                        Connections {
                            target: root
                            function onCurrentComponentChanged() {
                                switchAnim.complete();
                                switchAnim.start();
                            }
                        }

                        SequentialAnimation {
                            id: switchAnim

                            ParallelAnimation {
                                NumberAnimation {
                                    target: pageLoader
                                    property: "opacity"
                                    to: 0
                                    duration: 100
                                    easing.type: Easing.OutCubic
                                }
                                NumberAnimation {
                                    target: pageLoader
                                    property: "scale"
                                    to: 0.96
                                    duration: 100
                                    easing.type: Easing.OutCubic
                                }
                                NumberAnimation {
                                    target: loaderTranslate
                                    property: "y"
                                    to: 10
                                    duration: 100
                                    easing.type: Easing.OutCubic
                                }
                            }

                            PropertyAction {
                                target: pageLoader
                                property: "source"
                                value: root.currentComponent
                            }

                            ParallelAnimation {
                                NumberAnimation {
                                    target: pageLoader
                                    property: "opacity"
                                    to: 1
                                    duration: 300
                                    easing.type: Easing.OutCubic
                                }
                                NumberAnimation {
                                    target: pageLoader
                                    property: "scale"
                                    to: 1.0
                                    duration: 300
                                    easing.type: Easing.OutBack
                                }
                                NumberAnimation {
                                    target: loaderTranslate
                                    property: "y"
                                    from: -10
                                    to: 0
                                    duration: 300
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
