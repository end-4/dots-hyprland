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

RowLayout {
    WPanelIconButton {
        implicitWidth: 36
        implicitHeight: 36
        iconSize: 24
        iconName: "arrow-left"
        onClicked: LauncherSearch.query = ""
    }
    ListView {
        id: tagListView
        Layout.fillWidth: true
        Layout.fillHeight: true
        orientation: Qt.Horizontal
        spacing: 4
        model: [
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
        delegate: WBorderedButton {
            id: tagButton
            required property var modelData
            border.width: 1
            radius: height / 2
            implicitWidth: tagButtonText.implicitWidth + 12 * 2
            implicitHeight: 32
            checked: {
                if (modelData.prefix != "") {
                    return LauncherSearch.query.startsWith(modelData.prefix);
                } else {
                    return !tagListView.model.some(i => (i.prefix != "" && LauncherSearch.query.startsWith(i.prefix)))
                }
            }
            contentItem: Item {
                WText {
                    id: tagButtonText
                    anchors.centerIn: parent
                    color: tagButton.fgColor
                    text: tagButton.modelData.name
                    font.pixelSize: Looks.font.pixelSize.large
                }
            }
            onClicked: LauncherSearch.ensurePrefix(tagButton.modelData.prefix)
        }
    }
    WPanelIconButton {
        implicitWidth: 36
        implicitHeight: 36
        iconSize: 24
        iconName: "more-horizontal"
    }
}
