import qs.modules.common
import QtQuick

Text {
    id: root
    property real iconSize: Appearance?.font.pixelSize.small ?? 16
    property real fill: 0
    property real truncatedFill: Math.round(fill * 100) / 100 // Reduce memory consumption spikes from constant font remapping
    renderType: Text.NativeRendering
    font {
        hintingPreference: Font.PreferFullHinting
        family: Appearance?.font.family.iconMaterial ?? "Material Symbols Rounded"
        pixelSize: iconSize
        weight: Font.Normal + (Font.DemiBold - Font.Normal) * fill
        variableAxes: { 
            "FILL": truncatedFill,
            // "wght": font.weight,
            // "GRAD": 0,
            "opsz": iconSize,
        }
    }
    verticalAlignment: Text.AlignVCenter
    color: Appearance.m3colors.m3onBackground

    // Behavior on fill {
    //     NumberAnimation {
    //         duration: Appearance?.animation.elementMoveFast.duration ?? 200
    //         easing.type: Appearance?.animation.elementMoveFast.type ?? Easing.BezierSpline
    //         easing.bezierCurve: Appearance?.animation.elementMoveFast.bezierCurve ?? [0.34, 0.80, 0.34, 1.00, 1, 1]
    //     }
    // }
}
