import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

// Adjust path to point to your Appearance.qml
import "modules/common" as Common

Scope {
    id: root

    property string popupType: "neutral"
    property string title: ""
    property string message: ""

    // --- RELOADPOPUP COLORS (Fixed for Bad/Good) ---
    readonly property color bgBad: "#ffe99195"      // Pastel Red
    readonly property color bgGood: "#ffD1E8D5"     // Pastel Green
    readonly property color textBad: "#ff93000A"    // Dark Red Text
    readonly property color textGood: "#ff0C1F13"   // Dark Green Text

    // Access to Appearance Singleton/Component
    property var themeColors: Common.Appearance.m3colors

    // --- HELPERS ---

    function transparentize(color, alpha) {
        return Qt.rgba(color.r, color.g, color.b, alpha)
    }

    // --- COLOR LOGIC ---
    function getBgColor() {
        // Bad/Good: Fixed Pastel
        if (root.popupType === "bad")  return root.bgBad
        if (root.popupType === "good") return root.bgGood

        // Submap: Theme Highlighted Gray
        if (root.popupType === "submap")
            return transparentize(root.themeColors.m3surfaceContainerHighest, 0.7)

        // Neutral: Theme Standard Background
        return transparentize(root.themeColors.m3surfaceContainer, 0.85)
    }

    function getTextColor() {
        // Bad/Good: Fixed dark text for contrast
        if (root.popupType === "bad")  return root.textBad
        if (root.popupType === "good") return root.textGood

        // Submap/Neutral: Dynamic Theme Text (OnSurface)
        return root.themeColors.m3onSurface
    }

    function getBorderColor() {
        // No border for Neutral/Submap
        if (root.popupType === "neutral" || root.popupType === "submap") return "transparent"
        return "transparent"
    }

    // --- WATCHER (Log Listener) ---
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

                    // Reset Loader to restart animations/timers
                    popupLoader.active = false;
                    popupLoader.active = true;
                }
            }
        }
    }

    LazyLoader {
        id: popupLoader
        active: false

        PanelWindow {
            id: popup
            exclusiveZone: 0

            // --- POSITIONING ---
            // Submap at bottom, Alerts at top
            anchors.top: root.popupType !== "submap"
            anchors.bottom: root.popupType === "submap"

            margins.top: 10
            margins.bottom: root.popupType === "submap" ? 80 : 20

            implicitWidth: rect.width + shadow.radius * 2
            implicitHeight: rect.height + shadow.radius * 2

            WlrLayershell.namespace: "quickshell:popup"
            color: "transparent"

            Rectangle {
                id: rect
                anchors.centerIn: parent

                color: root.getBgColor()

                border.width: 0
                border.color: root.getBorderColor()

                // Adaptive size + Extra padding for Submap
                implicitHeight: layout.implicitHeight + (root.popupType === "submap" ? 80 : 30)
                implicitWidth: layout.implicitWidth + (root.popupType === "submap" ? 80 : 30)

                radius: 12

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onPressed: popupLoader.active = false
                }

                ColumnLayout {
                    id: layout
                    spacing: root.popupType === "submap" ? 2 : 5
                    anchors.centerIn: parent

                    Text {
                        // TITLE
                        renderType: Text.NativeRendering
                        font.family: root.popupType === "submap" ? "Iosevka Light" : "Iosevka Heavy"
                        font.pointSize: root.popupType === "submap" ? 19 : 14
                        font.bold: root.popupType !== "submap"

                        text: root.title
                        color: root.getTextColor()

                        Layout.alignment: Qt.AlignHCenter
                        Layout.maximumWidth: 400
                        elide: Text.ElideRight
                    }

                    Text {
                        // MESSAGE
                        renderType: Text.NativeRendering
                        font.family: root.popupType === "submap" ? "Iosevka Heavy" : "Iosevka"
                        font.pointSize: root.popupType === "submap" ? 21 : 12
                        font.bold: root.popupType === "submap"

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

                // --- TIMER ---
                Timer {
                    // Submap: 1.2s | Bad: 5s | Others: 3s
                    interval: root.popupType === "submap" ? 1200 : (root.popupType === "bad" ? 5000 : 3000)
                    running: popupLoader.active
                    onTriggered: popupLoader.active = false
                }
            }

            DropShadow {
                id: shadow
                anchors.fill: rect
                horizontalOffset: 0
                verticalOffset: 4
                radius: 8
                samples: 16
                color: Qt.rgba(0, 0, 0, 0.4)
                source: rect
                visible: root.popupType !== "neutral"
            }
        }
    }
}
