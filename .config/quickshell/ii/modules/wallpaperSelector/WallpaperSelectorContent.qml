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
    property int thumbnailWidth: 192
    property int thumbnailHeight: 108
    implicitHeight: columnLayout.implicitHeight
    implicitWidth: columnLayout.implicitWidth
    
    ColumnLayout {
        id: columnLayout
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        spacing: 8

        TextField {
            id: filterField
            Layout.alignment: Qt.AlignHCenter
            implicitHeight: 40
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
                let newModel = [];
                if (text.length > 0) {
                    for (let i = 0; i < Wallpapers.wallpapers.length; ++i) {
                        let wallpaperPath = Wallpapers.wallpapers[i];
                        if (wallpaperPath.toLowerCase().includes(text.toLowerCase())) {
                            newModel.push(wallpaperPath);
                        }
                    }
                    panelWindow.filteredWallpapers = newModel;
                } else {
                    panelWindow.filteredWallpapers = Wallpapers.wallpapers;
                }
            }

            Keys.onPressed: event => {
                if (text.length === 0) {
                    if (event.key === Qt.Key_Down || event.key === Qt.Key_Left || event.key === Qt.Key_Right) {
                        bg.forceActiveFocus();
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
                        bg.forceActiveFocus();
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

        Rectangle {
            id: bg
            focus: true
            color: Appearance.colors.colLayer0
            border.width: 1
            border.color: Appearance.colors.colLayer0Border
            radius: Appearance.rounding.screenRounding
            // Layout.alignment: Qt.AlignHCenter

            property int calculatedRows: Math.ceil(grid.count / grid.columns)

            implicitWidth: {
                if (panelWindow.filteredWallpapers.length === 0) {
                    return 300;
                } else if (panelWindow.filteredWallpapers.length < grid.columns) {
                    return panelWindow.filteredWallpapers.length * grid.cellWidth + 16;
                } else {
                    return Math.min(panelWindow.width * 0.7, 900);
                }
            }

            implicitHeight: {
                if (panelWindow.filteredWallpapers.length === 0) {
                    return 100;
                } else {
                    return Math.min(panelWindow.height * 0.6, Math.min(calculatedRows, 3) * grid.cellHeight + 16);
                }
            }

            Behavior on implicitWidth {
                animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
            }

            Behavior on implicitHeight {
                animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
            }

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

            GridView {
                id: grid
                visible: panelWindow.filteredWallpapers.length > 0

                property int currentIndex: 0
                readonly property int columns: root.columns
                readonly property int rows: Math.max(1, Math.ceil(count / columns))

                anchors.fill: parent
                cellWidth: root.thumbnailWidth
                cellHeight: root.thumbnailHeight
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

                model: panelWindow.filteredWallpapers
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

                    Rectangle {
                        anchors.fill: parent
                        radius: Appearance.rounding.windowRounding
                        color: Appearance.colors.colLayer1
                        border.width: (index === grid.currentIndex || parent.isHovered) ? 3 : 0
                        border.color: Appearance.colors.colSecondary
                    }

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 8
                        color: Appearance.colors.colLayer2
                        radius: Appearance.rounding.small

                        Image {
                            id: thumbnailImage
                            anchors.fill: parent
                            source: {
                                const resolvedUrl = Qt.resolvedUrl(modelData);
                                const md5Hash = Qt.md5(resolvedUrl);
                                const cacheSize = "normal"
                                const thumbnailPath = `${Directories.genericCache}/thumbnails/${cacheSize}/${md5Hash}.png`;
                                return thumbnailPath
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
                                border.width: 1
                                border.color: Appearance.colors.colOutlineVariant
                                radius: Appearance.rounding.small
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
                            Wallpapers.apply(modelData);
                        }
                    }
                }

                add: Transition {
                    from: "*"
                    to: "*"
                    ParallelAnimation {
                        PropertyAnimation {
                            property: "x"
                            from: grid.contentX + (grid.width / 2) - width / 2
                        }
                        PropertyAnimation {
                            property: "y"
                            from: grid.contentY + (grid.height / 2) - height / 2
                        }
                        NumberAnimation {
                            property: "scale"
                            from: 0.0
                            to: 1.0
                            duration: animationCurves.expressiveDefaultSpatialDuration
                            easing.bezierCurve: animationCurves.expressiveDefaultSpatial
                        }
                        NumberAnimation {
                            property: "opacity"
                            from: 0.0
                            to: 1.0
                            duration: animationCurves.expressiveDefaultSpatialDuration
                            easing.bezierCurve: animationCurves.expressiveDefaultSpatial
                        }
                    }
                }
            }

            Label {
                id: noWallpapersFoundLabel
                visible: panelWindow.filteredWallpapers.length === 0
                anchors.centerIn: parent
                text: "No wallpapers found"
                font.family: Appearance.font.family.main
                font.pixelSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colSubtext
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