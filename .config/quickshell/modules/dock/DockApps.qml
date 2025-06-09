import "root:/"
import "root:/services"
import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/modules/common/functions/color_utils.js" as ColorUtils
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell.Io
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Hyprland

Item {
    id: root
    property real maxWindowPreviewHeight: 200
    property real maxWindowPreviewWidth: 300
    property real windowControlsHeight: 30

    property Item lastHoveredButton
    property bool buttonHovered: false
    property bool requestDockShow: previewPopup.show
    property real popupX: parentWindow.mapFromItem(root.lastHoveredButton, root.lastHoveredButton.width / 2, root.lastHoveredButton.height / 2).x - implicitWidth / 2

    property int pinnedCount: ConfigOptions?.dock?.pinnedApps?.length ?? 0

    implicitWidth: rowLayout.implicitWidth
    implicitHeight: rowLayout.implicitHeight

    RowLayout {
        id: rowLayout
        spacing: 2

        Repeater {
            model: ScriptModel {
                objectProp: "appId"
                values: {
                    var map = new Map();

                    for (const toplevel of ToplevelManager.toplevels.values) {
                        const appId = toplevel.appId.toLowerCase();
                        if (!map.has(appId)) map.set(appId, []);
                        map.get(appId).push(toplevel);
                    }

                    var values = [];
                    const pinnedApps = ConfigOptions?.dock?.pinnedApps ?? [];

                    for (const appId of pinnedApps) {
                        values.push({ appId, isPinnedApp: true});
                    }

                    for (const [key, value] of map) {
                        let pinnedIndex = pinnedApps.indexOf(key);
                        if(pinnedIndex < 0) {
                            values.push({ appId: key, toplevels: value });
                        } else {
                            values[pinnedIndex].toplevels = value;
                            values[pinnedIndex].isRunning = true;
                        }
                    }

                    return values;
                }
            }

            delegate: Item {
                id: buttonWrapper

                property int buttonIndex: index

                implicitWidth: appButton.implicitWidth + (buttonIndex === pinnedCount ? separator.implicitWidth + rowLayout.spacing : 0)
                implicitHeight: appButton.implicitHeight

                RowLayout {

                    spacing: rowLayout.spacing

                    DockSeparator {
                        id: separator
                        visible: buttonIndex === pinnedCount
                    }

                    DockAppButton {
                        id: appButton
                        appToplevel: modelData
                        appListRoot: root
                    }
                }
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
            // anchors.horizontalCenter: parent.horizontalCenter
            hoverEnabled: true
            // x: previewPopup.width / 2 + root.popupX
            // Behavior on x {
            //     animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
            // }
            x: {
                const itemCenter = root.QsWindow.mapFromItem(root.lastHoveredButton, root.lastHoveredButton.width / 2, 0);
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
                        model: previewPopup.appTopLevel?.toplevels ?? []
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
                                        color: ColorUtils.transparentize(Appearance.m3colors.m3surfaceContainer)
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
                                        colBackground: ColorUtils.transparentize(Appearance.m3colors.m3surfaceContainer)
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
