import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import qs.services
import qs.modules.common
import qs.modules.waffle.looks

BarButton {
    id: root

    required property string iconName
    implicitWidth: height - topInset - bottomInset + leftInset + rightInset

    contentItem: Item {
        id: contentItem
        anchors.centerIn: root.background

        implicitHeight: iconWidget.implicitHeight
        implicitWidth: iconWidget.implicitWidth

        scale: root.down ? 5/6 : 1 // If/When we do dragging, the scale is 1.25
        Behavior on scale {
            NumberAnimation {
                duration: 90
                easing.type: Easing.BezierSpline
                easing.bezierCurve: root.down ? Looks.transition.easing.bezierCurve.easeIn : Looks.transition.easing.bezierCurve.easeOut
            }
        }

        Kirigami.Icon {
            id: iconWidget
            anchors.centerIn: parent
            implicitWidth: 26
            implicitHeight: 26
            roundToIconSize: false
            source: `${Looks.iconsPath}/${root.iconName}-${Looks.dark ? "dark" : "light"}.svg`
            fallback: root.iconName
        }
    }
}
