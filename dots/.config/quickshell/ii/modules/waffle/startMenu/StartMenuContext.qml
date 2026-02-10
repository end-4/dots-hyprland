import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.modules.common
import qs.services

Scope {
    id: root

    signal accepted

    property int currentIndex: 0
    function setCurrentIndex(index) {
        if (index == currentIndex)
            return;
        currentIndex = index;
    }

    function selectCategory(category) {
        for (let i = 0; i < root.categories.length; i++) {
            const thisCategoryName = root.categories[i].name;
            if (thisCategoryName.startsWith(category) || category.startsWith(thisCategoryName)) {
                LauncherSearch.ensurePrefix(root.categories[i].prefix);
                return;
            }
        }
    }
    property list<var> categories: [
        {
            name: Translation.tr("All"),
            prefix: ""
        },
        {
            name: Translation.tr("Apps"),
            prefix: Config.options.search.prefix.app
        },
        {
            name: Translation.tr("Actions"),
            prefix: Config.options.search.prefix.action
        },
        {
            name: Translation.tr("Clipboard"),
            prefix: Config.options.search.prefix.clipboard
        },
        {
            name: Translation.tr("Emojis"),
            prefix: Config.options.search.prefix.emojis
        },
        {
            name: Translation.tr("Math"),
            prefix: Config.options.search.prefix.math
        },
        {
            name: Translation.tr("Commands"),
            prefix: Config.options.search.prefix.shellCommand
        },
        {
            name: Translation.tr("Web"),
            prefix: Config.options.search.prefix.webSearch
        },
    ]

}
