pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

Scope {
    id: root
    property bool failed
    property string errorString
    property real progressHeight: 3

    // Connect to the Quickshell global to listen for the reload signals.
    Connections {
        target: Quickshell

        function onReloadCompleted() {
            root.failed = false;
            popupLoader.loading = true;
        }

        function onReloadFailed(error: string) {
            // Close any existing popup before making a new one.
            popupLoader.active = false;

            root.failed = true;
            root.errorString = error;
            popupLoader.loading = true;
        }
    }

    // Keep the popup in a loader because it isn't needed most of the time
    LazyLoader {
        id: popupLoader

        PanelWindow {
            id: popup

            exclusiveZone: 0
            anchors.top: true
            margins.top: 0

            implicitWidth: rect.width + 8 * 2
            implicitHeight: rect.height + 8 * 2

            WlrLayershell.namespace: "quickshell:reloadPopup"

            // color blending is a bit odd as detailed in the type reference.
            color: "transparent"

            RectangularShadow {
                anchors.fill: rect
                radius: rect.radius
                blur: 6.3
                offset: Qt.vector2d(0.0, 1.0)
                spread: 1
                color: "#55000000"
            }

            Rectangle {
                id: rect
                anchors.centerIn: parent
                color: root.failed ? "#ffe99195" : "#ffD1E8D5"

                implicitHeight: layout.implicitHeight + 30
                implicitWidth: layout.implicitWidth + 30
                radius: 8

                // Fills the whole area of the rectangle, making any clicks go to it,
                // which dismiss the popup.
                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    onPressed: {
                        popupLoader.active = false;
                    }

                    // makes the mouse area track mouse hovering, so the hide animation
                    // can be paused when hovering.
                    hoverEnabled: true
                }

                ColumnLayout {
                    id: layout
                    spacing: 10
                    anchors {
                        top: parent.top
                        topMargin: 10
                        horizontalCenter: parent.horizontalCenter
                    }

                    Text {
                        id: title
                        renderType: Text.NativeRendering
                        font.family: "Google Sans Flex"
                        font.pointSize: 14
                        text: root.failed ? "Quickshell: Reload failed" : "Quickshell reloaded"
                        color: root.failed ? "#ff93000A" : "#ff0C1F13"
                    }

                    Text {
                        id: info
                        renderType: Text.NativeRendering
                        font.family: "JetBrains Mono NF"
                        font.pointSize: 11
                        text: root.errorString
                        color: root.failed ? "#ff93000A" : "#ff0C1F13"
                        // When visible is false, it also takes up no space.
                        visible: root.errorString != ""
                    }
                }

                // A progress bar on the bottom of the screen, showing how long until the
                // popup is removed.
                Rectangle {
                    id: bar
                    z: 2
                    color: root.failed ? "#ff93000A" : "#ff0C1F13"
                    property real maxWidth: Math.max(title.width, info.width)
                    anchors {
                        left: parent.left
                        leftMargin: (parent.width - maxWidth) / 2
                        bottom: parent.bottom
                        bottomMargin: 10
                    }
                    height: root.progressHeight
                    radius: 9999

                    PropertyAnimation {
                        id: anim
                        target: bar
                        property: "width"
                        from: Math.max(title.width, info.width)
                        to: 0
                        duration: root.failed ? 10000 : 1000
                        onFinished: popupLoader.active = false

                        // Pause the animation when the mouse is hovering over the popup,
                        // so it stays onscreen while reading. This updates reactively
                        // when the mouse moves on and off the popup.
                        paused: mouseArea.containsMouse
                    }
                }
                // Its bg
                Rectangle {
                    id: bar_bg
                    z: 1
                    color: root.failed ? "#30af1b25" : "#4027643e"
                    property real maxWidth: Math.max(title.width, info.width)
                    anchors {
                        left: parent.left
                        right: parent.right
                        leftMargin: (parent.width - maxWidth) / 2
                        rightMargin: anchors.leftMargin
                        bottom: parent.bottom
                        bottomMargin: 10
                    }
                    height: root.progressHeight
                    radius: 9999
                    width: bar.width
                }

                // We could set `running: true` inside the animation, but the width of the
                // rectangle might not be calculated yet, due to the layout.
                // In the `Component.onCompleted` event handler, all of the component's
                // properties and children have been initialized.
                Component.onCompleted: anim.start()
            }
        }
    }
}
