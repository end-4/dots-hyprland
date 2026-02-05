import QtQuick
import qs.services
import qs.modules.common
import qs.modules.common.widgets as W

W.AppIcon {
    id: root
    required property string iconName
    property bool separateLightDark: false
    property bool tryCustomIcon: true
    
    roundToIconSize: false
    fallback: root.iconName
    source: tryCustomIcon ? `${Looks.iconsPath}/${root.iconName}${!root.separateLightDark ? "" : Looks.dark ? "-dark" : "-light"}.svg` : fallback

    color: Looks.colors.fg
}
