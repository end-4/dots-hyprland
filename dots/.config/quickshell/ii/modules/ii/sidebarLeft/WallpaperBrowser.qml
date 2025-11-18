import qs  
import qs.services  
import qs.modules.common  
import qs.modules.common.widgets  
import qs.modules.common.functions  
import qs.modules.ii.sidebarLeft.wallpaperBrowser  
import QtQuick  
import QtQuick.Controls  
import QtQuick.Layouts  
import Qt5Compat.GraphicalEffects  
import Quickshell  
  
Item {  
    id: root  
    property var inputField: tagInputField  
    readonly property var responses: UnsplashWallpapers.responses  
    property string previewDownloadPath: Directories.unsplashPreviews  
    property string downloadPath: FileUtils.trimFileProtocol(Directories.pictures + "/Wallpapers")  
    property string commandPrefix: "/"  
    property real scrollOnNewResponse: 100  
    property int tagSuggestionDelay: 210  
    property var suggestionQuery: ""  
    property var suggestionList: []  
  
    property bool pullLoading: false  
    property int pullLoadingGap: 80  
    property real normalizedPullDistance: Math.max(0, (1 - Math.exp(-unsplashResponseListView.verticalOvershoot / 50)) * unsplashResponseListView.dragging)  
  
    Connections {  
        target: UnsplashWallpapers  
        function onTagSuggestion(query, suggestions) {  
            root.suggestionQuery = query;  
            root.suggestionList = suggestions;  
        }  
        function onRunningRequestsChanged() {  
            if (UnsplashWallpapers.runningRequests === 0) {  
                root.pullLoading = false;  
            }  
        }  
    }  
  
    property var allCommands: [  
        {  
            name: "mode",  
            description: Translation.tr("Set the current API provider"),  
            execute: (args) => {  
                UnsplashWallpapers.setProvider(args[0]);  
            }  
        },  
        {  
            name: "clear",  
            description: Translation.tr("Clear the current list of images"),  
            execute: () => {  
                UnsplashWallpapers.clearResponses();  
            }  
        },  
        {  
            name: "next",  
            description: Translation.tr("Get the next page of results"),  
            execute: () => {  
                if (root.responses.length > 0) {  
                    const lastResponse = root.responses[root.responses.length - 1];  
                    root.handleInput(`${lastResponse.tags.join(" ")} ${parseInt(lastResponse.page) + 1}`);  
                } else {  
                    root.handleInput("");  
                }  
            }  
        }  
    ]
  
    function handleInput(inputText) {  
        if (inputText.startsWith(root.commandPrefix)) {  
            const command = inputText.split(" ")[0].substring(1);  
            const args = inputText.split(" ").slice(1);  
            const commandObj = root.allCommands.find(cmd => cmd.name === command);  
            if (commandObj) {  
                commandObj.execute(args);  
            } else {  
                UnsplashWallpapers.addSystemMessage(Translation.tr("Unknown command: ") + command);  
            }  
        }  
        else {  
            const tagList = inputText.split(/\s+/).filter(tag => tag.length > 0);  
            UnsplashWallpapers.makeRequest(tagList, Config.options.sidebar.unsplash.limit);  
        }  
    }  
  
    onFocusChanged: (focus) => {  
        if (focus) {  
            tagInputField.forceActiveFocus()  
        }  
    }  
  
    property real pageKeyScrollAmount: unsplashResponseListView.height / 2  
    Keys.onPressed: (event) => {  
        tagInputField.forceActiveFocus()  
        if (event.modifiers === Qt.NoModifier) {  
            if (event.key === Qt.Key_PageUp) {  
                if (unsplashResponseListView.atYBeginning) return;  
                unsplashResponseListView.contentY = Math.max(0, unsplashResponseListView.contentY - root.pageKeyScrollAmount)  
                event.accepted = true  
            } else if (event.key === Qt.Key_PageDown) {  
                if (unsplashResponseListView.atYEnd) return;  
                unsplashResponseListView.contentY = Math.min(unsplashResponseListView.contentHeight, unsplashResponseListView.contentY + root.pageKeyScrollAmount)  
                event.accepted = true  
            }  
        }  
        if ((event.modifiers & Qt.ControlModifier) && (event.modifiers & Qt.ShiftModifier) && event.key === Qt.Key_O) {  
            UnsplashWallpapers.clearResponses()  
        }  
    }  
  
    ColumnLayout {  
        id: columnLayout  
        anchors.fill: parent  
  
        Item {  
            Layout.fillWidth: true  
            Layout.fillHeight: true  
  
            layer.enabled: true  
            layer.effect: OpacityMask {  
                maskSource: Rectangle {  
                    width: unsplashResponseListView.width  
                    height: unsplashResponseListView.height  
                    radius: Appearance.rounding.small  
                }  
            }  
  
            ScrollEdgeFade {  
                z: 1  
                target: unsplashResponseListView  
                vertical: true  
            }  
  
            StyledListView {  
                id: unsplashResponseListView  
                z: 0  
                anchors.fill: parent  
                spacing: 10  
                  
                touchpadScrollFactor: Config.options.interactions.scrolling.touchpadScrollFactor * 1.4  
                mouseScrollFactor: Config.options.interactions.scrolling.mouseScrollFactor * 1.4  
  
                property int lastResponseLength: 0  
                Connections {  
                    target: root  
                    function onResponsesChanged() {  
                        if (root.responses.length > unsplashResponseListView.lastResponseLength) {  
                            if (unsplashResponseListView.lastResponseLength > 0 && root.responses[unsplashResponseListView.lastResponseLength].provider != "system")  
                                unsplashResponseListView.contentY = unsplashResponseListView.contentY + root.scrollOnNewResponse  
                            unsplashResponseListView.lastResponseLength = root.responses.length  
                        }  
                    }  
                }  
  
                model: ScriptModel {  
                    values: root.responses  
                }  
                delegate: UnsplashResponse {  
                    responseData: modelData  
                    tagInputField: root.inputField  
                    previewDownloadPath: root.previewDownloadPath  
                    downloadPath: root.downloadPath  
                }  
  
                onDragEnded: {  
                    const gap = unsplashResponseListView.verticalOvershoot  
                    if (gap > root.pullLoadingGap) {  
                        root.pullLoading = true  
                        root.handleInput(tagInputField.text)  
                    }  
                }  
            }  
  
            PagePlaceholder {  
                id: placeholderItem  
                z: 2  
                shown: root.responses.length === 0  
                icon: "gallery_thumbnail"  
                title: Translation.tr("Wallpapers")  
                description: ""  
                shape: MaterialShape.Shape.Bun  
            }  
  
            ScrollToBottomButton {  
                z: 3  
                target: unsplashResponseListView  
            }  
  
            MaterialLoadingIndicator {  
                id: loadingIndicator  
                z: 4  
                anchors {  
                    horizontalCenter: parent.horizontalCenter  
                    bottom: parent.bottom  
                    bottomMargin: 20 + (root.pullLoading ? 0 : Math.max(0, (root.normalizedPullDistance - 0.5) * 50))  
                    Behavior on bottomMargin {  
                        NumberAnimation {  
                            duration: 200  
                            easing.type: Easing.BezierSpline  
                            easing.bezierCurve: Appearance.animationCurves.expressiveFastSpatial  
                        }  
                    }  
                }  
                loading: root.pullLoading || UnsplashWallpapers.runningRequests > 0  
                pullProgress: Math.min(1, unsplashResponseListView.verticalOvershoot / root.pullLoadingGap * unsplashResponseListView.dragging)  
                scale: root.pullLoading ? 1 : Math.min(1, root.normalizedPullDistance * 2)  
            }  
        }  
  
        DescriptionBox {  
            text: root.suggestionList[tagSuggestions.selectedIndex]?.description ?? ""  
            showArrows: root.suggestionList.length > 1  
        }  
  
        FlowButtonGroup {  
            id: tagSuggestions  
            visible: root.suggestionList.length > 0 && tagInputField.text.length > 0  
            property int selectedIndex: 0  
            Layout.fillWidth: true  
            spacing: 5  
  
            Repeater {  
                id: tagSuggestionRepeater  
                model: {  
                    tagSuggestions.selectedIndex = 0  
                    return root.suggestionList.slice(0, 10)  
                }  
                delegate: ApiCommandButton {  
                    id: tagButton  
                    colBackground: tagSuggestions.selectedIndex === index ? Appearance.colors.colSecondaryContainerHover : Appearance.colors.colSecondaryContainer  
                    bounce: false  
                    contentItem: RowLayout {  
                        anchors.centerIn: parent  
                        spacing: 5  
                        StyledText {  
                            Layout.fillWidth: false  
                            font.pixelSize: Appearance.font.pixelSize.small  
                            color: Appearance.colors.colOnSecondaryContainer  
                            horizontalAlignment: Text.AlignRight  
                            text: modelData.displayName ?? modelData.name  
                        }  
                        StyledText {  
                            Layout.fillWidth: false  
                            visible: modelData.count !== undefined  
                            font.pixelSize: Appearance.font.pixelSize.smaller  
                            color: Appearance.colors.colOnSecondaryContainer  
                            horizontalAlignment: Text.AlignLeft  
                            text: modelData.count ?? ""  
                        }  
                    }  
  
                    onHoveredChanged: {  
                        if (tagButton.hovered) {  
                            tagSuggestions.selectedIndex = index;  
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
  
        Rectangle {  
            id: tagInputContainer  
            property real columnSpacing: 5  
            Layout.fillWidth: true  
            radius: Appearance.rounding.small  
            color: Appearance.colors.colLayer1  
            implicitWidth: tagInputField.implicitWidth  
            implicitHeight: Math.max(inputFieldRowLayout.implicitHeight + inputFieldRowLayout.anchors.topMargin   
                + commandButtonsRow.implicitHeight + commandButtonsRow.anchors.bottomMargin + columnSpacing, 45)  
            clip: true  
            border.color: Appearance.colors.colOutlineVariant  
            border.width: 1  
  
            Behavior on implicitHeight {  
                animation: Appearance.animation.elementMove.numberAnimation.createObject(this)  
            }  
  
            RowLayout {  
                id: inputFieldRowLayout  
                anchors.top: parent.top  
                anchors.left: parent.left  
                anchors.right: parent.right  
                anchors.topMargin: 5  
                spacing: 0  
  
                StyledTextArea {  
                    id: tagInputField  
                    wrapMode: TextArea.Wrap  
                    Layout.fillWidth: true  
                    padding: 10  
                    color: activeFocus ? Appearance.m3colors.m3onSurface : Appearance.m3colors.m3onSurfaceVariant  
                    renderType: Text.NativeRendering  
                    placeholderText: Translation.tr('Enter tags, or "%1" for commands').arg(root.commandPrefix)  
  
                    background: null  
  
                    property Timer searchTimer: Timer {  
                        interval: root.tagSuggestionDelay  
                        repeat: false  
                        onTriggered: {  
                            const inputText = tagInputField.text  
                            const words = inputText.trim().split(/\s+/);  
                            if (words.length > 0) {  
                                UnsplashWallpapers.triggerTagSearch(words[words.length - 1]);  
                            }  
                        }  
                    }  
  
                    onTextChanged: {  
                        if(tagInputField.text.length === 0) {  
                            root.suggestionQuery = ""  
                            root.suggestionList = []  
                            searchTimer.stop();  
                            return  
                        }  
                        if(tagInputField.text.startsWith(root.commandPrefix)) {  
                            root.suggestionQuery = tagInputField.text  
                            root.suggestionList = root.allCommands.filter(cmd => cmd.name.startsWith(tagInputField.text.substring(1))).map(cmd => {  
                                return {  
                                    name: `${root.commandPrefix}${cmd.name}`,  
                                    description: cmd.description,  
                                }  
                            })  
                            searchTimer.stop();  
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
                                tagInputField.insert(tagInputField.cursorPosition, "\n")  
                                event.accepted = true  
                            } else {  
                                const inputText = tagInputField.text  
                                root.handleInput(inputText)  
                                tagInputField.clear()  
                                event.accepted = true  
                            }  
                        }  
                    }  
                }  
  
                RippleButton {  
                    id: sendButton  
                    Layout.alignment: Qt.AlignTop  
                    Layout.rightMargin: 5  
                    implicitWidth: 40  
                    implicitHeight: 40  
                    buttonRadius: Appearance.rounding.small  
                    enabled: tagInputField.text.length > 0  
                    toggled: enabled  
  
                    MouseArea {  
                        anchors.fill: parent  
                        cursorShape: sendButton.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor  
                        onClicked: {  
                            const inputText = tagInputField.text  
                            root.handleInput(inputText)  
                            tagInputField.clear()  
                        }  
                    }  
  
                    contentItem: MaterialSymbol {  
                        anchors.centerIn: parent  
                        horizontalAlignment: Text.AlignHCenter  
                        iconSize: Appearance.font.pixelSize.larger  
                        color: sendButton.enabled ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer2Disabled  
                        text: "send"  
                    }  
                }  
            }  
  
            RowLayout {  
                id: commandButtonsRow  
                anchors.left: parent.left  
                anchors.right: parent.right  
                anchors.bottom: parent.bottom  
                anchors.bottomMargin: 5  
                anchors.leftMargin: 5  
                anchors.rightMargin: 5  
                spacing: 5  
  
                property var commandsShown: [  
                    {  
                        name: "mode",  
                        sendDirectly: false,  
                    },
                    {  
                        name: "clear",  
                        sendDirectly: true,  
                    },   
                ]  

                ApiInputBoxIndicator {  
                    icon: "api"  
                    text: UnsplashWallpapers.providers[UnsplashWallpapers.currentProvider].name  
                    tooltipText: Translation.tr("Current API endpoint: %1\nSet it with %2mode PROVIDER")  
                        .arg(UnsplashWallpapers.providers[UnsplashWallpapers.currentProvider].url)  
                        .arg(root.commandPrefix)  
                }
  
                Item { Layout.fillWidth: true }  
  
                ButtonGroup {  
                    padding: 0  
                    Repeater {  
                        id: commandRepeater  
                        model: commandButtonsRow.commandsShown  
                        delegate: ApiCommandButton {  
                            property string commandRepresentation: `${root.commandPrefix}${modelData.name}`  
                            buttonText: commandRepresentation  
                            colBackground: Appearance.colors.colLayer2  
  
                            downAction: () => {  
                                if (modelData.sendDirectly) {  
                                    root.handleInput(commandRepresentation)  
                                } else {  
                                    tagInputField.text = commandRepresentation + " "  
                                    tagInputField.cursorPosition = tagInputField.text.length  
                                    tagInputField.forceActiveFocus()  
                                }  
                                if (modelData.name === "clear") {  
                                    tagInputField.text = ""  
                                }  
                            }  
                        }  
                    }  
                }  
            }  
        }  
    }  
}




