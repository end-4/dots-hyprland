import QtQuick
import qs.modules.common
import qs.modules.ii.island

/**
 * Invisible spacer in the bar. Reserves room for an island and tells IslandState
 * where it is; the islands themselves are drawn by the overlay window.
 * role "main": the main island (fixed width). role "dj": the music island, which
 * only takes space while music is recent, so it can split off and merge back.
 */
Item {
    id: root
    property string screenName: ""
    property string role: "main"
    readonly property real inset: 4 // same vertical inset as BarGroup backgrounds
    readonly property bool djActive: IslandState.djActive

    implicitWidth: role === "dj" ? (djActive ? 210 : 0) : 220
    implicitHeight: Appearance.sizes.baseBarHeight
    Behavior on implicitWidth {
        NumberAnimation { duration: 550; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.38, 1.21, 0.22, 1, 1, 1] }
    }

    function report() {
        if (!root.screenName)
            return;
        const p = root.mapToItem(null, 0, 0);
        const key = root.role === "dj" ? root.screenName + ":dj" : root.screenName;
        IslandState.setSlot(key, p.x, p.y + root.inset, root.visible ? root.width : 0, root.height - root.inset * 2);
    }

    onXChanged: report()
    onWidthChanged: report()
    onVisibleChanged: report()
    onScreenNameChanged: report()
    Component.onCompleted: report()

    // Ancestors (the centred middle row) move without notifying us; re-check cheaply.
    Timer {
        interval: 500
        repeat: true
        running: root.visible
        onTriggered: root.report()
    }
    // While a slot animates (DJ splitting off / merging), track it closely so the pills follow.
    Timer {
        interval: 16
        repeat: true
        running: root.visible && IslandState.djAnimating
        onTriggered: root.report()
    }
}
