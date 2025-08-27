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

Item {
    id: root
    property int columns: 4
    property real previewCellAspectRatio: 4 / 3
    property bool useDarkMode: Appearance.m3colors.darkmode

    function updateThumbnails() {
        const totalImageMargin = (Appearance.sizes.wallpaperSelectorItemMargins + Appearance.sizes.wallpaperSelectorItemPadding) * 2
        const thumbnailSizeName = Images.thumbnailSizeNameForDimensions(grid.cellWidth - totalImageMargin, grid.cellHeight - totalImageMargin)
        Wallpapers.generateThumbnail(thumbnailSizeName)
    }

    Connections {
        target: Wallpapers
        function onDirectoryChanged() {
            root.updateThumbnails()
        }
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            GlobalStates.wallpaperSelectorOpen = false;
            event.accepted = true;
        } else if (event.modifiers & Qt.AltModifier && event.key === Qt.Key_Up) {
            Wallpapers.setDirectory(FileUtils.parentDirectory(Wallpapers.directory));
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
                            { icon: "home", name: "Home", path: Directories.home }, 
                            { icon: "docs", name: "Documents", path: Directories.documents }, 
                            { icon: "download", name: "Downloads", path: Directories.downloads }, 
                            { icon: "image", name: "Pictures", path: Directories.pictures }, 
                            { icon: "movie", name: "Videos", path: Directories.videos }, 
                            { icon: "", name: "---", path: "INTENTIONALLY_INVALID_DIR" }, 
                            { icon: "wallpaper", name: "Wallpapers", path: `${Directories.pictures}/Wallpapers` }, 
                            { icon: "favorite", name: "Homework", path: `${Directories.pictures}/homework` },
                        ]
                        delegate: RippleButton {
                            id: quickDirButton
                            required property var modelData
                            anchors {
                                left: parent.left
                                right: parent.right
                            }
                            onClicked: Wallpapers.setDirectory(quickDirButton.modelData.path)
                            enabled: modelData.icon.length > 0
                            toggled: Wallpapers.directory === FileUtils.trimFileProtocol(modelData.path)
                            colBackgroundToggled: Appearance.colors.colSecondaryContainer
                            colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
                            colRippleToggled: Appearance.colors.colSecondaryContainerActive

                            contentItem: RowLayout {
                                MaterialSymbol {
                                    color: quickDirButton.toggled ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer1
                                    iconSize: Appearance.font.pixelSize.larger
                                    text: quickDirButton.modelData.icon
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
                    directory: Wallpapers.directory
                    onNavigateToDirectory: path => {
                        Wallpapers.setDirectory(path.length == 0 ? "/" : path);
                    }
                    radius: wallpaperGridBackground.radius - Layout.margins
                }

                Item {
                    id: gridDisplayRegion
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: gridDisplayRegion.width
                            height: gridDisplayRegion.height
                            radius: wallpaperGridBackground.radius
                        }
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
                            root.updateThumbnails()
                        }

                        function moveSelection(delta) {
                            currentIndex = Math.max(0, Math.min(grid.model.count - 1, currentIndex + delta));
                            positionViewAtIndex(currentIndex, GridView.Contain);
                        }

                        function activateCurrent() {
                            const filePath = grid.model.get(currentIndex, "filePath")
                            Wallpapers.select(filePath, root.useDarkMode);
                            filterField.text = "";
                        }

                        model: Wallpapers.folderModel
                        onModelChanged: currentIndex = 0
                        delegate: WallpaperDirectoryItem {
                            required property var modelData
                            required property int index
                            fileModelData: modelData
                            width: grid.cellWidth
                            height: grid.cellHeight
                            colBackground: (index === grid?.currentIndex || containsMouse) ? Appearance.colors.colPrimary : (fileModelData.filePath === Config.options.background.wallpaperPath) ? Appearance.colors.colSecondaryContainer : ColorUtils.transparentize(Appearance.colors.colPrimaryContainer)
                            colText: (index === grid.currentIndex || containsMouse) ? Appearance.colors.colOnPrimary : (fileModelData.filePath === Config.options.background.wallpaperPath) ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer0

                            onEntered: {
                                grid.currentIndex = index;
                            }
                            
                            onActivated: {
                                Wallpapers.select(fileModelData.filePath, root.useDarkMode);
                                filterField.text = "";
                            }
                        }
                    }

                    Item {
                        id: extraOptions
                        anchors {
                            bottom: parent.bottom
                            horizontalCenter: parent.horizontalCenter
                        }
                        implicitHeight: extraOptionsBackground.implicitHeight + extraOptionsBackground.anchors.margins * 2
                        implicitWidth: extraOptionsBackground.implicitWidth + extraOptionsBackground.anchors.margins * 2

                        StyledRectangularShadow {
                            target: extraOptionsBackground
                        }

                        Rectangle { // Bottom toolbar
                            id: extraOptionsBackground
                            property real padding: 6
                            anchors {
                                fill: parent
                                margins: 8
                            }
                            color: Appearance.colors.colLayer2
                            implicitHeight: extraOptionsRowLayout.implicitHeight + padding * 2
                            implicitWidth: extraOptionsRowLayout.implicitWidth + padding * 2
                            radius: Appearance.rounding.full

                            RowLayout {
                                id: extraOptionsRowLayout
                                anchors {
                                    fill: parent
                                    margins: extraOptionsBackground.padding
                                }

                                RippleButton {
                                    Layout.fillHeight: true
                                    Layout.topMargin: 2
                                    Layout.bottomMargin: 2
                                    implicitWidth: height
                                    buttonRadius: Appearance.rounding.full
                                    onClicked: {
                                        Wallpapers.openFallbackPicker(root.useDarkMode);
                                        GlobalStates.wallpaperSelectorOpen = false;
                                    }
                                    contentItem: MaterialSymbol {
                                        text: "open_in_new"
                                        iconSize: Appearance.font.pixelSize.larger
                                    }
                                    StyledToolTip {
                                        content: Translation.tr("Use the system file picker instead")
                                    }
                                }

                                RippleButton {
                                    Layout.fillHeight: true
                                    Layout.topMargin: 2
                                    Layout.bottomMargin: 2
                                    implicitWidth: height
                                    buttonRadius: Appearance.rounding.full
                                    onClicked: root.useDarkMode = !root.useDarkMode
                                    contentItem: MaterialSymbol {
                                        text: root.useDarkMode ? "dark_mode" : "light_mode"
                                        iconSize: Appearance.font.pixelSize.larger
                                    }
                                    StyledToolTip {
                                        content: Translation.tr("Click to toggle light/dark mode (applied when wallpaper is chosen)")
                                    }
                                }

                                TextField {
                                    id: filterField
                                    Layout.fillHeight: true
                                    Layout.topMargin: 2
                                    Layout.bottomMargin: 2
                                    implicitWidth: 200
                                    padding: 10
                                    placeholderText: focus ? Translation.tr("Search wallpapers") : Translation.tr("Hit \"/\" to search")
                                    placeholderTextColor: Appearance.colors.colSubtext
                                    color: Appearance.colors.colOnLayer0
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    renderType: Text.NativeRendering
                                    selectedTextColor: Appearance.m3colors.m3onSecondaryContainer
                                    selectionColor: Appearance.colors.colSecondaryContainer
                                    background: Rectangle {
                                        color: Appearance.colors.colLayer1
                                        radius: Appearance.rounding.full
                                    }

                                    onTextChanged: {
                                        Wallpapers.searchQuery = text;
                                    }

                                    Keys.onPressed: event => {
                                        if (text.length !== 0) {
                                            // No filtering, just navigate grid
                                            if (event.key === Qt.Key_Down) {
                                                grid.moveSelection(grid.columns);
                                                event.accepted = true;
                                            }
                                            if (event.key === Qt.Key_Up) {
                                                grid.moveSelection(-grid.columns);
                                                event.accepted = true;
                                            }
                                        }
                                        event.accepted = false;
                                    }
                                }

                                RippleButton {
                                    Layout.fillHeight: true
                                    Layout.topMargin: 2
                                    Layout.bottomMargin: 2
                                    buttonRadius: Appearance.rounding.full
                                    onClicked: {
                                        GlobalStates.wallpaperSelectorOpen = false;
                                    }

                                    contentItem: StyledText {
                                        text: "Cancel"
                                    }
                                }
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
            GlobalStates.wallpaperSelectorOpen = false;
        }
    }
}
