import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "modules/common" as Common

Scope {
    id: root

    property string popupType: "neutral"
    property string title: ""
    property string message: ""
    property string displayState: "hidden"

    readonly property bool isBottomPopup: (root.popupType === "toggle")

    property int rounding: 12
    property int textOffset: (root.rounding / 2) - 1

    readonly property color bgBad: "#ffe99195"
    readonly property color bgGood: "#ffD1E8D5"
    readonly property color textBad: "#ff93000A"
    readonly property color textGood: "#ff0C1F13"

    property var themeColors: Common.Appearance.m3colors

    function transparentize(color, alpha) {
        return Qt.rgba(color.r, color.g, color.b, alpha)
    }

    function getBgColor() {
        if (root.popupType === "bad")  return root.bgBad
            if (root.popupType === "good") return root.bgGood

                if (root.isBottomPopup)
                    return transparentize(root.themeColors.m3surfaceContainerHighest, 0.75)

                    return transparentize(root.themeColors.m3surfaceContainer, 0.85)
    }

    function getTextColor() {
        if (root.popupType === "bad")  return root.textBad
            if (root.popupType === "good") return root.textGood
                return root.themeColors.m3onSurface
    }

    Process {
        id: watcher
        command: ["sh", "-c", "touch /tmp/qs_popup.log && stdbuf -oL tail -n 0 -f /tmp/qs_popup.log"]
        running: true
        stdout: SplitParser {
            onRead: (data) => {
                var parts = data.trim().split("|");
                if (parts.length >= 3) {
                    root.popupType = parts[0].toLowerCase();
                    root.title = parts[1];
                    root.message = parts[2];
                    root.displayState = "popup";
                    popupTimer.restart();
                }
            }
        }
    }

    Timer {
        id: popupTimer
        interval: root.isBottomPopup ? 1000 : (root.popupType === "bad" ? 5000 : 3000)
        running: root.displayState === "popup"
        onTriggered: {
            root.displayState = "hidden"
        }
    }

    LazyLoader {
        id: popupLoader
        active: root.displayState !== "hidden"

        PanelWindow {
            id: popup
            exclusiveZone: 0

            anchors.bottom: root.isBottomPopup
            anchors.top: !root.isBottomPopup

            // --- MARGIN LOGIC ---
            // Bottom: Is like buried in the screen, so it doesn't show the bottom round corners
            // Top: Uses a fixed small margin from the screen edge.
            margins.bottom: root.isBottomPopup ? (root.displayState === "indicator" ? -root.rounding : 80) : 0
            margins.top: !root.isBottomPopup ? 10 : 0

            Behavior on margins.bottom { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

            implicitWidth: rect.width
            implicitHeight: rect.height

            WlrLayershell.namespace: "quickshell:popup"
            color: "transparent"

            Rectangle {
                id: rect
                anchors.centerIn: parent

                width: layout.implicitWidth + 60

                // If Indicator: small height adjustment.
                // If Bottom Popup: Large padding (60).
                // If Top Popup: Small padding (25).
                height: {
                    if (root.displayState === "indicator")
                        return layout.implicitHeight + 20

                        return layout.implicitHeight + (root.isBottomPopup ? 60 : 25)
                }

                radius: root.rounding
                color: root.getBgColor()

                ColumnLayout {
                    id: layout
                    spacing: 0
                    anchors.centerIn: parent

                    anchors.verticalCenterOffset: root.displayState === "indicator" ? -root.textOffset : 0

                    Behavior on anchors.verticalCenterOffset { NumberAnimation { duration: 300 } }

                    Text {
                        // TITLE
                        visible: root.displayState === "popup"
                        renderType: Text.NativeRendering

                        font.family: root.isBottomPopup ? "Iosevka Light" : "Iosevka Heavy"
                        font.pointSize: root.isBottomPopup ? 19 : 14
                        font.bold: !root.isBottomPopup

                        text: root.title
                        color: root.getTextColor()

                        Layout.alignment: Qt.AlignHCenter
                        Layout.maximumWidth: 400
                        elide: Text.ElideRight

                        opacity: visible ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                    }

                    Text {
                        // MESSAGE
                        id: messageText
                        renderType: Text.NativeRendering

                        font.family: root.isBottomPopup ? "Iosevka Heavy" : "Iosevka"

                        font.pointSize: {
                            if (root.displayState === "indicator") return 16
                                if (root.isBottomPopup) return 21
                                    return 12
                        }

                        font.bold: (root.isBottomPopup && root.displayState !== "indicator")

                        text: root.message
                        color: root.getTextColor()

                        textFormat: Text.RichText
                        horizontalAlignment: Text.AlignHCenter
                        Layout.alignment: Qt.AlignHCenter
                        Layout.maximumWidth: 400
                        wrapMode: Text.WordWrap

                        visible: text !== ""
                    }
                }
            }
        }
    }
}
