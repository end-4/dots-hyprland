import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell.Io

MouseArea {
    id: root

    property bool expanded: false
    property var popupState: ({ "updated_at": "", "session_count": 0, "sessions": [] })
    property var popupSessions: popupState.sessions ?? []
    property int popupSessionCount: popupState.session_count ?? 0
    property string selectedSessionId: popupSessions.length > 0 ? (popupSessions[0].session_id ?? "") : ""
    readonly property var focusedSession: popupSessionCount > 0 ? popupSessions[0] : null
    readonly property string displayTitle: {
        if (!focusedSession)
            return "Orbitbar";
        return focusedSession.title ?? focusedSession.session_id ?? focusedSession.tool ?? "Orbitbar";
    }
    readonly property bool urgent: {
        const status = focusedSession?.status ?? "idle";
        return status === "approval_required" || status === "question" || status === "error";
    }
    readonly property color activeColor: {
        const status = focusedSession?.status ?? "idle";
        switch (status) {
        case "approval_required":
            return Appearance.colors.colSecondaryContainer;
        case "question":
            return Appearance.colors.colPrimary;
        case "error":
            return Appearance.colors.colError;
        case "done":
            return Appearance.colors.colPrimaryContainer;
        default:
            return Appearance.colors.colLayer1Hover;
        }
    }

    implicitWidth: buttonBackground.implicitWidth
    implicitHeight: Appearance.sizes.barHeight
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton

    onPressed: mouse => {
        if (mouse.button === Qt.LeftButton)
            root.expanded = !root.expanded;
    }

    Component.onCompleted: popupStateFile.reload()

    function parsePopupState(raw) {
        if (!raw || raw.trim().length === 0) {
            root.popupState = { "updated_at": "", "session_count": 0, "sessions": [] };
            return;
        }

        try {
            root.popupState = JSON.parse(raw);
        } catch (error) {
            console.warn(`[OrbitbarButton] Failed to parse state file: ${error}`);
        }
    }

    onPopupSessionsChanged: {
        if (popupSessions.length === 0) {
            root.selectedSessionId = "";
            if (root.expanded)
                root.expanded = false;
            return;
        }
        const stillExists = popupSessions.some(session => session.session_id === root.selectedSessionId);
        if (!stillExists)
            root.selectedSessionId = popupSessions[0].session_id ?? "";
    }

    FileView {
        id: popupStateFile
        path: Qt.resolvedUrl(Directories.orbitbarStatePath)
        watchChanges: true
        blockLoading: true
        onLoaded: root.parsePopupState(popupStateFile.text())
    }

    Rectangle {
        id: buttonBackground
        anchors.centerIn: parent
        radius: Appearance.rounding.full
        color: root.containsMouse || root.expanded ? Appearance.colors.colSurfaceContainerHighest : Appearance.colors.colLayer1
        border.width: 1
        border.color: Qt.rgba(root.activeColor.r, root.activeColor.g, root.activeColor.b, focusedSession ? 0.82 : 0.24)
        implicitWidth: row.implicitWidth + 20
        implicitHeight: row.implicitHeight + 12

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        RowLayout {
            id: row
            anchors.centerIn: parent
            spacing: 6

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                width: 14
                height: 14
                radius: 7
                color: focusedSession ? Qt.rgba(root.activeColor.r, root.activeColor.g, root.activeColor.b, 0.18) : Appearance.colors.colSurfaceContainerHigh

                Rectangle {
                    anchors.centerIn: parent
                    width: 6
                    height: 6
                    radius: 3
                    color: focusedSession ? root.activeColor : Appearance.colors.colOutlineVariant
                }
            }

            StyledText {
                text: root.displayTitle
                color: Appearance.colors.colOnLayer1
                font.pixelSize: Appearance.font.pixelSize.small
                elide: Text.ElideRight
                maximumLineCount: 1
                Layout.maximumWidth: 180
            }

            StyledText {
                text: root.popupSessionCount > 0 ? `${root.popupSessionCount}` : ""
                visible: root.popupSessionCount > 0
                color: root.urgent ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.smallest
                font.weight: root.urgent ? Font.Medium : Font.Normal
            }
        }
    }

    OrbitbarPopup {
        hoverTarget: root
        forcedOpen: root.expanded
        selectedSessionId: root.selectedSessionId
        sessions: root.popupSessions
        sessionCount: root.popupSessionCount
        onSelectedSessionIdChanged: root.selectedSessionId = selectedSessionId
        onRequestClose: root.expanded = false
    }
}
