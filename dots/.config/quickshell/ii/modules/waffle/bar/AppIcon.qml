import QtQuick
import org.kde.kirigami as Kirigami
import qs.services
import qs.modules.common
import qs.modules.waffle.looks

Kirigami.Icon {
    id: iconWidget
    required property string iconName
    
    implicitWidth: 26
    implicitHeight: 26
    roundToIconSize: false
    source: `${Looks.iconsPath}/${root.iconName}${!root.separateLightDark ? "" : Looks.dark ? "-dark" : "-light"}.svg`
    fallback: root.iconName
}
