import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import qs
import qs.services
import qs.modules.common
import qs.modules.waffle.looks

AppButton {
    id: root

    iconName: "task-view"
    separateLightDark: true

    checked: GlobalStates.overviewOpen
    onClicked: {
        GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
    }
}
