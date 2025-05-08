import QtQuick
import Quickshell
pragma Singleton
pragma ComponentBehavior: Bound

Singleton {
    property QtObject m3colors
    property QtObject animation
    property QtObject animationCurves
    property QtObject colors
    property QtObject rounding
    property QtObject font
    property QtObject sizes
    property string syntaxHighlightingTheme

    function mix(color1, color2, percentage) {
        var c1 = Qt.color(color1);
        var c2 = Qt.color(color2);
        return Qt.rgba(percentage * c1.r + (1 - percentage) * c2.r, percentage * c1.g + (1 - percentage) * c2.g, percentage * c1.b + (1 - percentage) * c2.b, percentage * c1.a + (1 - percentage) * c2.a);
    }

    // Transparentize
    function transparentize(color, percentage) {
        var c = Qt.color(color);
        return Qt.rgba(c.r, c.g, c.b, c.a * (1 - percentage));
    }

    m3colors: QtObject {
        property bool darkmode: false
        property bool transparent: false
        property color m3primary_paletteKeyColor: "#91689E"
        property color m3secondary_paletteKeyColor: "#837186"
        property color m3tertiary_paletteKeyColor: "#9D6A67"
        property color m3neutral_paletteKeyColor: "#7C757B"
        property color m3neutral_variant_paletteKeyColor: "#7D747D"
        property color m3background: "#161217"
        property color m3onBackground: "#EAE0E7"
        property color m3surface: "#161217"
        property color m3surfaceDim: "#161217"
        property color m3surfaceBright: "#3D373D"
        property color m3surfaceContainerLowest: "#110D12"
        property color m3surfaceContainerLow: "#1F1A1F"
        property color m3surfaceContainer: "#231E23"
        property color m3surfaceContainerHigh: "#2D282E"
        property color m3surfaceContainerHighest: "#383339"
        property color m3onSurface: "#EAE0E7"
        property color m3surfaceVariant: "#4C444D"
        property color m3onSurfaceVariant: "#CFC3CD"
        property color m3inverseSurface: "#EAE0E7"
        property color m3inverseOnSurface: "#342F34"
        property color m3outline: "#988E97"
        property color m3outlineVariant: "#4C444D"
        property color m3shadow: "#000000"
        property color m3scrim: "#000000"
        property color m3surfaceTint: "#E5B6F2"
        property color m3primary: "#E5B6F2"
        property color m3onPrimary: "#452152"
        property color m3primaryContainer: "#5D386A"
        property color m3onPrimaryContainer: "#F9D8FF"
        property color m3inversePrimary: "#775084"
        property color m3secondary: "#D5C0D7"
        property color m3onSecondary: "#392C3D"
        property color m3secondaryContainer: "#534457"
        property color m3onSecondaryContainer: "#F2DCF3"
        property color m3tertiary: "#F5B7B3"
        property color m3onTertiary: "#4C2523"
        property color m3tertiaryContainer: "#BA837F"
        property color m3onTertiaryContainer: "#000000"
        property color m3error: "#FFB4AB"
        property color m3onError: "#690005"
        property color m3errorContainer: "#93000A"
        property color m3onErrorContainer: "#FFDAD6"
        property color m3primaryFixed: "#F9D8FF"
        property color m3primaryFixedDim: "#E5B6F2"
        property color m3onPrimaryFixed: "#2E0A3C"
        property color m3onPrimaryFixedVariant: "#5D386A"
        property color m3secondaryFixed: "#F2DCF3"
        property color m3secondaryFixedDim: "#D5C0D7"
        property color m3onSecondaryFixed: "#241727"
        property color m3onSecondaryFixedVariant: "#514254"
        property color m3tertiaryFixed: "#FFDAD7"
        property color m3tertiaryFixedDim: "#F5B7B3"
        property color m3onTertiaryFixed: "#331110"
        property color m3onTertiaryFixedVariant: "#663B39"
        property color m3success: "#B5CCBA"
        property color m3onSuccess: "#213528"
        property color m3successContainer: "#374B3E"
        property color m3onSuccessContainer: "#D1E9D6"
        property color term0: "#EDE4E4"
        property color term1: "#B52755"
        property color term2: "#A97363"
        property color term3: "#AF535D"
        property color term4: "#A67F7C"
        property color term5: "#B2416B"
        property color term6: "#8D76AD"
        property color term7: "#272022"
        property color term8: "#0E0D0D"
        property color term9: "#B52755"
        property color term10: "#A97363"
        property color term11: "#AF535D"
        property color term12: "#A67F7C"
        property color term13: "#B2416B"
        property color term14: "#8D76AD"
        property color term15: "#221A1A"
    }

    colors: QtObject {
        property color colSubtext: m3colors.m3outline
        property color colLayer0: m3colors.m3background
        property color colOnLayer0: m3colors.m3onBackground
        property color colLayer0Hover: mix(colLayer0, colOnLayer0, 0.85)
        property color colLayer0Active: m3colors.m3surfaceContainerHigh
        property color colLayer1: m3colors.m3surfaceContainerLow;
        property color colOnLayer1: m3colors.m3onSurfaceVariant;
        property color colOnLayer1Inactive: mix(colOnLayer1, colLayer1, 0.45);
        property color colLayer2: mix(m3colors.m3surfaceContainer, m3colors.m3surfaceContainerHigh, 0.55);
        property color colOnLayer2: m3colors.m3onSurface;
        property color colOnLayer2Disabled: mix(colOnLayer2, m3colors.m3background, 0.4);
        property color colLayer3: mix(m3colors.m3surfaceContainerHigh, m3colors.m3onSurface, 0.96);
        property color colOnLayer3: m3colors.m3onSurface;
        property color colLayer1Hover: mix(colLayer1, colOnLayer1, 0.88);
        property color colLayer1Active: mix(colLayer1, colOnLayer1, 0.77);
        property color colLayer2Hover: mix(colLayer2, colOnLayer2, 0.90);
        property color colLayer2Active: mix(colLayer2, colOnLayer2, 0.80);
        property color colLayer2Disabled: mix(colLayer2, m3colors.m3background, 0.8);
        property color colLayer3Hover: mix(colLayer3, colOnLayer3, 0.90);
        property color colLayer3Active: mix(colLayer3, colOnLayer3, 0.80);
        property color colPrimaryHover: mix(m3colors.m3primary, colLayer1Hover, 0.85)
        property color colPrimaryActive: mix(m3colors.m3primary, colLayer1Active, 0.7)
        property color colPrimaryContainerHover: mix(m3colors.m3primaryContainer, colLayer1Hover, 0.7)
        property color colPrimaryContainerActive: mix(m3colors.m3primaryContainer, colLayer1Active, 0.6)
        property color colSecondaryHover: mix(m3colors.m3secondary, colLayer1Hover, 0.85)
        property color colSecondaryActive: mix(m3colors.m3secondary, colLayer1Active, 0.4)
        property color colSecondaryContainerHover: mix(m3colors.m3secondaryContainer, colLayer1Hover, 0.6)
        property color colSecondaryContainerActive: mix(m3colors.m3secondaryContainer, colLayer1Active, 0.54)
        property color colSurfaceContainerHighestHover: mix(m3colors.m3surfaceContainerHighest, m3colors.m3onSurface, 0.95)
        property color colSurfaceContainerHighestActive: mix(m3colors.m3surfaceContainerHighest, m3colors.m3onSurface, 0.85)
        property color colTooltip: "#3C4043" // m3colors.m3inverseSurface in the specs, but the m3 website actually uses this color
        property color colOnTooltip: "#F8F9FA" // m3colors.m3inverseOnSurface in the specs, but the m3 website actually uses this color
        property color colScrim: transparentize(m3colors.m3scrim, 0.5)
        property color colShadow: transparentize(m3colors.m3shadow, 0.75)
    }

    rounding: QtObject {
        property int unsharpen: 2
        property int verysmall: 8
        property int small: 12
        property int normal: 17
        property int large: 23
        property int full: 9999
        property int screenRounding: large
        property int windowRounding: 18
    }

    font: QtObject {
        property QtObject family: QtObject {
            property string main: "Rubik"
            property string title: "Rubik"
            property string iconMaterial: "Material Symbols Outlined"
            property string iconNerd: "SpaceMono NF"
            property string monospace: "JetBrains Mono NF"
            property string reading: "Readex Pro"
        }
        property QtObject pixelSize: QtObject {
            property int smaller: 13
            property int small: 15
            property int normal: 16
            property int large: 17
            property int larger: 19
            property int huge: 22
            property int hugeass: 23
            property int title: 28
        }
    }

    animationCurves: QtObject {
        readonly property list<real> emphasized: [0.05, 0, 2 / 15, 0.06, 1 / 6, 0.4, 5 / 24, 0.82, 0.25, 1, 1, 1]
        readonly property list<real> emphasizedAccel: [0.3, 0, 0.8, 0.15, 1, 1]
        readonly property list<real> emphasizedDecel: [0.05, 0.7, 0.1, 1, 1, 1]
        readonly property list<real> standard: [0.2, 0, 0, 1, 1, 1]
        readonly property list<real> standardAccel: [0.3, 0, 1, 1, 1, 1]
        readonly property list<real> standardDecel: [0, 0, 0, 1, 1, 1]
    }

    animation: QtObject {
        property QtObject elementMove: QtObject {
            property int duration: 450
            property int type: Easing.BezierSpline
            property list<real> bezierCurve: animationCurves.emphasized
            property int velocity: 650
        }
        property QtObject elementMoveEnter: QtObject {
            property int duration: 400
            property int type: Easing.BezierSpline
            property list<real> bezierCurve: animationCurves.emphasizedDecel
            property int velocity: 650
        }
        property QtObject elementMoveExit: QtObject {
            property int duration: 200
            property int type: Easing.BezierSpline
            property list<real> bezierCurve: animationCurves.emphasizedAccel
            property int velocity: 650
        }
        property QtObject elementMoveFast: QtObject {
            property int duration: 200
            property int type: Easing.BezierSpline
            property list<real> bezierCurve: animationCurves.standardDecel
            property int velocity: 850
        }
        property QtObject scroll: QtObject {
            property int duration: 400
            property int type: Easing.BezierSpline
            property list<real> bezierCurve: animationCurves.standardDecel
        }
        property QtObject menuDecel: QtObject {
            property int duration: 350
            property int type: Easing.OutExpo
        }
        property QtObject positionShift: QtObject {
            property int duration: 300
            property int type: Easing.BezierSpline
            property list<real> bezierCurve: animationCurves.emphasized
            property int velocity: 650
        }
    }

    sizes: QtObject {
        property int barHeight: 40
        property int barCenterSideModuleWidth: 360
        property int barPreferredSideSectionWidth: 400
        property int sidebarWidth: 450
        property int sidebarWidthExtended: 750
        property int notificationPopupWidth: 410
        property int searchWidthCollapsed: 260
        property int searchWidth: 450
        property int hyprlandGapsOut: 5
        property int elevationMargin: 7
        property int fabShadowRadius: 5
        property int fabHoveredShadowRadius: 7
    }

    syntaxHighlightingTheme: Appearance.m3colors.darkmode ? "Monokai" : "ayu Light"
}
