import QtQuick
import QtQuick.Effects
import qs.modules.common
import qs.modules.common.widgets

Item {
    default property Item contentItem
    property Item shadow: WRectangularShadow {
        target: contentItem
    }
    implicitWidth: contentItem.implicitWidth
    implicitHeight: contentItem.implicitHeight

    children: [shadow, contentItem]
}
