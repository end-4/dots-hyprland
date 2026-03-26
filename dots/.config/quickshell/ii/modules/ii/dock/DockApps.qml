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
    property bool requestDockShow: previewPopup.shouldShow || previewPopup.show

    property real hoverMouseX: 0
    property bool dockHovered: false

    Layout.fillHeight: true
    Layout.topMargin: Appearance.sizes.hyprlandGapsOut
    implicitWidth: listView.implicitWidth

    onButtonHoveredChanged: {
        if (!buttonHovered && !previewPopup.popupHovered)
            dockHovered = false
    }

    function popupCenterXForButton(button) {
        if (!button || !root.QsWindow)
            return 0
        return root.QsWindow.mapFromItem(button, button.width / 2, 0).x
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

        delegate: DockAppButton {
            required property var modelData

            appToplevel: modelData
            appListRoot: root

            topInset: Appearance.sizes.hyprlandGapsOut + root.buttonPadding
            bottomInset: Appearance.sizes.hyprlandGapsOut + root.buttonPadding
        }
    }

    PopupWindow {
        id: previewPopup

        property var lockedAppTopLevel: null
        property var appTopLevel: lockedAppTopLevel

        property bool popupHovered: false
        property bool shouldShow: (root.buttonHovered || popupHovered)
            && appTopLevel
            && appTopLevel.toplevels
            && appTopLevel.toplevels.length > 0

        property bool show: false
        property real cachedCenterX: 0

        // Track which button we're waiting to show popup for
        property Item pendingButton: null

        function lockCurrentApp() {
            if (root.lastHoveredButton && root.lastHoveredButton.appToplevel) {
                lockedAppTopLevel = root.lastHoveredButton.appToplevel
            }
        }

        function updateAnchorPosition() {
            if (!root.lastHoveredButton || !root.QsWindow)
                return
            cachedCenterX = root.popupCenterXForButton(root.lastHoveredButton)
        }

        // ── Fresh open timer (when no popup was showing) ──
        Timer {
            id: showTimer
            interval: 450
            repeat: false
            onTriggered: {
                // Only show if mouse is still on the SAME icon that triggered this
                if (root.buttonHovered && root.lastHoveredButton === previewPopup.pendingButton) {
                    previewPopup.lockCurrentApp()
                    if (previewPopup.appTopLevel 
                        && previewPopup.appTopLevel.toplevels 
                        && previewPopup.appTopLevel.toplevels.length > 0) {
                        previewPopup.updateAnchorPosition()
                        previewPopup.show = true
                    }
                }
                previewPopup.pendingButton = null
            }
        }

        // ── Timer to wait for close animation, then start open delay ──
        Timer {
            id: reopenDelayTimer
            interval: 250  // Wait for close animation
            repeat: false
            onTriggered: {
                // After close animation done, start fresh open timer
                if (root.buttonHovered && root.lastHoveredButton) {
                    var hasToplevels = root.lastHoveredButton.appToplevel
                        && root.lastHoveredButton.appToplevel.toplevels
                        && root.lastHoveredButton.appToplevel.toplevels.length > 0
                    
                    if (hasToplevels) {
                        previewPopup.pendingButton = root.lastHoveredButton
                        showTimer.restart()
                    }
                }
            }
        }

        Timer {
            id: hideTimer
            interval: 400
            repeat: false
            onTriggered: {
                if (!root.buttonHovered && !previewPopup.popupHovered) {
                    previewPopup.show = false
                }
            }
        }

        onShowChanged: {
            if (!show) {
                clearLockTimer.restart()
            }
        }

        Timer {
            id: clearLockTimer
            interval: 250
            repeat: false
            onTriggered: {
                if (!previewPopup.show) {
                    previewPopup.lockedAppTopLevel = null
                }
            }
        }

        onPopupHoveredChanged: {
            if (popupHovered) {
                showTimer.stop()
                hideTimer.stop()
                reopenDelayTimer.stop()
            } else {
                if (!root.buttonHovered)
                    hideTimer.restart()
            }
        }

        Connections {
            target: root

            function onLastHoveredButtonChanged() {
                if (!root.lastHoveredButton)
                    return

                var hasToplevels = root.lastHoveredButton.appToplevel
                    && root.lastHoveredButton.appToplevel.toplevels
                    && root.lastHoveredButton.appToplevel.toplevels.length > 0

                if (!hasToplevels) {
                    // No windows - close popup
                    showTimer.stop()
                    reopenDelayTimer.stop()
                    hideTimer.restart()
                    return
                }

                hideTimer.stop()

                if (previewPopup.show) {
                    // ── ICON SWITCH: Close current popup, wait, then reopen ──
                    showTimer.stop()
                    previewPopup.show = false  // Triggers close animation
                    reopenDelayTimer.restart()  // After close, will start showTimer
                } else if (reopenDelayTimer.running) {
                    // Already waiting to reopen - reset the process
                    reopenDelayTimer.restart()
                } else {
                    // Fresh hover - start delay
                    previewPopup.pendingButton = root.lastHoveredButton
                    showTimer.restart()
                }
            }

            function onButtonHoveredChanged() {
                if (root.buttonHovered) {
                    hideTimer.stop()
                    if (!previewPopup.show && !reopenDelayTimer.running) {
                        previewPopup.pendingButton = root.lastHoveredButton
                        showTimer.restart()
                    }
                } else if (!previewPopup.popupHovered) {
                    showTimer.stop()
                    reopenDelayTimer.stop()
                    previewPopup.pendingButton = null
                    hideTimer.restart()
                }
            }
        }

        anchor {
            window: root.QsWindow.window
            adjustment: PopupAdjustment.None
            gravity: Edges.Top | Edges.Right
            edges: Edges.Top | Edges.Left
        }

        visible: popupBackground.animProgress > 0
        color: "transparent"
        implicitWidth: root.QsWindow.window?.width ?? 1
        implicitHeight: popupContentArea.height + gapBridge.height

        // ── Small gap between popup and dock ──
        MouseArea {
            id: gapBridge
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 8  // Reduced from 30 to 8 - popup closer to dock
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            visible: popupBackground.animProgress > 0

            onContainsMouseChanged: {
                if (containsMouse) {
                    previewPopup.popupHovered = true
                    hideTimer.stop()
                } else if (!popupContentArea.containsMouse) {
                    checkHoverLater.restart()
                }
            }
        }

        Timer {
            id: checkHoverLater
            interval: 80
            repeat: false
            onTriggered: {
                var stillHovered = popupContentArea.containsMouse || gapBridge.containsMouse
                if (!stillHovered) {
                    previewPopup.popupHovered = false
                    if (!root.buttonHovered)
                        hideTimer.restart()
                }
            }
        }

        MouseArea {
            id: popupContentArea
            anchors.bottom: gapBridge.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: popupBackground.implicitHeight + Appearance.sizes.elevationMargin * 2
            hoverEnabled: true
            acceptedButtons: Qt.NoButton

            onContainsMouseChanged: {
                if (containsMouse) {
                    previewPopup.popupHovered = true
                    hideTimer.stop()
                    showTimer.stop()
                } else if (!gapBridge.containsMouse) {
                    checkHoverLater.restart()
                }
            }

            StyledRectangularShadow {
                target: popupBackground
                opacity: popupBackground.animProgress
                visible: opacity > 0
            }

            Rectangle {
                id: popupBackground
                property real padding: 6
                property real animProgress: 0.0

                states: [
                    State {
                        name: "visible"
                        when: previewPopup.show
                        PropertyChanges {
                            target: popupBackground
                            animProgress: 1.0
                        }
                    },
                    State {
                        name: "hidden"
                        when: !previewPopup.show
                        PropertyChanges {
                            target: popupBackground
                            animProgress: 0.0
                        }
                    }
                ]

                transitions: [
                    Transition {
                        from: "hidden"
                        to: "visible"
                        NumberAnimation {
                            target: popupBackground
                            property: "animProgress"
                            duration: 280
                            easing.type: Easing.OutCubic
                        }
                    },
                    Transition {
                        from: "visible"
                        to: "hidden"
                        NumberAnimation {
                            target: popupBackground
                            property: "animProgress"
                            duration: 200
                            easing.type: Easing.InCubic
                        }
                    }
                ]

                opacity: animProgress
                visible: animProgress > 0

                x: previewPopup.cachedCenterX - width / 2
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Appearance.sizes.elevationMargin

                transform: Scale {
                    origin.x: popupBackground.width / 2
                    origin.y: popupBackground.height
                    xScale: popupBackground.animProgress
                    yScale: popupBackground.animProgress
                }

                Behavior on x {
                    enabled: previewPopup.show
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                }

                clip: true
                color: Appearance.m3colors.m3surfaceContainer
                radius: Appearance.rounding.normal
                implicitHeight: previewRowLayout.implicitHeight + padding * 2
                implicitWidth: previewRowLayout.implicitWidth + padding * 2

                RowLayout {
                    id: previewRowLayout
                    anchors.centerIn: parent
                    spacing: 8

                    opacity: popupBackground.animProgress
                    scale: 0.85 + (0.15 * popupBackground.animProgress)
                    transformOrigin: Item.Bottom

                    Repeater {
                        model: ScriptModel {
                            values: previewPopup.appTopLevel?.toplevels ?? []
                        }

                        RippleButton {
                            id: windowButton
                            required property var modelData
                            padding: 0

                            middleClickAction: function() {
                                hideTimer.stop()
                                windowButton.modelData?.close()
                            }

                            onPressed: {
                                hideTimer.stop()
                            }

                            onClicked: {
                                hideTimer.stop()
                                windowButton.modelData?.activate()
                                previewPopup.show = false
                            }

                            contentItem: ColumnLayout {
                                spacing: 6
                                implicitWidth: screencopyView.implicitWidth
                                implicitHeight: titleRow.implicitHeight + screencopyView.implicitHeight

                                RowLayout {
                                    id: titleRow
                                    spacing: 6
                                    width: screencopyView.implicitWidth

                                    Rectangle {
                                        Layout.preferredWidth: screencopyView.implicitWidth - root.windowControlsHeight - 6
                                        Layout.maximumWidth: screencopyView.implicitWidth - root.windowControlsHeight - 6
                                        Layout.minimumWidth: screencopyView.implicitWidth - root.windowControlsHeight - 6
                                        implicitHeight: root.windowControlsHeight
                                        radius: Appearance.rounding.small
                                        color: ColorUtils.transparentize(Appearance.colors.colSurfaceContainer)

                                        StyledText {
                                            anchors.fill: parent
                                            anchors.leftMargin: 8
                                            anchors.rightMargin: 8
                                            verticalAlignment: Text.AlignVCenter
                                            font.pixelSize: Appearance.font.pixelSize.small
                                            text: windowButton.modelData?.title ?? ""
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

                                        onPressed: {
                                            hideTimer.stop()
                                        }

                                        contentItem: MaterialSymbol {
                                            anchors.centerIn: parent
                                            horizontalAlignment: Text.AlignHCenter
                                            text: "close"
                                            iconSize: Appearance.font.pixelSize.normal
                                            color: Appearance.m3colors.m3onSurface
                                        }

                                        onClicked: {
                                            hideTimer.stop()
                                            windowButton.modelData?.close()
                                        }
                                    }
                                }

                                ScreencopyView {
                                    id: screencopyView
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
