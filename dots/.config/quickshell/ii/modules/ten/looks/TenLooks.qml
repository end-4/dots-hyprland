pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import qs.modules.common
import qs.modules.common.functions

Singleton {
    id: root
    property QtObject darkColors
    property QtObject lightColors
    property QtObject colors
    property QtObject radius
    property QtObject font
    property QtObject transition
    property string iconsPath: `${Directories.assetsPath}/icons/fluent`
    property bool dark: Appearance.m3colors.darkmode

    readonly property bool transparencyEnabled: Config.options.appearance.transparency.enable
    property real backgroundTransparency: transparencyEnabled ? 0.16 : 0
    property real panelBackgroundTransparency: transparencyEnabled ? 0.14 : 0
    property real panelLayerTransparency: root.dark ? 0.9 : 0.7
    property real contentTransparency: root.dark ? 0.87 : 0.5
    function applyBackgroundTransparency(col) {
        return ColorUtils.applyAlpha(col, 1 - root.backgroundTransparency)
    }
    function applyContentTransparency(col) {
        return ColorUtils.applyAlpha(col, 1 - root.contentTransparency)
    }
    lightColors: QtObject {
        id: lightColors
        // Windows 10 light theme colors
        property color bgPanelBody: "#F3F3F3"
        property color bgPanelSeparator: "#DADADA"
        property color bg0: "#FFFFFF"
        property color bg0Border: '#E0E0E0'
        property color bg1Base: "#F0F0F0"
        property color bg1: "#F0F0F0"
        property color bg1Hover: "#E5E5E5"
        property color bg1Active: '#DADADA'
        property color bg1Border: '#E9E9E9'
        property color bg2: "#FAFAFA"
        property color bg2Base: "#FAFAFA"
        property color bg2Hover: '#F5F5F5'
        property color bg2Active: '#EEEEEE'
        property color bg2Border: '#E0E0E0'
        property color subfg: "#5C5C5C"
        property color fg: "#000000"
        property color fg1: "#1E1E1E"
        property color inactiveIcon: "#BEBEBE"
        property color controlBgInactive: '#5C5C5C'
        property color controlBg: '#7A7A7A'
        property color controlBgHover: '#6C6C6C'
        property color controlFg: "#FFFFFF"
        property color accentUnfocused: "#7A7A7A"
        property color link: "#0078D4"
        property color inputBg: ColorUtils.transparentize(bg0, 0.4)
    }
    darkColors: QtObject {
        id: darkColors
        // Windows 10 dark theme colors
        property color bgPanelBody: '#1F1F1F'
        property color bgPanelSeparator: "#2D2D2D"
        property color bg0: "#252525"
        property color bg0Border: "#3D3D3D"
        property color bg1Base: '#2D2D2D'
        property color bg1: '#2D2D2D'
        property color bg1Hover: "#333333"
        property color bg1Active: '#1A1A1A'
        property color bg1Border: '#4D4D4D'
        property color bg2Base: "#383838"
        property color bg2: '#383838'
        property color bg2Hover: '#3D3D3D'
        property color bg2Active: '#2B2B2B'
        property color bg2Border: '#454545'
        property color subfg: "#A0A0A0"
        property color fg: "#FFFFFF"
        property color fg1: "#E0E0E0"
        property color inactiveIcon: "#4D4D4D"
        property color controlBgInactive: "#8A8A8A"
        property color controlBg: "#6D6D6D"
        property color controlBgHover: "#7D7D7D"
        property color controlFg: "#FFFFFF"
        property color accentUnfocused: "#6D6D6D"
        property color link: "#60CDFF"
        property color inputBg: ColorUtils.transparentize(darkColors.bg0, 0.5)
    }
    colors: QtObject {
        id: colors
        // Special
        property color shadow: ColorUtils.transparentize('#161616', 0.62)
        property color ambientShadow: ColorUtils.transparentize("#000000", 0.75)
        property color bgPanelFooterBase: root.dark ? root.darkColors.bg0 : root.lightColors.bg0
        property color bgPanelFooterBackground: ColorUtils.transparentize(root.dark ? root.darkColors.bg0 : root.lightColors.bg0, root.panelBackgroundTransparency)
        property color bgPanelFooter: ColorUtils.transparentize(bgPanelFooterBackground, root.panelLayerTransparency)
        property color bgPanelBodyBase: root.dark ? root.darkColors.bgPanelBody : root.lightColors.bgPanelBody
        property color bgPanelBody: ColorUtils.solveOverlayColor(bgPanelFooterBackground,bgPanelBodyBase, 1 - root.panelLayerTransparency)
        property color bgPanelSeparator: ColorUtils.solveOverlayColor(bgPanelBodyBase, root.dark ? root.darkColors.bgPanelSeparator : root.lightColors.bgPanelSeparator, 1 - root.panelBackgroundTransparency)
        // Layer 0
        property color bg0Base: root.dark ? root.darkColors.bg0 : root.lightColors.bg0
        property color bg0: ColorUtils.transparentize(bg0Base, root.backgroundTransparency)
        property color bg0Border: ColorUtils.transparentize(root.dark ? root.darkColors.bg0Border : root.lightColors.bg0Border, root.backgroundTransparency)
        // Layer 1
        property color bg1Base: root.dark ? root.darkColors.bg1 : root.lightColors.bg1
        property color bg1: ColorUtils.solveOverlayColor(bg0Base, bg1Base, 1 - root.contentTransparency)
        property color bg1Hover: ColorUtils.solveOverlayColor(bg0Base, root.dark ? root.darkColors.bg1Hover : root.lightColors.bg1Hover, 1 - root.contentTransparency)
        property color bg1Active: ColorUtils.solveOverlayColor(bg0Base, root.dark ? root.darkColors.bg1Active : root.lightColors.bg1Active, 1 - root.contentTransparency)
        property color bg1Border: ColorUtils.solveOverlayColor(bg0Base, root.dark ? root.darkColors.bg1Border : root.lightColors.bg1Border, 1 - root.contentTransparency)
        // Layer 2
        property color bg2Base: root.dark ? root.darkColors.bg2 : root.lightColors.bg2
        property color bg2: ColorUtils.solveOverlayColor(bgPanelBodyBase, bg2Base, 1 - root.contentTransparency)
        property color bg2Hover: ColorUtils.solveOverlayColor(bgPanelBodyBase, root.dark ? root.darkColors.bg2Hover : root.lightColors.bg2Hover, 1 - root.contentTransparency)
        property color bg2Active: ColorUtils.solveOverlayColor(bgPanelBodyBase, root.dark ? root.darkColors.bg2Active : root.lightColors.bg2Active, 1 - root.contentTransparency)
        property color bg2Border: ColorUtils.solveOverlayColor(bgPanelBodyBase, root.dark ? root.darkColors.bg2Border : root.lightColors.bg2Border, 1 - root.contentTransparency)
        // Foreground / Text
        property color subfg: root.dark ? root.darkColors.subfg : root.lightColors.subfg
        property color fg: root.dark ? root.darkColors.fg : root.lightColors.fg
        property color fg1: root.dark ? root.darkColors.fg1 : root.lightColors.fg1
        property color inactiveIcon: root.dark ? root.darkColors.inactiveIcon : root.lightColors.inactiveIcon
        property color link: root.dark ? root.darkColors.link : root.lightColors.link
        // Controls
        property color controlBgInactive: root.dark ? root.darkColors.controlBgInactive : root.lightColors.controlBgInactive
        property color controlBg: root.dark ? root.darkColors.controlBg : root.lightColors.controlBg
        property color controlBgHover: root.dark ? root.darkColors.controlBgHover : root.lightColors.controlBgHover
        property color controlFg: root.dark ? root.darkColors.controlFg : root.lightColors.controlFg
        property color inputBg: root.dark ? root.darkColors.inputBg : root.lightColors.inputBg
        property color danger: "#C42B1C"
        property color dangerActive: "#B62D1F"
        property color warning: "#FF9900"
        // Accent - Windows 10 blue
        property color accent: "#0078D4"
        property color accentHover: "#1A8AD4"
        property color accentActive: "#006CBD"
        property color accentUnfocused: root.dark ? root.darkColors.accentUnfocused : root.lightColors.accentUnfocused
        property color accentFg: "#FFFFFF"
        property color selection: "#0078D4"
        property color selectionFg: "#FFFFFF"
    }

    // Windows 10 has more pronounced corner rounding
    radius: QtObject {
        id: radius
        property int none: 0
        property int small: 2
        property int medium: 4
        property int large: 6
        property int xLarge: 8
    }

    font: QtObject {
        id: font
        // Windows 10 uses Segoe UI, fallback to Noto Sans
        property QtObject family: QtObject {
            property string ui: "Segoe UI"
        }
        property QtObject weight: QtObject {
            property int thin: Font.Thin
            property int regular: Font.Normal
            property int strong: Font.Medium
            property int stronger: Font.SemiBold
            property int strongest: Font.Bold
        }
        property QtObject pixelSize: QtObject {
            property real normal: 11
            property real large: 12
            property real larger: 14
            property real xlarger: 15
        }
        property QtObject variableAxes: QtObject {
            property var ui: ({
                "wdth": 100
            })
        }
    }

    transition: QtObject {
        id: transition

        property int velocity: 850

        property QtObject easing: QtObject {
            property QtObject bezierCurve: QtObject {
                readonly property list<real> easeInOut: [0.42,0.00,0.58,1.00,1,1]
                readonly property list<real> easeIn: [0,1,1,1,1,1]
                readonly property list<real> easeOut: [1,0,1,1,1,1]
            }
        }

        property Component color: Component {
            ColorAnimation {
                duration: 80
                easing.type: Easing.BezierSpline
                easing.bezierCurve: transition.easing.bezierCurve.easeIn
            }
        }

        property Component opacity: Component {
            NumberAnimation {
                duration: 120
                easing.type: Easing.BezierSpline
                easing.bezierCurve: transition.easing.bezierCurve.easeIn
            }
        }

        property Component resize: Component {
            NumberAnimation {
                duration: 200
                easing.type: Easing.BezierSpline
                easing.bezierCurve: transition.easing.bezierCurve.easeIn
            }
        }

        property Component enter: Component {
            NumberAnimation {
                duration: 250
                easing.type: Easing.BezierSpline
                easing.bezierCurve: transition.easing.bezierCurve.easeIn
            }
        }

        property Component exit: Component {
            NumberAnimation {
                duration: 250
                easing.type: Easing.BezierSpline
                easing.bezierCurve: transition.easing.bezierCurve.easeOut
            }
        }

        property Component move: Component {
            NumberAnimation {
                duration: 170
                easing.type: Easing.BezierSpline
                easing.bezierCurve: transition.easing.bezierCurve.easeInOut
            }
        }

        property Component rotate: Component {
            NumberAnimation {
                duration: 170
                easing.type: Easing.BezierSpline
                easing.bezierCurve: transition.easing.bezierCurve.easeInOut
            }
        }

        property Component anchor: Component {
            AnchorAnimation {
                duration: 160
                easing.type: Easing.BezierSpline
                easing.bezierCurve: transition.easing.bezierCurve.easeIn
            }
        }

        property Component longMovement: Component {
            NumberAnimation {
                duration: 1000
                easing.type: Easing.BezierSpline
                easing.bezierCurve: transition.easing.bezierCurve.easeIn
            }
        }

        property Component scroll: Component {
            NumberAnimation {
                duration: 250
                easing.type: Easing.BezierSpline
                easing.bezierCurve: [0.0, 0.0, 0.25, 1.0, 1, 1]
            }
        }
    }
}
