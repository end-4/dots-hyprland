import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland

Item {
    id: root
    property real maxWindowPreviewHeight: 200
    property real maxWindowPreviewWidth: 300
    property real windowControlsHeight: 30
    property real buttonPadding: 5

    property Item lastHoveredButton
    property bool buttonHovered: false
    property bool requestDockShow: previewPopup.show

    // Drag and drop properties
    property Item draggedItem: null
    property int draggedIndex: -1
    property int targetIndex: -1

    // Throttling timer for smooth reordering
    Timer {
        id: reorderTimer
        interval: 80
        property int targetIndex: -1
        onTriggered: {
            if (draggedItem && targetIndex !== -1 && targetIndex !== draggedIndex) {
                performLiveReorder(draggedIndex, targetIndex)
            }
        }
    }


    // Drag and drop handlers
    function onDragStart(item) {
        draggedItem = item
        draggedIndex = getDockItemModelIndex(item)

        targetIndex = -1
    }

    function onDragMove(item, globalX, globalY) {
        if (draggedItem !== item) return

        // Calculate insertion point based on mouse position
        const newTargetIndex = calculateInsertionPoint(globalX)

        if (newTargetIndex !== targetIndex && Math.abs(newTargetIndex - targetIndex) >= 1) {
            targetIndex = newTargetIndex

            // Perform live reorder with throttling for smoothness
            if (targetIndex !== -1 && targetIndex !== draggedIndex) {
                // Use a timer to throttle rapid changes
                reorderTimer.targetIndex = targetIndex
                reorderTimer.restart()
            }
        }
    }

    function onDragEnd(item, globalX, globalY) {
        if (draggedItem !== item) return

        if (targetIndex !== -1 && targetIndex !== draggedIndex) {
            saveReorderConfiguration()
        }

        // Clean up
        draggedItem = null
        draggedIndex = -1
        targetIndex = -1
    }

    function getDockItemModelIndex(item) {
        // Find the model index by matching the appId
        const values = listView.model.values
        for (let i = 0; i < values.length; i++) {
            if (values[i].appId === item.appToplevel.appId) {
                return i
            }
        }
        return -1
    }

    function calculateInsertionPoint(globalX) {
        // Convert to ListView coordinate space
        const listViewPos = listView.mapFromItem(root, globalX, 0)
        const dragX = listViewPos.x

        const values = listView.model.values
        if (!values || values.length === 0) return 0

        // If drag is before the first item, insert at beginning
        if (dragX < 0) return 0

        // Find insertion point by checking against each item's position
        let insertionIndex = 0

        for (let modelIndex = 0; modelIndex < values.length; modelIndex++) {
            // Skip the dragged item itself
            if (modelIndex === draggedIndex) continue

            // Find the visual item for this model index
            const visualItem = findVisualItemByModelIndex(modelIndex)
            if (!visualItem) continue

            const itemCenter = visualItem.x + visualItem.width / 2

            if (dragX < itemCenter) {
                // Insert before this item
                return modelIndex
            }

            insertionIndex = modelIndex + 1
        }

        // Insert at the end
        return Math.min(insertionIndex, values.length)
    }

    function findVisualItemByModelIndex(modelIndex) {
        const values = listView.model.values
        if (!values || modelIndex >= values.length) return null

        const targetAppId = values[modelIndex].appId

        // Find the visual item with this appId
        for (let i = 0; i < listView.contentItem.children.length; i++) {
            const child = listView.contentItem.children[i]
            if (child && child.appToplevel && child.appToplevel.appId === targetAppId) {
                return child
            }
        }
        return null
    }

    function performLiveReorder(fromIndex, toIndex) {
        const values = listView.model.values
        if (!values || fromIndex < 0 || fromIndex >= values.length) return

        // Clamp toIndex
        toIndex = Math.max(0, Math.min(toIndex, values.length))

        if (fromIndex === toIndex) return

        // Create new array with item moved to new position
        let newValues = [...values]
        const item = newValues.splice(fromIndex, 1)[0]

        // Adjust insertion index
        const actualToIndex = toIndex > fromIndex ? toIndex - 1 : toIndex
        newValues.splice(actualToIndex, 0, item)

        // Update model
        listView.model.values = newValues

        // Update tracking indices
        draggedIndex = actualToIndex
    }

    function saveReorderConfiguration() {
        const values = listView.model.values
        updatePinnedAppsOrder(values)
    }



    function updatePinnedAppsOrder(newValues) {
        // Extract pinned apps in their new order
        const newPinnedApps = []
        for (const item of newValues) {
            if (item.pinned && item.appId !== "SEPARATOR") {
                newPinnedApps.push(item.appId)
            }
        }

        // Update the configuration
        if (newPinnedApps.length > 0) {
            Config.options.dock.pinnedApps = newPinnedApps
        }
    }

    Layout.fillHeight: true
    Layout.topMargin: Appearance.sizes.hyprlandGapsOut // why does this work
    implicitWidth: listView.implicitWidth
    
    StyledListView {
        id: listView
        spacing: 2
        orientation: ListView.Horizontal
        anchors {
            top: parent.top
            bottom: parent.bottom
        }
        implicitWidth: contentWidth

        // Disable interactive behavior during drag
        interactive: draggedItem === null
        flickableDirection: Flickable.AutoFlickDirection
        boundsBehavior: Flickable.StopAtBounds

        Behavior on implicitWidth {
            enabled: draggedItem === null
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }

        model: ScriptModel {
            objectProp: "appId"
            values: {
                var map = new Map();

                // Pinned apps
                const pinnedApps = Config.options?.dock.pinnedApps ?? [];
                for (const appId of pinnedApps) {
                    if (!map.has(appId.toLowerCase())) map.set(appId.toLowerCase(), ({
                        pinned: true,
                        toplevels: []
                    }));
                }

                // Separator
                if (pinnedApps.length > 0) {
                    map.set("SEPARATOR", { pinned: false, toplevels: [] });
                }

                // Ignored apps
                const ignoredRegexStrings = Config.options?.dock.ignoredAppRegexes ?? [];
                const ignoredRegexes = ignoredRegexStrings.map(pattern => new RegExp(pattern, "i"));
                // Open windows
                for (const toplevel of ToplevelManager.toplevels.values) {
                    if (ignoredRegexes.some(re => re.test(toplevel.appId))) continue;
                    if (!map.has(toplevel.appId.toLowerCase())) map.set(toplevel.appId.toLowerCase(), ({
                        pinned: false,
                        toplevels: []
                    }));
                    map.get(toplevel.appId.toLowerCase()).toplevels.push(toplevel);
                }

                var values = [];

                for (const [key, value] of map) {
                    values.push({ appId: key, toplevels: value.toplevels, pinned: value.pinned });
                }

                return values;
            }
        }
        delegate: DockAppButton {
            required property var modelData
            appToplevel: modelData
            appListRoot: root

            topInset: Appearance.sizes.hyprlandGapsOut + root.buttonPadding
            bottomInset: Appearance.sizes.hyprlandGapsOut + root.buttonPadding

            // Ultra-smooth position animation
            Behavior on x {
                enabled: !isDragging
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutExpo
                }
            }
        }

        // Smoother ListView transitions
        add: Transition {
            NumberAnimation {
                properties: "x,opacity"
                duration: 350
                easing.type: Easing.OutExpo
            }
        }

        move: Transition {
            NumberAnimation {
                properties: "x"
                duration: 300
                easing.type: Easing.OutExpo
            }
        }

        displaced: Transition {
            NumberAnimation {
                properties: "x"
                duration: 300
                easing.type: Easing.OutExpo
            }
        }

        // Smooth content width changes
        Behavior on contentWidth {
            enabled: draggedItem === null
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutExpo
            }
        }
    }

    PopupWindow {
        id: previewPopup
        property var appTopLevel: root.lastHoveredButton?.appToplevel
        property bool allPreviewsReady: false
        Connections {
            target: root
            function onLastHoveredButtonChanged() {
                previewPopup.allPreviewsReady = false; // Reset readiness when the hovered button changes
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
            const hoverConditions = (popupMouseArea.containsMouse || root.buttonHovered)
            return hoverConditions && allPreviewsReady;
        }
        property bool show: false

        onShouldShowChanged: {
            if (shouldShow) {
                // show = true;
                updateTimer.restart();
            } else {
                updateTimer.restart();
            }
        }
        Timer {
            id: updateTimer
            interval: 100
            onTriggered: {
                previewPopup.show = previewPopup.shouldShow
            }
        }
        anchor {
            window: root.QsWindow.window
            adjustment: PopupAdjustment.None
            gravity: Edges.Top | Edges.Right
            edges: Edges.Top | Edges.Left

        }
        visible: popupBackground.visible
        color: "transparent"
        implicitWidth: root.QsWindow.window?.width ?? 1
        implicitHeight: popupMouseArea.implicitHeight + root.windowControlsHeight + Appearance.sizes.elevationMargin * 2

        MouseArea {
            id: popupMouseArea
            anchors.bottom: parent.bottom
            implicitWidth: popupBackground.implicitWidth + Appearance.sizes.elevationMargin * 2
            implicitHeight: root.maxWindowPreviewHeight + root.windowControlsHeight + Appearance.sizes.elevationMargin * 2
            hoverEnabled: true
            x: {
                const itemCenter = root.QsWindow?.mapFromItem(root.lastHoveredButton, root.lastHoveredButton?.width / 2, 0);
                return itemCenter.x - width / 2
            }
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
                color: Appearance.colors.colSurfaceContainer
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
                                        baseWidth: windowControlsHeight
                                        baseHeight: windowControlsHeight
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
                                    captureSource: previewPopup ? windowButton.modelData : null
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
}
