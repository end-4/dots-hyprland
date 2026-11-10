import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io

MouseArea {
    id: root
    property int columns: 4
    property real previewCellAspectRatio: 4 / 3
    property bool useDarkMode: Appearance.m3colors.darkmode

    function updateThumbnails() {
        const totalImageMargin = (Appearance.sizes.wallpaperSelectorItemMargins + Appearance.sizes.wallpaperSelectorItemPadding) * 2;
        const thumbnailSizeName = Images.thumbnailSizeNameForDimensions(grid.cellWidth - totalImageMargin, grid.cellHeight - totalImageMargin);
        Wallpapers.generateThumbnail(thumbnailSizeName);
    }

    Connections {
        target: Wallpapers
        function onDirectoryChanged() {
            root.updateThumbnails();
        }
    }

    function handleFilePasting(event) {
        const currentClipboardEntry = Cliphist.entries[0];
        if (/^\d+\tfile:\/\/\S+/.test(currentClipboardEntry)) {
            const url = StringUtils.cleanCliphistEntry(currentClipboardEntry);
            Wallpapers.setDirectory(FileUtils.trimFileProtocol(decodeURIComponent(url)));
            event.accepted = true;
        } else {
            event.accepted = false; // No image, let text pasting proceed
        }
    }

    function selectWallpaperPath(filePath) {
        if (!filePath || filePath.length === 0) return;
        if (GlobalStates.dualWallpaperSelectorMode) {
            if (GlobalStates.dualWallpaperActiveTarget === "dark") {
                Wallpapers.setDarkWallpaper(filePath);
                if (!Config.options.background.lightWallpaperPath) {
                    GlobalStates.dualWallpaperActiveTarget = "light";
                }
            } else {
                Wallpapers.setLightWallpaper(filePath);
                if (!Config.options.background.darkWallpaperPath) {
                    GlobalStates.dualWallpaperActiveTarget = "dark";
                }
            }
        } else {
            Wallpapers.select(filePath, root.useDarkMode);
            filterField.text = "";
        }
    }

    acceptedButtons: Qt.BackButton | Qt.ForwardButton
    onPressed: event => {
        if (event.button === Qt.BackButton) {
            Wallpapers.navigateBack();
        } else if (event.button === Qt.ForwardButton) {
            Wallpapers.navigateForward();
        }
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            GlobalStates.wallpaperSelectorOpen = false;
            event.accepted = true;
        } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_V) { // Intercept Ctrl+V to handle "paste to go to" in pickers
            root.handleFilePasting(event);
        } else if (event.modifiers & Qt.AltModifier && event.key === Qt.Key_Up) {
            Wallpapers.navigateUp();
            event.accepted = true;
        } else if (event.modifiers & Qt.AltModifier && event.key === Qt.Key_Left) {
            Wallpapers.navigateBack();
            event.accepted = true;
        } else if (event.modifiers & Qt.AltModifier && event.key === Qt.Key_Right) {
            Wallpapers.navigateForward();
            event.accepted = true;
        } else if (event.key === Qt.Key_Left) {
            grid.moveSelection(-1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Right) {
            grid.moveSelection(1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Up) {
            grid.moveSelection(-grid.columns);
            event.accepted = true;
        } else if (event.key === Qt.Key_Down) {
            grid.moveSelection(grid.columns);
            event.accepted = true;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            grid.activateCurrent();
            event.accepted = true;
        } else if (event.key === Qt.Key_Backspace) {
            if (filterField.text.length > 0) {
                filterField.text = filterField.text.substring(0, filterField.text.length - 1);
            }
            filterField.forceActiveFocus();
            event.accepted = true;
        } else if (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_L) {
            addressBar.focusBreadcrumb();
            event.accepted = true;
        } else if (event.key === Qt.Key_Slash) {
            filterField.forceActiveFocus();
            event.accepted = true;
        } else {
            if (event.text.length > 0) {
                filterField.text += event.text;
                filterField.cursorPosition = filterField.text.length;
                filterField.forceActiveFocus();
            }
            event.accepted = true;
        }
    }

    implicitHeight: mainLayout.implicitHeight
    implicitWidth: mainLayout.implicitWidth

    StyledRectangularShadow {
        target: wallpaperGridBackground
    }
    Rectangle {
        id: wallpaperGridBackground
        anchors {
            fill: parent
            margins: Appearance.sizes.elevationMargin
        }
        focus: true
        border.width: 1
        border.color: Appearance.colors.colLayer0Border
        color: Appearance.colors.colLayer0
        radius: Appearance.rounding.screenRounding - Appearance.sizes.hyprlandGapsOut + 1

        property int calculatedRows: Math.ceil(grid.count / grid.columns)

        implicitWidth: gridColumnLayout.implicitWidth
        implicitHeight: gridColumnLayout.implicitHeight

        RowLayout {
            id: mainLayout
            anchors.fill: parent
            spacing: -4

            Rectangle {
                Layout.fillHeight: true
                Layout.margins: 4
                implicitWidth: quickDirColumnLayout.implicitWidth
                implicitHeight: quickDirColumnLayout.implicitHeight
                color: Appearance.colors.colLayer1
                radius: wallpaperGridBackground.radius - Layout.margins

                ColumnLayout {
                    id: quickDirColumnLayout
                    anchors.fill: parent
                    spacing: 0

                    StyledText {
                        Layout.margins: 12
                        font {
                            pixelSize: Appearance.font.pixelSize.normal
                            weight: Font.Medium
                        }
                        text: Translation.tr("Pick a wallpaper")
                    }
                    ListView {
                        // Quick dirs
                        Layout.fillHeight: true
                        Layout.margins: 4
                        implicitWidth: 140
                        clip: true
                        model: [
                            {
                                icon: "home",
                                name: "Home",
                                path: Directories.home
                            },
                            {
                                icon: "docs",
                                name: "Documents",
                                path: Directories.documents
                            },
                            {
                                icon: "download",
                                name: "Downloads",
                                path: Directories.downloads
                            },
                            {
                                icon: "image",
                                name: "Pictures",
                                path: Directories.pictures
                            },
                            {
                                icon: "movie",
                                name: "Videos",
                                path: Directories.videos
                            },
                            {
                                icon: "",
                                name: "---",
                                path: "INTENTIONALLY_INVALID_DIR"
                            },
                            {
                                icon: "wallpaper",
                                name: "Wallpapers",
                                path: `${Directories.pictures}/Wallpapers`
                            },
                            ...(Config.options.policies.weeb === 1 ? [
                                    {
                                        icon: "favorite",
                                        name: "Homework",
                                        path: `${Directories.pictures}/homework`
                                    }
                                ] : []),]
                        delegate: RippleButton {
                            id: quickDirButton
                            required property var modelData
                            anchors {
                                left: parent.left
                                right: parent.right
                            }
                            onClicked: Wallpapers.setDirectory(quickDirButton.modelData.path)
                            enabled: modelData.icon.length > 0
                            toggled: Wallpapers.directory === Qt.resolvedUrl(modelData.path)
                            colBackgroundToggled: Appearance.colors.colSecondaryContainer
                            colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
                            colRippleToggled: Appearance.colors.colSecondaryContainerActive
                            buttonRadius: height / 2
                            implicitHeight: 38

                            contentItem: RowLayout {
                                MaterialSymbol {
                                    color: quickDirButton.toggled ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer1
                                    iconSize: Appearance.font.pixelSize.larger
                                    text: quickDirButton.modelData.icon
                                    fill: quickDirButton.toggled ? 1 : 0
                                }
                                StyledText {
                                    Layout.fillWidth: true
                                    horizontalAlignment: Text.AlignLeft
                                    color: quickDirButton.toggled ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer1
                                    text: quickDirButton.modelData.name
                                }
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                id: gridColumnLayout
                Layout.fillWidth: true
                Layout.fillHeight: true

                AddressBar {
                    id: addressBar
                    Layout.margins: 4
                    Layout.fillWidth: true
                    Layout.fillHeight: false
                    directory: Wallpapers.effectiveDirectory
                    onNavigateToDirectory: path => {
                        Wallpapers.setDirectory(path.length == 0 ? "/" : path);
                    }
                    radius: wallpaperGridBackground.radius - Layout.margins
                }

                Rectangle {
                    id: dualWallpaperHeader
                    visible: GlobalStates.dualWallpaperSelectorMode
                    Layout.fillWidth: true
                    Layout.leftMargin: 4
                    Layout.rightMargin: 4
                    Layout.bottomMargin: 2
                    implicitHeight: 82
                    radius: Appearance.rounding.small
                    color: Appearance.colors.colLayer1
                    border.width: 1
                    border.color: Appearance.colors.colOutlineVariant

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 6
                        spacing: 8

                        // Dark Wallpaper Card
                        Rectangle {
                            id: darkSlotCard
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: Appearance.rounding.small
                            color: GlobalStates.dualWallpaperActiveTarget === "dark" ? Appearance.colors.colSecondaryContainer : Appearance.colors.colLayer2
                            border.width: GlobalStates.dualWallpaperActiveTarget === "dark" ? 2 : 1
                            border.color: GlobalStates.dualWallpaperActiveTarget === "dark" ? Appearance.colors.colSecondary : Appearance.colors.colOutlineVariant

                            Behavior on color {
                                ColorAnimation { duration: 150 }
                            }
                            Behavior on border.color {
                                ColorAnimation { duration: 150 }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    GlobalStates.dualWallpaperActiveTarget = "dark";
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 6
                                    spacing: 8

                                    Rectangle {
                                        Layout.preferredWidth: 64
                                        Layout.fillHeight: true
                                        radius: Appearance.rounding.small
                                        color: Appearance.colors.colLayer0
                                        clip: true

                                        Image {
                                            anchors.fill: parent
                                            fillMode: Image.PreserveAspectCrop
                                            source: Config.options.background.darkWallpaperPath ? Qt.resolvedUrl(Config.options.background.darkWallpaperPath) : ""
                                            visible: status === Image.Ready
                                        }

                                        MaterialSymbol {
                                            anchors.centerIn: parent
                                            visible: !Config.options.background.darkWallpaperPath || parent.children[0].status !== Image.Ready
                                            text: "dark_mode"
                                            iconSize: 22
                                            color: Appearance.colors.colOnSecondaryContainer
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        RowLayout {
                                            spacing: 4
                                            MaterialSymbol {
                                                text: "dark_mode"
                                                iconSize: 15
                                                color: GlobalStates.dualWallpaperActiveTarget === "dark" ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer2
                                            }
                                            StyledText {
                                                text: Translation.tr("Dark Mode Wallpaper")
                                                font.weight: Font.Bold
                                                font.pixelSize: Appearance.font.pixelSize.small
                                                color: GlobalStates.dualWallpaperActiveTarget === "dark" ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer2
                                            }
                                            Item { Layout.fillWidth: true }
                                            Rectangle {
                                                visible: GlobalStates.dualWallpaperActiveTarget === "dark"
                                                radius: 6
                                                color: Appearance.colors.colPrimary
                                                implicitWidth: darkActiveText.implicitWidth + 8
                                                implicitHeight: 16
                                                StyledText {
                                                    id: darkActiveText
                                                    anchors.centerIn: parent
                                                    text: Translation.tr("SELECTING")
                                                    font.pixelSize: Appearance.font.pixelSize.smallest
                                                    font.weight: Font.Bold
                                                    color: Appearance.colors.colOnPrimary
                                                }
                                            }
                                        }

                                        StyledText {
                                            Layout.fillWidth: true
                                            elide: Text.ElideMiddle
                                            font.pixelSize: Appearance.font.pixelSize.smaller
                                            opacity: 0.85
                                            color: GlobalStates.dualWallpaperActiveTarget === "dark" ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer2
                                            text: Config.options.background.darkWallpaperPath ? FileUtils.fileNameForPath(Config.options.background.darkWallpaperPath) : Translation.tr("Click below to select")
                                        }
                                    }
                                }
                            }
                        }

                        // Light Wallpaper Card
                        Rectangle {
                            id: lightSlotCard
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: Appearance.rounding.small
                            color: GlobalStates.dualWallpaperActiveTarget === "light" ? Appearance.colors.colTertiaryContainer : Appearance.colors.colLayer2
                            border.width: GlobalStates.dualWallpaperActiveTarget === "light" ? 2 : 1
                            border.color: GlobalStates.dualWallpaperActiveTarget === "light" ? Appearance.colors.colTertiary : Appearance.colors.colOutlineVariant

                            Behavior on color {
                                ColorAnimation { duration: 150 }
                            }
                            Behavior on border.color {
                                ColorAnimation { duration: 150 }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    GlobalStates.dualWallpaperActiveTarget = "light";
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 6
                                    spacing: 8

                                    Rectangle {
                                        Layout.preferredWidth: 64
                                        Layout.fillHeight: true
                                        radius: Appearance.rounding.small
                                        color: Appearance.colors.colLayer0
                                        clip: true

                                        Image {
                                            anchors.fill: parent
                                            fillMode: Image.PreserveAspectCrop
                                            source: Config.options.background.lightWallpaperPath ? Qt.resolvedUrl(Config.options.background.lightWallpaperPath) : ""
                                            visible: status === Image.Ready
                                        }

                                        MaterialSymbol {
                                            anchors.centerIn: parent
                                            visible: !Config.options.background.lightWallpaperPath || parent.children[0].status !== Image.Ready
                                            text: "light_mode"
                                            iconSize: 22
                                            color: Appearance.colors.colOnTertiaryContainer
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        RowLayout {
                                            spacing: 4
                                            MaterialSymbol {
                                                text: "light_mode"
                                                iconSize: 15
                                                color: GlobalStates.dualWallpaperActiveTarget === "light" ? Appearance.colors.colOnTertiaryContainer : Appearance.colors.colOnLayer2
                                            }
                                            StyledText {
                                                text: Translation.tr("Light Mode Wallpaper")
                                                font.weight: Font.Bold
                                                font.pixelSize: Appearance.font.pixelSize.small
                                                color: GlobalStates.dualWallpaperActiveTarget === "light" ? Appearance.colors.colOnTertiaryContainer : Appearance.colors.colOnLayer2
                                            }
                                            Item { Layout.fillWidth: true }
                                            Rectangle {
                                                visible: GlobalStates.dualWallpaperActiveTarget === "light"
                                                radius: 6
                                                color: Appearance.colors.colTertiary
                                                implicitWidth: lightActiveText.implicitWidth + 8
                                                implicitHeight: 16
                                                StyledText {
                                                    id: lightActiveText
                                                    anchors.centerIn: parent
                                                    text: Translation.tr("SELECTING")
                                                    font.pixelSize: Appearance.font.pixelSize.smallest
                                                    font.weight: Font.Bold
                                                    color: Appearance.colors.colOnTertiary
                                                }
                                            }
                                        }

                                        StyledText {
                                            Layout.fillWidth: true
                                            elide: Text.ElideMiddle
                                            font.pixelSize: Appearance.font.pixelSize.smaller
                                            opacity: 0.85
                                            color: GlobalStates.dualWallpaperActiveTarget === "light" ? Appearance.colors.colOnTertiaryContainer : Appearance.colors.colOnLayer2
                                            text: Config.options.background.lightWallpaperPath ? FileUtils.fileNameForPath(Config.options.background.lightWallpaperPath) : Translation.tr("Click below to select")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Item {
                    id: gridDisplayRegion
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    StyledIndeterminateProgressBar {
                        id: indeterminateProgressBar
                        visible: Wallpapers.thumbnailGenerationRunning && value == 0
                        anchors {
                            bottom: parent.top
                            left: parent.left
                            right: parent.right
                            leftMargin: 4
                            rightMargin: 4
                        }
                    }

                    StyledProgressBar {
                        visible: Wallpapers.thumbnailGenerationRunning && value > 0
                        value: Wallpapers.thumbnailGenerationProgress
                        anchors.fill: indeterminateProgressBar
                    }

                    GridView {
                        id: grid
                        visible: Wallpapers.folderModel.count > 0

                        readonly property int columns: root.columns
                        readonly property int rows: Math.max(1, Math.ceil(count / columns))
                        property int currentIndex: 0

                        anchors.fill: parent
                        cellWidth: width / root.columns
                        cellHeight: cellWidth / root.previewCellAspectRatio
                        interactive: true
                        clip: true
                        keyNavigationWraps: true
                        boundsBehavior: Flickable.StopAtBounds
                        bottomMargin: extraOptions.implicitHeight
                        ScrollBar.vertical: StyledScrollBar {}

                        Component.onCompleted: {
                            root.updateThumbnails();
                        }

                        function moveSelection(delta) {
                            currentIndex = Math.max(0, Math.min(grid.model.count - 1, currentIndex + delta));
                            positionViewAtIndex(currentIndex, GridView.Contain);
                        }

                        function activateCurrent() {
                            const isDir = grid.model.get(currentIndex, "fileIsDir");
                            const filePath = grid.model.get(currentIndex, "filePath");
                            if (isDir) {
                                Wallpapers.setDirectory(filePath);
                            } else {
                                root.selectWallpaperPath(filePath);
                            }
                        }

                        model: Wallpapers.folderModel
                        onModelChanged: currentIndex = 0
                        delegate: WallpaperDirectoryItem {
                            required property var modelData
                            required property int index
                            fileModelData: modelData
                            width: grid.cellWidth
                            height: grid.cellHeight
                            colBackground: (index === grid?.currentIndex || containsMouse) ? Appearance.colors.colPrimary :
                                (!fileModelData.fileIsDir && GlobalStates.dualWallpaperSelectorMode && fileModelData.filePath === Config.options.background.darkWallpaperPath) ? Appearance.colors.colSecondaryContainer :
                                (!fileModelData.fileIsDir && GlobalStates.dualWallpaperSelectorMode && fileModelData.filePath === Config.options.background.lightWallpaperPath) ? Appearance.colors.colTertiaryContainer :
                                (!fileModelData.fileIsDir && fileModelData.filePath === Config.options.background.wallpaperPath) ? Appearance.colors.colSecondaryContainer :
                                ColorUtils.transparentize(Appearance.colors.colPrimaryContainer)
                            colText: (index === grid.currentIndex || containsMouse) ? Appearance.colors.colOnPrimary :
                                (!fileModelData.fileIsDir && GlobalStates.dualWallpaperSelectorMode && fileModelData.filePath === Config.options.background.darkWallpaperPath) ? Appearance.colors.colOnSecondaryContainer :
                                (!fileModelData.fileIsDir && GlobalStates.dualWallpaperSelectorMode && fileModelData.filePath === Config.options.background.lightWallpaperPath) ? Appearance.colors.colOnTertiaryContainer :
                                (!fileModelData.fileIsDir && fileModelData.filePath === Config.options.background.wallpaperPath) ? Appearance.colors.colOnSecondaryContainer :
                                Appearance.colors.colOnLayer0

                            onEntered: {
                                grid.currentIndex = index;
                            }

                            onActivated: {
                                if (fileModelData.fileIsDir) {
                                    Wallpapers.setDirectory(fileModelData.filePath);
                                } else {
                                    root.selectWallpaperPath(fileModelData.filePath);
                                }
                            }

                            onRightClicked: {
                                if (!fileModelData.fileIsDir) {
                                    contextMenu.targetPath = fileModelData.filePath;
                                    contextMenu.targetName = fileModelData.fileName;
                                    contextMenu.openAtItem(this);
                                }
                            }
                        }

                        layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: Rectangle {
                                width: gridDisplayRegion.width
                                height: gridDisplayRegion.height
                                radius: wallpaperGridBackground.radius
                            }
                        }
                    }

                    Row {
                        id: extraOptions
                        anchors {
                            bottom: parent.bottom
                            horizontalCenter: parent.horizontalCenter
                            bottomMargin: 8
                        }
                        spacing: 6
                        Toolbar {

                            IconToolbarButton {
                                implicitWidth: height
                                onClicked: {
                                    Wallpapers.openFallbackPicker(root.useDarkMode);
                                    GlobalStates.wallpaperSelectorOpen = false;
                                }
                                altAction: () => {
                                    Wallpapers.openFallbackPicker(root.useDarkMode);
                                    GlobalStates.wallpaperSelectorOpen = false;
                                    Config.options.wallpaperSelector.useSystemFileDialog = true;
                                }
                                text: "open_in_new"
                                StyledToolTip {
                                    text: Translation.tr("Use the system file picker instead\nRight-click to make this the default behavior")
                                }
                            }

                            IconToolbarButton {
                                implicitWidth: height
                                onClicked: {
                                    Wallpapers.randomFromCurrentFolder();
                                }
                                text: "ifl"
                                StyledToolTip {
                                    text: Translation.tr("Pick random from this folder")
                                }
                            }

                            IconToolbarButton {
                                implicitWidth: height
                                onClicked: root.useDarkMode = !root.useDarkMode
                                text: root.useDarkMode ? "dark_mode" : "light_mode"
                                StyledToolTip {
                                    text: Translation.tr("Click to toggle light/dark mode\n(applied when wallpaper is chosen)")
                                }
                            }

                            IconToolbarButton {
                                implicitWidth: height
                                onClicked: {
                                    GlobalStates.dualWallpaperSelectorMode = !GlobalStates.dualWallpaperSelectorMode;
                                    if (GlobalStates.dualWallpaperSelectorMode && !GlobalStates.dualWallpaperActiveTarget) {
                                        GlobalStates.dualWallpaperActiveTarget = Appearance.m3colors.darkmode ? "dark" : "light";
                                    }
                                }
                                text: GlobalStates.dualWallpaperSelectorMode ? "view_agenda" : "split_scene"
                                toggled: GlobalStates.dualWallpaperSelectorMode
                                colBackgroundToggled: Appearance.colors.colSecondaryContainer
                                StyledToolTip {
                                    text: GlobalStates.dualWallpaperSelectorMode ?
                                        Translation.tr("Dual Wallpaper Mode: Active\n(Click to switch to single wallpaper mode)") :
                                        Translation.tr("Switch to Dual Wallpaper Mode\n(Choose both Dark & Light wallpapers)")
                                }
                            }

                            ToolbarTextField {
                                id: filterField
                                placeholderText: focus ? Translation.tr("Search wallpapers") : Translation.tr("Hit \"/\" to search")

                                // Style
                                clip: true
                                font.pixelSize: Appearance.font.pixelSize.small

                                // Search
                                onTextChanged: {
                                    Wallpapers.searchQuery = text;
                                }

                                Keys.onPressed: event => {
                                    if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_V) { // Intercept Ctrl+V to handle "paste to go to" in pickers
                                        root.handleFilePasting(event);
                                        return;
                                    } else if (text.length !== 0) {
                                        // No filtering, just navigate grid
                                        if (event.key === Qt.Key_Down) {
                                            grid.moveSelection(grid.columns);
                                            event.accepted = true;
                                            return;
                                        }
                                        if (event.key === Qt.Key_Up) {
                                            grid.moveSelection(-grid.columns);
                                            event.accepted = true;
                                            return;
                                        }
                                    }
                                    event.accepted = false;
                                }
                            }
                        }

                        ToolbarPairedFab {
                            visible: GlobalStates.dualWallpaperSelectorMode
                            iconText: "check"
                            onClicked: GlobalStates.wallpaperSelectorOpen = false;
                            StyledToolTip {
                                text: Translation.tr("Done / Apply dual wallpaper selection")
                            }
                        }

                        ToolbarPairedFab {
                            iconText: "close"
                            onClicked: GlobalStates.wallpaperSelectorOpen = false;
                            StyledToolTip {
                                text: Translation.tr("Cancel wallpaper selection")
                            }
                        }
                    }
                }
            }
        }
    }

    Connections {
        target: GlobalStates
        function onWallpaperSelectorOpenChanged() {
            if (GlobalStates.wallpaperSelectorOpen && monitorIsFocused) {
                filterField.forceActiveFocus();
            }
        }
    }

    Connections {
        target: Wallpapers
        function onChanged() {
            if (!GlobalStates.dualWallpaperSelectorMode) {
                GlobalStates.wallpaperSelectorOpen = false;
            }
        }
    }

    Popup {
        id: contextMenu
        property string targetPath: ""
        property string targetName: ""

        function openAtItem(item) {
            const mapped = item.mapToItem(wallpaperGridBackground, 0, 0);
            x = Math.max(10, Math.min(mapped.x + 20, wallpaperGridBackground.width - width - 20));
            y = Math.max(10, Math.min(mapped.y + 40, wallpaperGridBackground.height - height - 20));
            open();
        }

        padding: 6
        background: Rectangle {
            color: Appearance.colors.colLayer1
            radius: Appearance.rounding.small
            border.width: 1
            border.color: Appearance.colors.colOutlineVariant
            StyledRectangularShadow { target: parent }
        }

        contentItem: ColumnLayout {
            spacing: 3

            StyledText {
                Layout.margins: 6
                Layout.maximumWidth: 220
                text: contextMenu.targetName
                elide: Text.ElideMiddle
                font.weight: Font.Bold
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colOnLayer1
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Appearance.colors.colOutlineVariant
            }

            RippleButton {
                Layout.fillWidth: true
                implicitHeight: 34
                buttonRadius: Appearance.rounding.small
                onClicked: {
                    Wallpapers.setDarkWallpaper(contextMenu.targetPath);
                    contextMenu.close();
                }
                contentItem: RowLayout {
                    spacing: 8
                    MaterialSymbol {
                        text: "dark_mode"
                        iconSize: 16
                        color: Appearance.colors.colSecondary
                    }
                    StyledText {
                        text: Translation.tr("Set as Dark Wallpaper")
                        font.pixelSize: Appearance.font.pixelSize.smaller
                    }
                }
            }

            RippleButton {
                Layout.fillWidth: true
                implicitHeight: 34
                buttonRadius: Appearance.rounding.small
                onClicked: {
                    Wallpapers.setLightWallpaper(contextMenu.targetPath);
                    contextMenu.close();
                }
                contentItem: RowLayout {
                    spacing: 8
                    MaterialSymbol {
                        text: "light_mode"
                        iconSize: 16
                        color: Appearance.colors.colTertiary
                    }
                    StyledText {
                        text: Translation.tr("Set as Light Wallpaper")
                        font.pixelSize: Appearance.font.pixelSize.smaller
                    }
                }
            }

            RippleButton {
                Layout.fillWidth: true
                implicitHeight: 34
                buttonRadius: Appearance.rounding.small
                onClicked: {
                    Wallpapers.setBothWallpapers(contextMenu.targetPath);
                    contextMenu.close();
                }
                contentItem: RowLayout {
                    spacing: 8
                    MaterialSymbol {
                        text: "style"
                        iconSize: 16
                        color: Appearance.colors.colPrimary
                    }
                    StyledText {
                        text: Translation.tr("Set as Both (Dark & Light)")
                        font.pixelSize: Appearance.font.pixelSize.smaller
                    }
                }
            }
        }
    }
}
