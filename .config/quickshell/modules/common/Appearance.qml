import QtQuick
import Quickshell
pragma Singleton
pragma ComponentBehavior: Bound

Singleton {
    property QtObject m3colors
    property QtObject animation
    property QtObject colors
    property QtObject rounding
    property QtObject font
    property QtObject sizes

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
        property color m3primary_paletteKeyColor: "#8A7175"
        property color m3secondary_paletteKeyColor: "#847376"
        property color m3tertiary_paletteKeyColor: "#8F6E74"
        property color m3neutral_paletteKeyColor: "#7B7676"
        property color m3neutral_variant_paletteKeyColor: "#7B7676"
        property color m3background: "#FFF8F7"
        property color m3onBackground: "#1E1B1B"
        property color m3surface: "#FFF8F7"
        property color m3surfaceDim: "#E0D8D8"
        property color m3surfaceBright: "#FFF8F7"
        property color m3surfaceContainerLowest: "#FFFFFF"
        property color m3surfaceContainerLow: "#FAF2F2"
        property color m3surfaceContainer: "#F4ECEC"
        property color m3surfaceContainerHigh: "#EEE6E6"
        property color m3surfaceContainerHighest: "#E8E1E1"
        property color m3onSurface: "#1E1B1B"
        property color m3surfaceVariant: "#E8E1E1"
        property color m3onSurfaceVariant: "#4A4646"
        property color m3inverseSurface: "#332F30"
        property color m3inverseOnSurface: "#F7EFEF"
        property color m3outline: "#797373"
        property color m3outlineVariant: "#CCC5C5"
        property color m3shadow: "#000000"
        property color m3scrim: "#000000"
        property color m3surfaceTint: "#70585D"
        property color m3primary: "#70585D"
        property color m3onPrimary: "#FFFFFF"
        property color m3primaryContainer: "#FADBE0"
        property color m3onPrimaryContainer: "#564145"
        property color m3inversePrimary: "#DDBFC4"
        property color m3secondary: "#6A5A5D"
        property color m3onSecondary: "#FFFFFF"
        property color m3secondaryContainer: "#F3DDE0"
        property color m3onSecondaryContainer: "#524346"
        property color m3tertiary: "#8D6C72"
        property color m3onTertiary: "#FFFFFF"
        property color m3tertiaryContainer: "#8D6C72"
        property color m3onTertiaryContainer: "#FFFFFF"
        property color m3error: "#BA1A1A"
        property color m3onError: "#FFFFFF"
        property color m3errorContainer: "#FFDAD6"
        property color m3onErrorContainer: "#93000A"
        property color m3primaryFixed: "#FADBE0"
        property color m3primaryFixedDim: "#DDBFC4"
        property color m3onPrimaryFixed: "#28171A"
        property color m3onPrimaryFixedVariant: "#564145"
        property color m3secondaryFixed: "#F3DDE0"
        property color m3secondaryFixedDim: "#D6C2C4"
        property color m3onSecondaryFixed: "#24191B"
        property color m3onSecondaryFixedVariant: "#524346"
        property color m3tertiaryFixed: "#FFD9DF"
        property color m3tertiaryFixedDim: "#E4BDC3"
        property color m3onTertiaryFixed: "#2B151A"
        property color m3onTertiaryFixedVariant: "#5B3F45"
        property color m3success: "#4F6354"
        property color m3onSuccess: "#FFFFFF"
        property color m3successContainer: "#D1E8D5"
        property color m3onSuccessContainer: "#0C1F13"
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
        property color colLayer3: mix(m3colors.m3surfaceContainerHigh, m3colors.m3onSurface, 0.96);
        property color colOnLayer3: m3colors.m3onSurface;
        property color colLayer1Hover: mix(colLayer1, colOnLayer1, 0.88);
        property color colLayer1Active: mix(colLayer1, colOnLayer1, 0.77);
        property color colLayer2Hover: mix(colLayer2, colOnLayer2, 0.90);
        property color colLayer2Active: mix(colLayer2, colOnLayer2, 0.80);
        property color colLayer3Hover: mix(colLayer3, colOnLayer3, 0.90);
        property color colLayer3Active: mix(colLayer3, colOnLayer3, 0.80);
        property color colPrimaryHover: mix(m3colors.m3primary, colLayer1Hover, 0.85)
        property color colPrimaryActive: mix(m3colors.m3primary, colLayer1Active, 0.7)
        property color colPrimaryContainerHover: mix(m3colors.m3primaryContainer, colLayer1Hover, 0.7)
        property color colPrimaryContainerActive: mix(m3colors.m3primaryContainer, colLayer1Active, 0.6)
        property color colSecondaryHover: mix(m3colors.m3secondary, colLayer1Hover, 0.85)
        property color colSecondaryActive: mix(m3colors.m3secondary, colLayer1Active, 0.4)
        property color colSecondaryContainerHover: mix(m3colors.m3secondaryContainer, colLayer1Hover, 0.8)
        property color colSecondaryContainerActive: mix(m3colors.m3secondaryContainer, colLayer1Active, 0.6)
        property color colTooltip: m3colors.m3inverseSurface
        property color colOnTooltip: m3colors.m3inverseOnSurface
        property color colScrim: transparentize(m3colors.m3scrim, 0.5)
    }

    rounding: QtObject {
        property int unsharpen: 2
        property int verysmall: 8
        property int small: 12
        property int normal: 17
        property int large: 25
        property int full: 9999
        property int screenRounding: large
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
        }
    }

    animation: QtObject {
        property QtObject elementDecel: QtObject {
            property int duration: 200
            property int type: Easing.OutCirc
            property int velocity: 650
        }
        property QtObject elementDecelFast: QtObject {
            property int duration: 140
            property int type: Easing.OutCirc
            property int velocity: 750
        }
        property QtObject menuDecel: QtObject {
            property int duration: 350
            property int type: Easing.OutExpo
        }
        property QtObject positionShift: QtObject {
            property int duration: 300
            property int type: Easing.InOutExpo
            property int velocity: 650
        }
    }

    sizes: QtObject {
        property int barHeight: 40
        property int barCenterSideModuleWidth: 360
        property int barPreferredSideSectionWidth: 400
        property int sidebarWidth: 450
        property int hyprlandGapsOut: 5
        property int elevationMargin: 7
        property int fabShadowRadius: 5
        property int fabHoveredShadowRadius: 7
    }

}
