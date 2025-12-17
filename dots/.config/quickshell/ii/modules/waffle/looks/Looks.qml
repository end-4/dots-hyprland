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

    property real backgroundTransparency: 0.16
    property real panelBackgroundTransparency: 0.14
    property real panelLayerTransparency: root.dark ? 0.9 : 0.7
    property real contentTransparency: root.dark ? 0.87 : 0.5
    function applyBackgroundTransparency(col) {
        return ColorUtils.applyAlpha(col, 1 - root.backgroundTransparency)
    }
    function applyContentTransparency(col) {
        return ColorUtils.applyAlpha(col, 1 - root.contentTransparency)
    }
    lightColors: QtObject { // TODO: figure out transparency
        id: lightColors
        property color bgPanelFooter: "#EEEEEE"
        property color bgPanelBody: "#F2F2F2"
        property color bgPanelSeparator: "#E0E0E0"
        property color bg0: "#EEEEEE"
        property color bg0Border: '#adadad'
        property color bg1: "#F7F7F7"
        property color bg1Base: "#F7F7F7"
        property color bg1Hover: "#F7F7F7"
        property color bg1Active: '#EFEFEF'
        property color bg1Border: '#d7d7d7'
        property color bg2: "#FBFBFB"
        property color bg2Base: "#FBFBFB"
        property color bg2Hover: '#ffffff'
        property color bg2Active: '#eeeeee'
        property color bg2Border: '#cdcdcd'
        property color subfg: "#5C5C5C"
        property color fg: "#000000"
        property color fg1: "#626262"
        property color inactiveIcon: "#C4C4C4"
        property color controlBgInactive: '#555458'
        property color controlBg: '#807F85'
        property color controlBgHover: '#57575B'
        property color controlFg: "#FFFFFF"
        property color accentUnfocused: "#848484"
        property color link: "#235CCF"
        property color inputBg: ColorUtils.transparentize(bg0, 0.4)
    }
    darkColors: QtObject {
        id: darkColors
        property color bgPanelFooter: "#1C1C1C"
        property color bgPanelBody: '#616161'
        property color bgPanelSeparator: "#191919"
        property color bg0: "#1C1C1C"
        property color bg0Border: "#404040"
        property color bg1Base: "#2C2C2C"
        property color bg1: '#9f9f9f'
        property color bg1Hover: "#b3b3b3"
        property color bg1Active: '#727272'
        property color bg1Border: '#bebebe'
        property color bg2Base: "#313131"
        property color bg2: '#8a8a8a'
        property color bg2Hover: '#b1b1b1'
        property color bg2Active: '#919191'
        property color bg2Border: '#bdbdbd'
        property color subfg: "#CED1D7"
        property color fg: "#FFFFFF"
        property color fg1: "#D1D1D1"
        property color inactiveIcon: "#494949"
        property color controlBgInactive: "#CDCECF"
        property color controlBg: "#9B9B9B"
        property color controlBgHover: "#CFCED1"
        property color controlFg: "#454545"
        property color accentUnfocused: "#989898"
        property color link: "#A7C9FC"
        property color inputBg: ColorUtils.transparentize(darkColors.bg0, 0.5)
    }
    colors: QtObject {
        id: colors
        property color shadow: ColorUtils.transparentize('#161616', 0.62)
        property color ambientShadow: ColorUtils.transparentize("#000000", 0.75)
        property color bgPanelFooterBase: ColorUtils.transparentize(root.dark ? root.darkColors.bgPanelFooter : root.lightColors.bgPanelFooter, root.panelBackgroundTransparency)
        property color bgPanelFooter: ColorUtils.transparentize(root.dark ? root.darkColors.bgPanelFooter : root.lightColors.bgPanelFooter, root.panelLayerTransparency)
        property color bgPanelBody: ColorUtils.transparentize(root.dark ? root.darkColors.bgPanelBody : root.lightColors.bgPanelBody, root.panelLayerTransparency)
        property color bgPanelSeparator: ColorUtils.transparentize(root.dark ? root.darkColors.bgPanelSeparator : root.lightColors.bgPanelSeparator, root.backgroundTransparency)
        property color bg0Opaque: root.dark ? root.darkColors.bg0 : root.lightColors.bg0
        property color bg0: ColorUtils.transparentize(bg0Opaque, root.backgroundTransparency)
        property color bg0Border: ColorUtils.transparentize(root.dark ? root.darkColors.bg0Border : root.lightColors.bg0Border, root.backgroundTransparency)
        property color bg1Base: root.dark ? root.darkColors.bg1Base : root.lightColors.bg1Base
        property color bg1: ColorUtils.transparentize(root.dark ? root.darkColors.bg1 : root.lightColors.bg1, root.contentTransparency)
        property color bg1Hover: ColorUtils.transparentize(root.dark ? root.darkColors.bg1Hover : root.lightColors.bg1Hover, root.contentTransparency)
        property color bg1Active: ColorUtils.transparentize(root.dark ? root.darkColors.bg1Active : root.lightColors.bg1Active, root.contentTransparency)
        property color bg1Border: ColorUtils.transparentize(root.dark ? root.darkColors.bg1Border : root.lightColors.bg1Border, root.contentTransparency)
        property color bg2Base: root.dark ? root.darkColors.bg2Base : root.lightColors.bg2Base
        property color bg2: ColorUtils.transparentize(root.dark ? root.darkColors.bg2 : root.lightColors.bg2, root.contentTransparency)
        property color bg2Hover: ColorUtils.transparentize(root.dark ? root.darkColors.bg2Hover : root.lightColors.bg2Hover, root.contentTransparency)
        property color bg2Active: ColorUtils.transparentize(root.dark ? root.darkColors.bg2Active : root.lightColors.bg2Active, root.contentTransparency)
        property color bg2Border: ColorUtils.transparentize(root.dark ? root.darkColors.bg2Border : root.lightColors.bg2Border, root.contentTransparency)
        property color subfg: root.dark ? root.darkColors.subfg : root.lightColors.subfg
        property color fg: root.dark ? root.darkColors.fg : root.lightColors.fg
        property color fg1: root.dark ? root.darkColors.fg1 : root.lightColors.fg1
        property color inactiveIcon: root.dark ? root.darkColors.inactiveIcon : root.lightColors.inactiveIcon
        property color controlBgInactive: root.dark ? root.darkColors.controlBgInactive : root.lightColors.controlBgInactive
        property color controlBg: root.dark ? root.darkColors.controlBg : root.lightColors.controlBg
        property color controlBgHover: root.dark ? root.darkColors.controlBgHover : root.lightColors.controlBgHover
        property color controlFg: root.dark ? root.darkColors.controlFg : root.lightColors.controlFg
        property color inputBg: root.dark ? root.darkColors.inputBg : root.lightColors.inputBg
        property color link: root.dark ? root.darkColors.link : root.lightColors.link
        property color danger: "#C42B1C"
        property color dangerActive: "#B62D1F"
        property color warning: "#FF9900"
        property color accent: Appearance.colors.colPrimary
        property color accentHover: Appearance.colors.colPrimaryHover
        property color accentActive: Appearance.colors.colPrimaryActive
        property color accentUnfocused: root.dark ? root.darkColors.accentUnfocused : root.lightColors.accentUnfocused
        property color accentFg: ColorUtils.isDark(accent) ? "#FFFFFF" : "#000000"
        property color selection: Appearance.colors.colPrimaryContainer
        property color selectionFg: Appearance.colors.colOnPrimaryContainer
    }

    radius: QtObject {
        id: radius
        property int none: 0
        property int small: 2
        property int medium: 4
        property int large: 8
        property int xLarge: 12
    }

    font: QtObject {
        id: font
        property QtObject family: QtObject {
            property string ui: "Noto Sans"
        }
        property QtObject weight: QtObject { // Noto is not Segoe, so we might use slightly different weights
            property int thin: Font.Normal
            property int regular: Font.Medium
            property int strong: Font.DemiBold
            property int stronger: (Font.DemiBold + 2*Font.Bold) / 3
            property int strongest: Font.Bold
        }
        property QtObject pixelSize: QtObject {
            property real normal: 11
            property real large: 13
            property real larger: 15
            property real xlarger: 17
        }
        property QtObject variableAxes: QtObject {
            property var ui: ({
                "wdth": 25
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

        property Component resize: Component { // TODO: better curve needed
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
