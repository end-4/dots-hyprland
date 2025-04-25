import "root:/"
import "root:/modules/common"
import "root:/modules/common/widgets"
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item { // Wrapper
    id: root
    required property var panelWindow
    property string searchingText: ""
    property bool showResults: searchingText != ""
    property real searchBarHeight: searchBar.height + Appearance.sizes.elevationMargin * 2
    implicitWidth: searchWidgetContent.implicitWidth + Appearance.sizes.elevationMargin * 2
    implicitHeight: searchWidgetContent.implicitHeight + Appearance.sizes.elevationMargin * 2

    property string mathResult: ""

    function focusFirstItemIfNeeded() {
        if (searchInput.focus) appResults.currentIndex = 0; // Focus the first item
    }

    Timer {
        id: nonAppResultsTimer
        interval: ConfigOptions.search.nonAppResultDelay
        onTriggered: {
            mathProcess.calculateExpression(root.searchingText);
        }
    }

    Process {
        id: mathProcess
        property list<string> baseCommand: ["qalc", "-t"]
        function calculateExpression(expression) {
            // mathProcess.running = false
            mathProcess.command = baseCommand.concat(expression)
            mathProcess.running = true
        }
        stdout: SplitParser {
            onRead: data => {
                root.mathResult = data
                root.focusFirstItemIfNeeded()
            }
        }
    }

    Process {
        id: copyText
        property list<string> baseCommand: ["wl-copy"]
        function copyTextToClipboard(text) {
            copyText.running = false
            copyText.command = baseCommand.concat(text)
            copyText.running = true
        }
    }

    Process {
        id: webSearch
        property list<string> baseCommand: ["xdg-open"]
        function search(query) {
            webSearch.running = false
            let url = ConfigOptions.search.engineBaseUrl + query
            for (let site of ConfigOptions.search.excludedSites) {
                url += ` -site:${site}`;
            }
            webSearch.command = baseCommand.concat(url)
            webSearch.running = true
        }
    }

    Process {
        id: executor
        property list<string> baseCommand: ["bash", "-c"]
        function executeCommand(command) {
            executor.running = false
            executor.command = baseCommand.concat(
                `${command} || ${ConfigOptions.apps.terminal} fish -C 'echo "${qsTr("Searching for package with that command")}..." && pacman -F ${command}'`
            )
            executor.running = true
        }
    }

    Keys.onPressed: (event) => {
        // Prevent Esc and Backspace from registering
        if (event.key === Qt.Key_Escape) return;

        // Handle Backspace: focus and delete character if not focused
        if (event.key === Qt.Key_Backspace) {
            if (!searchInput.activeFocus) {
                searchInput.forceActiveFocus();
                if (event.modifiers & Qt.ControlModifier) {
                    // Delete word before cursor
                    let text = searchInput.text;
                    let pos = searchInput.cursorPosition;
                    if (pos > 0) {
                        // Find the start of the previous word
                        let left = text.slice(0, pos);
                        let match = left.match(/(\s*\S+)\s*$/);
                        let deleteLen = match ? match[0].length : 1;
                        searchInput.text = text.slice(0, pos - deleteLen) + text.slice(pos);
                        searchInput.cursorPosition = pos - deleteLen;
                    }
                } else {
                    // Delete character before cursor if any
                    if (searchInput.cursorPosition > 0) {
                        searchInput.text = searchInput.text.slice(0, searchInput.cursorPosition - 1) +
                            searchInput.text.slice(searchInput.cursorPosition);
                        searchInput.cursorPosition -= 1;
                    }
                }
                // Always move cursor to end after programmatic edit
                searchInput.cursorPosition = searchInput.text.length;
                event.accepted = true;
            }
            // If already focused, let TextField handle it
            return;
        }

        // Only handle visible printable characters (ignore control chars, arrows, etc.)
        if (
            event.text &&
            event.text.length === 1 &&
            event.key !== Qt.Key_Enter &&
            event.key !== Qt.Key_Return &&
            event.text.charCodeAt(0) >= 0x20 // ignore control chars like Backspace, Tab, etc.
        ) {
            if (!searchInput.activeFocus) {
                searchInput.forceActiveFocus();
                // Insert the character at the cursor position
                searchInput.text = searchInput.text.slice(0, searchInput.cursorPosition) +
                                event.text +
                                searchInput.text.slice(searchInput.cursorPosition);
                searchInput.cursorPosition += 1;
                event.accepted = true;
            }
        }
    }

    Rectangle { // Background
        id: searchWidgetContent
        anchors.centerIn: parent
        implicitWidth: columnLayout.implicitWidth
        implicitHeight: columnLayout.implicitHeight
        radius: Appearance.rounding.large
        color: Appearance.colors.colLayer0

        ColumnLayout {
            id: columnLayout
            anchors.centerIn: parent
            spacing: 0

            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: searchWidgetContent.width
                    height: searchWidgetContent.width
                    radius: searchWidgetContent.radius
                }
            }

            RowLayout {
                id: searchBar
                spacing: 5
                MaterialSymbol {
                    id: searchIcon
                    Layout.leftMargin: 15
                    font.pixelSize: Appearance.font.pixelSize.huge
                    color: Appearance.m3colors.m3onSurface
                    text: "search"
                }
                TextField { // Search box
                    id: searchInput

                    focus: root.panelWindow.visible || GlobalStates.overviewOpen
                    Layout.rightMargin: 15
                    padding: 15
                    color: activeFocus ? Appearance.m3colors.m3onSurface : Appearance.m3colors.m3onSurfaceVariant
                    selectedTextColor: Appearance.m3colors.m3onSurface
                    placeholderText: qsTr("Search, calculate or run")
                    placeholderTextColor: Appearance.m3colors.m3outline
                    implicitWidth: root.searchingText == "" ? Appearance.sizes.searchWidthCollapsed : Appearance.sizes.searchWidth

                    KeyNavigation.down: {
                        if (appResults.count > 1) {
                            appResults.focus = true;
                            appResults.currentIndex = 1;
                        }
                    }

                    Behavior on implicitWidth {
                        NumberAnimation {
                            duration: Appearance.animation.elementDecelFast.duration
                            easing.type: Appearance.animation.elementDecelFast.type
                        }
                    }

                    onTextChanged: root.searchingText = text
                    Connections {
                        target: root
                        function onVisibleChanged() {
                            searchInput.selectAll()
                            root.searchingText = ""
                        }
                    }

                    onAccepted: {
                        if (appResults.count > 0) {
                            // Get the first visible delegate and trigger its click
                            let firstItem = appResults.itemAtIndex(0);
                            if (firstItem && firstItem.clicked) {
                                firstItem.clicked();
                            }
                        }
                    }

                    background: Item {}

                    cursorDelegate: Rectangle {
                        width: 1
                        color: searchInput.activeFocus ? Appearance.m3colors.m3primary : "transparent"
                        radius: 1
                    }
                }
            }

            Rectangle { // Separator
                visible: root.showResults
                Layout.fillWidth: true
                height: 1
                color: Appearance.m3colors.m3outline
            }

            ListView { // App results
                id: appResults
                visible: root.showResults
                Layout.fillWidth: true
                implicitHeight: Math.min(600, appResults.contentHeight + topMargin + bottomMargin)
                clip: true
                topMargin: 10
                bottomMargin: 10
                spacing: 0
                KeyNavigation.up: searchBar

                Connections {
                    target: root
                    function onSearchingTextChanged() {
                        if (appResults.count > 0)
                            appResults.currentIndex = 0;
                    }
                }

                model: ScriptModel {
                    id: model
                    values: {
                        if(root.searchingText == "") return [];

                        // Start math and other non-app stuff
                        nonAppResultsTimer.restart();

                        // Init result array
                        let result = [];

                        // Add filtered application entries
                        result = result.concat(
                            DesktopEntries.applications.values
                                .filter((entry) => {
                                    if (root.searchingText == "") return false
                                    return entry.name.toLowerCase().includes(root.searchingText.toLowerCase())
                                })
                                .map((entry) => {
                                    entry.clickActionName = "Launch";
                                    entry.type = "App"
                                    return entry;
                                })
                        );

                        // Add non-app results
                        result.push({
                            name: root.mathResult,
                            clickActionName: "Copy",
                            type: qsTr("Math result"),
                            fontType: "monospace",
                            materialSymbol: 'calculate',
                            execute: () => {
                                copyText.copyTextToClipboard(root.mathResult);
                            }
                        });
                        result.push({
                            name: searchingText,
                            clickActionName: "Run",
                            type: qsTr("Run command"),
                            fontType: "monospace",
                            materialSymbol: 'terminal',
                            execute: () => {
                                executor.executeCommand(searchingText.startsWith('sudo') ? `${ConfigOptions.apps.terminal} fish -C '${root.searchingText}'` : root.searchingText);
                            }
                        });
                        result.push({
                            name: root.searchingText,
                            clickActionName: "Search",
                            type: "Search the web",
                            materialSymbol: 'travel_explore',
                            execute: () => {
                                webSearch.search(root.searchingText);
                            }
                        });

                        return result;
                    }
                }
                delegate: SearchItem {
                    entry: modelData
                    // itemName: modelData.name
                    // itemIcon: modelData.icon
                }
            }
            
        }
    }

    DropShadow {
        id: searchWidgetShadow
        anchors.fill: searchWidgetContent
        source: searchWidgetContent
        radius: Appearance.sizes.elevationMargin
        samples: radius * 2 + 1
        color: Appearance.colors.colShadow
        verticalOffset: 2
        horizontalOffset: 0
    }
}