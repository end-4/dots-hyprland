pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs.modules.ii.island

// Controls for every audio source. Opens with the active source (the one making
// sound, as MprisController decides) on the left and the others to its right, the
// next one peeking in. Scrolling only browses the cards so each source can be
// controlled on its own; it never changes which source is active.
Column {
    id: root
    width: 352
    spacing: 6

    readonly property int count: order.count
    readonly property bool multi: count > 1
    readonly property real cardW: multi ? width * 0.9 : width

    // Sources as dbus names, active first (fixed while the player is open).
    ListModel {
        id: order
    }

    function playerFor(name: string): var {
        return MprisController.players.find(p => p.dbusName === name) ?? null;
    }
    function indexOfName(name: string): int {
        for (let i = 0; i < order.count; i++)
            if (order.get(i).name === name)
                return i;
        return -1;
    }

    function build(): void {
        order.clear();
        const active = MprisController.activePlayer?.dbusName ?? "";
        if (active && root.playerFor(active))
            order.append({ name: active });
        for (const p of MprisController.players)
            if (p.dbusName !== active)
                order.append({ name: p.dbusName });
        list.currentIndex = 0;
        list.positionViewAtBeginning();
    }

    // A source appeared or went away: keep the order, append newcomers at the end.
    function syncPlayers(): void {
        const names = MprisController.players.map(p => p.dbusName);
        for (let i = order.count - 1; i >= 0; i--)
            if (names.indexOf(order.get(i).name) < 0)
                order.remove(i);
        for (const n of names)
            if (root.indexOfName(n) < 0)
                order.append({ name: n });
    }

    function go(i: int): void {
        if (i >= 0 && i < order.count)
            list.currentIndex = i;
    }

    Component.onCompleted: build()
    Connections {
        target: MprisController
        function onPlayersChanged(): void {
            Qt.callLater(root.syncPlayers);
        }
    }

    Timer {
        id: wheelCooldown
        interval: 380
    }

    ListView {
        id: list
        width: root.width
        height: currentItem ? currentItem.height : 56
        clip: true
        orientation: ListView.Horizontal
        spacing: 8
        model: order
        interactive: root.multi
        snapMode: ListView.SnapOneItem
        highlightRangeMode: ListView.StrictlyEnforceRange
        preferredHighlightBegin: 0
        preferredHighlightEnd: root.cardW
        highlightMoveDuration: 350
        highlightMoveVelocity: -1 // use the duration (smooth slide), not a fixed speed
        boundsBehavior: Flickable.StopAtBounds

        // The blurred background follows the card you're looking at.
        onCurrentIndexChanged: {
            const p = currentIndex >= 0 && currentIndex < order.count ? root.playerFor(order.get(currentIndex).name) : null;
            IslandState.viewedArtUrl = p?.trackArtUrl ?? "";
        }

        // Mouse wheel (either axis) slides one card, with a cooldown so a
        // touchpad's momentum doesn't skip several at once.
        WheelHandler {
            enabled: root.multi
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: event => {
                if (wheelCooldown.running)
                    return;
                const d = Math.abs(event.angleDelta.x) > Math.abs(event.angleDelta.y) ? event.angleDelta.x : event.angleDelta.y;
                if (d === 0)
                    return;
                root.go(list.currentIndex + (d < 0 ? 1 : -1));
                wheelCooldown.restart();
            }
        }

        delegate: Item {
            id: slot
            required property string name
            required property int index
            readonly property var player: root.playerFor(name)
            readonly property bool isCurrent: index === list.currentIndex

            width: root.cardW
            height: card.implicitHeight

            // Neighbours read as separate cards; the one in view sits on the island.
            Rectangle {
                anchors.fill: parent
                radius: 18
                color: Appearance.colors.colLayer2
                opacity: slot.isCurrent ? 0 : 1
                Behavior on opacity { NumberAnimation { duration: 250 } }
            }

            MusicCard {
                id: card
                visible: slot.player !== null
                player: slot.player
                anchors.fill: parent
                anchors.leftMargin: slot.isCurrent ? 0 : 12
                anchors.rightMargin: slot.isCurrent ? 0 : 12
                Behavior on anchors.leftMargin { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                Behavior on anchors.rightMargin { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
            }

            // Tapping a peeking card slides it into view.
            MouseArea {
                anchors.fill: parent
                enabled: !slot.isCurrent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.go(slot.index)
            }
        }
    }

    // Page dots, one per card in view order; the card being looked at is highlighted.
    Item {
        visible: root.multi
        width: root.width
        height: 5

        Row {
            anchors.centerIn: parent
            spacing: 6
            Repeater {
                model: order
                Rectangle {
                    id: dot
                    required property int index
                    readonly property bool active: index === list.currentIndex
                    width: active ? 14 : 5
                    height: 5
                    radius: 2.5
                    color: active ? Appearance.colors.colPrimary : Appearance.colors.colSecondaryContainer
                    Behavior on width { NumberAnimation { duration: 200 } }

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -4
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.go(dot.index)
                    }
                }
            }
        }
    }
}
