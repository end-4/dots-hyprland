import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import "../../common"
import "../../common/widgets/shapes" as S
import "../../common/widgets/shapes/material-shapes.js" as MaterialShapes
import "../../common/widgets/shapes/shapes/corner-rounding.js" as CornerRounding
import "../../common/widgets/shapes/geometry/offset.js" as Offset

import "bar"

/**
 * Fullscreen layer. Uses masking to not block clicks on windows n' stuff.
 */
PanelWindow {
    id: root

    ///////////////// Window //////////////////
    color: "transparent"
    WlrLayershell.namespace: "quickshell:topLayerPanel"
    exclusionMode: ExclusionMode.Ignore
    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    mask: Region {
        item: root.currentPanel
    }
    // HyprlandWindow.visibleMask: mask // TODO: use this later to optimize hyprland's rendering

    ///////////////// Content //////////////////

    property alias roundedPolygon: backgroundShape.roundedPolygon
    property bool finishedMorphing: true
    onRoundedPolygonChanged: finishedMorphing = false
    Connections {
        target: backgroundShape
        function onProgressChanged() {
            // While it overshoots because of the spring animation, waiting for the bounce to finish entirely would be too slow
            // ^ (totally not an excuse for my laziness)
            if (backgroundShape.progress >= 1.0) {
                root.finishedMorphing = true
            }
        }
    }
    S.ShapeCanvas {
        id: backgroundShape
        anchors.fill: parent
        polygonIsNormalized: false
        roundedPolygon: MaterialShapes.customPolygon([new MaterialShapes.PointNRound(new Offset.Offset(root.screen.width, 0), new CornerRounding.CornerRounding(9999)),])
        // animation: NumberAnimation {
        //     duration: 500
        //     easing.type: Easing.BezierSpline
        //     easing.bezierCurve: Appearance.animationCurves.expressiveDefaultSpatial
        // }
        animation: SpringAnimation {
            spring: 3.5
            damping: 0.35
        }
        color: Appearance.colors.colLayer0
        borderWidth: (root.currentPanel === bar && Config.options.bar.cornerStyle !== 1) ? 0 : 1
        borderColor: Appearance.colors.colLayer0Border
        visible: false // cuz there's already the shadow
        debug: true
    }
    DropShadow {
        id: shadow
        source: backgroundShape
        anchors.fill: backgroundShape
        radius: 10
        samples: radius * 2 + 1 // Ideally radius * 2 + 1, see qt docs
        color: "#44000000"
    }

    property HAbstractMorphedPanel currentPanel: null
    Component.onCompleted: currentPanel = bar
    roundedPolygon: currentPanel.backgroundPolygon

    // Do we want to have reserved area always follow the bar or maybe differ per panel?
    EdgeReservedArea {
        anchors.top: true
        exclusiveZone: bar.reservedTop
    }
    EdgeReservedArea {
        anchors.bottom: true
        exclusiveZone: bar.reservedBottom
    }
    EdgeReservedArea {
        anchors.left: true
        exclusiveZone: bar.reservedLeft
    }
    EdgeReservedArea {
        anchors.right: true
        exclusiveZone: bar.reservedRight
    }

    ////////////// Content: Panels ///////////////

    function dismiss() {
        root.currentPanel = bar;
    }

    HBar {
        id: bar
        load: root.currentPanel === this && root.finishedMorphing // the extra condition is to prevent workspace widget from acting up when switching horizontal/vertical... should be fixed later
        shown: root.finishedMorphing
    }

    HOverview {
        id: overview
        load: root.currentPanel === this
        shown: root.finishedMorphing
        onRequestFocus: root.currentPanel = overview;
        onDismissed: root.dismiss();
    }

    //////////////// Components /////////////////

    component EdgeReservedArea: PanelWindow {
        WlrLayershell.namespace: "quickshell:edgeReservedArea"
        implicitWidth: 0
        implicitHeight: 0
        mask: Region {
            item: null
        }
    }
}
