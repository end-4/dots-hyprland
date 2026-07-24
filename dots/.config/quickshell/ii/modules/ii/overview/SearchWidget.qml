pragma ComponentBehavior: Bound

import Qt.labs.synchronizer
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item { // Wrapper
    id: root

    readonly property string xdgConfigHome: Directories.config
    readonly property int typingDebounceInterval: 200
    readonly property int typingResultLimit: 15 // Should be enough to cover the whole view
    readonly property bool clearBtnHasFocus: clearClipboardBtn.activeFocus || clearResultsBtn.activeFocus
    readonly property bool clipboardSearching: root.searchingText.startsWith(Config.options.search.prefix.clipboard) && root.searchingText.length > Config.options.search.prefix.clipboard.length

    property string searchingText: LauncherSearch.query
    property bool showResults: searchingText != ""
    implicitWidth: searchWidgetContent.implicitWidth + Appearance.sizes.elevationMargin * 2
    implicitHeight: searchWidgetContent.implicitHeight + searchBar.verticalPadding * 2 + Appearance.sizes.elevationMargin * 2

    function focusFirstItem() {
        appResults.currentIndex = 0;
    }

    function focusSearchInput() {
        searchBar.forceFocus();
    }

    function disableExpandAnimation() {
        searchBar.animateWidth = false;
    }

    function cancelSearch() {
        searchBar.searchInput.selectAll();
        LauncherSearch.query = "";
        searchBar.animateWidth = true;
    }

    function setSearchingText(text) {
        searchBar.searchInput.text = text;
        LauncherSearch.query = text;
    }

    Keys.onPressed: event => {
        // Prevent Esc and Backspace from registering
        if (event.key === Qt.Key_Escape)
            return;

        // Handle Down arrow: navigate to Clear results/Clear all button or list
        if (event.key === Qt.Key_Down) {
            const isClipboard = root.searchingText.startsWith(Config.options.search.prefix.clipboard);
            if (isClipboard) {
                if (root.clipboardSearching && !clearResultsBtn.activeFocus) {
                    clearResultsBtn.forceActiveFocus();
                    event.accepted = true;
                    return;
                } else if (!clearClipboardBtn.activeFocus) {
                    clearClipboardBtn.forceActiveFocus();
                    event.accepted = true;
                    return;
                }
            }
        }

        // Handle Backspace: focus and delete character if not focused
        if (event.key === Qt.Key_Backspace) {
            if (!searchBar.searchInput.activeFocus) {
                root.focusSearchInput();
                if (event.modifiers & Qt.ControlModifier) {
                    // Delete word before cursor
                    let text = searchBar.searchInput.text;
                    let pos = searchBar.searchInput.cursorPosition;
                    if (pos > 0) {
                        // Find the start of the previous word
                        let left = text.slice(0, pos);
                        let match = left.match(/(\s*\S+)\s*$/);
                        let deleteLen = match ? match[0].length : 1;
                        searchBar.searchInput.text = text.slice(0, pos - deleteLen) + text.slice(pos);
                        searchBar.searchInput.cursorPosition = pos - deleteLen;
                    }
                } else {
                    // Delete character before cursor if any
                    if (searchBar.searchInput.cursorPosition > 0) {
                        searchBar.searchInput.text = searchBar.searchInput.text.slice(0, searchBar.searchInput.cursorPosition - 1) + searchBar.searchInput.text.slice(searchBar.searchInput.cursorPosition);
                        searchBar.searchInput.cursorPosition -= 1;
                    }
                }
                // Always move cursor to end after programmatic edit
                searchBar.searchInput.cursorPosition = searchBar.searchInput.text.length;
                event.accepted = true;
            }
            // If already focused, let TextField handle it
            return;
        }

        // Only handle visible printable characters (ignore control chars, arrows, etc.)
        if (event.text && event.text.length === 1 && event.key !== Qt.Key_Enter && event.key !== Qt.Key_Return && event.key !== Qt.Key_Delete && event.text.charCodeAt(0) >= 0x20) // ignore control chars like Backspace, Tab, etc.
        {
            if (!searchBar.searchInput.activeFocus) {
                root.focusSearchInput();
                // Insert the character at the cursor position
                searchBar.searchInput.text = searchBar.searchInput.text.slice(0, searchBar.searchInput.cursorPosition) + event.text + searchBar.searchInput.text.slice(searchBar.searchInput.cursorPosition);
                searchBar.searchInput.cursorPosition += 1;
                event.accepted = true;
                root.focusFirstItem();
            }
        }
    }

    StyledRectangularShadow {
        target: searchWidgetContent
    }
    Rectangle { // Background
        id: searchWidgetContent
        anchors {
            top: parent.top
            horizontalCenter: parent.horizontalCenter
            topMargin: Appearance.sizes.elevationMargin
        }
        clip: true
        implicitWidth: columnLayout.implicitWidth
        implicitHeight: columnLayout.implicitHeight
        radius: searchBar.height / 2 + searchBar.verticalPadding
        color: Appearance.colors.colBackgroundSurfaceContainer

        Behavior on implicitHeight {
            id: searchHeightBehavior
            enabled: GlobalStates.overviewOpen && root.showResults
            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
        }

        ColumnLayout {
            id: columnLayout
            anchors {
                top: parent.top
                horizontalCenter: parent.horizontalCenter
            }
            spacing: 0

            // clip: true
            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: searchWidgetContent.width
                    height: searchWidgetContent.width
                    radius: searchWidgetContent.radius
                }
            }

            SearchBar {
                id: searchBar
                property real verticalPadding: 4
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.rightMargin: 4
                Layout.topMargin: verticalPadding
                Layout.bottomMargin: verticalPadding
                Synchronizer on searchingText {
                    property alias source: root.searchingText
                }
            }

            Rectangle {
                // Separator
                visible: root.showResults
                Layout.fillWidth: true
                height: 1
                color: Appearance.colors.colOutlineVariant
            }

            RowLayout {
                visible: root.showResults && root.searchingText.startsWith(Config.options.search.prefix.clipboard)
                Layout.fillWidth: true
                Layout.leftMargin: 16
                Layout.rightMargin: 10
                Layout.topMargin: 6
                Layout.bottomMargin: 2

                StyledText {
                    text: Translation.tr("Clipboard")
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                }
                Item {
                    Layout.fillWidth: true
                }
                Button {
                    id: clearResultsBtn
                    visible: root.clipboardSearching
                    implicitHeight: 28
                    hoverEnabled: true
                    contentItem: StyledText {
                        text: Translation.tr("Clear results")
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: clearResultsBtn.focus ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colPrimary
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        radius: Appearance.rounding.small
                        color: clearResultsBtn.down ? Appearance.colors.colPrimaryContainerActive : (clearResultsBtn.hovered ? Appearance.colors.colPrimaryContainer : ColorUtils.transparentize(Appearance.colors.colPrimaryContainer, 1))
                        border.width: clearResultsBtn.focus ? 2 : 0
                        border.color: Appearance.colors.colSecondary
                        Behavior on color {
                            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                        }
                    }
                    onClicked: {
                        const searchString = StringUtils.cleanPrefix(root.searchingText, Config.options.search.prefix.clipboard);
                        const matches = Cliphist.fuzzyQuery(searchString);
                        Cliphist.deleteEntries(matches);
                        root.focusSearchInput();
                    }
                    KeyNavigation.right: clearClipboardBtn
                    KeyNavigation.down: appResults
                }
                Button {
                    id: clearClipboardBtn
                    implicitHeight: 28
                    hoverEnabled: true
                    contentItem: StyledText {
                        text: Translation.tr("Clear all")
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: clearClipboardBtn.focus ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colPrimary
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        radius: Appearance.rounding.small
                        color: clearClipboardBtn.down ? Appearance.colors.colPrimaryContainerActive : (clearClipboardBtn.hovered ? Appearance.colors.colPrimaryContainer : ColorUtils.transparentize(Appearance.colors.colPrimaryContainer, 1))
                        border.width: clearClipboardBtn.focus ? 2 : 0
                        border.color: Appearance.colors.colSecondary
                        Behavior on color {
                            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                        }
                    }
                    onClicked: {
                        Cliphist.wipe();
                        root.focusSearchInput();
                    }
                    KeyNavigation.left: root.clipboardSearching ? clearResultsBtn : searchBar
                    KeyNavigation.down: appResults
                }
            }

            Item {
                visible: root.showResults && root.searchingText.startsWith(Config.options.search.prefix.clipboard) && appResults.count === 0
                Layout.fillWidth: true
                implicitHeight: 120

                readonly property bool hasEntries: Cliphist.entries.length > 0
                readonly property bool isSearching: hasEntries && root.clipboardSearching

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 5

                    MaterialSymbol {
                        Layout.alignment: Qt.AlignHCenter
                        iconSize: 48
                        color: Appearance.m3colors.m3outline
                        text: parent.parent.isSearching ? "search_off" : "content_paste"
                    }
                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.DemiBold
                        color: Appearance.m3colors.m3outline
                        horizontalAlignment: Text.AlignHCenter
                        text: parent.parent.isSearching ? Translation.tr("No results found") : Translation.tr("Clipboard is empty")
                    }
                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.m3colors.m3outline
                        horizontalAlignment: Text.AlignHCenter
                        text: parent.parent.isSearching ? Translation.tr("Try a different search") : Translation.tr("Copy something to see it here")
                    }
                }
            }

            ListView { // App results
                id: appResults
                visible: root.showResults
                Layout.fillWidth: true
                implicitHeight: Math.min(600, appResults.contentHeight + topMargin + bottomMargin)
                clip: true
                topMargin: 10
                bottomMargin: 10
                spacing: 2
                KeyNavigation.up: searchBar
                highlightMoveDuration: 100

                onFocusChanged: {
                    if (focus)
                        appResults.currentIndex = 0;
                }

                Connections {
                    target: root
                    function onSearchingTextChanged() {
                        if (appResults.count > 0)
                            appResults.currentIndex = 0;
                    }
                }

                Timer {
                    id: debounceTimer
                    interval: root.typingDebounceInterval
                    onTriggered: {
                        resultModel.values = LauncherSearch.results ?? [];
                    }
                }

                Connections {
                    target: LauncherSearch
                    function onResultsChanged() {
                        resultModel.values = LauncherSearch.results.slice(0, root.typingResultLimit);
                        root.focusFirstItem();
                        debounceTimer.restart();
                    }
                }

                model: ScriptModel {
                    id: resultModel
                    objectProp: "key"
                }

                delegate: SearchItem {
                    id: searchItem
                    // The selectable item for each search result
                    required property var modelData
                    required property int index
                    anchors.left: parent?.left
                    anchors.right: parent?.right
                    entry: modelData
                    clearBtnHasFocus: root.clearBtnHasFocus
                    query: StringUtils.cleanOnePrefix(root.searchingText, [Config.options.search.prefix.action, Config.options.search.prefix.app, Config.options.search.prefix.clipboard, Config.options.search.prefix.emojis, Config.options.search.prefix.math, Config.options.search.prefix.shellCommand, Config.options.search.prefix.webSearch])

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Tab) {
                            if (LauncherSearch.results.length === 0)
                                return;
                            const tabbedText = searchItem.modelData.name;
                            LauncherSearch.query = tabbedText;
                            searchBar.searchInput.text = tabbedText;
                            event.accepted = true;
                            root.focusSearchInput();
                        } else if (event.key === Qt.Key_Up && searchItem.index === 0) {
                            const isClipboard = root.searchingText.startsWith(Config.options.search.prefix.clipboard);
                            if (isClipboard) {
                                if (root.clipboardSearching) {
                                    clearResultsBtn.forceActiveFocus();
                                } else {
                                    clearClipboardBtn.forceActiveFocus();
                                }
                                event.accepted = true;
                            }
                        } else if (event.key === Qt.Key_Down) {
                            const listView = searchItem.ListView.view;
                            if (searchItem.index === listView.count - 1) {
                                event.accepted = true;
                            }
                        }
                    }
                }
            }
        }
    }
}
