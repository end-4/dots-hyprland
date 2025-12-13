import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import qs
import qs.services
import qs.modules.common
import qs.modules.waffle.looks

AppButton {
    id: root

    iconName: checked ? "system-search-checked" : "system-search"
    separateLightDark: true

    checked: GlobalStates.searchOpen && LauncherSearch.query !== ""
    onClicked: {
        GlobalStates.searchOpen = !GlobalStates.searchOpen; // For now...
    }

    BarToolTip {
        id: tooltip
        text: Translation.tr("Search")
        extraVisibleCondition: root.shouldShowTooltip
    }
}
