import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import qs
import qs.services
import qs.modules.common
import qs.modules.waffle.looks

AppButton {
    id: root

    leftInset: Config.options.waffles.bar.leftAlignApps ? 12 : 0
    iconName: "start-here"

    onClicked: {
        GlobalStates.overviewOpen = !GlobalStates.overviewOpen; // For now...
    }

    BarToolTip {
        id: tooltip
        text: Translation.tr("Start")
        extraVisibleCondition: root.shouldShowTooltip
    }

    altAction: () => {
        contextMenu.active = !contextMenu.active;
    }

    BarMenu {
        id: contextMenu
    }
}
