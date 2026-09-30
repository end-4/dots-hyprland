pragma ComponentBehavior: Bound
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item {
    id: root
    property real maxWindowPreviewHeight: 200
    property real maxWindowPreviewWidth: 300
    property real windowControlsHeight: 30
    property real buttonPadding: 5

    property Item lastHoveredButton: null
    property bool buttonHovered: false
    property bool requestDockShow: previewPopup.show || contextMenu.isOpen

    // Drag-to-reorder state
    property bool dragging: false
    property bool _reordering: false
    property bool _suppressTranslateAnim: false
    property int dragSourceIndex: -1
    property real dragCursorX: 0
    property real dragStartCursorX: 0
    property real slotWidth: 0
    property int dragTargetIndex: {
        if (!dragging || slotWidth <= 0) return dragSourceIndex;
        var delta = dragCursorX - dragStartCursorX;
        var slots = Math.round(delta / slotWidth);
        var pinnedCount = Config.options.dock.pinnedApps.length;
        return Math.max(0, Math.min(dragSourceIndex + slots, pinnedCount - 1));
    }

    function finishDrag() {
        _suppressTranslateAnim = true;
        if (dragging && dragSourceIndex !== dragTargetIndex) {
            _reordering = true;
            TaskbarApps.reorderPinned(dragSourceIndex, dragTargetIndex);
        }
        dragging = false;
        dragSourceIndex = -1;
        dragCursorX = 0;
        dragStartCursorX = 0;
        Qt.callLater(function() {
            _reordering = false;
            _suppressTranslateAnim = false;
        });
    }

    function cancelDrag() {
        _suppressTranslateAnim = true;
        dragging = false;
        dragSourceIndex = -1;
        dragCursorX = 0;
        dragStartCursorX = 0;
        Qt.callLater(function() { _suppressTranslateAnim = false; });
    }

    function openContextMenu(button, appToplevelData) {
        contextMenu.open(button, appToplevelData);
    }

    function popupCenterXForButton(button) {
        if (!button || !root.QsWindow)
            return 0;
        return root.QsWindow.mapFromItem(button, button.width / 2, 0).x;
    }

    Layout.fillHeight: true
    Layout.topMargin: Appearance.sizes.hyprlandGapsOut
    implicitWidth: listView.implicitWidth

    StyledListView {
        id: listView
        spacing: 2
        clip: false
        interactive: false
        animateAppearance: !root._reordering
        orientation: ListView.Horizontal
        anchors {
            top: parent.top
            bottom: parent.bottom
        }
        implicitWidth: contentWidth

        Behavior on implicitWidth {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }

        model: ScriptModel {
            objectProp: "appId"
            values: TaskbarApps.apps
        }
        delegate: DockAppButton {
            required property var modelData
            required property int index
            appToplevel: modelData
            appListRoot: root
            delegateIndex: index

            topInset: Appearance.sizes.hyprlandGapsOut + root.buttonPadding
            bottomInset: Appearance.sizes.hyprlandGapsOut + root.buttonPadding
        }
    }

    PopupWindow {
        id: previewPopup
        property var appTopLevel: root.lastHoveredButton?.appToplevel
        property bool allPreviewsReady: false
        property real cachedCenterX: 0

        Connections {
            target: root
            function onLastHoveredButtonChanged() {
                previewPopup.allPreviewsReady = false; // Reset readiness when the hovered button changes
                if (root.lastHoveredButton && root.QsWindow)
                    previewPopup.cachedCenterX = root.popupCenterXForButton(root.lastHoveredButton);
            }
            function onButtonHoveredChanged() {
                if (root.buttonHovered && root.lastHoveredButton && root.QsWindow)
                    previewPopup.cachedCenterX = root.popupCenterXForButton(root.lastHoveredButton);
                updateTimer.restart();
            }
        }

        function updatePreviewReadiness() {
            for(var i = 0; i < previewRowLayout.children.length; i++) {
                const view = previewRowLayout.children[i];
                if (view.hasContent === false) {
                    allPreviewsReady = false;
                    return;
                }
            }
            allPreviewsReady = true;
        }

        property bool shouldShow: {
            if (root.dragging || contextMenu.isOpen) return false;
            const hoverConditions = (popupMouseArea.containsMouse || root.buttonHovered)
            return hoverConditions && allPreviewsReady;
        }
        property bool show: false

        onShouldShowChanged: {
            updateTimer.restart();
        }

        Timer {
            id: updateTimer
            interval: 100
            onTriggered: {
                previewPopup.show = previewPopup.shouldShow;
            }
        }

        anchor {
            window: root.QsWindow.window
            adjustment: PopupAdjustment.None
            gravity: Edges.Top | Edges.Right
            edges: Edges.Top | Edges.Left
        }

        visible: popupBackground.opacity > 0
        color: "transparent"
        implicitWidth: root.QsWindow.window?.width ?? 1
        implicitHeight: popupMouseArea.implicitHeight + root.windowControlsHeight + Appearance.sizes.elevationMargin * 2

        MouseArea {
            id: popupMouseArea
            anchors.bottom: parent.bottom
            implicitWidth: popupBackground.implicitWidth + Appearance.sizes.elevationMargin * 2
            implicitHeight: root.maxWindowPreviewHeight + root.windowControlsHeight + Appearance.sizes.elevationMargin * 2
            hoverEnabled: true
            x: previewPopup.cachedCenterX - width / 2

            StyledRectangularShadow {
                target: popupBackground
                opacity: previewPopup.show ? 1 : 0
                visible: opacity > 0
                Behavior on opacity {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
            }

            Rectangle {
                id: popupBackground
                property real padding: 5
                opacity: previewPopup.show ? 1 : 0
                visible: opacity > 0
                Behavior on opacity {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
                clip: true
                color: Appearance.m3colors.m3surfaceContainer
                radius: Appearance.rounding.normal
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Appearance.sizes.elevationMargin
                anchors.horizontalCenter: parent.horizontalCenter
                implicitHeight: previewRowLayout.implicitHeight + padding * 2
                implicitWidth: previewRowLayout.implicitWidth + padding * 2
                Behavior on implicitWidth {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
                Behavior on implicitHeight {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }

                RowLayout {
                    id: previewRowLayout
                    anchors.centerIn: parent
                    Repeater {
                        model: ScriptModel {
                            values: previewPopup.appTopLevel?.toplevels ?? []
                        }
                        RippleButton {
                            id: windowButton
                            Layout.fillHeight: true
                            required property var modelData
                            padding: 0
                            middleClickAction: () => {
                                windowButton.modelData?.close();
                            }
                            onClicked: {
                                windowButton.modelData?.activate();
                            }
                            contentItem: ColumnLayout {
                                implicitWidth: screencopyView.implicitWidth
                                implicitHeight: screencopyView.implicitHeight

                                ButtonGroup {
                                    contentWidth: parent.width - anchors.margins * 2
                                    WrapperRectangle {
                                        Layout.fillWidth: true
                                        color: ColorUtils.transparentize(Appearance.colors.colSurfaceContainer)
                                        radius: Appearance.rounding.small
                                        margin: 5
                                        StyledText {
                                            Layout.fillWidth: true
                                            font.pixelSize: Appearance.font.pixelSize.small
                                            text: windowButton.modelData?.title
                                            elide: Text.ElideRight
                                            color: Appearance.m3colors.m3onSurface
                                        }
                                    }
                                    GroupButton {
                                        id: closeButton
                                        colBackground: ColorUtils.transparentize(Appearance.colors.colSurfaceContainer)
                                        baseWidth: root.windowControlsHeight
                                        baseHeight: root.windowControlsHeight
                                        buttonRadius: Appearance.rounding.full
                                        contentItem: MaterialSymbol {
                                            anchors.centerIn: parent
                                            horizontalAlignment: Text.AlignHCenter
                                            text: "close"
                                            iconSize: Appearance.font.pixelSize.normal
                                            color: Appearance.m3colors.m3onSurface
                                        }
                                        onClicked: {
                                            windowButton.modelData?.close();
                                        }
                                    }
                                }
                                ScreencopyView {
                                    id: screencopyView
                                    // Gate capture on actual visibility: hover or popup-mouse, AND not in
                                    // a state that's about to tear down the popup (context menu, drag).
                                    // Hyprland 0.54.0 asserts in CScreenshareFrame::copyDmabuf if a frame
                                    // is in flight when the popup is destroyed — that crashed the session
                                    // on right-click before this gate.
                                    captureSource: (root.buttonHovered || popupMouseArea.containsMouse)
                                        && !contextMenu.isOpen
                                        && !root.dragging
                                        ? windowButton.modelData : null
                                    live: true
                                    paintCursor: true
                                    constraintSize: Qt.size(root.maxWindowPreviewWidth, root.maxWindowPreviewHeight)
                                    onHasContentChanged: {
                                        previewPopup.updatePreviewReadiness();
                                    }
                                    layer.enabled: true
                                    layer.effect: OpacityMask {
                                        maskSource: Rectangle {
                                            width: screencopyView.width
                                            height: screencopyView.height
                                            radius: Appearance.rounding.small
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

    DockContextMenu {
        id: contextMenu
    }
}
