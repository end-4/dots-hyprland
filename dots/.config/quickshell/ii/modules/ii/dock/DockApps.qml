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
    property bool requestDockShow: previewPopup.show

    // Drag reorder state
    property bool dragActive: false
    property string draggedAppId: ""
    property int draggedPinnedIndex: -1
    property int targetInsertIndex: -1
    property int pinnedCount: 0

    Layout.fillHeight: true
    Layout.topMargin: Appearance.sizes.hyprlandGapsOut
    implicitWidth: listView.implicitWidth

    function popupCenterXForButton(button) {
        if (!button || !root.QsWindow)
            return 0;
        return root.QsWindow.mapFromItem(button, button.width / 2, 0).x;
    }

    function endDrag() {
        if (root.dragActive && root.targetInsertIndex >= 0) {
            var fromIdx = root.draggedPinnedIndex;
            var toIdx = root.targetInsertIndex;
            if (fromIdx < toIdx) toIdx -= 1;
            if (fromIdx !== toIdx) {
                TaskbarApps.movePinnedApp(fromIdx, toIdx);
            }
        }
        root.dragActive = false;
        root.draggedAppId = "";
        root.draggedPinnedIndex = -1;
        root.targetInsertIndex = -1;
    }

    StyledListView {
        id: listView
        spacing: 2
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
        delegate: Item {
            id: delegateRoot
            required property var modelData

            readonly property bool isPinned: modelData.pinned
            readonly property bool isSeparator: modelData.appId === "SEPARATOR"

            implicitWidth: button.implicitWidth
            implicitHeight: button.implicitHeight

            Drag.active: dragHandler.active
            Drag.source: this
            Drag.hotSpot.x: width / 2
            Drag.hotSpot.y: height / 2
            Drag.supportedActions: Qt.MoveAction

            DockAppButton {
                id: button
                appToplevel: modelData
                appListRoot: root

                topInset: Appearance.sizes.hyprlandGapsOut + root.buttonPadding
                bottomInset: Appearance.sizes.hyprlandGapsOut + root.buttonPadding

                dragActive: root.dragActive && modelData.appId === root.draggedAppId
            }

            // Drop indicator — left side when inserting before an icon,
            // right side only for the last icon when appending past the end.
            Rectangle {
                readonly property int pinnedIdx: isPinned ? TaskbarApps.pinnedAppIndex(modelData.appId) : -1
                readonly property bool showLeft: root.targetInsertIndex >= 0 && pinnedIdx === root.targetInsertIndex && root.targetInsertIndex < root.pinnedCount
                readonly property bool showRight: root.targetInsertIndex >= 0 && pinnedIdx === root.targetInsertIndex - 1 && root.targetInsertIndex === root.pinnedCount

                anchors.verticalCenter: parent.verticalCenter
                width: 3
                height: parent.height * 0.6
                radius: 1.5
                color: Appearance.colors.colPrimary
                opacity: (showLeft || showRight) ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 120 } }

                x: showLeft ? -1 : (showRight ? parent.width - width + 1 : 0)
            }

            DragHandler {
                id: dragHandler
                enabled: isPinned && !isSeparator
                target: null
                margin: 15

                onActiveChanged: {
                    if (dragHandler.active) {
                        root.draggedAppId = modelData.appId
                        root.draggedPinnedIndex = TaskbarApps.pinnedAppIndex(modelData.appId)
                        root.dragActive = true
                    } else if (root.dragActive && root.draggedAppId === modelData.appId) {
                        root.endDrag()
                    }
                }

                onTranslationChanged: {
                    if (dragHandler.active) {
                        var localPt = delegateRoot.mapToItem(listView.contentItem, dragHandler.centroid.position.x, 0)
                        root.targetInsertIndex = -1

                        var pinned = []
                        var children = listView.contentItem.children
                        for (var i = 0; i < children.length; i++) {
                            var child = children[i]
                            if (child.modelData && child.isPinned) {
                                pinned.push(child)
                            }
                        }

                        root.pinnedCount = pinned.length
                        if (pinned.length === 0) return

                        // Before the first item
                        if (localPt.x < pinned[0].x) {
                            root.targetInsertIndex = 0
                            return
                        }

                        // Past the last item → append (indicator on right of last)
                        var last = pinned[pinned.length - 1]
                        if (localPt.x >= last.x + last.width) {
                            root.targetInsertIndex = pinned.length
                            return
                        }

                        // Walk items, split each by its midpoint
                        for (var i = 0; i < pinned.length; i++) {
                            var c = pinned[i]
                            var mid = c.x + c.width / 2
                            if (localPt.x < mid) {
                                root.targetInsertIndex = i
                                return
                            }
                            if (localPt.x < c.x + c.width) {
                                root.targetInsertIndex = i + 1
                                return
                            }
                        }
                    }
                }
            }
        }
    }

    PopupWindow {
        id: previewPopup
        property var appTopLevel: root.lastHoveredButton?.appToplevel

        property bool shouldShow: (popupMouseArea.containsMouse || root.buttonHovered) && appTopLevel && appTopLevel.toplevels && appTopLevel.toplevels.length > 0

        property bool show: false
        property real cachedCenterX: 0

        Connections {
            target: root
            function onLastHoveredButtonChanged() {
                if (root.lastHoveredButton && root.QsWindow)
                    previewPopup.cachedCenterX = root.popupCenterXForButton(root.lastHoveredButton);
            }
            function onButtonHoveredChanged() {
                if (root.buttonHovered && root.lastHoveredButton && root.QsWindow)
                    previewPopup.cachedCenterX = root.popupCenterXForButton(root.lastHoveredButton);
                updateTimer.restart();
            }
        }

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
                                    StyledText {
                                        Layout.margins: 5
                                        Layout.fillWidth: true
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        text: windowButton.modelData?.title
                                        elide: Text.ElideRight
                                        color: Appearance.m3colors.m3onSurface
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
                                Item {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    implicitHeight: screencopyView.height
                                    implicitWidth: screencopyView.width
                                    ScreencopyView {
                                        id: screencopyView
                                        anchors.centerIn: parent
                                        captureSource: windowButton.modelData
                                        live: true
                                        paintCursor: true
                                        constraintSize: Qt.size(root.maxWindowPreviewWidth, root.maxWindowPreviewHeight)
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
    }
}
