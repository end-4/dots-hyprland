import QtQuick
import QtQuick.Effects
import "root:/modules/common"

RectangularShadow {
    required property var target
    anchors.fill: target
    radius: target.radius
    blur: 1.2 * Appearance.sizes.elevationMargin
    spread: 1
    color: Appearance.colors.colShadow
    cached: true
}
