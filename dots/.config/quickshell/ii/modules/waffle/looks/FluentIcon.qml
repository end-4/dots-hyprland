import QtQuick
import org.kde.kirigami as Kirigami
import qs.modules.common
import qs.modules.waffle.looks

Kirigami.Icon {
    id: root
    required property string icon
    property int implicitSize: 18 // Should be 16, but it appears the icons have some padding
    implicitWidth: implicitSize
    implicitHeight: implicitSize

    roundToIconSize: false
    color: Looks.colors.fg
    isMask: true
    source: `${Looks.iconsPath}/${root.icon}.svg`
}
