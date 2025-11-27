pragma ComponentBehavior: Bound
import Qt.labs.synchronizer
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.models.quickToggles
import qs.modules.common.functions
import qs.modules.waffle.looks
import qs.modules.waffle.actionCenter.toggles

Item {
    id: root

    property int columns: 3
    property int rows: 2
    property int currentPage: 0
    readonly property int itemsPerPage: columns * rows
    readonly property int pages: Math.ceil(toggles.length / itemsPerPage)
    property list<string> toggles: Config.options.waffles.actionCenter.toggles

    property real padding: 22
    property real reducedBottomPadding: 12
    implicitHeight: swipeView.implicitHeight + (padding - swipeView.padding) * 2 - reducedBottomPadding

    function togglesInPage(index) {
        var start = index * root.itemsPerPage;
        var end = start + root.itemsPerPage;
        return root.toggles.slice(start, end);
    }

    function decreasePage() {
        if (root.currentPage > 0) {
            root.currentPage -= 1;
        }
    }

    function increasePage() {
        if (root.currentPage < (root.pages - 1)) {
            root.currentPage += 1;
        }
    }

    clip: true
    SwipeView {
        id: swipeView
        anchors {
            fill: parent
            topMargin: root.padding - swipeView.padding
            bottomMargin: root.padding - swipeView.padding - root.reducedBottomPadding
        }
        padding: 4
        leftPadding: root.padding
        rightPadding: root.padding
        spacing: padding

        orientation: Qt.Vertical
        clip: true
        Synchronizer on currentIndex {
            property alias source: root.currentPage
        }

        Repeater {
            model: root.pages
            delegate: GridLayout {
                id: grid
                required property int index
                // width: SwipeView.view.width - root.padding * 2
                // height: SwipeView.view.height - root.padding * 2

                columns: root.columns
                rows: root.rows
                rowSpacing: 12
                columnSpacing: 12

                Repeater {
                    model: ScriptModel {
                        values: root.togglesInPage(grid.index)
                    }
                    delegate: ActionCenterTogglesDelegateChooser {}
                }
            }
        }
    }

    Column {
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: 6
        spacing: 6

        NavigationArrow {
            down: false
        }

        Repeater {
            model: root.pages
            delegate: MouseArea {
                id: pageIndicator
                required property int index
                hoverEnabled: true
                onClicked: root.currentPage = index
                anchors.horizontalCenter: parent.horizontalCenter
                implicitWidth: 6
                implicitHeight: 6

                Circle {
                    anchors.centerIn: parent
                    diameter: (index === root.currentPage || pageIndicator.containsMouse) && !pageIndicator.pressed ? 6 : 4
                    color: pageIndicator.containsMouse ? Looks.colors.controlBgHover : Looks.colors.controlBg
                }
            }
        }

        NavigationArrow {
            down: true
        }
    }

    FocusedScrollMouseArea {
        z: 999
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        hoverEnabled: false
        onScrollUp: decreasePage();
        onScrollDown: increasePage();
    }

    component NavigationArrow: FluentIcon {
        id: navArrow
        required property bool down
        anchors.horizontalCenter: parent.horizontalCenter
        implicitHeight: 12
        implicitWidth: 12 - (2 * upArea.containsPress)
        icon: down ? "caret-down" : "caret-up"
        color: upArea.containsMouse ? Looks.colors.controlBgHover : Looks.colors.controlBg
        filled: true
        opacity: ((down && root.currentPage < root.pages - 1) || (!down && root.currentPage > 0)) ? 1 : 0
        MouseArea {
            id: upArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: navArrow.down ? root.increasePage() : root.decreasePage();
        }
    }
}
