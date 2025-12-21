pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.synchronizer
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.utils
import qs.modules.common.widgets
import qs.modules.waffle.looks

PanelWindow {
    id: root

    enum MediaType {
        Image,
        Video
    }
    enum ImageAction {
        Copy,
        Menu,
        CharRecognition,
        Search
    }
    enum VideoAction {
        Record,
        RecordWithSound
    }
    enum SelectionMode {
        Rect,
        Window
    }

    signal closed
    function close() {
        root.closed();
    }

    property var mediaType: WRegionSelectionPanel.MediaType.Image
    property var imageAction: WRegionSelectionPanel.ImageAction.Copy
    property var selectionMode: WRegionSelectionPanel.SelectionMode.Rect

    visible: false
    color: "transparent"
    WlrLayershell.namespace: "quickshell:regionSelector"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusionMode: ExclusionMode.Ignore
    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    // Hyprland stuff
    readonly property HyprlandMonitor hyprlandMonitor: Hyprland.monitorFor(screen)
    readonly property real monitorScale: hyprlandMonitor.scale
    readonly property var windows: [...HyprlandData.windowList].sort((a, b) => {
        // Sort floating=true windows before others
        if (a.floating === b.floating)
            return 0;
        return a.floating ? -1 : 1;
    })

    property string screenshotDir: Directories.screenshotTemp
    property string screenshotPath: `${root.screenshotDir}/image-${screen.name}`
    TempScreenshotProcess {
        id: screenshotProc
        running: true
        screen: root.screen
        screenshotDir: root.screenshotDir
        screenshotPath: root.screenshotPath
        onExited: (exitCode, exitStatus) => {
            root.preparationDone = true;
        }
    }
    property bool preparationDone: false
    onPreparationDoneChanged: {
        if (!preparationDone)
            return;
        root.visible = true;
    }

    function getScreenshotAction() {
        switch (root.mediaType) {
        case WRegionSelectionPanel.MediaType.Image:
            switch (root.imageAction) {
            case WRegionSelectionPanel.ImageAction.Copy:
                return ScreenshotAction.Action.Copy;
            case WRegionSelectionPanel.ImageAction.Menu:
                return ScreenshotAction.Action.Edit;
            case WRegionSelectionPanel.ImageAction.CharRecognition:
                return ScreenshotAction.Action.CharRecognition;
            case WRegionSelectionPanel.ImageAction.Search:
                return ScreenshotAction.Action.Search;
            default:
                return ScreenshotAction.Action.Copy;
            }
            break;
        case WRegionSelectionPanel.MediaType.Video:
            switch (root.videoAction) {
            case WRegionSelectionPanel.VideoAction.Record:
                return ScreenshotAction.Action.Record;
            case WRegionSelectionPanel.VideoAction.RecordWithSound:
                return ScreenshotAction.Action.RecordWithSound;
            }
        }
    }

    Process {
        id: snipProc
    }

    ScreencopyView {
        id: screencopyView
        anchors.fill: parent
        live: false
        captureSource: root.screen

        focus: root.visible
        Keys.onPressed: event => { // Esc to close
            if (event.key === Qt.Key_Escape) {
                root.close();
            } else if (event.key === Qt.Key_E && event.modifiers & Qt.ControlModifier) {
                if (root.imageAction === WRegionSelectionPanel.ImageAction.Menu) {
                    root.imageAction = WRegionSelectionPanel.ImageAction.Copy;
                } else {
                    root.imageAction = WRegionSelectionPanel.ImageAction.Menu;
                }
            }
        }

        DragManager {
            id: dragArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.CrossCursor

            property bool isWindowSelection: root.selectionMode === WRegionSelectionPanel.SelectionMode.Window
            property var hoveredWindow: root.windows.find(w => {
                const inCurrentWorkspace = w.workspace.id === HyprlandData.activeWorkspace.id;
                const withinXRange = w.at[0] <= dragArea.mouseX && dragArea.mouseX <= w.at[0] + w.size[0];
                const withinYRange = w.at[1] <= dragArea.mouseY && dragArea.mouseY <= w.at[1] + w.size[1];
                return inCurrentWorkspace && withinXRange && withinYRange;
            })
            property int winPadding: 1
            property int selectionX: isWindowSelection ? ((hoveredWindow?.at[0] ?? 0) - winPadding) : regionTopLeftX
            property int selectionY: isWindowSelection ? ((hoveredWindow?.at[1] ?? 0) - winPadding) : regionTopLeftY
            property int selectionWidth: isWindowSelection ? ((hoveredWindow?.size[0] ?? 0) + winPadding * 2) : regionWidth
            property int selectionHeight: isWindowSelection ? ((hoveredWindow?.size[1] ?? 0) + winPadding * 2) : regionHeight

            onDragReleased: (diffX, diffY) => {
                if (selectionWidth === 0 || selectionHeight === 0) {
                    return;
                }
                const screenshotDir = Config.options.screenSnip.savePath !== "" ? Config.options.screenSnip.savePath : "";
                const screenshotAction = root.getScreenshotAction();
                const command = ScreenshotAction.getCommand(dragArea.selectionX * root.monitorScale //
                , dragArea.selectionY * root.monitorScale //
                , dragArea.selectionWidth * root.monitorScale//
                , dragArea.selectionHeight * root.monitorScale //
                , root.screenshotPath //
                , screenshotAction //
                , screenshotDir); // yo wtf is this formatting qmlls do be funnie
                snipProc.command = command;

                // Image post-processing
                snipProc.startDetached();
                root.close();
            }

            WRectangularSelection {
                id: rectangularSelection
                anchors.fill: parent
                regionX: dragArea.selectionX
                regionY: dragArea.selectionY
                regionWidth: dragArea.selectionWidth
                regionHeight: dragArea.selectionHeight
                dashed: root.selectionMode === WRegionSelectionPanel.SelectionMode.Rect
            }

            RegionSelectionOptionsToolbar {
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: parent.top
                    topMargin: 12
                }
            }
        }
    }

    component RegionSelectionOptionsToolbar: WToolbar {
        // Image/video
        WToolbarTabBar {
            currentIndex: switch (root.mediaType) {
            case WRegionSelectionPanel.MediaType.Image:
                return 0;
            case WRegionSelectionPanel.MediaType.Video:
                return 1;
            default:
                return 0;
            }
            WToolbarIconTabButton {
                icon.name: "camera"
                icon.color: Looks.colors.fg
            }
            WToolbarIconTabButton {
                icon.name: "video"
                icon.color: Looks.colors.fg
            }
            onCurrentIndexChanged: {
                switch (currentIndex) {
                case 0:
                    root.mediaType = WRegionSelectionPanel.MediaType.Image;
                    break;
                case 1:
                    root.mediaType = WRegionSelectionPanel.MediaType.Video;
                    break;
                }
            }

            WToolTip {
                text: Translation.tr("Snip")
            }
        }

        // Selection type
        WToolbarButton {
            id: selectionTypeBtn
            implicitWidth: selectionTypeBtnRow.implicitWidth + 11 * 2
            leftPadding: 11
            rightPadding: 11
            onClicked: {
                selectionTypeMenu.visible = !selectionTypeMenu.visible;
            }
            contentItem: Row {
                id: selectionTypeBtnRow
                spacing: 4
                FluentIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    icon: switch (root.selectionMode) {
                    case WRegionSelectionPanel.SelectionMode.Rect:
                        return "crop";
                    case WRegionSelectionPanel.SelectionMode.Window:
                        return "calendar-add";
                    default:
                        return "crop";
                    }
                    implicitSize: 18
                }
                FluentIcon {
                    anchors {
                        top: parent.top
                        topMargin: (parent.height - height) / 2 + (selectionTypeBtn.down ? 2 : 0)
                        Behavior on topMargin {
                            animation: Looks.transition.enter.createObject(this)
                        }
                    }
                    icon: "chevron-down"
                    implicitSize: 12
                }
            }

            WMenu {
                id: selectionTypeMenu
                onClosed: screencopyView.focus = true
                x: -margins
                y: -margins - (selectionTypeBtn.parent.height - selectionTypeBtn.height) - 16
                topMargin: -6
                height: implicitHeight + sourceEdgeMargin

                color: Looks.colors.bg1Base

                Action {
                    icon.name: "crop"
                    text: Translation.tr("Rectangle")
                    checked: root.selectionMode === WRegionSelectionPanel.SelectionMode.Rect
                    onTriggered: {
                        root.selectionMode = WRegionSelectionPanel.SelectionMode.Rect;
                    }
                }
                Action {
                    icon.name: "calendar-add"
                    text: Translation.tr("Window")
                    checked: root.selectionMode === WRegionSelectionPanel.SelectionMode.Window
                    onTriggered: {
                        root.selectionMode = WRegionSelectionPanel.SelectionMode.Window;
                    }
                }
            }

            WToolTip {
                text: Translation.tr("Snipping area")
            }
        }

        // Markup
        WToolbarIconButton {
            icon.name: "image-edit"
            enabled: root.mediaType === WRegionSelectionPanel.MediaType.Image
            checked: root.imageAction === WRegionSelectionPanel.ImageAction.Menu
            onClicked: {
                if (root.imageAction === WRegionSelectionPanel.ImageAction.Menu) {
                    root.imageAction = WRegionSelectionPanel.ImageAction.Copy;
                } else {
                    root.imageAction = WRegionSelectionPanel.ImageAction.Menu;
                }
            }
            WToolTip {
                text: Translation.tr("Quick markup (Ctrl+E)")
            }
        }

        WToolbarSeparator {}

        // Tools
        WToolbarIconButton {
            icon.name: "search-visual"
            checked: root.imageAction === WRegionSelectionPanel.ImageAction.Search
            onClicked: {
                if (root.imageAction === WRegionSelectionPanel.ImageAction.Search && root.mediaType === WRegionSelectionPanel.MediaType.Image) {
                    root.imageAction = WRegionSelectionPanel.ImageAction.Copy;
                } else {
                    root.mediaType = WRegionSelectionPanel.MediaType.Image;
                    root.imageAction = WRegionSelectionPanel.ImageAction.Search;
                }
            }
            WToolTip {
                text: Translation.tr("Image search")
            }
        }
        WToolbarIconButton {
            icon.name: "eyedropper"
            onClicked: {
                Quickshell.execDetached(["bash", "-c", "sleep 0.2; hyprpicker -a"]);
                root.closed();
            }
            WToolTip {
                text: Translation.tr("Color picker")
            }
        }
        WToolbarIconButton {
            icon.name: "scan-text"
            checked: root.imageAction === WRegionSelectionPanel.ImageAction.CharRecognition
            onClicked: {
                if (root.imageAction === WRegionSelectionPanel.ImageAction.CharRecognition && root.mediaType === WRegionSelectionPanel.MediaType.Image) {
                    root.imageAction = WRegionSelectionPanel.ImageAction.Copy;
                } else {
                    root.mediaType = WRegionSelectionPanel.MediaType.Image;
                    root.imageAction = WRegionSelectionPanel.ImageAction.CharRecognition;
                }
            }
            WToolTip {
                text: Translation.tr("Text extractor")
            }
        }

        WToolbarSeparator {}

        WToolbarIconButton {
            icon.name: "dismiss"
            onClicked: root.close()
            WToolTip {
                text: Translation.tr("Close (Esc)")
            }
        }
    }
}
