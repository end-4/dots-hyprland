import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland
import Quickshell.Services.Notifications

Scope {
    id: root

    property var cards: []

    function symbolFor(kind) {
        switch (kind) {
            case "mic": return "mic";
            case "camera": return "videocam";
            case "screen": return "screen_share";
        }
        return "shield";
    }

    function messageFor(kind) {
        switch (kind) {
            case "mic": return Translation.tr("Captures audio from the microphone");
            case "camera": return Translation.tr("Captures video from the camera");
            case "screen": return Translation.tr("Captures picture of the screen");
        }
        return "";
    }

    readonly property string unknownApp: Translation.tr("Unknown application")

    function enabled(kind) {
        if (kind === "mic") return Config.options.bar.indicators.mic.showIndicator;
        if (kind === "camera") return Config.options.bar.indicators.camera.showIndicator;
        return Config.options.bar.indicators.screen.showIndicator;
    }

    function iconNameFor(node) {
        if (!node)
            return "";
        let icon = AppSearch.guessIcon(node.properties["application.icon-name"] ?? "");
        if (!AppSearch.iconExists(icon))
            icon = AppSearch.guessIcon(node.properties["node.name"] ?? "");
        return AppSearch.iconExists(icon) ? icon : "";
    }

    function displayName(node, app) {
        if (!node)
            return app ?? "";
        return node.properties?.["application.name"] ?? node.properties?.["media.name"] ?? "";
    }

    function put(kind, app, icon) {
        if (!root.enabled(kind))
            return;
        const previous = root.cards.find(card => card.kind === kind);
        const next = root.cards.filter(card => card.kind !== kind);
        next.push({
            kind,
            app: app || previous?.app || "",
            icon: icon || previous?.icon || ""
        });
        root.cards = next;
    }

    function drop(kind) {
        const next = root.cards.filter(card => card.kind !== kind);
        if (next.length !== root.cards.length)
            root.cards = next;
    }

    function dropDisabled() {
        root.cards = root.cards.filter(card => root.enabled(card.kind));
    }

    Connections {
        target: Privacy
        function onMicCaptureStarted(node) {
            root.put("mic", root.displayName(node, ""), root.iconNameFor(node));
        }
        function onCameraCaptureStarted(node, app) {
            root.put("camera", root.displayName(node, app), root.iconNameFor(node));
        }
        function onScreenCaptureStarted(node) {
            root.put("screen", root.displayName(node, ""), root.iconNameFor(node));
        }
        function onScreenCaptureNodesChanged() {
            const card = root.cards.find(c => c.kind === "screen");
            if (!card || card.app !== "")
                return;
            const node = Privacy.screenCaptureNodes[0];
            if (node)
                root.put("screen", root.displayName(node, ""), root.iconNameFor(node));
        }
        function onCameraCaptureNodesChanged() {
            const card = root.cards.find(c => c.kind === "camera");
            if (!card || card.app !== "")
                return;
            const node = Privacy.cameraCaptureNodes[0];
            if (node)
                root.put("camera", root.displayName(node, card.app), root.iconNameFor(node));
        }
    }

    Connections {
        target: Config.options.bar.indicators.mic
        function onShowIndicatorChanged() {
            root.dropDisabled();
        }
    }

    Connections {
        target: Config.options.bar.indicators.camera
        function onShowIndicatorChanged() {
            root.dropDisabled();
        }
    }

    Connections {
        target: Config.options.bar.indicators.screen
        function onShowIndicatorChanged() {
            root.dropDisabled();
        }
    }

    PanelWindow {
        id: popupRoot
        visible: root.cards.length > 0

        screen: Quickshell.screens.find(s => Config.options.notifications.forceMonitor.enable
            ? s.name === Config.options.notifications.forceMonitor.name
            : s.name === Hyprland.focusedMonitor?.name) ?? null

        WlrLayershell.namespace: "quickshell:privacyCapturePopup"
        WlrLayershell.layer: WlrLayer.Overlay
        exclusiveZone: 0

        anchors {
            top: true
            right: true
            bottom: true
        }

        color: "transparent"
        implicitWidth: Appearance.sizes.notificationPopupWidth

        readonly property real publishedHeight: root.cards.length > 0 ? stack.height : 0
        onPublishedHeightChanged: GlobalStates.privacyPopupHeight = popupRoot.publishedHeight
        Component.onDestruction: GlobalStates.privacyPopupHeight = 0

        mask: Region {
            item: stack
        }

        Column {
            id: stack
            anchors {
                top: parent.top
                right: parent.right
                rightMargin: 4
                topMargin: 4
            }
            spacing: 8

            Repeater {
                id: repeater
                model: ScriptModel {
                    values: root.cards
                }

                delegate: Item {
                    id: delegate
                    required property var modelData
                    required property int index

                    readonly property string kind: modelData.kind
                    readonly property string app: modelData.app
                    readonly property string icon: modelData.icon

                    implicitWidth: card.implicitWidth
                    implicitHeight: card.implicitHeight

                    property bool hovered: false

                    Timer {
                        id: cardTimer
                        interval: Config.options.notifications.timeout
                        repeat: false
                        running: !delegate.hovered
                        onTriggered: root.drop(delegate.kind)
                    }

                    MouseArea {
                        anchors.fill: card
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton
                        onContainsMouseChanged: delegate.hovered = containsMouse
                        onClicked: root.drop(delegate.kind)
                    }

                    StyledRectangularShadow {
                        target: card
                    }

                    Rectangle {
                        id: card
                        property real padding: 10
                        color: Appearance.colors.colBackgroundSurfaceContainer
                        radius: Appearance.rounding.normal
                        clip: true
                        implicitWidth: popupRoot.width - Appearance.sizes.elevationMargin * 2
                        implicitHeight: row.implicitHeight + padding * 2

                        RowLayout {
                            id: row
                            anchors {
                                top: parent.top
                                left: parent.left
                                right: parent.right
                                bottom: parent.bottom
                                margins: card.padding
                            }
                            spacing: 10

                            NotificationAppIcon {
                                Layout.alignment: Qt.AlignTop
                                Layout.fillWidth: false
                                summary: ""
                                urgency: NotificationUrgency.Critical
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    IconImage {
                                        visible: delegate.icon !== ""
                                        Layout.preferredWidth: 18
                                        Layout.preferredHeight: 18
                                        Layout.alignment: Qt.AlignVCenter
                                        asynchronous: true
                                        source: Quickshell.iconPath(delegate.icon, "image-missing")
                                    }
                                    StyledText {
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        color: Appearance.colors.colOnLayer2
                                        text: delegate.app !== "" ? delegate.app : root.unknownApp
                                    }
                                }
                                StyledText {
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    color: Appearance.colors.colSubtext
                                    text: root.messageFor(delegate.kind)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
