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
import qs.modules.common.functions
import qs.modules.common.functions as CF

ApplicationWindow {
    id: root
    property string firstRunFilePath: CF.FileUtils.trimFileProtocol(`${Directories.state}/user/first_run.txt`)
    property string firstRunFileContent: "This file is just here to confirm you've been greeted :>"
    property real contentPadding: 8
    property bool showNextTime: false
    property bool settingsReady: false
    property bool animateInnerRail: false
    property var iiPages: [
        {
            name: Translation.tr("Quick"),
            icon: "instant_mix",
            component: "modules/settings/QuickConfig.qml"
        },
        {
            name: Translation.tr("General"),
            icon: "browse",
            component: "modules/settings/GeneralConfig.qml"
        },
        {
            name: Translation.tr("Bar"),
            icon: "toast",
            iconRotation: 180,
            component: "modules/settings/BarConfig.qml"
        },
        {
            name: Translation.tr("Background"),
            icon: "texture",
            component: "modules/settings/BackgroundConfig.qml"
        },
        {
            name: Translation.tr("Interface"),
            icon: "bottom_app_bar",
            component: "modules/settings/InterfaceConfig.qml"
        },
        {
            name: Translation.tr("Services"),
            icon: "settings",
            component: "modules/settings/ServicesConfig.qml"
        },
        {
            name: Translation.tr("Advanced"),
            icon: "construction",
            component: "modules/settings/AdvancedConfig.qml"
        },
        {
            name: Translation.tr("About"),
            icon: "info",
            component: "modules/settings/About.qml"
        }
    ]
    property var categories: [
        {
            name: "illogical-impulse",
            icon: "settings",
            customIcon: "illogical-impulse-symbolic.svg",
            pages: iiPages
        },
        {
            name: "Connectivity",
            icon: "settings_input_antenna",
            pages: [
                {
                    name: Translation.tr("Wi-Fi"),
                    icon: "wifi",
                    component: "modules/settings/system/WifiConfig.qml"
                },
                {
                    name: Translation.tr("Saved\nnetworks"),
                    icon: "bookmark",
                    component: "modules/settings/system/WifiKnownConfig.qml"
                },
                {
                    name: Translation.tr("Bluetooth"),
                    icon: "bluetooth",
                    component: "modules/settings/system/BluetoothConfig.qml"
                },
                {
                    name: Translation.tr("VPN"),
                    icon: "vpn_key",
                    component: "modules/settings/system/VpnConfig.qml"
                },
                {
                    name: Translation.tr("Advanced"),
                    icon: "tune",
                    component: "modules/settings/system/WifiAdvancedConfig.qml"
                }
            ]
        },
        {
            name: "Monitor",
            icon: "monitor",
            component: "modules/settings/system/MonitorConfig.qml"
        },
        {
            name: "KDE",
            icon: "palette",
            component: "modules/settings/system/KdeConfig.qml"
        }
    ]
    property int currentCategory: 0
    property int currentPage: 0
    readonly property bool categoryOpen: currentCategory >= 0
    readonly property var currentCategoryData: categoryOpen ? categories[currentCategory] : ({})
    readonly property bool currentCategoryHasPages: categoryOpen && currentCategoryData.pages !== undefined
    readonly property string currentComponent: !categoryOpen ? "modules/settings/SettingsHome.qml"
        : currentCategoryHasPages ? currentCategoryData.pages[currentPage].component
        : currentCategoryData.component

    function openCategory(index) {
        animateInnerRail = false;
        currentCategory = index;
        currentPage = 0;
        categoryRail.expanded = false;
        enableInnerRailAnimationTimer.restart();
    }

    visible: true
    onClosing: Qt.quit()
    title: "illogical-impulse Settings"

    Component.onCompleted: {
        MaterialThemeLoader.reapplyTheme()
        Config.readWriteDelay = 0 // Settings app always only sets one var at a time so delay isn't needed
        settingsReady = true
        enableInnerRailAnimationTimer.restart();
    }

    Timer {
        id: enableInnerRailAnimationTimer
        interval: 50
        repeat: false
        onTriggered: {
            root.animateInnerRail = true;
        }
    }

    minimumWidth: 750
    minimumHeight: 500
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
                    if (root.currentCategoryHasPages)
                        root.currentPage = Math.min(root.currentPage + 1, root.categories[root.currentCategory].pages.length - 1)
                    event.accepted = true;
                } 
                else if (event.key === Qt.Key_PageUp) {
                    if (root.currentCategoryHasPages)
                        root.currentPage = Math.max(root.currentPage - 1, 0)
                    event.accepted = true;
                }
                else if (event.key === Qt.Key_Tab) {
                    if (root.currentCategoryHasPages)
                        root.currentPage = (root.currentPage + 1) % root.categories[root.currentCategory].pages.length;
                    event.accepted = true;
                }
                else if (event.key === Qt.Key_Backtab) {
                    if (root.currentCategoryHasPages)
                        root.currentPage = (root.currentPage - 1 + root.categories[root.currentCategory].pages.length) % root.categories[root.currentCategory].pages.length;
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
                font {
                    family: Appearance.font.family.title
                    pixelSize: Appearance.font.pixelSize.title
                    variableAxes: Appearance.font.variableAxes.title
                }
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
            spacing: 0
            Item {
                id: categoryRailWrapper
                Layout.fillHeight: true
                Layout.leftMargin: 5
                Layout.rightMargin: contentPadding
                Layout.topMargin: 5
                Layout.bottomMargin: 5
                implicitWidth: categoryRail.expanded ? 184 : 56
                Behavior on implicitWidth {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
                NavigationRail {
                    id: categoryRail
                    anchors {
                        left: parent.left
                        top: parent.top
                        bottom: parent.bottom
                    }
                    spacing: 10
                    expanded: false

                    NavigationRailExpandButton {
                        focus: root.visible
                    }

                    NavigationRailTabArray {
                        currentIndex: root.currentCategory
                        expanded: categoryRail.expanded
                        Layout.topMargin: 25
                        Repeater {
                            model: root.categories
                            NavigationRailButton {
                                required property var index
                                required property var modelData
                                toggled: root.currentCategory === index
                                onPressed: root.openCategory(index)
                                expanded: categoryRail.expanded
                                buttonIcon: modelData.icon
                                customIconSource: modelData.customIcon || ""
                                buttonText: modelData.name
                                showCollapsedText: false
                                showToggledHighlight: false
                            }
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                    }
                }
            }

            Item {
                id: navRailWrapper
                readonly property int leftPadding: 8
                readonly property int rightPadding: 8
                visible: root.currentCategoryHasPages
                Layout.fillHeight: true
                implicitWidth: visible ? ((navRail.expanded ? 150 : fab.baseSize) + leftPadding + rightPadding) : 0
                Behavior on implicitWidth {
                    enabled: root.settingsReady && root.animateInnerRail
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }

                Rectangle {
                    anchors.fill: parent
                    color: ColorUtils.mix(Appearance.m3colors.m3surfaceContainerLow, Appearance.m3colors.m3background, 0.55)
                    topLeftRadius: Appearance.rounding.large
                    bottomLeftRadius: Appearance.rounding.large
                }

                NavigationRail { // Window content with navigation rail and content pane
                    id: navRail
                    anchors {
                        left: parent.left
                        leftMargin: navRailWrapper.leftPadding
                        top: parent.top
                        bottom: parent.bottom
                    }
                    spacing: 10
                    expanded: true
                    
                    NavigationRailExpandButton {
                        focus: root.visible
                    }

                    FloatingActionButton {
                        id: fab
                        visible: root.currentCategory === 0
                        property bool justCopied: false
                        iconText: justCopied ? "check" : "edit"
                        buttonText: justCopied ? Translation.tr("Path copied") : Translation.tr("Config file")
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
                            onTriggered: {
                                fab.justCopied = false;
                            }
                        }

                        StyledToolTip {
                            text: Translation.tr("Open the shell config file\nAlternatively right-click to copy path")
                        }
                    }

                    NavigationRailTabArray {
                        currentIndex: root.currentPage
                        expanded: navRail.expanded
                        Repeater {
                            model: root.currentCategoryHasPages ? root.categories[root.currentCategory].pages : []
                            NavigationRailButton {
                                required property var index
                                required property var modelData
                                toggled: root.currentPage === index
                                onPressed: root.currentPage = index;
                                expanded: navRail.expanded
                                buttonIcon: modelData.icon
                                buttonIconRotation: modelData.iconRotation || 0
                                buttonText: modelData.name
                                animateLayout: root.settingsReady && root.animateInnerRail
                                showCollapsedText: false
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
                radius: 0
                topLeftRadius: root.currentCategoryHasPages ? 0 : Appearance.rounding.windowRounding - root.contentPadding
                bottomLeftRadius: root.currentCategoryHasPages ? 0 : Appearance.rounding.windowRounding - root.contentPadding
                topRightRadius: Appearance.rounding.windowRounding - root.contentPadding
                bottomRightRadius: Appearance.rounding.windowRounding - root.contentPadding

                Loader {
                    id: pageLoader
                    anchors.fill: parent
                    opacity: 1.0

                    active: Config.ready
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

                        NumberAnimation {
                            target: pageLoader
                            properties: "opacity"
                            from: 1
                            to: 0
                            duration: 100
                            easing.type: Appearance.animation.elementMoveExit.type
                            easing.bezierCurve: Appearance.animationCurves.emphasizedFirstHalf
                        }
                        ParallelAnimation {
                            PropertyAction {
                                target: pageLoader
                                property: "source"
                                value: root.currentComponent
                            }
                            PropertyAction {
                                target: pageLoader
                                property: "anchors.topMargin"
                                value: 20
                            }
                        }
                        ParallelAnimation {
                            NumberAnimation {
                                target: pageLoader
                                properties: "opacity"
                                from: 0
                                to: 1
                                duration: 200
                                easing.type: Appearance.animation.elementMoveEnter.type
                                easing.bezierCurve: Appearance.animationCurves.emphasizedLastHalf
                            }
                            NumberAnimation {
                                target: pageLoader
                                properties: "anchors.topMargin"
                                to: 0
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
}
