import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Hyprland

/**
 * Alt+Tab window switcher.
 * Hold Alt and press Tab to move forward (Shift+Tab back, arrow keys, Enter; Esc cancels; click or hover with the
 * mouse); releasing Alt switches to the selected window.
 * - Lists the windows of every workspace in a fixed order: by workspace, then left to right (and top to bottom)
 *   inside it, so the cards don't reshuffle with every switch.
 * - Opens on the previously used window, so a quick Alt+Tab flips between the last two windows.
 * - Live previews; windows on another workspace get a badge with the workspace name.
 */
Scope {
    id: root

    property bool open: false
    property bool reverseOpen: false
    property var cards: [] // [{ address, title, cls, wsName, otherWs, toplevel, icon }]
    property int sel: 0
    property bool mouseArmed: false // don't select the card under the cursor just because the switcher opened there

    readonly property int cardWidth: 232
    readonly property int cardHeight: 170
    readonly property int cardGap: 12
    readonly property int boxPadding: 20
    readonly property int thumbWidth: 212
    readonly property int thumbHeight: 118

    function toplevelFor(address) {
        return ToplevelManager.toplevels.values.find(t => `0x${t.HyprlandToplevel?.address}` === address) ?? null;
    }

    function build() {
        // Special workspaces (negative ids) go last
        const wsKey = id => id < 0 ? 100000 - id : id;
        const list = HyprlandData.windowList
            .filter(w => w.mapped && !w.hidden && w.workspace && w.workspace.id !== -1)
            .sort((a, b) => wsKey(a.workspace.id) - wsKey(b.workspace.id) || a.at[0] - b.at[0] || a.at[1] - b.at[1]);
        const current = list.findIndex(w => w.focusHistoryID === 0);
        const previous = list.findIndex(w => w.focusHistoryID === 1); // the window used before the focused one
        const activeWs = HyprlandData.activeWorkspace?.id;
        root.cards = list.map(w => ({
            address: w.address,
            title: w.title || w.class,
            cls: w.class,
            wsName: w.workspace.name,
            otherWs: w.workspace.id !== activeWs,
            toplevel: root.toplevelFor(w.address),
            icon: Quickshell.iconPath(AppSearch.guessIcon(w.class), "image-missing")
        }));
        // Alt+Tab starts on the previously used window; Shift+Tab on the card before the focused one
        const n = root.cards.length;
        const from = current >= 0 ? current : 0;
        if (n <= 1) root.sel = 0;
        else if (!root.reverseOpen && previous >= 0) root.sel = previous;
        else root.sel = ((from + (root.reverseOpen ? -1 : 1)) % n + n) % n;
    }

    function openSwitcher(reverse) {
        root.reverseOpen = reverse;
        root.mouseArmed = false;
        root.build();
        if (root.cards.length === 0) return;
        root.open = true;
    }

    function step(d) {
        if (!root.open) {
            root.openSwitcher(d < 0);
            return;
        }
        const n = root.cards.length;
        if (n > 0) root.sel = ((root.sel + d) % n + n) % n;
    }

    function stepRow(dy, perRow) {
        const t = root.sel + dy * perRow;
        if (t >= 0 && t < root.cards.length) root.sel = t;
    }

    function commit() {
        if (!root.open) return;
        const card = root.cards[root.sel];
        root.close();
        if (!card) return;
        // Focus only after the layer is gone: when it unmaps, Hyprland gives keyboard focus back to the window that
        // had it before the switcher, and if that lands after our focus the window history (and Alt+Tab) gets mixed up
        focusLater.address = card.address;
        focusLater.restart();
    }

    function close() {
        root.open = false;
        root.cards = [];
    }

    Timer {
        id: focusLater
        property string address: ""
        interval: 60
        onTriggered: Hyprland.dispatch(`hl.dsp.focus({window = "address:${address}"})`)
    }

    Loader {
        id: switcherLoader
        active: root.open

        sourceComponent: PanelWindow {
            id: panel
            visible: root.open
            screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null
            color: "transparent"
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell:altSwitcher"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            readonly property int perRow: Math.max(1, Math.min(root.cards.length,
                Math.floor((width * 0.9 - 2 * root.boxPadding + root.cardGap) / (root.cardWidth + root.cardGap))))

            // A click outside cancels
            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }

            StyledRectangularShadow {
                target: box
            }
            Rectangle {
                id: box
                anchors.centerIn: parent
                width: panel.perRow * (root.cardWidth + root.cardGap) - root.cardGap + 2 * root.boxPadding
                height: grid.implicitHeight + 2 * root.boxPadding
                radius: Appearance.rounding.windowRounding
                color: Appearance.colors.colLayer0
                border.width: 1
                border.color: Appearance.colors.colLayer0Border

                MouseArea { // clicks inside the box don't cancel
                    anchors.fill: parent
                }

                focus: true
                Keys.onPressed: event => {
                    switch (event.key) {
                    case Qt.Key_Right: root.step(1); break;
                    case Qt.Key_Left: root.step(-1); break;
                    case Qt.Key_Down: root.stepRow(1, panel.perRow); break;
                    case Qt.Key_Up: root.stepRow(-1, panel.perRow); break;
                    case Qt.Key_Tab: root.step(1); break; // in case the bind reaches the layer
                    case Qt.Key_Backtab: root.step(-1); break;
                    case Qt.Key_Return:
                    case Qt.Key_Enter: root.commit(); break;
                    case Qt.Key_Escape: root.close(); break;
                    default: return;
                    }
                    event.accepted = true;
                }
                Keys.onReleased: event => {
                    if (event.key === Qt.Key_Alt || event.key === Qt.Key_AltGr) {
                        root.commit();
                        event.accepted = true;
                    }
                }

                Grid {
                    id: grid
                    anchors.centerIn: parent
                    columns: panel.perRow
                    spacing: root.cardGap

                    Repeater {
                        model: root.cards
                        delegate: Rectangle {
                            id: card
                            required property var modelData
                            required property int index
                            readonly property bool selected: index === root.sel
                            width: root.cardWidth
                            height: root.cardHeight
                            radius: Appearance.rounding.normal
                            color: selected ? Appearance.colors.colPrimaryContainer : Appearance.colors.colLayer1
                            border.color: selected ? Appearance.colors.colPrimary : "transparent"
                            border.width: selected ? 2 : 0
                            Behavior on color {
                                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                            }

                            Item {
                                x: (root.cardWidth - root.thumbWidth) / 2
                                y: 12
                                width: root.thumbWidth
                                height: root.thumbHeight

                                ScreencopyView {
                                    id: preview
                                    anchors.centerIn: parent
                                    // Stop capturing when the window closes while the switcher is open: capturing a
                                    // dead Wayland object crashes Quickshell
                                    readonly property bool alive: card.modelData.toplevel !== null
                                        && ToplevelManager.toplevels.values.indexOf(card.modelData.toplevel) >= 0
                                    captureSource: root.open && alive ? card.modelData.toplevel : null
                                    live: true
                                    visible: alive && hasContent
                                    // Keep the aspect ratio
                                    readonly property real k: sourceSize.width > 0 && sourceSize.height > 0
                                        ? Math.min(root.thumbWidth / sourceSize.width, root.thumbHeight / sourceSize.height) : 1
                                    width: sourceSize.width > 0 ? sourceSize.width * k : root.thumbWidth
                                    height: sourceSize.height > 0 ? sourceSize.height * k : root.thumbHeight
                                }
                                IconImage { // A large icon when there is no preview
                                    anchors.centerIn: parent
                                    visible: !preview.visible
                                    source: card.modelData.icon
                                    implicitSize: 56
                                }
                            }

                            RowLayout {
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    bottom: parent.bottom
                                    margins: 10
                                }
                                spacing: 6
                                IconImage {
                                    source: card.modelData.icon
                                    implicitSize: 22
                                }
                                StyledText {
                                    Layout.fillWidth: true
                                    text: card.modelData.title
                                    color: card.selected ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer1
                                    elide: Text.ElideRight
                                    font.pixelSize: Appearance.font.pixelSize.small
                                }
                                Rectangle { // Badge for a window on another workspace
                                    visible: card.modelData.otherWs
                                    radius: Appearance.rounding.full
                                    color: Appearance.colors.colSecondaryContainer
                                    implicitWidth: wsText.implicitWidth + 12
                                    implicitHeight: 18
                                    StyledText {
                                        id: wsText
                                        anchors.centerIn: parent
                                        text: card.modelData.wsName
                                        color: Appearance.colors.colOnSecondaryContainer
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onPositionChanged: {
                                    if (root.mouseArmed) root.sel = card.index;
                                    else root.mouseArmed = true;
                                }
                                onClicked: {
                                    root.sel = card.index;
                                    root.commit();
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "altSwitcher"

        function next(): void { root.step(1); }
        function prev(): void { root.step(-1); }
        function commit(): void { root.commit(); }
        function cancel(): void { root.close(); }
    }

    GlobalShortcut {
        name: "altSwitcherNext"
        description: "Alt+Tab switcher: open / next window"
        onPressed: root.step(1)
    }
    GlobalShortcut {
        name: "altSwitcherPrev"
        description: "Alt+Tab switcher: open / previous window"
        onPressed: root.step(-1)
    }
    GlobalShortcut {
        // The release of a transparent bind on Alt itself: caught even if Alt is released before the layer gets
        // keyboard focus, while applications still receive Alt
        name: "altSwitcherAlt"
        description: "Alt+Tab switcher: switch to the selection when Alt is released"
        onReleased: root.commit()
    }
}
