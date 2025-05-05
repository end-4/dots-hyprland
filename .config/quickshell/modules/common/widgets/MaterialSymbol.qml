import "root:/modules/common/"
import QtQuick
import QtQuick.Layouts

Text {
    id: root
    property real iconSize: Appearance.font.pixelSize.small
    property real fill: 0
    renderType: Text.NativeRendering
    font.hintingPreference: Font.PreferFullHinting
    verticalAlignment: Text.AlignVCenter
    font.family: Appearance.font.family.iconMaterial
    font.pixelSize: iconSize
    color: Appearance.m3colors.m3onBackground

    Behavior on fill {
        NumberAnimation {
            duration: Appearance.animation.elementMoveFast.duration
            easing.type: Appearance.animation.elementMoveFast.type
            easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
        }
    }

    font.variableAxes: { 
        "FILL": fill,
        // "wght": font.weight,
        // "GRAD": 0,
        "opsz": iconSize,
    }
}
