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
import Quickshell.Wayland
import Quickshell.Hyprland

Item {
    id: root
    property int columns: 4
    property real previewCellAspectRatio: 4 / 3
    implicitHeight: columnLayout.implicitHeight
    implicitWidth: columnLayout.implicitWidth
    property var wallpapers: Wallpapers.wallpapers
    property string filterQuery: ""
    property bool useDarkMode: Appearance.m3colors.darkmode

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
        } else {
            filterField.forceActiveFocus();
            if (event.text.length > 0) {
                filterField.text += event.text;
                filterField.cursorPosition = filterField.text.length;
            }
            event.accepted = true;
        }
    }

    ColumnLayout {
        id: columnLayout
        anchors.fill: parent
        spacing: -Appearance.sizes.elevationMargin

        Item { // The grid
            id: wallpaperGrid
            Layout.fillWidth: true
            Layout.fillHeight: true
            implicitWidth: wallpaperGridBackground.implicitWidth + Appearance.sizes.elevationMargin * 2
            implicitHeight: wallpaperGridBackground.implicitHeight + Appearance.sizes.elevationMargin * 2

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

                // implicitWidth: gridColumnLayout.implicitWidth
                // implicitHeight: gridColumnLayout.implicitHeight

                ColumnLayout {
                    // The grid
                    anchors.fill: parent

                    AddressBar {
                        id: addressBar
                        Layout.margins: 4
                        Layout.fillWidth: true
                        Layout.fillHeight: false
                        directory: Wallpapers.directory
                        onNavigateToDirectory: path => {
                            Wallpapers.setDirectory(path);
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
                            visible: root.wallpapers.length > 0

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

                            ScrollBar.vertical: ScrollBar {
                                policy: ScrollBar.AsNeeded
                            }

                            function moveSelection(delta) {
                                for (let i = 0; i < count; i++) {
                                    const item = itemAtIndex(i);
                                    if (item) {
                                        item.isHovered = false;
                                    }
                                }
                                currentIndex = Math.max(0, Math.min(root.wallpapers.length - 1, currentIndex + delta));
                                positionViewAtIndex(currentIndex, GridView.Contain);
                            }

                            function activateCurrent() {
                                print("ACTIVATE");
                                const path = grid.model.values[currentIndex];
                                if (!path)
                                    return;
                                GlobalStates.wallpaperSelectorOpen = false;
                                filterField.text = "";
                                Wallpapers.apply(path, root.useDarkMode);
                            }

                            model: ScriptModel {
                                values: root.wallpapers.filter(w => (w.toLowerCase().includes(root.filterQuery.toLowerCase())))
                            }
                            onModelChanged: currentIndex = 0

                            delegate: Item {
                                id: wallpaperItem
                                required property var modelData
                                required property int index
                                visible: modelData.length > 0
                                width: grid.cellWidth
                                height: grid.cellHeight
                                property bool isHovered: false

                                Rectangle {
                                    anchors {
                                        fill: parent
                                        margins: 8
                                    }
                                    radius: Appearance.rounding.normal
                                    color: (index === grid.currentIndex || parent.isHovered) ? Appearance.colors.colPrimary : ColorUtils.transparentize(Appearance.colors.colPrimary)
                                    Behavior on color {
                                        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                                    }

                                    ColumnLayout {
                                        id: wallpaperItemColumnLayout
                                        anchors {
                                            fill: parent
                                            margins: 6
                                        }
                                        spacing: 4

                                        Item {
                                            id: wallpaperItemImageContainer
                                            Layout.fillHeight: true
                                            Layout.fillWidth: true

                                            StyledRectangularShadow {
                                                target: thumbnailImageLoader
                                                radius: Appearance.rounding.small
                                            }

                                            Loader {
                                                id: thumbnailImageLoader
                                                anchors.fill: parent
                                                active: wallpaperItem.visible
                                                sourceComponent: Image {
                                                    id: thumbnailImage
                                                    source: {
                                                        if (wallpaperItem.modelData.length == 0)
                                                            return;
                                                        const resolvedUrl = Qt.resolvedUrl(wallpaperItem.modelData);
                                                        const md5Hash = Qt.md5(resolvedUrl);
                                                        const cacheSize = "normal";
                                                        const thumbnailPath = `${Directories.genericCache}/thumbnails/${cacheSize}/${md5Hash}.png`;
                                                        return thumbnailPath;
                                                    }
                                                    asynchronous: true
                                                    cache: false
                                                    smooth: true
                                                    mipmap: false

                                                    fillMode: Image.PreserveAspectCrop
                                                    clip: true
                                                    sourceSize.width: wallpaperItemColumnLayout.width
                                                    sourceSize.height: wallpaperItemColumnLayout.height - wallpaperItemColumnLayout.spacing - wallpaperItemName.height

                                                    opacity: status === Image.Ready ? 1 : 0
                                                    Behavior on opacity {
                                                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                                                    }

                                                    layer.enabled: true
                                                    layer.effect: OpacityMask {
                                                        maskSource: Rectangle {
                                                            width: wallpaperItemImageContainer.width
                                                            height: wallpaperItemImageContainer.height
                                                            radius: Appearance.rounding.small
                                                        }
                                                    }
                                                }
                                            }
                                        }

                                        StyledText {
                                            id: wallpaperItemName
                                            Layout.fillWidth: true
                                            Layout.leftMargin: 10
                                            Layout.rightMargin: 10

                                            horizontalAlignment: Text.AlignHCenter
                                            elide: Text.ElideRight
                                            font.pixelSize: Appearance.font.pixelSize.smaller
                                            color: (index === grid.currentIndex || parent.isHovered) ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer0
                                            Behavior on color {
                                                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                                            }
                                            text: FileUtils.fileNameForPath(wallpaperItem.modelData)
                                        }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onEntered: {
                                        for (let i = 0; i < grid.count; i++) {
                                            const item = grid.itemAtIndex(i);
                                            if (item && item !== parent) {
                                                item.isHovered = false;
                                            }
                                        }
                                        parent.isHovered = true;
                                        grid.currentIndex = index;
                                    }
                                    onExited: {
                                        parent.isHovered = false;
                                    }
                                    onClicked: {
                                        GlobalStates.wallpaperSelectorOpen = false;
                                        filterField.text = "";
                                        Wallpapers.apply(wallpaperItem.modelData, root.useDarkMode);
                                    }
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
                                            Wallpapers.openFallbackPicker();
                                            GlobalStates.wallpaperSelectorOpen = false;
                                        }
                                        contentItem: MaterialSymbol {
                                            text: "files"
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
                                        placeholderText: Translation.tr("Search wallpapers...")
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
                                            root.filterQuery = text;
                                        }

                                        Keys.onPressed: event => {
                                            if (text.length !== 0) {
                                                // No filtering, just navigate grid
                                                if (event.key === Qt.Key_Down) {
                                                    grid.moveSelection(grid.columns);
                                                    wallpaperGrid.forceActiveFocus();
                                                    event.accepted = true;
                                                }
                                                if (event.key === Qt.Key_Up) {
                                                    grid.moveSelection(-grid.columns);
                                                    wallpaperGrid.forceActiveFocus();
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
    }

    Connections {
        target: GlobalStates
        function onWallpaperSelectorOpenChanged() {
            if (GlobalStates.wallpaperSelectorOpen && monitorIsFocused) {
                filterField.forceActiveFocus();
            }
        }
    }
}
