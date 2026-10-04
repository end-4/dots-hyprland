import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Notifications

Scope {
    id: root
    property bool shown: false
    property string appName: ""
    property string appIconName: ""
    property string message: ""

    // application.name and media.name identify the app; node.name often doesn't (every Electron
    // app is "electron") and node.description is a device or codec string. A generic "an app" beats
    // a name that tells the reader nothing.
    function displayName(node) {
        return node?.properties?.["application.name"] ?? node?.properties?.["media.name"] ?? "";
    }

    function messageFor(kind) {
        switch (kind) {
            case "mic": return Translation.tr("started to capture microphone");
            case "camera": return Translation.tr("started to use the camera");
            case "screen": return Translation.tr("started to share your screen");
        }
        return "";
    }

    function show(node, kind) {
        if (!node)
            return;

        root.appName = root.displayName(node);
        // Only a real icon name goes to NotificationAppIcon: it resolves the path itself, and
        // guessIcon() can return a name that does not exist, which would leave a broken image.
        let icon = AppSearch.guessIcon(node.properties["application.icon-name"] ?? "");
        if (!AppSearch.iconExists(icon))
            icon = AppSearch.guessIcon(node.properties["node.name"] ?? "");
        root.appIconName = AppSearch.iconExists(icon) ? icon : "";

        root.message = root.messageFor(kind);
        root.shownKind = kind;
        root.shown = true;
        hideTimer.restart();
    }

    // Read the raw state, not Privacy.micIndicatorVisible and friends: those are bindings *on*
    // Privacy.micActive, and a change handler runs before its dependents are re-evaluated, so during
    // the capture-started signal they still hold the previous value - the popup would read the
    // indicator as off and hide itself exactly when it should appear.
    function enabled(kind) {
        if (kind === "mic") return Config.options.bar.indicators.mic.showIndicator;
        if (kind === "camera") return Config.options.bar.indicators.camera.showIndicator;
        return Config.options.bar.indicators.screen.showIndicator;
    }

    // Whichever capture is currently on, preferring the most privacy-relevant one. Used for the
    // "setting was flipped while a capture was running" case, in both directions.
    function activeKind() {
        if (Privacy.micActive && root.enabled("mic")) return "mic";
        if (Privacy.cameraActive && root.enabled("camera")) return "camera";
        if (Privacy.screenCaptureActive && root.enabled("screen")) return "screen";
        return null;
    }

    function activeNode(kind) {
        if (kind === "mic") return Privacy.micActiveNodes[0];
        if (kind === "camera") return Privacy.cameraCaptureNodes[0];
        return Privacy.screenCaptureNodes[0];
    }

    function showFor(node, kind) {
        if (!node || !root.enabled(kind))
            return;
        root.show(node, kind);
    }

    function sync() {
        const kind = root.activeKind();
        if (kind === null) {
            hideTimer.stop();
            root.shown = false;
            root.shownKind = "";
            return;
        }
        // Only ever raise (or re-label) it here. A setting flip re-evaluates this, and hiding on that
        // path would let an unrelated re-evaluation kill a notification that is still true - the
        // capture ending is what hides it, via the timer.
        if (!root.shown || root.shownKind !== kind)
            root.show(root.activeNode(kind), kind);
    }

    property string shownKind: ""

    Timer {
        id: hideTimer
        interval: Config.options.notifications.timeout
        repeat: false
        onTriggered: root.shown = false
    }

    Connections {
        target: Privacy
        function onMicCaptureStarted(node) {
            root.showFor(node, "mic");
        }
        function onCameraCaptureStarted(node) {
            root.showFor(node, "camera");
        }
        function onScreenCaptureStarted(node) {
            root.showFor(node, "screen");
        }
    }

    Connections {
        target: Config.options.bar.indicators.mic
        function onShowIndicatorChanged() {
            root.sync();
        }
    }

    Connections {
        target: Config.options.bar.indicators.camera
        function onShowIndicatorChanged() {
            root.sync();
        }
    }

    Connections {
        target: Config.options.bar.indicators.screen
        function onShowIndicatorChanged() {
            root.sync();
        }
    }

    PanelWindow {
        id: popupRoot
        visible: root.shown

        // Тот же монитор, что и у попапов уведомлений, включая принудительный из настроек:
        // попап приватности обязан быть там же, где уведомления, иначе он просто не виден.
        screen: Quickshell.screens.find(s => Config.options.notifications.forceMonitor.enable
            ? s.name === Config.options.notifications.forceMonitor.name
            : s.name === Hyprland.focusedMonitor?.name) ?? null

        WlrLayershell.namespace: "quickshell:privacyCapturePopup"
        WlrLayershell.layer: WlrLayer.Overlay
        // Без exclusionMode окно ведёт себя как окно уведомлений: по умолчанию Auto, и
        // композитор сам отодвигает его от панели - сверху и справа. С Ignore окно уезжало под
        // панель, и приходилось угадывать сдвиг вручную.
        exclusiveZone: 0

        // Окно во всю высоту, прижато к правому верхнему углу - как окно уведомлений.
        anchors {
            top: true
            right: true
            bottom: true
        }

        color: "transparent"
        // Только ширина, как у окна уведомлений: с высотой окно перестаёт растягиваться по краям.
        implicitWidth: Appearance.sizes.notificationPopupWidth

        // Пока попапа нет, эта высота нулевая, и уведомления остаются ровно на своём месте.
        readonly property real publishedHeight: root.shown ? card.height : 0
        onPublishedHeightChanged: GlobalStates.privacyPopupHeight = popupRoot.publishedHeight
        Component.onDestruction: GlobalStates.privacyPopupHeight = 0

        mask: Region {
            item: card
        }

        StyledRectangularShadow {
            target: card
        }

        Rectangle { // Card, same metrics as a notification card
            id: card
            anchors {
                top: parent.top
                right: parent.right
                // Ровно как у списка уведомлений, без ручных поправок на положение панели.
                topMargin: 4
                rightMargin: 4
            }
            property real padding: 10
            color: Appearance.colors.colBackgroundSurfaceContainer
            radius: Appearance.rounding.normal
            clip: true
            // Ширина ровно как у карточки уведомления: иначе рядом с ней стопка выглядит
            // разнокалиберной.
            implicitWidth: popupRoot.width - Appearance.sizes.elevationMargin * 2
            implicitHeight: row.implicitHeight + padding * 2

            RowLayout {
                id: row
                // Прижат к краям на ширину карточки, как в NotificationGroup: центрирование
                // сдвигало бы текст относительно уведомлений ступенькой вбок.
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    margins: card.padding
                }
                spacing: 10

                NotificationAppIcon {
                    Layout.alignment: Qt.AlignTop
                    Layout.fillWidth: false
                    appIcon: root.appIconName
                    summary: root.appName
                    urgency: NotificationUrgency.Critical
                }

                ColumnLayout {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnLayer2
                        text: root.appName !== "" ? root.appName : Translation.tr("An app")
                    }
                    StyledText {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                        text: root.message
                    }
                }
            }
        }
    }
}
