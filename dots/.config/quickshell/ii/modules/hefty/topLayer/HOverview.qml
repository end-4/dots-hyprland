import QtQuick
import Quickshell.Hyprland
import qs
import qs.modules.common
import "../../common/widgets/shapes/material-shapes.js" as MaterialShapes
import "../../common/widgets/shapes/shapes/corner-rounding.js" as CornerRounding
import "../../common/widgets/shapes/geometry/offset.js" as Offset

HAbstractMorphedPanel {
    id: root

    // Own props
    property int edgeGap: Appearance.sizes.hyprlandGapsOut
    property real rounding: Appearance.rounding.windowRounding
    property real contentHeight: 300 // For now

    // Background
    backgroundPolygon: MaterialShapes.customPolygon([
        // bottom-middle
        new MaterialShapes.PointNRound(new Offset.Offset(root.screenWidth / 2, edgeGap + root.contentHeight), new CornerRounding.CornerRounding(0)),
        // bottom-left
        new MaterialShapes.PointNRound(new Offset.Offset(edgeGap + rounding, edgeGap + root.contentHeight), new CornerRounding.CornerRounding(rounding)),
        new MaterialShapes.PointNRound(new Offset.Offset(edgeGap, edgeGap + root.contentHeight), new CornerRounding.CornerRounding(rounding)),
        new MaterialShapes.PointNRound(new Offset.Offset(edgeGap, edgeGap + root.contentHeight - rounding), new CornerRounding.CornerRounding(rounding)),
        // top-left
        new MaterialShapes.PointNRound(new Offset.Offset(edgeGap, edgeGap + rounding), new CornerRounding.CornerRounding(rounding)),
        new MaterialShapes.PointNRound(new Offset.Offset(edgeGap, edgeGap), new CornerRounding.CornerRounding(rounding)),
        new MaterialShapes.PointNRound(new Offset.Offset(edgeGap + rounding, edgeGap), new CornerRounding.CornerRounding(rounding)),
        // top-middle
        new MaterialShapes.PointNRound(new Offset.Offset(root.screenWidth / 2, edgeGap), new CornerRounding.CornerRounding(0)),
        // top-right
        new MaterialShapes.PointNRound(new Offset.Offset(root.screenWidth - edgeGap - rounding, edgeGap), new CornerRounding.CornerRounding(rounding)),
        new MaterialShapes.PointNRound(new Offset.Offset(root.screenWidth - edgeGap, edgeGap), new CornerRounding.CornerRounding(rounding)),
        new MaterialShapes.PointNRound(new Offset.Offset(root.screenWidth - edgeGap, edgeGap + rounding), new CornerRounding.CornerRounding(rounding)),

        // bottom-right
        new MaterialShapes.PointNRound(new Offset.Offset(root.screenWidth - edgeGap, edgeGap + root.contentHeight - rounding), new CornerRounding.CornerRounding(rounding)),
        new MaterialShapes.PointNRound(new Offset.Offset(root.screenWidth - edgeGap, edgeGap + root.contentHeight), new CornerRounding.CornerRounding(rounding)),
        new MaterialShapes.PointNRound(new Offset.Offset(root.screenWidth - edgeGap - rounding, edgeGap + root.contentHeight), new CornerRounding.CornerRounding(rounding)),
    ], 1, new Offset.Offset(root.screenWidth / 2, edgeGap + contentHeight / 2))

    // Keybinds
    GlobalShortcut {
        name: "searchToggle"
        description: "Toggles search on press"

        onPressed: {
            GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
        }
    }
    GlobalShortcut {
        name: "searchToggleRelease"
        description: "Toggles search on release"

        onPressed: {
            GlobalStates.superReleaseMightTrigger = true;
        }

        onReleased: {
            if (!GlobalStates.superReleaseMightTrigger) {
                GlobalStates.superReleaseMightTrigger = true;
                return;
            }
            GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
        }
    }
    GlobalShortcut {
        name: "searchToggleReleaseInterrupt"
        description: "Interrupts possibility of search being toggled on release. " + "This is necessary because GlobalShortcut.onReleased in quickshell triggers whether or not you press something else while holding the key. " + "To make sure this works consistently, use binditn = MODKEYS, catchall in an automatically triggered submap that includes everything."

        onPressed: {
            GlobalStates.superReleaseMightTrigger = false;
        }
    }
}