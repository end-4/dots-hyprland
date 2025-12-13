import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Qt.labs.settings 1.1
import Quickshell.Io
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root

    Settings {
        id: cheatsheetSettings
        category: "ii.cheatsheet"
        property int defaultTabIndex: 0
    }

    property var tabButtonList: [
        {
            "icon": "keyboard",
            "name": Translation.tr("Keybinds")
        },
        {
            "icon": "experiment",
            "name": Translation.tr("Elements")
        },
        {
            "icon": "note",
            "name": Translation.tr("Notes")
        }
    ]

    function openCheatsheet() {
        cheatsheetLoader.active = true
        if (cheatsheetLoader.item)
            cheatsheetLoader.item.open()
    }

    function closeCheatsheet() {
        if (cheatsheetLoader.item)
            cheatsheetLoader.item.hide()
        else
            cheatsheetLoader.active = false
    }

    function toggleCheatsheet() {
        if (cheatsheetLoader.active && cheatsheetLoader.item && cheatsheetLoader.item.visible)
            closeCheatsheet()
        else
            openCheatsheet()
    }

    Loader {
        id: cheatsheetLoader
        active: false

        onLoaded: item.open()

        sourceComponent: PanelWindow {
            id: cheatsheetRoot

            visible: false

            property int savedDefaultTabIndex: 0

            anchors { top: true; bottom: true; left: true; right: true }

            function hide() {
                visible = false
                cheatsheetLoader.active = false
            }

            function clampTabIndex(idx) {
                if (idx === undefined || idx === null) return 0
                idx = Number(idx)
                if (!isFinite(idx)) return 0
                if (idx < 0) return 0
                if (idx >= root.tabButtonList.length) return 0
                return idx
            }

            function readPersistedDefaultTabIndex() {
                let idx = undefined

                if (typeof Config !== "undefined"
                        && Config.cheatsheet
                        && Config.cheatsheet.defaultTabIndex !== undefined) {
                    idx = Config.cheatsheet.defaultTabIndex
                } else {
                    idx = cheatsheetSettings.defaultTabIndex
                }

                return clampTabIndex(idx)
            }

            function writePersistedDefaultTabIndex(idx) {
                const clamped = clampTabIndex(idx)

                cheatsheetSettings.defaultTabIndex = clamped
                if (typeof cheatsheetSettings.sync === "function")
                    cheatsheetSettings.sync()

                if (typeof Config !== "undefined" && Config.cheatsheet) {
                    Config.cheatsheet.defaultTabIndex = clamped
                    if (typeof Config.save === "function") Config.save()
                    else if (typeof Config.sync === "function") Config.sync()
                }

                savedDefaultTabIndex = clamped
            }

            function jumpToTabWithoutAnimation(idx) {
                const clamped = clampTabIndex(idx)
                savedDefaultTabIndex = clamped

                const lv = swipeView.contentItem
                const oldMove = lv ? lv.highlightMoveDuration : 250
                const oldResize = lv ? lv.highlightResizeDuration : 250
                if (lv) {
                    lv.highlightMoveDuration = 0
                    lv.highlightResizeDuration = 0
                }

                tabBar.setCurrentIndex(clamped)
                swipeView.currentIndex = clamped

                Qt.callLater(() => {
                    const lv2 = swipeView.contentItem
                    if (lv2) {
                        lv2.highlightMoveDuration = oldMove
                        lv2.highlightResizeDuration = oldResize
                    }
                })
            }

            function open() {
                const idx = readPersistedDefaultTabIndex()

                Qt.callLater(() => {
                    jumpToTabWithoutAnimation(idx)
                    visible = true
                })
            }

            function setDefaultTab(idx) {
                writePersistedDefaultTabIndex(idx)

                jumpToTabWithoutAnimation(savedDefaultTabIndex)
            }

            exclusiveZone: 0
            implicitWidth: cheatsheetBackground.width + Appearance.sizes.elevationMargin * 2
            implicitHeight: cheatsheetBackground.height + Appearance.sizes.elevationMargin * 2
            WlrLayershell.namespace: "quickshell:cheatsheet"
            color: "transparent"

            mask: Region { item: cheatsheetBackground }

            HyprlandFocusGrab {
                id: grab
                windows: [cheatsheetRoot]
                active: cheatsheetRoot.visible
                onCleared: () => { if (!active) cheatsheetRoot.hide() }
            }

            StyledRectangularShadow { target: cheatsheetBackground }

            Rectangle {
                id: cheatsheetBackground
                anchors.centerIn: parent
                color: Appearance.colors.colLayer0
                border.width: 1
                border.color: Appearance.colors.colLayer0Border
                radius: Appearance.rounding.windowRounding

                property real padding: 20
                implicitWidth: cheatsheetColumnLayout.implicitWidth + padding * 2
                implicitHeight: cheatsheetColumnLayout.implicitHeight + padding * 2

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        cheatsheetRoot.hide()
                    }
                    if (event.modifiers === Qt.ControlModifier) {
                        if (event.key === Qt.Key_PageDown) {
                            tabBar.incrementCurrentIndex()
                            event.accepted = true
                        } else if (event.key === Qt.Key_PageUp) {
                            tabBar.decrementCurrentIndex()
                            event.accepted = true
                        } else if (event.key === Qt.Key_Tab) {
                            tabBar.setCurrentIndex((tabBar.currentIndex + 1) % root.tabButtonList.length)
                            event.accepted = true
                        } else if (event.key === Qt.Key_Backtab) {
                            tabBar.setCurrentIndex((tabBar.currentIndex - 1 + root.tabButtonList.length) % root.tabButtonList.length)
                            event.accepted = true
                        }
                    }
                }

                RippleButton {
                    id: lockButton
                    implicitWidth: 40
                    implicitHeight: 40
                    buttonRadius: Appearance.rounding.full
                    z: 10

                    anchors {
                        top: parent.top
                        right: closeButton.left
                        topMargin: 20
                        rightMargin: 10
                    }

                    property bool isDefaultTab: cheatsheetRoot.savedDefaultTabIndex === swipeView.currentIndex
                    onClicked: cheatsheetRoot.setDefaultTab(swipeView.currentIndex)

                    background: Rectangle {
                        color: lockButton.isDefaultTab ? "black" : "transparent"
                        radius: width / 2
                    }

                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: Appearance.font.pixelSize.title
                        text: lockButton.isDefaultTab ? "lock" : "lock_open"
                    }
                }


                RippleButton {
                    id: closeButton
                    focus: cheatsheetRoot.visible
                    implicitWidth: 40
                    implicitHeight: 40
                    buttonRadius: Appearance.rounding.full

                    anchors {
                        top: parent.top
                        right: parent.right
                        topMargin: 20
                        rightMargin: 20
                    }

                    onClicked: cheatsheetRoot.hide()

                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: Appearance.font.pixelSize.title
                        text: "close"
                    }
                }

                ColumnLayout {
                    id: cheatsheetColumnLayout
                    anchors.centerIn: parent
                    spacing: 10

                    Toolbar {
                        Layout.alignment: Qt.AlignHCenter
                        enableShadow: false

                        ToolbarTabBar {
                            id: tabBar
                            tabButtonList: root.tabButtonList
                            onCurrentIndexChanged: swipeView.currentIndex = currentIndex
                        }
                    }

                    SwipeView {
                        id: swipeView
                        Layout.topMargin: 5
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 10

                        onCurrentIndexChanged: tabBar.setCurrentIndex(currentIndex)

                        implicitWidth: Math.max.apply(null, contentChildren.map(child => child.implicitWidth || 0))
                        implicitHeight: Math.max.apply(null, contentChildren.map(child => child.implicitHeight || 0))

                        clip: true
                        layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: Rectangle {
                                width: swipeView.width
                                height: swipeView.height
                                radius: Appearance.rounding.small
                            }
                        }

                        CheatsheetKeybinds {}
                        CheatsheetPeriodicTable {}
                        CheatsheetNotes {}
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "cheatsheet"
        function toggle(): void { root.toggleCheatsheet() }
        function close(): void { root.closeCheatsheet() }
        function open(): void { root.openCheatsheet() }
    }

    GlobalShortcut {
        name: "cheatsheetToggle"
        description: "Toggles cheatsheet on press"
        onPressed: root.toggleCheatsheet()
    }

    GlobalShortcut {
        name: "cheatsheetOpen"
        description: "Opens cheatsheet on press"
        onPressed: root.openCheatsheet()
    }

    GlobalShortcut {
        name: "cheatsheetClose"
        description: "Closes cheatsheet on press"
        onPressed: root.closeCheatsheet()
    }
}