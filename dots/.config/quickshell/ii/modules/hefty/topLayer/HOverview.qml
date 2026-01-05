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
    property real contentWidth: root.screenWidth * 0.9
    property real horizontalGap: (root.screenWidth - contentWidth) / 2

    // Background
    backgroundPolygon: {
        const bottom = Config.options.bar.bottom
        const topY = bottom ? (root.screenHeight - edgeGap - contentHeight) : edgeGap
        const bottomY = bottom ? (root.screenHeight - edgeGap) : (edgeGap + contentHeight)
        const points = [
            // bottom-middle
            new MaterialShapes.PointNRound(new Offset.Offset(root.screenWidth / 2, bottomY), new CornerRounding.CornerRounding(0)),
            // bottom-left
            new MaterialShapes.PointNRound(new Offset.Offset(horizontalGap + rounding, bottomY), new CornerRounding.CornerRounding(rounding)),
            new MaterialShapes.PointNRound(new Offset.Offset(horizontalGap, bottomY), new CornerRounding.CornerRounding(rounding)),
            new MaterialShapes.PointNRound(new Offset.Offset(horizontalGap, bottomY - rounding), new CornerRounding.CornerRounding(rounding)),
            // top-left
            new MaterialShapes.PointNRound(new Offset.Offset(horizontalGap, topY + rounding), new CornerRounding.CornerRounding(rounding)),
            new MaterialShapes.PointNRound(new Offset.Offset(horizontalGap, topY), new CornerRounding.CornerRounding(rounding)),
            new MaterialShapes.PointNRound(new Offset.Offset(horizontalGap + rounding, topY), new CornerRounding.CornerRounding(rounding)),
            // top-middle
            new MaterialShapes.PointNRound(new Offset.Offset(root.screenWidth / 2, topY), new CornerRounding.CornerRounding(0)),
            // top-right
            new MaterialShapes.PointNRound(new Offset.Offset(root.screenWidth - horizontalGap - rounding, topY), new CornerRounding.CornerRounding(rounding)),
            new MaterialShapes.PointNRound(new Offset.Offset(root.screenWidth - horizontalGap, topY), new CornerRounding.CornerRounding(rounding)),
            new MaterialShapes.PointNRound(new Offset.Offset(root.screenWidth - horizontalGap, topY + rounding), new CornerRounding.CornerRounding(rounding)),

            // bottom-right
            new MaterialShapes.PointNRound(new Offset.Offset(root.screenWidth - horizontalGap, bottomY - rounding), new CornerRounding.CornerRounding(rounding)),
            new MaterialShapes.PointNRound(new Offset.Offset(root.screenWidth - horizontalGap, bottomY), new CornerRounding.CornerRounding(rounding)),
            new MaterialShapes.PointNRound(new Offset.Offset(root.screenWidth - horizontalGap - rounding, bottomY), new CornerRounding.CornerRounding(rounding)),
        ]
        return MaterialShapes.customPolygon(points, 1, new Offset.Offset(root.screenWidth / 2, edgeGap + contentHeight / 2))
    }

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

    Connections {
        target: GlobalStates
        function onOverviewOpenChanged() {
            if (GlobalStates.overviewOpen) {
                root.requestFocus();
            } else {
                root.dismissed();
            }
        }
    }
}