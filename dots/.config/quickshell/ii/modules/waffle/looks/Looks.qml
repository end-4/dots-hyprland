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

    property real fluentBackgroundTransparency: 0.17
    property real fluentContentTransparency: 0.3
    colors: QtObject {
        id: colors
        property color bg0: "#1C1C1C"
        property color bg0Border: "#404040"
        property color bg1: "#2E2E2E"
        property color bg1Hover: "#292929"
        property color bg1Active: "#252525"
        property color bg1Border: "#333333"
        property color fg: "#FFFFFF"
        property color brand: Appearance.m3colors.m3primary
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
            property int regular: Font.Medium
            property int strong: Font.DemiBold
            property int stronger: Font.Bold
        }
        property QtObject pixelSize: QtObject {
            property real normal: 11
        }
    }

    transition: QtObject {
        id: transition
        property QtObject easing: QtObject {
            property QtObject bezierCurve: QtObject {
                readonly property list<real> easeInOut: [0.42,0.00,0.58,1.00]
                readonly property list<real> easeIn: [0,1,1,1]
                readonly property list<real> easeOut: [1,0,1,1]
            }
        }

        property Component color: Component {
            ColorAnimation {
                duration: 80
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
                duration: 100
                easing.type: Easing.BezierSpline
                easing.bezierCurve: transition.easing.bezierCurve.easeInOut
            }
        }

        property Component anchor: Component {
            AnchorAnimation {
                duration: 250
                easing.type: Easing.BezierSpline
                easing.bezierCurve: transition.easing.bezierCurve.easeInOut
            }
        }
    }
}
