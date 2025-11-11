import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import qs
import qs.services
import qs.modules.common
import qs.modules.waffle.looks

AppButton {
    id: root

    readonly property bool expandedForm: Config.options.waffles.bar.leftAlignApps
    leftInset: Config.options.waffles.bar.leftAlignApps ? 0 : 12
    implicitWidth: expandedForm ? 148 : (height - topInset - bottomInset + leftInset + rightInset)
    iconName: "widgets"

    checked: GlobalStates.sidebarLeftOpen
    onClicked: {
        GlobalStates.sidebarLeftOpen = !GlobalStates.sidebarLeftOpen
    }

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
            spacing: 6

            AppIcon {
                id: iconWidget
                anchors.verticalCenter: parent.verticalCenter
                iconName: root.iconName
            }

            Column {
                visible: root.expandedForm
                anchors.verticalCenter: parent.verticalCenter
                WText {
                    text: Translation.tr("Widgets")
                }
            }
        }
    }
}
