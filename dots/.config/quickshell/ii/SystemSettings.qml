//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

/**
 * System Settings — A comprehensive KDE/GNOME-style settings app.
 *
 * Categories:
 *   System
 *     ├── Display & Monitor
 *     ├── Audio
 *     ├── Network & Wi-Fi
 *     ├── Bluetooth
 *     ├── Users & Accounts
 *     └── Date & Time
 *   Hardware
 *     ├── Keyboard
 *     ├── Mouse & Touchpad
 *     └── Power Management
 *   Shell (dotfiles)
 *     ├── Quick
 *     ├── Appearance & Wallpaper
 *     ├── Wallpaper Slideshow
 *     ├── Bar
 *     ├── Background Widgets
 *     ├── Interface
 *     ├── Services
 *     ├── YouTube Downloader
 *     ├── Tools
 *     └── Advanced
 *   About
 *
 * Launch with:  quickshell -p ~/.config/quickshell/ii/SystemSettings.qml
 */

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions as CF

ApplicationWindow {
    id: root

    visible: true
    onClosing: Qt.quit()
    title: "System Settings"
    minimumWidth: 900
    minimumHeight: 600
    width: 1200
    height: 780
    color: Appearance.m3colors.m3background

    Component.onCompleted: {
        MaterialThemeLoader.reapplyTheme()
        Config.readWriteDelay = 0
        Emojis.load()
    }

    // ── Category/page model ──────────────────────────────────────────────
    property int currentCategoryIndex: 0
    property int currentPageIndex: 0

    property var categories: [
        {
            name: "System",
            icon: "computer",
            pages: [
                { name: "Display",      icon: "monitor",            component: "modules/sysSettings/DisplaySettings.qml"    },
                { name: "Audio",        icon: "volume_up",          component: "modules/sysSettings/AudioSettings.qml"      },
                { name: "Network",      icon: "wifi",               component: "modules/sysSettings/NetworkSettings.qml"    },
                { name: "Bluetooth",    icon: "bluetooth",          component: "modules/sysSettings/BluetoothSettings.qml"  },
                { name: "Date & Time",  icon: "schedule",           component: "modules/sysSettings/DateTimeSettings.qml"   },
                { name: "Users",        icon: "manage_accounts",    component: "modules/sysSettings/UsersSettings.qml"      },
            ]
        },
        {
            name: "Hardware",
            icon: "hardware",
            pages: [
                { name: "Keyboard",     icon: "keyboard",           component: "modules/sysSettings/KeyboardSettings.qml"   },
                { name: "Mouse",        icon: "mouse",              component: "modules/sysSettings/MouseSettings.qml"      },
                { name: "Power",        icon: "battery_charging_full", component: "modules/sysSettings/PowerSettings.qml"  },
            ]
        },
        {
            name: "Shell",
            icon: "terminal",
            pages: [
                { name: "Quick",        icon: "instant_mix",        component: "modules/settings/QuickConfig.qml"           },
                { name: "Appearance",   icon: "palette",            component: "modules/settings/QuickConfig.qml"           },
                { name: "Slideshow",    icon: "slideshow",          component: "modules/settings/WallpaperSlideshowConfig.qml" },
                { name: "Bar",          icon: "toast",              component: "modules/settings/BarConfig.qml"             },
                { name: "Background",   icon: "texture",            component: "modules/settings/BackgroundConfig.qml"      },
                { name: "Interface",    icon: "bottom_app_bar",     component: "modules/settings/InterfaceConfig.qml"       },
                { name: "Services",     icon: "settings",           component: "modules/settings/ServicesConfig.qml"        },
                { name: "Downloader",   icon: "download",           component: "modules/settings/YtDownloaderConfig.qml"    },
                { name: "Tools",        icon: "build",              component: "modules/settings/ToolsConfig.qml"           },
                { name: "Advanced",     icon: "construction",       component: "modules/settings/AdvancedConfig.qml"        },
            ]
        },
        {
            name: "About",
            icon: "info",
            pages: [
                { name: "About System", icon: "info",               component: "modules/settings/About.qml"                },
            ]
        }
    ]

    readonly property var currentCategory: categories[currentCategoryIndex]
    readonly property var currentPage: currentCategory.pages[Math.min(currentPageIndex, currentCategory.pages.length - 1)]

    onCurrentCategoryIndexChanged: currentPageIndex = 0

    // ── Keyboard navigation ───────────────────────────────────────────────
    Keys.onPressed: event => {
        if (event.modifiers === Qt.ControlModifier) {
            if (event.key === Qt.Key_PageDown) {
                currentPageIndex = Math.min(currentPageIndex + 1, currentCategory.pages.length - 1)
                event.accepted = true
            } else if (event.key === Qt.Key_PageUp) {
                currentPageIndex = Math.max(currentPageIndex - 1, 0)
                event.accepted = true
            }
        }
    }

    ColumnLayout {
        anchors { fill: parent; margins: 8 }
        spacing: 6

        // ── Title bar ─────────────────────────────────────────────────────
        Item {
            visible: Config.options?.windows.showTitlebar ?? true
            Layout.fillWidth: true
            implicitHeight: Math.max(titleRow.implicitHeight, 36)

            RowLayout {
                id: titleRow
                anchors { fill: parent; leftMargin: 12; rightMargin: 8 }
                spacing: 10

                // Back breadcrumb
                StyledText {
                    visible: false // Could add breadcrumb later
                    text: root.currentCategory.name + " › " + root.currentPage.name
                    font { family: Appearance.font.family.title; pixelSize: Appearance.font.pixelSize.title }
                    color: Appearance.colors.colOnLayer0
                }
                StyledText {
                    text: root.currentPage.name
                    font { family: Appearance.font.family.title; pixelSize: Appearance.font.pixelSize.title }
                    color: Appearance.colors.colOnLayer0
                    Layout.fillWidth: true
                }

                // Window controls
                RippleButton {
                    buttonRadius: Appearance.rounding.full
                    implicitWidth: 35; implicitHeight: 35
                    onClicked: root.close()
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: "close"; iconSize: 20
                    }
                }
            }
        }

        // ── Main content area ─────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8

            // Left: category sidebar
            Rectangle {
                Layout.fillHeight: true
                implicitWidth: 160
                color: Appearance.m3colors.m3surfaceContainerLow
                radius: Appearance.rounding.windowRounding - 8

                ColumnLayout {
                    anchors { fill: parent; margins: 8 }
                    spacing: 4

                    Repeater {
                        model: root.categories
                        delegate: CategoryButton {
                            required property var modelData
                            required property int index
                            Layout.fillWidth: true
                            toggled: root.currentCategoryIndex === index
                            onClicked: root.currentCategoryIndex = index
                            iconName: modelData.icon
                            labelText: modelData.name
                        }
                    }
                    Item { Layout.fillHeight: true }
                }
            }

            // Center: page list sidebar
            Rectangle {
                Layout.fillHeight: true
                implicitWidth: 180
                color: Appearance.m3colors.m3surfaceContainerLow
                radius: Appearance.rounding.windowRounding - 8

                ColumnLayout {
                    anchors { fill: parent; margins: 8 }
                    spacing: 2

                    StyledText {
                        text: root.currentCategory.name
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                        Layout.leftMargin: 8
                        Layout.topMargin: 4
                        Layout.bottomMargin: 4
                    }

                    Repeater {
                        model: root.currentCategory.pages
                        delegate: PageButton {
                            required property var modelData
                            required property int index
                            Layout.fillWidth: true
                            toggled: root.currentPageIndex === index
                            onClicked: root.currentPageIndex = index
                            iconName: modelData.icon
                            labelText: modelData.name
                        }
                    }
                    Item { Layout.fillHeight: true }
                }
            }

            // Right: content pane
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Appearance.m3colors.m3surfaceContainerLow
                radius: Appearance.rounding.windowRounding - 8

                Loader {
                    id: pageLoader
                    anchors.fill: parent
                    opacity: 1.0
                    active: Config.ready

                    Component.onCompleted: {
                        source = root.currentPage.component
                    }

                    Connections {
                        target: root
                        function onCurrentPageChanged() {
                            switchAnim.complete()
                            switchAnim.start()
                        }
                    }

                    SequentialAnimation {
                        id: switchAnim
                        NumberAnimation {
                            target: pageLoader; properties: "opacity"; from: 1; to: 0
                            duration: 80; easing.type: Easing.OutQuad
                        }
                        ParallelAnimation {
                            PropertyAction { target: pageLoader; property: "source"; value: root.currentPage.component }
                            PropertyAction { target: pageLoader; property: "anchors.topMargin"; value: 16 }
                        }
                        ParallelAnimation {
                            NumberAnimation { target: pageLoader; properties: "opacity"; from: 0; to: 1; duration: 160; easing.type: Easing.OutQuad }
                            NumberAnimation { target: pageLoader; properties: "anchors.topMargin"; to: 0; duration: 160; easing.type: Easing.OutQuad }
                        }
                    }
                }
            }
        }
    }

    // ── Category button component ─────────────────────────────────────────
    component CategoryButton: RippleButton {
        property string iconName: ""
        property string labelText: ""
        property bool toggled: false
        implicitHeight: 46
        buttonRadius: Appearance.rounding.normal
        colBackground: toggled ? Appearance.colors.colSecondaryContainer : "transparent"
        colBackgroundHover: toggled ? Appearance.colors.colSecondaryContainerHover : Appearance.colors.colLayer1Hover

        contentItem: RowLayout {
            spacing: 10
            anchors { fill: parent; leftMargin: 12; rightMargin: 8 }
            MaterialSymbol {
                text: iconName
                iconSize: 18
                color: toggled ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer0
            }
            StyledText {
                Layout.fillWidth: true
                text: labelText
                font.pixelSize: Appearance.font.pixelSize.small
                color: toggled ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer0
                elide: Text.ElideRight
            }
        }
    }

    // ── Page button component ─────────────────────────────────────────────
    component PageButton: RippleButton {
        property string iconName: ""
        property string labelText: ""
        property bool toggled: false
        implicitHeight: 38
        buttonRadius: Appearance.rounding.small
        colBackground: toggled ? Appearance.colors.colPrimaryContainer : "transparent"
        colBackgroundHover: toggled ? Appearance.colors.colPrimaryContainerHover : Appearance.colors.colLayer1Hover

        contentItem: RowLayout {
            spacing: 8
            anchors { fill: parent; leftMargin: 10; rightMargin: 8 }
            MaterialSymbol {
                text: iconName
                iconSize: 16
                color: toggled ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colSubtext
            }
            StyledText {
                Layout.fillWidth: true
                text: labelText
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: toggled ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer0
                elide: Text.ElideRight
            }
        }
    }
}
