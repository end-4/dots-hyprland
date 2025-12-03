import qs.modules.waffle.looks
import qs.modules.common.functions
import qs.modules.common
import qs.services
import qs
import Quickshell
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick
pragma ComponentBehavior: Bound

RowLayout {
    id: root

    function focusFirstItem() {
        resultList.currentIndex = 0;
    }

    ResultList {
        id: resultList
        Layout.fillHeight: true
        Layout.fillWidth: true
    }
    ResultPreview {
        Layout.preferredWidth: 386
        Layout.leftMargin: 1
        Layout.rightMargin: 1
    }

    component ResultList: ListView {
        section {
            criteria: ViewSection.FullString
            property: "type"
        }
        clip: true
        spacing: 4
        model: ScriptModel {
            values: {
                // TODO: categorize and have max per category
                LauncherSearch.results.slice(0, 10)
            }
            onValuesChanged: {
                root.focusFirstItem();
            }
        }
        delegate: WSearchResultButton {
            required property int index
            required property var modelData
            entry: modelData
            firstEntry: index === 0
            width: ListView.view?.width
        }
    }

    component ResultPreview: Rectangle {
        Layout.fillHeight: true
        color: Looks.colors.bg1
        radius: Looks.radius.large
    }
}
