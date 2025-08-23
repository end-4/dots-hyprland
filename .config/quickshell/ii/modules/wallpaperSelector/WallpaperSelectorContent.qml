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
    property real previewAspectRatio: 16 / 9
    implicitHeight: columnLayout.implicitHeight
    implicitWidth: columnLayout.implicitWidth
    property var filteredWallpapers: Wallpapers.wallpapers
    property string filterQuery: ""

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            GlobalStates.wallpaperSelectorOpen = false;
            event.accepted = true;
        } else if (event.key === Qt.Key_Left) {
            grid.moveSelection(-1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Right) {
            grid.moveSelection(1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Up) {
            if (grid.currentIndex < grid.columns) {
                filterField.forceActiveFocus();
            } else {
                grid.moveSelection(-grid.columns);
            }
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

        Item {
            // Search box
            implicitHeight: filterField.implicitHeight + Appearance.sizes.elevationMargin * 2
            implicitWidth: filterField.implicitWidth + Appearance.sizes.elevationMargin * 2
            Layout.alignment: Qt.AlignHCenter

            StyledRectangularShadow {
                target: filterField
            }

            TextField {
                id: filterField
                anchors {
                    fill: parent
                    margins: Appearance.sizes.elevationMargin
                }
                implicitHeight: 44
                implicitWidth: Appearance.sizes.searchWidth
                padding: 10
                placeholderText: "Search wallpapers..."
                placeholderTextColor: Appearance.colors.colSubtext
                color: Appearance.colors.colPrimary
                background: Rectangle {
                    color: Appearance.colors.colLayer0
                    border.color: Appearance.colors.colLayer0Border
                    border.width: 1
                    radius: Appearance.rounding.small
                }
                font.family: Appearance.font.family.main
                font.pixelSize: Appearance.font.pixelSize.normal

                onTextChanged: {
                    root.filterQuery = text;
                }

                Keys.onPressed: event => {
                    if (text.length === 0) {
                        if (event.key === Qt.Key_Down || event.key === Qt.Key_Left || event.key === Qt.Key_Right) {
                            wallpaperGrid.forceActiveFocus();
                            if (event.key === Qt.Key_Down)
                                grid.moveSelection(grid.columns);
                            else if (event.key === Qt.Key_Left)
                                grid.moveSelection(-1);
                            else if (event.key === Qt.Key_Right)
                                grid.moveSelection(1);
                            event.accepted = true;
                        }
                    } else {
                        if (event.key === Qt.Key_Down) {
                            grid.moveSelection(grid.columns);
                            event.accepted = true;
                            wallpaperGrid.forceActiveFocus();
                        }
                    }
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        grid.activateCurrent();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Escape) {
                        if (filterField.text.length > 0) {
                            filterField.text = "";
                        } else {
                            GlobalStates.wallpaperSelectorOpen = false;
                        }
                        event.accepted = true;
                    }
                }
            }
        }

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
                radius: Appearance.rounding.screenRounding
                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: wallpaperGridBackground.width
                        height: wallpaperGridBackground.height
                        radius: wallpaperGridBackground.radius
                    }
                }

                property int calculatedRows: Math.ceil(grid.count / grid.columns)

                implicitWidth: grid.implicitWidth
                implicitHeight: grid.implicitHeight

                GridView {
                    id: grid
                    visible: root.filteredWallpapers.length > 0

                    property int currentIndex: 0
                    readonly property int columns: root.columns
                    readonly property int rows: Math.max(1, Math.ceil(count / columns))

                    anchors.fill: parent
                    cellWidth: width / root.columns
                    cellHeight: cellWidth / root.previewAspectRatio
                    clip: true
                    interactive: true
                    keyNavigationWraps: true
                    boundsBehavior: Flickable.StopAtBounds

                    cacheBuffer: cellHeight * 2
                    ScrollBar.horizontal: ScrollBar {
                        policy: ScrollBar.AsNeeded
                    }
                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                    }

                    model: ScriptModel {
                        values: {
                            return root.filteredWallpapers.filter(w => (w.toLowerCase().includes(root.filterQuery.toLowerCase())));
                        }
                    }
                    onModelChanged: currentIndex = 0

                    function moveSelection(delta) {
                        for (let i = 0; i < count; i++) {
                            const item = itemAtIndex(i);
                            if (item) {
                                item.isHovered = false;
                            }
                        }
                        currentIndex = Math.max(0, Math.min(count - 1, currentIndex + delta));
                        positionViewAtIndex(currentIndex, GridView.Contain);
                    }
                    function activateCurrent() {
                        const path = model[currentIndex];
                        if (!path)
                            return;
                        GlobalStates.wallpaperSelectorOpen = false;
                        filterField.text = "";
                        Wallpapers.apply(path);
                    }

                    delegate: Item {
                        width: grid.cellWidth
                        height: grid.cellHeight
                        property bool isHovered: false

                        Image {
                            id: thumbnailImage
                            anchors {
                                fill: parent
                                margins: 8
                            }
                            source: {
                                const resolvedUrl = Qt.resolvedUrl(modelData);
                                const md5Hash = Qt.md5(resolvedUrl);
                                const cacheSize = "normal";
                                const thumbnailPath = `${Directories.genericCache}/thumbnails/${cacheSize}/${md5Hash}.png`;
                                return thumbnailPath;
                            }
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: false
                            smooth: true
                            mipmap: false

                            sourceSize.width: Math.min(128, grid.cellWidth - 16)
                            sourceSize.height: Math.min(96, grid.cellHeight - 16)

                            opacity: status === Image.Ready ? 1 : 0
                            Behavior on opacity {
                                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                            }

                            layer.enabled: true
                            layer.effect: OpacityMask {
                                maskSource: Rectangle {
                                    width: thumbnailImage.width
                                    height: thumbnailImage.height
                                    radius: Appearance.rounding.small
                                }
                            }

                            Rectangle {
                                anchors.fill: parent
                                color: "transparent"
                                radius: Appearance.rounding.small
                                border.width: (index === grid.currentIndex || parent.isHovered) ? 2 : 1
                                border.color: (index === grid.currentIndex || parent.isHovered) ? Appearance.colors.colSecondary : Appearance.colors.colOutlineVariant
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
                                Wallpapers.apply(modelData);
                            }
                        }
                    }
                }

                Label {
                    id: noWallpapersFoundLabel
                    visible: root.filteredWallpapers.length === 0
                    anchors.centerIn: parent
                    text: "No wallpapers found"
                    font.family: Appearance.font.family.main
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colSubtext
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
