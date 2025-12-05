import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.models
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.waffle.looks

WChoiceButton {
    id: root

    required property LauncherSearchResult entry
    property bool firstEntry: false

    checked: focus
    animateChoiceHighlight: false
    implicitWidth: contentLayout.implicitWidth + leftPadding + rightPadding
    implicitHeight: contentLayout.implicitHeight + topPadding + bottomPadding

    onClicked: {
        execute();
    }

    function execute() {
        GlobalStates.searchOpen = false;
        root.entry.execute();
    }

    contentItem: RowLayout {
        id: contentLayout
        spacing: 8

        SearchEntryIcon {
            entry: root.entry
            iconSize: 24
        }
        EntryNameColumn {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
        }
    }

    component EntryNameColumn: ColumnLayout {
        spacing: 4

        WText {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            text: root.entry.name
            font.pixelSize: Looks.font.pixelSize.large
            maximumLineCount: 2
        }

        WText {
            Layout.fillWidth: true
            visible: root.firstEntry
            text: root.entry.type
            color: Looks.colors.accentUnfocused
        }
    }

    MouseArea {
        anchors.fill: parent
        // hoverEnabled: true
        acceptedButtons: Qt.NoButton
        cursorShape: Qt.PointingHandCursor
    }
}
