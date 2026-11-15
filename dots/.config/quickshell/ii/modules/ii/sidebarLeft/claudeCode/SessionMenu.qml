pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts

/**
 * Session list under the header: the default session, new session, sessions open
 * in the sidebar, then recent sessions from every project.
 */
Item {
    id: root
    signal chosen

    readonly property var entries: {
        const out = [];
        const defaultId = ClaudeCode.state.sessionId;
        out.push({
            kind: "default",
            icon: "support_agent",
            title: ClaudeCode.defaultName,
            subtitle: Translation.tr("Default session · %1").arg(root.shortPath(ClaudeCode.defaultDir)),
            key: ClaudeCode.defaultKey
        });
        out.push({
            kind: "new",
            icon: "add",
            title: Translation.tr("New session"),
            subtitle: root.shortPath(ClaudeCode.newSessionDir)
        });
        const openIds = [];
        for (const key in ClaudeCode.sessions) {
            const t = ClaudeCode.sessions[key];
            openIds.push(t.sessionId);
            if (key === ClaudeCode.defaultKey || key === "fixture")
                continue;
            const state = t.status === "busy" ? Translation.tr("Working") : t.status === "waiting" ? Translation.tr("Needs approval") : t.alive ? Translation.tr("Open in sidebar") : Translation.tr("Stopped");
            out.push({
                kind: "open",
                icon: t.status === "waiting" ? "front_hand" : "forum",
                title: ClaudeCode.labels[key] ?? (t.name || t.sessionId.slice(0, 8)),
                subtitle: state + " · " + root.shortPath(t.cwd ?? ""),
                key: key
            });
        }
        if (ClaudeCode.menuNotice)
            out.push({
                kind: "header",
                title: ClaudeCode.menuNotice
            });
        const recent = ClaudeCode.recentSessions.filter(s => s.id !== defaultId && !openIds.includes(s.id));
        if (recent.length > 0)
            out.push({
                kind: "header",
                title: Translation.tr("Recent sessions")
            });
        for (const s of recent) {
            out.push({
                kind: "session",
                icon: s.live ? "radio_button_checked" : "history",
                title: s.title,
                subtitle: root.shortPath(s.cwd) + " · " + root.ago(s.mtime) + (s.live ? " · " + Translation.tr("running elsewhere, opens a copy") : ""),
                session: s
            });
        }
        return out;
    }

    function shortPath(p) {
        return p.startsWith(ClaudeCode.home) ? "~" + p.slice(ClaudeCode.home.length) : p;
    }
    function ago(t) {
        const s = Math.max(0, Date.now() / 1000 - t);
        if (s < 60)
            return Translation.tr("just now");
        if (s < 3600)
            return Translation.tr("%1 min ago").arg(Math.floor(s / 60));
        if (s < 86400)
            return Translation.tr("%1 h ago").arg(Math.floor(s / 3600));
        return Translation.tr("%1 d ago").arg(Math.floor(s / 86400));
    }

    function choose(e) {
        if (e.kind === "default")
            ClaudeCode.openDefault();
        else if (e.kind === "new")
            ClaudeCode.newSession();
        else if (e.kind === "open")
            ClaudeCode.activate(e.key);
        else if (e.kind === "session")
            ClaudeCode.openSession(e.session);
        ClaudeCode.sessionMenuOpen = false;
        root.chosen();
    }

    implicitHeight: Math.min(list.contentHeight + 8 * 2, 420)

    StyledRectangularShadow {
        target: background
    }
    Rectangle {
        id: background
        anchors.fill: parent
        radius: Appearance.rounding.normal
        color: Appearance.m3colors.m3surfaceContainerHigh
    }

    StyledListView {
        id: list
        anchors.fill: parent
        anchors.margins: 8
        clip: true
        spacing: 2
        popin: false
        model: root.entries
        delegate: Loader {
            id: entryLoader
            required property var modelData
            width: ListView.view.width
            sourceComponent: modelData.kind === "header" ? headerComponent : itemComponent

            Component {
                id: headerComponent
                StyledText {
                    topPadding: 8
                    bottomPadding: 2
                    leftPadding: 12
                    text: entryLoader.modelData.title
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                }
            }

            Component {
                id: itemComponent
                RippleButton {
                    id: item
                    readonly property var entry: entryLoader.modelData
                    readonly property bool current: (entry.kind === "default" || entry.kind === "open") && entry.key === ClaudeCode.activeKey
                    implicitHeight: itemRow.implicitHeight + 8 * 2
                    buttonRadius: Appearance.rounding.small
                    toggled: current
                    colBackground: ColorUtils.transparentize(Appearance.colors.colLayer3, 1)
                    colBackgroundHover: Appearance.colors.colLayer3Hover
                    colRipple: Appearance.colors.colLayer3Active
                    colBackgroundToggled: Appearance.colors.colSecondaryContainer
                    colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
                    colRippleToggled: Appearance.colors.colSecondaryContainerActive
                    onClicked: root.choose(entry)

                    contentItem: RowLayout {
                        id: itemRow
                        anchors {
                            fill: parent
                            leftMargin: 12
                            rightMargin: 8
                        }
                        spacing: 10
                        MaterialSymbol {
                            text: item.entry.icon
                            iconSize: Appearance.font.pixelSize.larger
                            fill: item.current ? 1 : 0
                            color: item.entry.session?.live ? Appearance.colors.colPrimary : (item.current ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer3)
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            StyledText {
                                Layout.fillWidth: true
                                text: item.entry.title
                                elide: Text.ElideRight
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: item.current ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer3
                            }
                            StyledText {
                                Layout.fillWidth: true
                                text: item.entry.subtitle
                                elide: Text.ElideMiddle
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colSubtext
                            }
                        }
                        RippleButton { // Delete a stopped session: click twice
                            id: deleteButton
                            property bool armed: false
                            readonly property bool running: item.entry.session?.live ?? false
                            visible: item.entry.kind === "session"
                            enabled: !running
                            implicitWidth: 28
                            implicitHeight: 28
                            buttonRadius: Appearance.rounding.full
                            colBackground: armed ? Appearance.colors.colErrorContainer : ColorUtils.transparentize(Appearance.colors.colLayer3, 1)
                            onClicked: {
                                if (armed)
                                    ClaudeCode.deleteSession(item.entry.session.id);
                                armed = !armed;
                            }
                            Timer {
                                running: deleteButton.armed
                                interval: 3000
                                onTriggered: deleteButton.armed = false
                            }
                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                horizontalAlignment: Text.AlignHCenter
                                text: deleteButton.armed ? "delete" : "close"
                                iconSize: Appearance.font.pixelSize.normal
                                color: deleteButton.armed ? Appearance.colors.colOnErrorContainer : deleteButton.running ? Appearance.colors.colOutlineVariant : Appearance.colors.colSubtext
                            }
                            StyledToolTip {
                                text: deleteButton.running ? Translation.tr("Running elsewhere, stop it first") : deleteButton.armed ? Translation.tr("Click again to delete") : Translation.tr("Delete session")
                            }
                        }
                        RippleButton { // Close a session that is open in the sidebar
                            visible: item.entry.kind === "open"
                            implicitWidth: 28
                            implicitHeight: 28
                            buttonRadius: Appearance.rounding.full
                            onClicked: ClaudeCode.closeSession(item.entry.key)
                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                horizontalAlignment: Text.AlignHCenter
                                text: "close"
                                iconSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colSubtext
                            }
                            StyledToolTip {
                                text: Translation.tr("Close session")
                            }
                        }
                    }
                }
            }
        }
    }

    MaterialLoadingIndicator {
        visible: ClaudeCode.sessionsLoading && ClaudeCode.recentSessions.length === 0
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 12
        implicitSize: 28
    }
}
