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

    signal requestFocus()

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

    horizontalPadding: 0
    verticalPadding: 0

    contentItem: RowLayout {
        id: contentLayout
        spacing: 0

        WButton {
            id: launchButton
            Layout.fillWidth: true
            Layout.fillHeight: true
            horizontalPadding: 10
            verticalPadding: 11
            implicitHeight: root.firstEntry ? 62 : 36
            implicitWidth: entryContentRow.implicitWidth + leftPadding + rightPadding
            topRightRadius: 0
            bottomRightRadius: 0
            onClicked: root.click()
            contentItem: Item {
                RowLayout {
                    id: entryContentRow
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                    }
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
            }
        }
        Rectangle {
            id: separator
            opacity: (root.hovered && !root.checked) ? 1 : 0
            Layout.fillHeight: true
            implicitWidth: 1
            color: ColorUtils.transparentize(Looks.colors.fg, 0.75)
        }
        WButton {
            visible: !root.checked
            Layout.fillHeight: true
            implicitWidth: 47
            topLeftRadius: 0
            bottomLeftRadius: 0
            onClicked: root.requestFocus()
            contentItem: Item {
                FluentIcon {
                    anchors.centerIn: parent
                    icon: "chevron-right"
                    implicitSize: 14
                }
            }
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
