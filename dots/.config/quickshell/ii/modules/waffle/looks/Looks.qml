pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import qs.modules.common
import qs.modules.common.functions

Singleton {
    id: root
    property QtObject colors
    property QtObject radius
    property QtObject font
    property QtObject transition
    property string iconsPath: `${Directories.assetsPath}/icons/fluent`
    property bool dark: Appearance.m3colors.darkmode

    property real backgroundTransparency: 0.17
    property real contentTransparency: 0.25
    function applyBackgroundTransparency(col) {
        return ColorUtils.applyAlpha(col, 1 - root.backgroundTransparency)
    }
    function applyContentTransparency(col) {
        return ColorUtils.applyAlpha(col, 1 - root.contentTransparency)
    }
    colors: QtObject {
        id: colors
        property color ambientShadow: ColorUtils.transparentize("#000000", 0.75)
        property color bgPanelFooter: root.dark ? "#1C1C1C" : "#EEEEEE"
        property color bgPanelBody: root.dark ? "#242424" : "#F2F2F2"
        property color bgPanelSeparator: root.dark ? "#191919" : "#E0E0E0"
        property color bg0: root.dark ? "#1C1C1C" : "#EEEEEE"
        property color bg0Border: root.dark ? "#404040" : "#BEBEBE"
        property color bg1: root.dark ? "#2C2C2C" : "#F7F7F7"
        property color bg1Hover: root.dark ? "#292929" : "#F7F7F7"
        property color bg1Active: root.dark ? "#252525" : "#F3F3F3"
        property color bg1Border: root.dark ? "#333333" : "#E9E9E9"
        property color bg2: root.dark ? "#313131" : "#FBFBFB"
        property color bg2Hover: root.dark ? "#383838" : "#FDFDFD"
        property color bg2Active: root.dark ? "#333333" : "#FDFDFD"
        property color bg2Border: root.dark ? "#464646" : "#EEEEEE"
        property color fg: root.dark ? "#FFFFFF" : "#000000"
        property color fg1: root.dark ? "#D1D1D1" : "#626262"
        property color controlBg: root.dark ? "#9B9B9B" : "#868686"
        property color controlFg: root.dark ? "#454545" : "#FFFFFF"
        property color danger: "#C42B1C"
        property color dangerActive: "#B62D1F"
        property color warning: "#FF9900"
        // property color accent: root.dark ? "#A5C6D8" : "#5377A3"
        property color accent: Appearance.colors.colPrimary
        property color accentHover: Appearance.colors.colPrimaryHover
        property color accentActive: Appearance.colors.colPrimaryActive
        property color accentUnfocused: root.dark ? "#989898" : "#848484"
        property color accentFg: ColorUtils.isDark(accent) ? "#FFFFFF" : "#000000"
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
            property int stronger: Font.Bold
        }
        property QtObject pixelSize: QtObject {
            property real normal: 11
            property real large: 14
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
                duration: 120
                easing.type: Easing.BezierSpline
                easing.bezierCurve: transition.easing.bezierCurve.easeIn
            }
        }

        property Component opacity: Component {
            NumberAnimation{
                duration: 120
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
    }
}
