import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs.modules.ii.island

// Notification: icon, app · summary, body, actions, "+N" badge.
RowLayout {
    id: root
    property var ev
    property int extra: 0
    readonly property var p: ev?.payload ?? ({})
    spacing: 12
    width: 352

    function esc(t) {
        return String(t).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
    }

    NotificationAppIcon {
        implicitWidth: 44
        implicitHeight: 44
        appIcon: root.p.appIcon ?? ""
        image: root.p.image ?? ""
        summary: root.p.summary ?? ""
    }
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 1
        StyledText {
            Layout.fillWidth: true
            elide: Text.ElideRight
            textFormat: Text.StyledText
            text: "<b>" + root.esc(root.p.appName || root.p.summary || "") + "</b>" + (root.p.appName && root.p.summary ? " · " + root.esc(root.p.summary) : "")
            color: Appearance.colors.colOnLayer1
        }
        StyledText {
            Layout.fillWidth: true
            text: (root.p.body ?? "").replace(/<[^>]*>/g, "")
            visible: text.length > 0
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
        }
    }
    Repeater {
        model: (root.p.actions ?? []).filter(a => a.identifier !== "default").slice(0, 2)
        IslandChip {
            required property var modelData
            text: modelData.text
            onClicked: {
                Notifications.attemptInvokeAction(root.p.notificationId, modelData.identifier);
                IslandState.dismiss(root.ev.id);
            }
        }
    }
    Rectangle {
        visible: root.extra > 0
        implicitWidth: badge.implicitWidth + 12
        implicitHeight: 22
        radius: 11
        color: Appearance.colors.colSecondaryContainer
        StyledText {
            id: badge
            anchors.centerIn: parent
            text: "+" + root.extra
            font.pixelSize: Appearance.font.pixelSize.smallest
            color: Appearance.colors.colOnSecondaryContainer
        }
    }

    // Body click (IslandBody makes the whole card clickable): default action if any, then gone.
    function activate() {
        IslandState.activateNotification(root.p.notificationId, root.ev.id);
    }
}
