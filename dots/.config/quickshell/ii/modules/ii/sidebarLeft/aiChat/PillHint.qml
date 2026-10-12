import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls

/**
 * Explains the pill it hangs off, in the card's own colours rather than a tooltip's dark bubble,
 * so it reads as part of the question. Floats instead of taking layout space, so the pills hold
 * still. Set extraVisibleCondition when the parent has no `hovered` of its own.
 */
ToolTip {
    id: root
    property bool extraVisibleCondition: true
    // A comfortable line length to read a sentence or two at, not however much room happens to
    // be going: the sidebar being extended should not stretch this into one long line
    property real maximumTextWidth: 400
    readonly property real fittedTextWidth: root.bounds
        ? Math.min(root.maximumTextWidth, root.bounds.width - root.padding * 2)
        : root.maximumTextWidth

    // Held inside this item, not the window: the left sidebar's window is far wider than the
    // panel you can see, so the popup's own fitting would still leave it over the desktop
    property Item bounds

    readonly property bool internalVisibleCondition: extraVisibleCondition
        && (parent?.hovered === undefined || parent?.hovered)
    visible: internalVisibleCondition && root.text.length > 0
    delay: 0
    padding: 8
    y: parent.height + 4
    // Centered on the pill, then slid back inside bounds if that would hang over an edge.
    // Recomputed on show rather than bound: mapToItem reads live positions instead of properties,
    // so a binding would keep whatever the layout looked like when the pill was created — which
    // for a pill in the Flow's second row is its spot before the row wrapped
    function updatePosition() {
        const centred = (parent.width - root.width) / 2;
        const origin = root.bounds ? parent.mapToItem(root.bounds, 0, 0) : null;
        if (!origin) {
            root.x = centred;
            return;
        }
        const left = origin.x + centred;
        const maxLeft = Math.max(0, root.bounds.width - root.width);
        root.x = centred + (Math.min(Math.max(left, 0), maxLeft) - left);
    }
    onVisibleChanged: if (visible) Qt.callLater(root.updatePosition)
    onWidthChanged: if (visible) Qt.callLater(root.updatePosition)
    // Sized from the label, which keeps its own width: the popup assigns its content item's
    // width, so a label bound to that would feed back into this
    width: implicitContentWidth + leftPadding + rightPadding

    background: Item {
        StyledRectangularShadow {
            target: hintBackground
        }
        Rectangle {
            id: hintBackground
            anchors.fill: parent
            color: Appearance.m3colors.m3surfaceContainer
            radius: Appearance.rounding.small

            border.width: 1
            border.color: Appearance.colors.colLayer0Border
        }
    }

    // Sized from the widest line the label actually lays out, so the box loses the slack on the
    // right without moving any break: wrapping happens at the full width, keeping early lines full
    contentItem: Item {
        implicitWidth: label.contentWidth
        implicitHeight: label.contentHeight

        StyledText {
            id: label
            width: root.fittedTextWidth
            wrapMode: Text.Wrap
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colSubtext
            text: root.text
        }
    }

    // Grows and fades like the shell's other tooltips, but leaves the same way instead of
    // blinking out. Scale rather than size: the width is bound, so a transition cannot drive it
    enter: Transition {
        NumberAnimation {
            property: "opacity"
            from: 0
            to: 1
            duration: Appearance.animation.elementMoveFast.duration
            easing.type: Appearance.animation.elementMoveFast.type
            easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
        }
        NumberAnimation {
            property: "scale"
            from: 0.9
            to: 1
            duration: Appearance.animation.elementMoveFast.duration
            easing.type: Appearance.animation.elementMoveFast.type
            easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
        }
    }
    exit: Transition {
        NumberAnimation {
            property: "opacity"
            from: 1
            to: 0
            duration: Appearance.animation.elementMoveFast.duration
            easing.type: Appearance.animation.elementMoveFast.type
            easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
        }
        NumberAnimation {
            property: "scale"
            from: 1
            to: 0.9
            duration: Appearance.animation.elementMoveFast.duration
            easing.type: Appearance.animation.elementMoveFast.type
            easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
        }
    }
}
