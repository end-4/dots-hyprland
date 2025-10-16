import QtQuick
import qs.modules.common
import qs.modules.common.functions

/**
 * Material color scheme adapted to a given color. It's incomplete but enough for what we need...
 */
QtObject {
    id: root
    required property color color
    readonly property bool colorIsDark: color.hslLightness < 0.5

    property color colLayer0: ColorUtils.mix(Appearance.colors.colLayer0, root.color, (colorIsDark && Appearance.m3colors.darkmode) ? 0.6 : 0.5)
    property color colLayer1: ColorUtils.mix(Appearance.colors.colLayer1, root.color, 0.5)
    property color colOnLayer0: ColorUtils.mix(Appearance.colors.colOnLayer0, root.color, 0.5)
    property color colOnLayer1: ColorUtils.mix(Appearance.colors.colOnLayer1, root.color, 0.5)
    property color colSubtext: ColorUtils.mix(Appearance.colors.colOnLayer1, root.color, 0.5)
    property color colPrimary: ColorUtils.mix(ColorUtils.adaptToAccent(Appearance.colors.colPrimary, root.color), root.color, 0.5)
    property color colPrimaryHover: ColorUtils.mix(ColorUtils.adaptToAccent(Appearance.colors.colPrimaryHover, root.color), root.color, 0.3)
    property color colPrimaryActive: ColorUtils.mix(ColorUtils.adaptToAccent(Appearance.colors.colPrimaryActive, root.color), root.color, 0.3)
    property color colSecondary: ColorUtils.mix(ColorUtils.adaptToAccent(Appearance.colors.colSecondary, root.color), root.color, 0.5)
    property color colSecondaryContainer: ColorUtils.mix(Appearance.m3colors.m3secondaryContainer, root.color, 0.15)
    property color colSecondaryContainerHover: ColorUtils.mix(Appearance.colors.colSecondaryContainerHover, root.color, 0.3)
    property color colSecondaryContainerActive: ColorUtils.mix(Appearance.colors.colSecondaryContainerActive, root.color, 0.5)
    property color colOnPrimary: ColorUtils.mix(ColorUtils.adaptToAccent(Appearance.m3colors.m3onPrimary, root.color), root.color, 0.5)
    property color colOnSecondaryContainer: ColorUtils.mix(Appearance.m3colors.m3onSecondaryContainer, root.color, 0.5)
}
