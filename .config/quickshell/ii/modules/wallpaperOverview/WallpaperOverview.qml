import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: scope

    PanelWindow {
        id: root
        readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.screen)
        property bool monitorIsFocused: (Hyprland.focusedMonitor?.id == monitor?.id)
        visible: GlobalStates.wallpaperOverviewOpen
        property var filteredWallpapers: Wallpapers.wallpapers

        WlrLayershell.namespace: "quickshell:wallpaper-overview"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
        color: "transparent"

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        ColumnLayout {
            id: layout
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            spacing: 8

            TextField {
                id: filterField
                Layout.preferredWidth: bg.implicitWidth
                Layout.alignment: Qt.AlignHcenter
                implicitHeight: 40
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
                        root.filteredWallpapers = newModel;
                    } else {
                        root.filteredWallpapers = Wallpapers.wallpapers;
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
                            GlobalStates.wallpaperOverviewOpen = false;
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

                property int calculatedRows: Math.ceil(grid.count / grid.columns)

                implicitWidth: {
                    if (root.filteredWallpapers.length === 0) {
                        return 300;
                    } else if (root.filteredWallpapers.length < grid.columns) {
                        return root.filteredWallpapers.length * grid.cellWidth + 16;
                    } else {
                        return Math.min(root.width * 0.7, 900);
                    }
                }

                implicitHeight: {
                    if (root.filteredWallpapers.length === 0) {
                        return 100;
                    } else {
                        return Math.min(root.height * 0.6, Math.min(calculatedRows, 3) * grid.cellHeight + 16);
                    }
                }

                Behavior on implicitWidth {
                    SpringAnimation {
                        spring: 3
                        damping: 0.2
                    }
                }

                Behavior on implicitHeight {
                    SpringAnimation {
                        spring: 3
                        damping: 0.2
                    }
                }

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        GlobalStates.wallpaperOverviewOpen = false;
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
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8

                    GridView {
                        id: grid
                        visible: root.filteredWallpapers.length > 0

                        readonly property int columns: 4
                        property int currentIndex: 0
                        readonly property int rows: Math.max(1, Math.ceil(count / columns))

                        Layout.preferredWidth: columns * cellWidth
                        Layout.alignment: Qt.AlignHcenter
                        Layout.fillHeight: true
                        cellWidth: 220
                        cellHeight: 140
                        clip: true
                        interactive: true
                        keyNavigationWraps: true
                        boundsBehavior: Flickable.StopAtBounds

                        cacheBuffer: cellHeight * 2
                        ScrollBar.horizontal: ScrollBar {
                            policy: ScrollBar.AsNeeded
                            visible: false
                        }
                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AsNeeded
                            visible: false
                        }

                        model: root.filteredWallpapers
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
                            GlobalStates.wallpaperOverviewOpen = false;
                            filterField.text = "";
                            Wallpapers.apply(path);
                        }

                        delegate: Item {
                            width: grid.cellWidth
                            height: grid.cellHeight
                            property bool isHovered: false

                            Behavior on width {
                                NumberAnimation {
                                    duration: animationCurves.expressiveDefaultSpatialDuration
                                    easing.bezierCurve: animationCurves.expressiveDefaultSpatial
                                }
                            }

                            Behavior on height {
                                NumberAnimation {
                                    duration: animationCurves.expressiveDefaultSpatialDuration
                                    easing.bezierCurve: animationCurves.expressiveDefaultSpatial
                                }
                            }

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
                                radius: Appearance.rounding.elementRounding

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: Math.min(parent.width * 0.4, 32)
                                    height: Math.min(parent.height * 0.4, 32)
                                    radius: Appearance.rounding.elementRounding
                                    color: Appearance.colors.colLayer3
                                    visible: thumbnailImage.status !== Image.Ready

                                    opacity: 0.3
                                    SequentialAnimation on opacity {
                                        running: parent.visible
                                        loops: Animation.Infinite
                                        NumberAnimation {
                                            to: 1.0
                                            duration: 800
                                            easing.type: Easing.InOutSine
                                        }
                                        NumberAnimation {
                                            to: 0.3
                                            duration: 800
                                            easing.type: Easing.InOutSine
                                        }
                                    }
                                }

                                Image {
                                    id: thumbnailImage
                                    anchors.fill: parent
                                    source: `file://${modelData}`
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    cache: false
                                    smooth: true

                                    sourceSize.width: Math.min(128, grid.cellWidth - 16)
                                    sourceSize.height: Math.min(96, grid.cellHeight - 16)

                                    mipmap: false

                                    opacity: status === Image.Ready ? 1 : 0
                                    Behavior on opacity {
                                        NumberAnimation {
                                            duration: 200
                                            easing.type: Easing.OutCubic
                                        }
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
                                    GlobalStates.wallpaperOverviewOpen = false;
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
                    // show when no wallpaper found
                    ColumnLayout {
                        id: noWallpapersFoundLayout
                        visible: root.filteredWallpapers.length === 0
                        anchors.centerIn: parent

                        implicitHeight: noWallpapersFoundLabel.implicitHeight
                        implicitWidth: noWallpapersFoundLabel.implicitWidth

                        Label {
                            id: noWallpapersFoundLabel
                            text: "No wallpapers found"
                            font.family: Appearance.font.family.main
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colSubtext
                            Layout.alignment: Qt.AlignHcenter | Qt.AlignVCenter
                        }
                    }
                }
            }
        }

        Connections {
            target: GlobalStates
            function onWallpaperOverviewOpenChanged() {
                if (GlobalStates.wallpaperOverviewOpen && monitorIsFocused) {
                    filterField.forceActiveFocus();
                }
            }
        }
    }

    GlobalShortcut {
        name: "wallpaperOverviewToggle"
        description: "Toggle wallpaper overview"
        onPressed: {
            GlobalStates.wallpaperOverviewOpen = !GlobalStates.wallpaperOverviewOpen;
        }
    }
}
