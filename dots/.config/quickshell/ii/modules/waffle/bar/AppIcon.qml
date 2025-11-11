import QtQuick
import org.kde.kirigami as Kirigami
import qs.services
import qs.modules.common
import qs.modules.waffle.looks

Kirigami.Icon {
    id: root
    required property string iconName
    property bool separateLightDark: false
    
    property real implicitSize: 26
    implicitWidth: implicitSize
    implicitHeight: implicitSize
    roundToIconSize: false
    source: `${Looks.iconsPath}/${root.iconName}${!root.separateLightDark ? "" : Looks.dark ? "-dark" : "-light"}.svg`
    fallback: root.iconName
}
