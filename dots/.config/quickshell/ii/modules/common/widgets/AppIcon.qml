import QtQuick
import org.kde.kirigami as Kirigami
import qs.services
import qs.modules.common

Kirigami.Icon {
    id: root
    
    property real implicitSize: 26
    implicitWidth: implicitSize
    implicitHeight: implicitSize

    roundToIconSize: false
    animated: true // It's just fading from one icon to another
}
