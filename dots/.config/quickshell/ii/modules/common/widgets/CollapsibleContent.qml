import qs.modules.common
import QtQuick
import QtQuick.Layouts

/**
 * Clipping window for content that collapses to nothing, or to a peek of itself. Anchor the
 * content to an edge, not filling, and set contentHeight to its own height. Bottom anchor
 * slides it away; top anchor suits content that also grows while expanded, which a bottom
 * anchor pushes out of view, and is the one that can show a peek.
 */
Item {
    id: root
    property bool collapsed: false
    property real contentHeight: 0
    // How much stays visible while collapsed
    property real collapsedHeight: 0
    property var animation: Appearance?.animation.elementMoveFast
    // Off while content is still arriving, so growth isn't animated as a collapse
    property bool animated: true

    Layout.fillWidth: true
    clip: true
    implicitHeight: root.collapsed ? root.collapsedHeight : root.contentHeight

    Behavior on implicitHeight {
        enabled: root.animated
        NumberAnimation {
            duration: root.animation.duration
            easing.type: root.animation.type
            easing.bezierCurve: root.animation.bezierCurve
        }
    }
}
