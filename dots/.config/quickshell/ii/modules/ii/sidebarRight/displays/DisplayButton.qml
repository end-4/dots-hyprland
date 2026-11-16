import qs.modules.common
import qs.modules.common.widgets

DialogButton {
    id: root
    property bool primary: false

    colBackground: root.primary ? Appearance.colors.colPrimary : Appearance.colors.colLayer2
    colBackgroundHover: root.primary ? Appearance.colors.colPrimaryHover : Appearance.colors.colLayer2Hover
    colBackgroundToggled: Appearance.colors.colPrimary
    colBackgroundToggledHover: Appearance.colors.colPrimaryHover
    colRipple: root.primary ? Appearance.colors.colPrimaryActive : Appearance.colors.colLayer2Active
    colRippleToggled: Appearance.colors.colPrimaryActive
    colText: !root.enabled ? Appearance.m3colors.m3outline
        : ((root.primary || root.toggled) ? Appearance.colors.colOnPrimary : Appearance.colors.colPrimary)
}
