import "root:/"
import "root:/services"
import "root:/modules/common"
import "root:/modules/common/widgets"
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
    property real maxWindowPreviewWidth: 350
    property Item lastHoveredButton
    property bool buttonHovered: false
    property bool requestDockShow: previewPopup.show

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
                        if (!map.has(toplevel.appId.toLowerCase())) map.set(toplevel.appId.toLowerCase(), []);
                        map.get(toplevel.appId.toLowerCase()).push(toplevel);
                    }

                    var values = [];

                    for (const [key, value] of map) {
                        values.push({ appId: key, toplevels: value });
                    }

                    return values;
                }
            }
            delegate: DockAppButton {
                required property var modelData
                appToplevel: modelData
                appListRoot: root
            }
        }
    }

    PopupWindow {
        id: previewPopup
        property var appTopLevel: root.lastHoveredButton?.appToplevel
        property bool allPreviewsReady: false
        Connections {
            target: root
            onLastHoveredButtonChanged: previewPopup.allPreviewsReady = false; // Reset readiness when the hovered button changes
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
            rect: {
                if (root.lastHoveredButton === null) return; // Don't update
                const parentWindow = root.QsWindow.window
                const mappedPosition = parentWindow.mapFromItem(root.lastHoveredButton, root.lastHoveredButton.width / 2, root.lastHoveredButton.height / 2)
                const modifiedX = mappedPosition.x - implicitWidth / 2
                const modifiedY = 0
                return Qt.rect(modifiedX, modifiedY, implicitWidth, implicitHeight)
            }
            gravity: Edges.Top
            edges: Edges.Top
        }
        visible: popupBackground.visible
        color: "transparent"
        implicitWidth: root.QsWindow.window.width
        implicitHeight: popupBackground.implicitHeight + Appearance.sizes.elevationMargin * 2

        MouseArea {
            id: popupMouseArea
            anchors.bottom: parent.bottom
            implicitWidth: popupBackground.implicitWidth + Appearance.sizes.elevationMargin * 2
            implicitHeight: popupBackground.implicitHeight + Appearance.sizes.elevationMargin * 2
            anchors.horizontalCenter: parent.horizontalCenter
            hoverEnabled: true
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
                color: Appearance.colors.colLayer1
                radius: Appearance.rounding.normal
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Appearance.sizes.elevationMargin
                anchors.horizontalCenter: parent.horizontalCenter
                implicitWidth: previewRowLayout.implicitWidth + padding * 2
                implicitHeight: root.maxWindowPreviewHeight + padding * 2

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
                            contentItem: Item {
                                implicitWidth: screencopyView.implicitWidth
                                implicitHeight: screencopyView.implicitHeight
                                ScreencopyView {
                                    id: screencopyView
                                    anchors.centerIn: parent
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
                                ButtonGroup {
                                    contentWidth: parent.width - anchors.margins * 2
                                    anchors {
                                        top: parent.top
                                        left: parent.left
                                        right: parent.right
                                        margins: 3
                                    }
                                    WrapperRectangle {
                                        Layout.fillWidth: true
                                        color: Appearance.m3colors.m3surfaceContainer
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
                                        colBackground: Appearance.m3colors.m3surfaceContainer
                                        baseWidth: 30
                                        baseHeight: 30
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
                            }
                        }
                    }
                }
            }
        }
    }
}
