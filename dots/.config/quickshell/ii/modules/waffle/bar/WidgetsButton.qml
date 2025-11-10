import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import qs.services
import qs.modules.common
import qs.modules.waffle.looks

AppButton {
    id: root

    readonly property bool expandedForm: Config.options.waffles.bar.leftAlignApps
    leftInset: Config.options.waffles.bar.leftAlignApps ? 0 : 12
    implicitWidth: expandedForm ? 148 : (height - topInset - bottomInset + leftInset + rightInset)
    iconName: "widgets"

    contentItem: Item {
        anchors {
            verticalCenter: parent.verticalCenter
            left: root.expandedForm ? parent.left : undefined
            horizontalCenter: root.expandedForm ? undefined : background.horizontalCenter
        }
        implicitHeight: row.implicitHeight
        implicitWidth: row.implicitWidth
        Row {
            id: row
            anchors {
                verticalCenter: parent.verticalCenter
                left: root.expandedForm ? parent.left : undefined
                horizontalCenter: root.expandedForm ? undefined : parent.horizontalCenter
                margins: 8
            }

            AppIcon {
                id: iconWidget
                iconName: root.iconName
            }
        }
    }
}
