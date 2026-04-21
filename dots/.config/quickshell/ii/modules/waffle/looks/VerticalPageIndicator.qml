pragma ComponentBehavior: Bound
import Qt.labs.synchronizer
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.waffle.looks

Column {
    id: root

    property bool showArrows: true
    property int currentIndex: 0
    property int count: 1
    signal clicked(int index)
    signal increasePage()
    signal decreasePage()

    visible: count > 1
    spacing: 6

    NavigationArrow {
        visible: root.showArrows
        down: false
    }

    Repeater {
        model: root.count
        delegate: MouseArea {
            id: pageIndicator
            required property int index
            hoverEnabled: true
            onClicked: root.clicked(index);
            anchors.horizontalCenter: parent.horizontalCenter
            implicitWidth: 6
            implicitHeight: 6

            Circle {
                anchors.centerIn: parent
                diameter: (index === root.currentIndex || pageIndicator.containsMouse) && !pageIndicator.pressed ? 6 : 4
                color: pageIndicator.containsMouse ? Looks.colors.controlBgHover : Looks.colors.controlBg
            }
        }
    }

    NavigationArrow {
        visible: root.showArrows
        down: true
    }

    component NavigationArrow: FluentIcon {
        id: navArrow
        required property bool down
        anchors.horizontalCenter: parent.horizontalCenter
        implicitHeight: 12
        implicitWidth: 12 - (2 * upArea.containsPress)
        icon: down ? "caret-down" : "caret-up"
        color: upArea.containsMouse ? Looks.colors.controlBgHover : Looks.colors.controlBg
        filled: true
        opacity: ((down && root.currentIndex < root.count - 1) || (!down && root.currentIndex > 0)) ? 1 : 0
        MouseArea {
            id: upArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: navArrow.down ? root.increasePage() : root.decreasePage();
        }
    }
}
