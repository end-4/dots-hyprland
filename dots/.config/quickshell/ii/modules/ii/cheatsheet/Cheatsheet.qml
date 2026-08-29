import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.synchronizer
import Qt5Compat.GraphicalEffects
import Quickshell.Io
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Scope { // Scope
    id: root
    property var tabButtonList: [
        {
            "icon": "keyboard",
            "name": Translation.tr("Keybinds")
        },
        {
            "icon": "experiment",
            "name": Translation.tr("Elements")
        },
    ]

    Loader {
        id: cheatsheetLoader
        active: false

        sourceComponent: PanelWindow { // Window
            id: cheatsheetRoot
            visible: cheatsheetLoader.active

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            function hide() {
                cheatsheetLoader.active = false;
            }
            property bool keyboardReady: false
            exclusiveZone: 0
            implicitWidth: cheatsheetBackground.width + Appearance.sizes.elevationMargin * 2
            implicitHeight: cheatsheetBackground.height + Appearance.sizes.elevationMargin * 2
            WlrLayershell.namespace: "quickshell:cheatsheet"
            WlrLayershell.layer: WlrLayer.Overlay
            //--> It dont take that sweet time to open Anymore!
            WlrLayershell.keyboardFocus: cheatsheetRoot.keyboardReady ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
            color: "transparent"

            mask: Region {
                item: cheatsheetBackground
            }

            Timer {
                id: lockWidthTimer
                interval: 150
                repeat: false
                onTriggered: {
                    if (cheatsheetBackground.lockedWidth === 0) {
                        const contentWidth = Math.max(
                            headerColumn.implicitWidth,
                            keybindsPage.implicitWidth,
                            periodicTablePage.implicitWidth,
                        );
                        cheatsheetBackground.lockedWidth = contentWidth + cheatsheetBackground.padding * 2;
                    }
                }
            }

            Timer {
                id: keyboardFocusTimer
                interval: 150
                repeat: false
                onTriggered: {
                    if (cheatsheetRoot.visible) {
                        cheatsheetRoot.keyboardReady = true;
                    }
                }
            }

            Component.onCompleted: {
                GlobalFocusGrab.addDismissable(cheatsheetRoot);
            }
            Component.onDestruction: {
                GlobalFocusGrab.removeDismissable(cheatsheetRoot);
            }
            Connections {
                target: cheatsheetRoot
                function onVisibleChanged() {
                    if (cheatsheetRoot.visible) {
                        cheatsheetRoot.keyboardReady = false;
                        lockWidthTimer.restart();
                        keyboardFocusTimer.restart();
                    } else {
                        keyboardFocusTimer.stop();
                        cheatsheetRoot.keyboardReady = false;
                        cheatsheetBackground.lockedWidth = 0;
                        cheatsheetBackground.collapseSearch();
                    }
                }
            }
            Connections {
                target: GlobalFocusGrab
                function onDismissed() {
                    cheatsheetRoot.hide();
                }
            }

            // Background
            StyledRectangularShadow {
                target: cheatsheetBackground
            }
            Rectangle {
                id: cheatsheetBackground
                anchors.centerIn: parent
                focus: cheatsheetRoot.visible
                color: Appearance.colors.colLayer0
                border.width: 1
                border.color: Appearance.colors.colLayer0Border
                radius: Appearance.rounding.windowRounding
                property real padding: 20
                property real lockedWidth: 0
                property bool searchExpanded: false

                function collapseSearch() {
                    searchExpanded = false;
                    searchField.focus = false;
                    if (searchField.text !== "") {
                        searchField.text = "";
                    }
                    cheatsheetBackground.forceActiveFocus();
                    GlobalFocusGrab.addDismissable(cheatsheetRoot);
                }

                function expandSearch() {
                    GlobalFocusGrab.removeDismissable(cheatsheetRoot);
                    searchExpanded = true;
                    searchField.forceActiveFocus();
                }

                implicitWidth: lockedWidth > 0 ? lockedWidth : cheatsheetColumnLayout.implicitWidth + padding * 2
                implicitHeight: cheatsheetColumnLayout.implicitHeight + padding * 2

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        event.accepted = true;
                        if (searchField.text.length > 0 || searchExpanded) {
                            clearSearchButton.clicked();
                        } else {
                            cheatsheetRoot.hide();
                        }
                        return;
                    }
                    if (event.modifiers === Qt.ControlModifier) {
                        if (event.key === Qt.Key_PageDown) {
                            tabBar.incrementCurrentIndex();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_PageUp) {
                            tabBar.decrementCurrentIndex();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Tab) {
                            tabBar.setCurrentIndex((tabBar.currentIndex + 1) % root.tabButtonList.length);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Backtab) {
                            tabBar.setCurrentIndex((tabBar.currentIndex - 1 + root.tabButtonList.length) % root.tabButtonList.length);
                            event.accepted = true;
                        }
                        return;
                    }

                    if (searchField.activeFocus && cheatsheetBackground.searchExpanded) {
                        event.accepted = false;
                        return;
                    }

                    if (event.key === Qt.Key_Backspace) {
                        if (!cheatsheetBackground.searchExpanded) {
                            event.accepted = true;
                            return;
                        }
                        if (searchField.text.length > 0) {
                            searchField.text = searchField.text.substring(0, searchField.text.length - 1);
                        }
                        event.accepted = true;
                        return;
                    }
                    if (event.text.length > 0) {
                        expandSearch();
                        searchField.text += event.text;
                        searchField.cursorPosition = searchField.text.length;
                        searchField.forceActiveFocus();
                        event.accepted = true;
                    }
                }

                RippleButton { // Close button
                    id: closeButton
                    implicitWidth: 40
                    implicitHeight: 40
                    buttonRadius: Appearance.rounding.full
                    anchors {
                        top: parent.top
                        right: parent.right
                        topMargin: 20
                        rightMargin: 20
                    }

                    onClicked: {
                        cheatsheetRoot.hide();
                    }

                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: Appearance.font.pixelSize.title
                        text: "close"
                    }
                }

                ColumnLayout { // Real content
                    id: cheatsheetColumnLayout
                    anchors.centerIn: parent
                    spacing: 10

                    ColumnLayout {
                        id: headerColumn
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 6

                        Toolbar {
                            id: tabToolbar
                            Layout.alignment: Qt.AlignHCenter
                            enableShadow: false
                            ToolbarTabBar {
                                id: tabBar
                                tabButtonList: root.tabButtonList

                                Synchronizer on currentIndex {
                                    property alias source: swipeView.currentIndex
                                }
                            }
                        }

                        Item {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: Math.max(keybindsPage.implicitWidth, periodicTablePage.implicitWidth)
                            implicitHeight: 30

                            MouseArea {
                                anchors.fill: parent
                                enabled: !cheatsheetBackground.searchExpanded
                                cursorShape: Qt.IBeamCursor
                                onClicked: cheatsheetBackground.expandSearch()
                            }

                            RowLayout {
                                id: searchHintRow
                                anchors.centerIn: parent
                                spacing: 4
                                visible: !cheatsheetBackground.searchExpanded

                                MaterialSymbol {
                                    Layout.alignment: Qt.AlignVCenter
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    color: Appearance.colors.colSubtext
                                    text: "search"
                                }

                                StyledText {
                                    Layout.alignment: Qt.AlignVCenter
                                    color: Appearance.colors.colSubtext
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    text: Translation.tr("Type or click here to search…")
                                }
                            }

                            Item {
                                id: searchFieldContainer
                                anchors.centerIn: parent
                                width: Math.max(tabBar.implicitWidth, 220)
                                height: 30
                                visible: cheatsheetBackground.searchExpanded
                                enabled: cheatsheetBackground.searchExpanded

                                ToolbarTextField {
                                    id: searchField
                                    anchors.fill: parent
                                    enabled: cheatsheetBackground.searchExpanded
                                    padding: 6
                                    rightPadding: 32
                                    placeholderText: ""
                                    font.pixelSize: Appearance.font.pixelSize.smaller

                                    Keys.onPressed: event => {
                                        if (event.key === Qt.Key_Escape) {
                                            event.accepted = true;
                                            if (cheatsheetBackground.searchExpanded || text.length > 0) {
                                                clearSearchButton.clicked();
                                            }
                                        }
                                    }

                                    onTextChanged: {
                                        if (text.length === 0 && cheatsheetBackground.searchExpanded) {
                                            cheatsheetBackground.collapseSearch();
                                        }
                                    }
                                }

                                IconToolbarButton {
                                    id: clearSearchButton
                                    anchors {
                                        right: parent.right
                                        verticalCenter: parent.verticalCenter
                                        rightMargin: 2
                                    }
                                    implicitWidth: 26
                                    implicitHeight: 26
                                    text: "close"
                                    onClicked: cheatsheetBackground.collapseSearch()
                                }
                            }
                        }
                    }

                    SwipeView { // Content pages
                        id: swipeView
                        Layout.topMargin: 5
                        spacing: 10
                        currentIndex: Persistent.states.cheatsheet.tabIndex
                        onCurrentIndexChanged: {
                            Persistent.states.cheatsheet.tabIndex = currentIndex;
                        }

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

                        CheatsheetKeybinds {
                            id: keybindsPage
                            searchQuery: searchField.text
                        }
                        CheatsheetPeriodicTable {
                            id: periodicTablePage
                            searchQuery: searchField.text
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "cheatsheet"

        function toggle(): void {
            cheatsheetLoader.active = !cheatsheetLoader.active;
        }

        function close(): void {
            cheatsheetLoader.active = false;
        }

        function open(): void {
            cheatsheetLoader.active = true;
        }
    }

    GlobalShortcut {
        name: "cheatsheetToggle"
        description: "Toggles cheatsheet on press"

        onPressed: {
            cheatsheetLoader.active = !cheatsheetLoader.active;
        }
    }

    GlobalShortcut {
        name: "cheatsheetOpen"
        description: "Opens cheatsheet on press"

        onPressed: {
            cheatsheetLoader.active = true;
        }
    }

    GlobalShortcut {
        name: "cheatsheetClose"
        description: "Closes cheatsheet on press"

        onPressed: {
            cheatsheetLoader.active = false;
        }
    }
}
