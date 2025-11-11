import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import qs.services
import qs.modules.common
import qs.modules.waffle.looks

BarButton {
    id: root

    required property string iconName
    property bool separateLightDark: false
    leftInset: 2
    rightInset: 2
    implicitWidth: height - topInset - bottomInset + leftInset + rightInset

    onDownChanged: {
        scaleAnim.duration = root.down ? 150 : 200
        scaleAnim.easing.bezierCurve = root.down ? Looks.transition.easing.bezierCurve.easeIn : Looks.transition.easing.bezierCurve.easeOut
        contentItem.scale = root.down ? 5/6 : 1 // If/When we do dragging, the scale is 1.25
    }

    contentItem: Item {
        id: contentItem
        anchors.centerIn: root.background

        implicitHeight: iconWidget.implicitHeight
        implicitWidth: iconWidget.implicitWidth

        Behavior on scale {
            NumberAnimation {
                id: scaleAnim
                easing.type: Easing.BezierSpline
            }
        }

        AppIcon {
            id: iconWidget
            anchors.centerIn: parent
            iconName: root.iconName
            separateLightDark: root.separateLightDark
        }
    }
}
