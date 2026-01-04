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
    S.ShapeCanvas {
        id: backgroundShape
        anchors.fill: parent
        polygonIsNormalized: false
        roundedPolygon: MaterialShapes.customPolygon([new MaterialShapes.PointNRound(new Offset.Offset(root.screen.width, 0), new CornerRounding.CornerRounding(9999)),])
        animation: NumberAnimation {
            duration: 500
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves.expressiveDefaultSpatial
        }
        // animation: SpringAnimation {
        //     spring: 3.5
        //     damping: 0.3
        // }
        color: Appearance.colors.colLayer0
        borderWidth: (root.currentPanel === bar && Config.options.bar.cornerStyle !== 1) ? 0 : 1
        borderColor: Appearance.colors.colLayer0Border
        visible: false // cuz there's already the shadow
        // debug: true
    }
    DropShadow {
        id: shadow
        source: backgroundShape
        anchors.fill: backgroundShape
        radius: 10
        samples: radius * 2 + 1 // Ideally radius * 2 + 1, see qt docs
        color: "#44000000"
    }

    property HAbstractMorphedPanel currentPanel: bar
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

    HBar {
        id: bar
        screenWidth: root.width
        screenHeight: root.height
    }

    HOverview {
        id: overview
        screenWidth: root.width
        screenHeight: root.height
    }

    Connections {
        target: GlobalStates
        function onOverviewOpenChanged() {
            if (GlobalStates.overviewOpen) {
                currentPanel = overview;
            } else {
                currentPanel = bar;
            }
        }
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
