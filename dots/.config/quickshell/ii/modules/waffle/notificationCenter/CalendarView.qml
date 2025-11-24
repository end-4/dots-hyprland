pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.waffle.looks

BodyRectangle {
    id: root

    property bool collapsed
    implicitHeight: collapsed ? 0 : 400 // For now
    implicitWidth: 334

    Behavior on implicitHeight {
        animation: Looks.transition.enter.createObject(this)
    }

}
