import "root:/"
import "root:/services"
import "root:/modules/common"
import "root:/modules/common/widgets"
import "./anime/"
import Qt.labs.platform
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell.Io
import Quickshell
import Quickshell.Hyprland

Item {
    id: root
    property var panelWindow
    property var inputField: tagInputField
    property string previewDownloadPath: `${StandardPaths.standardLocations(StandardPaths.CacheLocation)[0]}/media/waifus`.replace("file://", "")
    property string downloadPath: (StandardPaths.standardLocations(StandardPaths.PicturesLocation)[0] + "/homework").replace("file://", "")
    property string nsfwPath: (StandardPaths.standardLocations(StandardPaths.PicturesLocation)[0] + "/homework/🌶️").replace("file://", "")
    property string commandPrefix: "/"
    property real scrollOnNewResponse: 100
    property int tagSuggestionDelay: 210
    property var suggestionQuery: ""
    property var suggestionList: []

    Connections {
        target: Booru
        function onTagSuggestion(query, suggestions) {
            root.suggestionQuery = query;
            root.suggestionList = suggestions;
        }
    }

    Component.onCompleted: {
        Hyprland.dispatch(`exec rm -rf ${previewDownloadPath}`)
        Hyprland.dispatch(`exec mkdir -p ${previewDownloadPath}`)
    }

    function handleInput(inputText) {
        if (inputText.startsWith(root.commandPrefix)) {
            // Handle special commands
            const command = inputText.split(" ")[0].substring(1);
            const args = inputText.split(" ").slice(1);
            if (command === "clear") {
                Booru.clearResponses();
            } 
            else if (command === "mode") {
                const newProvider = args[0];
                Booru.setProvider(newProvider);
            }
            else if (command == "nsfw") {
                ConfigOptions.sidebar.booru.allowNsfw = !ConfigOptions.sidebar.booru.allowNsfw
            }
            else if (command == "safe") {
                ConfigOptions.sidebar.booru.allowNsfw = false
            }
            else if (command == "lewd") {
                ConfigOptions.sidebar.booru.allowNsfw = true
            }
            else if (command == "next") {
                if (Booru.responses.length > 0) {
                    const lastResponse = Booru.responses[Booru.responses.length - 1]
                    root.handleInput(lastResponse.tags.join(" ") + ` ${parseInt(lastResponse.page) + 1}`);
                }
            }
        }
        else if (inputText.trim() == "+") {
            if (Booru.responses.length > 0) {
                const lastResponse = Booru.responses[Booru.responses.length - 1]
                root.handleInput(lastResponse.tags.join(" ") + ` ${parseInt(lastResponse.page) + 1}`);
            }
        }
        else {
            // Create tag list
            const tagList = inputText.split(/\s+/).filter(tag => tag.length > 0);
            let pageIndex = 1;
            for (let i = 0; i < tagList.length; ++i) { // Detect page number
                if (/^\d+$/.test(tagList[i])) {
                    pageIndex = parseInt(tagList[i], 10);
                    tagList.splice(i, 1);
                    break;
                }
            }
            Booru.makeRequest(tagList, ConfigOptions.sidebar.booru.allowNsfw, ConfigOptions.sidebar.booru.limit, pageIndex);
        }
    }

    Keys.onPressed: (event) => {
        tagInputField.forceActiveFocus()
        if (event.modifiers === Qt.NoModifier) {
            if (event.key === Qt.Key_PageUp) {
                booruResponseListView.contentY = Math.max(0, booruResponseListView.contentY - booruResponseListView.height / 2)
                event.accepted = true
            } else if (event.key === Qt.Key_PageDown) {
                booruResponseListView.contentY = Math.min(booruResponseListView.contentHeight - booruResponseListView.height / 2, booruResponseListView.contentY + booruResponseListView.height / 2)
                event.accepted = true
            }
        }
    }

    onFocusChanged: (focus) => {
        if (focus) {
            tagInputField.forceActiveFocus()
        }
    }

    ColumnLayout {
        id: columnLayout
        anchors.fill: parent

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            ListView { // Booru responses
                id: booruResponseListView
                anchors.fill: parent
                
                property int lastResponseLength: 0

                clip: true
                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: swipeView.width
                        height: swipeView.height
                        radius: Appearance.rounding.small
                    }
                }

                Behavior on contentY {
                    NumberAnimation {
                        id: scrollAnim
                        duration: Appearance.animation.elementDecel.duration
                        easing.type: Appearance.animation.elementDecel.type
                    }
                }

                spacing: 10
                model: ScriptModel {
                    values: {
                        if(Booru.responses.length > booruResponseListView.lastResponseLength) {
                            if (booruResponseListView.lastResponseLength > 0 && Booru.responses[booruResponseListView.lastResponseLength].provider != "system")
                                booruResponseListView.contentY = booruResponseListView.contentY + root.scrollOnNewResponse
                            booruResponseListView.lastResponseLength = Booru.responses.length
                        }
                        return Booru.responses
                    }
                }
                delegate: BooruResponse {
                    responseData: modelData
                    tagInputField: root.inputField
                    previewDownloadPath: root.previewDownloadPath
                    downloadPath: root.downloadPath
                    nsfwPath: root.nsfwPath
                }
            }

            Item { // Placeholder when list is empty
                opacity: Booru.responses.length === 0 ? 1 : 0
                visible: opacity > 0
                anchors.fill: parent

                Behavior on opacity {
                    NumberAnimation {
                        duration: Appearance.animation.elementDecel.duration
                        easing.type: Appearance.animation.elementDecel.type
                    }
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 5

                    MaterialSymbol {
                        Layout.alignment: Qt.AlignHCenter
                        font.pixelSize: 55
                        color: Appearance.m3colors.m3outline
                        text: "bookmark_heart"
                    }
                    StyledText {
                        id: widgetNameText
                        Layout.alignment: Qt.AlignHCenter
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: Appearance.m3colors.m3outline
                        horizontalAlignment: Text.AlignHCenter
                        text: qsTr("Anime boorus")
                    }
                }
            }
        }

        Flow { // Tag suggestions
            id: tagSuggestions
            visible: root.suggestionList.length > 0 && 
                tagInputField.text.length > 0
            property int selectedIndex: 0
            Layout.fillWidth: true
            spacing: 5

            Repeater {
                id: tagSuggestionRepeater
                model: {
                    tagSuggestions.selectedIndex = 0
                    return root.suggestionList.slice(0, 10)
                }
                delegate: BooruTagButton {
                    id: tagButton
                    // buttonText: `${modelData.name}_{${modelData.count}}`
                    background: Rectangle {
                        radius: Appearance.rounding.small
                        color: tagSuggestions.selectedIndex === index ? Appearance.colors.colLayer2Hover : 
                            tagButton.down ? Appearance.colors.colLayer2Active : 
                            tagButton.hovered ? Appearance.colors.colLayer2Hover :
                            Appearance.colors.colLayer2
                            
                        Behavior on color {
                            ColorAnimation {
                                duration: Appearance.animation.elementDecel.duration
                                easing.type: Appearance.animation.elementDecel.type
                            }
                        }
                    }
                    contentItem: RowLayout {
                        spacing: 5
                        StyledText {
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.m3colors.m3onSurface
                            text: modelData.name
                        }
                        StyledText {
                            visible: modelData.count !== undefined
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.m3colors.m3outline
                            text: modelData.count ?? ""
                        }
                    }
                    onClicked: {
                        tagSuggestions.acceptTag(modelData.name)
                    }
                }
            }

            function acceptTag(tag) {
                const words = tagInputField.text.trim().split(/\s+/);
                if (words.length > 0) {
                    words[words.length - 1] = tag;
                } else {
                    words.push(tag);
                }
                const updatedText = words.join(" ") + " ";
                tagInputField.text = updatedText;
                tagInputField.cursorPosition = tagInputField.text.length;
                tagInputField.forceActiveFocus();
            }

            function acceptSelectedTag() {
                if (tagSuggestions.selectedIndex >= 0 && tagSuggestions.selectedIndex < tagSuggestionRepeater.count) {
                    const tag = root.suggestionList[tagSuggestions.selectedIndex].name;
                    tagSuggestions.acceptTag(tag);
                }
            }
        }

        Rectangle { // Tag input area
            id: tagInputContainer
            property real columnSpacing: 5
            Layout.fillWidth: true
            radius: Appearance.rounding.small
            color: Appearance.colors.colLayer1
            implicitWidth: tagInputField.implicitWidth
            implicitHeight: Math.max(inputFieldRowLayout.implicitHeight + inputFieldRowLayout.anchors.topMargin 
                + commandButtonsRow.implicitHeight + commandButtonsRow.anchors.bottomMargin + columnSpacing, 45)
            clip: true
            border.color: Appearance.m3colors.m3outlineVariant
            border.width: 1

            Behavior on implicitHeight {
                NumberAnimation {
                    duration: Appearance.animation.elementDecel.duration
                    easing.type: Appearance.animation.elementDecel.type
                }
            }

            RowLayout { // Input field and send button
                id: inputFieldRowLayout
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.topMargin: 5
                spacing: 0

                TextArea { // The actual TextArea
                    id: tagInputField
                    wrapMode: TextArea.Wrap
                    Layout.fillWidth: true
                    padding: 10
                    color: activeFocus ? Appearance.m3colors.m3onSurface : Appearance.m3colors.m3onSurfaceVariant
                    renderType: Text.NativeRendering
                    selectedTextColor: Appearance.m3colors.m3onPrimary
                    selectionColor: Appearance.m3colors.m3primary
                    placeholderText: qsTr("Enter tags")
                    placeholderTextColor: Appearance.m3colors.m3outline

                    background: Item {}

                    property Timer searchTimer: Timer {
                        interval: root.tagSuggestionDelay
                        repeat: false
                        onTriggered: {
                            const inputText = tagInputField.text
                            if (inputText.length === 0 || inputText.startsWith(root.commandPrefix)) return;
                            const words = inputText.trim().split(/\s+/);
                            if (words.length > 0) {
                                Booru.triggerTagSearch(words[words.length - 1]);
                            }
                        }
                    }

                    onTextChanged: {
                        if(tagInputField.text.length === 0) {
                            root.suggestionQuery = ""
                            root.suggestionList = []
                            return
                        }
                        searchTimer.restart();
                    }

                    function accept() {
                        root.handleInput(text)
                        text = ""
                    }

                    Keys.onPressed: (event) => {
                        if (event.key === Qt.Key_Tab) {
                            tagSuggestions.acceptSelectedTag();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Up) {
                            tagSuggestions.selectedIndex = Math.max(0, tagSuggestions.selectedIndex - 1);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Down) {
                            tagSuggestions.selectedIndex = Math.min(root.suggestionList.length - 1, tagSuggestions.selectedIndex + 1);
                            event.accepted = true;
                        } else if ((event.key === Qt.Key_Enter || event.key === Qt.Key_Return)) {
                            if (event.modifiers & Qt.ShiftModifier) {
                                // Insert newline
                                tagInputField.insert(tagInputField.cursorPosition, "\n")
                                event.accepted = true
                            } else { // Accept text
                                const inputText = tagInputField.text
                                root.handleInput(inputText)
                                tagInputField.clear()
                                event.accepted = true
                            }
                        }
                    }
                }

                Button { // Send button
                    id: sendButton
                    Layout.alignment: Qt.AlignTop
                    Layout.rightMargin: 5
                    implicitWidth: 40
                    implicitHeight: 40
                    enabled: tagInputField.text.length > 0

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: sendButton.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: {
                            const inputText = tagInputField.text
                            root.handleInput(inputText)
                            tagInputField.clear()
                        }
                    }

                    background: Rectangle {
                        radius: Appearance.rounding.small
                        color: sendButton.enabled ? (sendButton.down ? Appearance.colors.colPrimaryActive : 
                            sendButton.hovered ? Appearance.colors.colPrimaryHover :
                            Appearance.m3colors.m3primary) : Appearance.colors.colLayer2Disabled
                            
                        Behavior on color {
                            ColorAnimation {
                                duration: Appearance.animation.elementDecel.duration
                                easing.type: Appearance.animation.elementDecel.type
                            }
                        }
                    }

                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: "send"
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: Appearance.font.pixelSize.larger
                        color: sendButton.enabled ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer2Disabled
                    }
                }
            }

            RowLayout { // Controls
                id: commandButtonsRow
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 5
                anchors.leftMargin: 5
                anchors.rightMargin: 5
                spacing: 5

                property var commands: [
                    {
                        name: "/mode",
                        sendDirectly: false,
                    },
                    {
                        name: "/clear",
                        sendDirectly: true,
                    }, 
                ]

                Item {
                    implicitHeight: providerRowLayout.implicitHeight + 5 * 2
                    implicitWidth: providerRowLayout.implicitWidth + 10 * 2
                    
                    RowLayout {
                        id: providerRowLayout
                        anchors.centerIn: parent

                        MaterialSymbol {
                            text: "api"
                            font.pixelSize: Appearance.font.pixelSize.large
                        }
                        StyledText {
                            id: providerName
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: Font.DemiBold
                            color: Appearance.m3colors.m3onSurface
                            text: Booru.providers[Booru.currentProvider].name
                        }
                    }
                    StyledToolTip {
                        id: toolTip
                        alternativeVisibleCondition: mouseArea.containsMouse // Show tooltip when hovered
                        content: qsTr("The current API used. Endpoint: ") + Booru.providers[Booru.currentProvider].url + qsTr("\nSet with /mode PROVIDER")
                    }

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                    }
                }

                StyledText {
                    font.pixelSize: Appearance.font.pixelSize.large
                    color: Appearance.colors.colOnLayer1
                    text: "•"
                }

                Rectangle {
                    implicitWidth: switchesRow.implicitWidth

                    RowLayout {
                        id: switchesRow
                        spacing: 5
                        anchors.centerIn: parent

                        StyledText {
                            Layout.fillHeight: true
                            Layout.leftMargin: 10
                            Layout.alignment: Qt.AlignVCenter
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colOnLayer1
                            text: qsTr("NSFW")
                        }
                        StyledSwitch {
                            id: nsfwSwitch
                            enabled: Booru.currentProvider !== "zerochan"
                            scale: 0.6
                            Layout.alignment: Qt.AlignVCenter
                            checked: (ConfigOptions.sidebar.booru.allowNsfw && Booru.currentProvider !== "zerochan")
                            onCheckedChanged: {
                                if (!nsfwSwitch.enabled) return;
                                ConfigOptions.sidebar.booru.allowNsfw = checked
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                Repeater { // Command buttons
                    id: commandRepeater
                    model: commandButtonsRow.commands
                    delegate: BooruTagButton {
                        id: tagButton
                        buttonText: modelData.name
                        background: Rectangle {
                            radius: Appearance.rounding.small
                            color: tagButton.down ? Appearance.colors.colLayer2Active : 
                                tagButton.hovered ? Appearance.colors.colLayer2Hover :
                                Appearance.colors.colLayer2
                                
                            Behavior on color {
                                ColorAnimation {
                                    duration: Appearance.animation.elementDecel.duration
                                    easing.type: Appearance.animation.elementDecel.type
                                }
                            }
                        }
                        onClicked: {
                            if(modelData.sendDirectly) {
                                root.handleInput(modelData.name)
                            } else {
                                tagInputField.text = modelData.name + " "
                                tagInputField.cursorPosition = tagInputField.text.length
                                tagInputField.forceActiveFocus()
                            }
                        }
                    }
                }
            }

        }
    }
}
