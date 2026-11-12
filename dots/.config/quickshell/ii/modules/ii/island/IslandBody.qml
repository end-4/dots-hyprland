pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.functions
import qs.modules.ii.island
import qs.modules.common.widgets
import qs.services
import qs.modules.ii.island.cards

/**
 * The island itself. Resting: sits exactly over this screen's bar slot.
 * Dropped: detaches, falls below the bar and widens into a card.
 */
Item {
    id: root
    anchors.fill: parent

    property string screenName: ""
    readonly property var slot: IslandState.slots[screenName] ?? null
    readonly property bool hasSlot: slot !== null && slot.width > 1

    // Clicking the resting pill opens the full player on this screen only.
    property bool hoverOpen: false
    property string openKind: "music" // what a click/long-press opened: "music", "overview" or "toggles"
    property bool heldOpen: false // a long-press just opened toggles: swallow the click that follows
    Connections {
        target: IslandState
        function onCardRequested(kind) {
            if (!root.isTarget || !root.hasSlot)
                return;
            if (kind === "player") {
                root.djOpen = root.djShown;
                return;
            }
            root.openKind = kind;
            root.hoverOpen = true;
        }
        function onCardCloseRequested() {
            root.hoverOpen = false;
            root.djOpen = false;
        }
    }
    readonly property bool pointerOver: hover.hovered || cardHover.hovered
    onPointerOverChanged: pointerOver ? closeTimer.stop() : (hoverOpen && closeTimer.restart())
    onHoverOpenChanged: {
        if (hoverOpen && !pointerOver)
            closeTimer.restart();
        if (!hoverOpen)
            IslandState.viewedArtUrl = "";
    }
    readonly property var ev: IslandState.main
    // Drop on the focused monitor; if Hyprland hasn't reported one, use the first screen.
    readonly property bool isTarget: IslandState.focusedScreen !== "" ? IslandState.focusedScreen === screenName : Quickshell.screens[0]?.name === screenName
    // Full player open: by click/hover, or forced via IslandState.openPlayer() on the focused screen.
    readonly property bool playerOpen: hoverOpen
    readonly property bool dropped: (ev !== null && isTarget) || playerOpen
    readonly property string kind: dropped ? (ev !== null && isTarget ? ev.kind : (hoverOpen ? openKind : "overview")) : ""
    readonly property bool compactCard: false

    property alias islandItem: island
    property alias bubbleItem: bubble
    property alias hoverBridge: bridge

    readonly property real dropTop: Appearance.sizes.baseBarHeight + 14
    readonly property var curve: [0.38, 1.21, 0.22, 1, 1, 1]

    // Unread notifications: a soft, slowly breathing glow around the resting pill.
    // Stepped at ~7 fps (not a continuous animation) to stay cheap, and only for two breaths
    // after each new notification; then it holds still (unread can stay > 0 for hours).
    readonly property bool glowing: IslandState.unread > 0 &&!root.dropped && root.hasSlot && root.isTarget
    readonly property int glowStopTick: 57 // sin(57 * 0.22) ≈ 0: rests at the mid glow
    property int glowTick: 0
    Timer {
        interval: 140
        repeat: true
        running: root.glowing && root.glowTick < root.glowStopTick
        onTriggered: root.glowTick++
    }
    Connections {
        target: Notifications
        function onUnreadChanged() {
            root.glowTick = 0;
        }
    }
    StyledRectangularShadow {
        target: island
        blur: 14
        spread: 1
        offset: Qt.vector2d(0, 0)
        color: Appearance.colors.colPrimary
        visible: opacity > 0.01
        opacity: root.glowing ? 0.18 + 0.22 * (0.5 + 0.5 * Math.sin(root.glowTick * 0.22)) : 0
        Behavior on opacity { enabled: !root.glowing; NumberAnimation { duration: 300 } }
    }

    StyledRectangularShadow {
        target: island
        opacity: root.dropped ? 1 : 0
        Behavior on opacity {
            NumberAnimation { duration: 400 }
        }
    }

    Rectangle {
        id: island
        color: Appearance.colors.colLayer1Base
        clip: true
        opacity: (root.dropped || root.hasSlot) ? 1 : 0
        Behavior on opacity {
            NumberAnimation { duration: 200 }
        }

        readonly property real cardW: 380 // fixed: long titles/bodies elide instead of widening the card
        readonly property real cardH: root.compactCard ? 40 : Math.max(76, cardLoader.implicitHeight + 24)

        width: root.dropped ? cardW : (root.hasSlot ? root.slot.width : 0)
        height: root.dropped ? cardH : (root.hasSlot ? root.slot.height : 32)
        x: root.dropped ? (root.width - cardW) / 2 : (root.hasSlot ? root.slot.x : root.width / 2)
        y: root.dropped ? root.dropTop : (root.hasSlot ? root.slot.y : 4)
        radius: root.dropped ? (root.compactCard ? height / 2 : 26) : height / 2

        Behavior on x { NumberAnimation { duration: 550; easing.type: Easing.BezierSpline; easing.bezierCurve: root.curve } }
        Behavior on y { NumberAnimation { duration: 550; easing.type: Easing.BezierSpline; easing.bezierCurve: root.curve } }
        Behavior on width { NumberAnimation { duration: 550; easing.type: Easing.BezierSpline; easing.bezierCurve: root.curve } }
        Behavior on height { NumberAnimation { duration: 550; easing.type: Easing.BezierSpline; easing.bezierCurve: root.curve } }
        Behavior on radius { NumberAnimation { duration: 550 } }


        RestingPill {
            id: restingPill
            anchors.fill: parent
            allowMusic: false // music lives in the DJ pill
            paused: hover.hovered
            interactive: !root.dropped
            z: 2 // above the pill's click area so the logo gets hover/click
            onLogoHovered: hovered => {
                feedTimer.running = hovered;
                if (!hovered)
                    root.feedOpen = false;
            }
            animate: root.isTarget
            opacity: root.dropped ? 0 : 1
            Behavior on opacity {
                NumberAnimation { duration: 250 }
            }
        }

        // Dropped notification: the whole card is clickable, not just its text row.
        // Declared before the Loader so the card's own chips stay on top of it.
        MouseArea {
            anchors.fill: parent
            enabled: root.dropped && root.kind === "notif"
            cursorShape: Qt.PointingHandCursor
            onClicked: cardLoader.item?.activate()
        }

        Loader {
            id: cardLoader
            anchors.centerIn: parent
            active: root.kind !== ""
            opacity: root.dropped ? 1 : 0
            Behavior on opacity {
                SequentialAnimation {
                    PauseAnimation { duration: cardLoader.opacity < 0.5 ? 200 : 0 }
                    NumberAnimation { duration: 250 }
                }
            }
            sourceComponent: {
                switch (root.kind) {
                case "notif": return notifCard;
                case "info": return infoCard;
                case "toggles": return togglesCard;
                case "overview": return overviewCard;
                }
                return null;
            }
        }

        // Resting pill: left toggles the player, middle play/pause, right/forward next, back previous.
        MouseArea {
            anchors.fill: parent
            enabled: !root.dropped
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton | Qt.BackButton | Qt.ForwardButton
            pressAndHoldInterval: 450
            onPressed: root.heldOpen = false
            onPressAndHold: mouse => {
                if (mouse.button !== Qt.LeftButton)
                    return;
                root.heldOpen = true;
                root.openKind = "toggles";
                root.hoverOpen = true;
            }
            onClicked: mouse => {
                switch (mouse.button) {
                case Qt.MiddleButton:
                    MprisController.togglePlaying();
                    break;
                case Qt.RightButton:
                case Qt.ForwardButton:
                    MprisController.next();
                    break;
                case Qt.BackButton:
                    MprisController.previous();
                    break;
                default:
                    if (root.heldOpen) {
                        root.heldOpen = false;
                        return;
                    }
                    // An activity / idle glance with an action handles the click.
                    if (restingPill.mode === "activity" && (restingPill.act?.command ?? []).length > 0)
                        Quickshell.execDetached(restingPill.act.command);
                    else {
                        // Overview: audio sources + notifications + actions.
                        root.openKind = "overview";
                        root.hoverOpen = !root.hoverOpen;
                    }
                }
            }
        }

    }


    // ---------------------------------------------------------------------------
    // DJ: the music island. While music is recent it splits off the main island and
    // slides into its own bar slot on the left; afterwards it merges back.
    readonly property var djSlot: IslandState.slots[screenName + ":dj"] ?? null
    readonly property bool djShown: IslandState.djActive && djSlot !== null && djSlot.width > 1
    property bool djOpen: false
    readonly property bool djDropped: djShown && djOpen
    property alias djItem: dj
    onDjOpenChanged: {
        if (djOpen && !djHover.hovered)
            djClose.restart();
        if (!djOpen)
            IslandState.viewedArtUrl = "";
    }
    onDjShownChanged: if (!djShown) djOpen = false
    Timer {
        id: djClose
        interval: 4000 // close the player 4 s after opening / leaving it
        onTriggered: root.djOpen = false
    }

    StyledRectangularShadow {
        target: dj
        opacity: root.djDropped ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 400 } }
    }

    Rectangle {
        id: dj
        color: Appearance.colors.colLayer1Base
        clip: true
        readonly property real cardW: 380
        readonly property real cardH: Math.max(76, djLoader.implicitHeight + 24)
        // Merged: tucked behind the main island's centre. Out: its own slot. Open: card under it.
        readonly property real mergedX: root.hasSlot ? root.slot.x + root.slot.width * 0.3 : root.width / 2
        readonly property real mergedW: root.hasSlot ? root.slot.width * 0.4 : 0

        width: root.djDropped ? cardW : (root.djShown ? root.djSlot.width : mergedW)
        height: root.djDropped ? cardH : (root.djSlot ? root.djSlot.height : (root.hasSlot ? root.slot.height : 32))
        x: root.djDropped ? Math.max(8, Math.min(root.width - cardW - 8, root.djSlot.x + root.djSlot.width / 2 - cardW / 2)) : (root.djShown ? root.djSlot.x : mergedX)
        y: root.djDropped ? root.dropTop : (root.djSlot ? root.djSlot.y : (root.hasSlot ? root.slot.y : 4))
        radius: root.djDropped ? 26 : height / 2
        opacity: root.djShown ? 1 : 0
        visible: opacity > 0.01
        z: -1 // slides out from behind the main island

        Behavior on x { NumberAnimation { duration: 550; easing.type: Easing.BezierSpline; easing.bezierCurve: root.curve } }
        Behavior on y { NumberAnimation { duration: 550; easing.type: Easing.BezierSpline; easing.bezierCurve: root.curve } }
        Behavior on width { NumberAnimation { duration: 550; easing.type: Easing.BezierSpline; easing.bezierCurve: root.curve } }
        Behavior on height { NumberAnimation { duration: 550; easing.type: Easing.BezierSpline; easing.bezierCurve: root.curve } }
        Behavior on radius { NumberAnimation { duration: 550 } }
        Behavior on opacity { NumberAnimation { duration: 350 } }

        // Blurred album art behind the open player, clipped to the rounded shape.
        Item {
            id: artBg
            anchors.fill: parent
            readonly property string artUrl: IslandState.viewedArtUrl || (MprisController.activeTrack?.artUrl ?? "")
            readonly property bool wanted: root.djDropped && artUrl.length > 0
            opacity: wanted ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 250 } }
            visible: opacity > 0
            layer.enabled: visible
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: dj.width
                    height: dj.height
                    radius: dj.radius
                }
            }
            Image {
                id: artImg
                anchors.fill: parent
                source: artBg.artUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize.width: 128
                sourceSize.height: 128
                visible: status === Image.Ready
                layer.enabled: visible
                layer.effect: MultiEffect {
                    source: artImg
                    blurEnabled: true
                    blurMax: 64
                    blur: 1.0
                }
            }
            Rectangle {
                anchors.fill: parent
                color: Appearance.colors.colLayer1Base
                opacity: 0.55
            }
        }

        // end-4's cava wave over the blurred art (like the stock media player), only while open and playing.
        Item {
            id: waveBg
            anchors.fill: parent
            readonly property bool wanted: root.djDropped && IslandConfig.equalizer && IslandState.cavaAvailable && (MprisController.activePlayer?.isPlaying ?? false)
            property list<real> points: []
            // On pause the wave settles to the floor instead of vanishing: the last frame
            // eases down to zero over decayMs (cava stops right away).
            property list<real> decayFrom: []
            property real decayStartedAt: 0
            readonly property int decayMs: 700
            function startDecay(): void {
                if (waveBg.points.length === 0)
                    return;
                waveBg.decayFrom = waveBg.points;
                waveBg.decayStartedAt = Date.now();
                decayTimer.start();
            }
            Timer {
                id: decayTimer
                interval: 33
                repeat: true
                onTriggered: {
                    const t = Math.min(1, (Date.now() - waveBg.decayStartedAt) / waveBg.decayMs);
                    const k = 1 - t * t * (3 - 2 * t); // smoothstep: soft start, soft landing
                    if (t >= 1) {
                        stop();
                        waveBg.points = [];
                        return;
                    }
                    waveBg.points = waveBg.decayFrom.map(v => v * k);
                }
            }
            opacity: root.djDropped && points.length > 0 ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 300 } }
            visible: opacity > 0
            layer.enabled: visible
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: dj.width
                    height: dj.height
                    radius: dj.radius
                }
            }

            Process {
                running: waveBg.wanted
                command: ["cava", "-p", FileUtils.trimFileProtocol(Qt.resolvedUrl("cava/island-wave.conf"))]
                onRunningChanged: if (!running) waveBg.startDecay()
                stdout: SplitParser {
                    onRead: data => {
                        decayTimer.stop();
                        waveBg.points = data.split(";").map(p => parseFloat(p.trim())).filter(p => !isNaN(p));
                    }
                }
            }

            WaveVisualizer {
                live: true // the decay above brings it down smoothly
                points: waveBg.points
                maxVisualizerValue: 1000
                smoothing: 2
                color: IslandState.accent.a > 0 ? IslandState.accent : Appearance.colors.colPrimary
            }
        }

        RestingPill {
            anchors.fill: parent
            djPill: true
            z: 2
            interactive: !root.djDropped
            animate: root.isTarget
            opacity: root.djDropped ? 0 : 1
            Behavior on opacity { NumberAnimation { duration: 250 } }
        }

        Loader {
            id: djLoader
            anchors.centerIn: parent
            active: root.djDropped
            opacity: root.djDropped ? 1 : 0
            Behavior on opacity {
                SequentialAnimation {
                    PauseAnimation { duration: djLoader.opacity < 0.5 ? 200 : 0 }
                    NumberAnimation { duration: 250 }
                }
            }
            sourceComponent: MusicCarousel {}
        }

        // Resting DJ: left opens the player, middle play/pause, right/forward next, back previous.
        MouseArea {
            anchors.fill: parent
            enabled: !root.djDropped
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton | Qt.BackButton | Qt.ForwardButton
            onClicked: mouse => {
                switch (mouse.button) {
                case Qt.MiddleButton:
                    MprisController.togglePlaying();
                    break;
                case Qt.RightButton:
                case Qt.ForwardButton:
                    MprisController.next();
                    break;
                case Qt.BackButton:
                    MprisController.previous();
                    break;
                default:
                    root.djOpen = !root.djOpen;
                }
            }
        }
        // Open player: right/back/forward skip tracks; left falls through to the card's buttons.
        MouseArea {
            anchors.fill: parent
            enabled: root.djDropped
            acceptedButtons: Qt.RightButton | Qt.BackButton | Qt.ForwardButton
            onClicked: mouse => {
                if (mouse.button === Qt.BackButton)
                    MprisController.previous();
                else
                    MprisController.next();
            }
        }
        HoverHandler {
            id: djHover
            onHoveredChanged: hovered ? djClose.stop() : (root.djOpen && djClose.restart())
        }
    }

    // Covers the resting slot and the card while hover-opened, so moving the
    // cursor from the bar down to the card doesn't close it. Only the slot's own
    // columns: the card is wider, and the bar row beside the slot holds the DJ
    // and the workspace buttons, which must stay clickable.
    Item {
        id: bridge
        x: root.hoverOpen && root.hasSlot ? root.slot.x : island.x
        y: root.hoverOpen && root.hasSlot ? root.slot.y : island.y
        width: root.hoverOpen && root.hasSlot ? root.slot.width : island.width
        height: root.hoverOpen && root.hasSlot ? (island.y + island.height) - y : island.height
        HoverHandler {
            id: hover
            enabled: root.ev === null || root.hoverOpen
        }
    }

    // The open card is wider than the slot and centred on the screen, so it needs its own
    // hover area. A sibling on top, not a handler on the card: hover-enabled controls inside
    // the card would otherwise take the hover away from it.
    Item {
        x: island.x
        y: island.y
        width: island.width
        height: island.height
        HoverHandler {
            id: cardHover
            enabled: root.hoverOpen
        }
    }

    Timer {
        id: closeTimer
        interval: 4000 // close the player 4 s after opening / leaving it
        onTriggered: root.hoverOpen = false
    }

    // Hovering the Claude logo shows the last few things Claude did.
    property bool feedOpen: false
    property alias feedItem: feed
    Timer {
        id: feedTimer
        interval: 350
        onTriggered: root.feedOpen = IslandState.claudeFeed.length > 0
    }
    // Hover-leave events can get lost (focus changes, windows resizing), so the
    // feed also closes on its own.
    onFeedOpenChanged: if (feedOpen) feedAutoClose.restart()
    Timer {
        id: feedAutoClose
        interval: 4000
        onTriggered: root.feedOpen = false
    }
    ClaudeFeed {
        id: feed
        visible: opacity > 0
        opacity: root.feedOpen && !root.dropped && root.isTarget ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        x: island.x + island.width - width
        y: island.y + island.height + 8
    }

    // Claude bursts: confetti when it finishes, "?" when it needs permission.
    // Thrown from the logo in the bar, on the focused screen.
    property alias confettiActive: confetti.active
    Confetti {
        id: confetti
        anchors.fill: parent
        z: 10
    }
    function agentBurst(kind) {
        if (!root.isTarget)
            return;
        const p = restingPill.mapToItem(root, restingPill.slotCenter.x, restingPill.slotCenter.y);
        confetti.burst(p.x, p.y, kind);
    }
    Connections {
        target: IslandState
        function onClaudeBurst(kind) {
            root.agentBurst(kind);
        }
        function onOpencodeBurst(kind) {
            if (kind !== "pop") // a retry only pops the logo in the pill
                root.agentBurst(kind);
        }
    }

    MusicBubble {
        id: bubble
        visible: false // DJ stays in the bar, so no music bubble beside cards
        x: island.x + island.width + 8
        y: island.y + (island.height - height) / 2
    }

    Component {
        id: overviewCard
        OverviewCard {
            onDone: root.hoverOpen = false
        }
    }
    Component {
        id: togglesCard
        TogglesCard {
            onDone: root.hoverOpen = false
        }
    }
    Component {
        id: infoCard
        InfoCard {
            ev: root.ev
        }
    }
    Component {
        id: notifCard
        NotificationCard {
            ev: root.ev
            extra: IslandState.extra
        }
    }
}
