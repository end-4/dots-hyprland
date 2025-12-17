pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.waffle.looks

Rectangle {
    id: root
    property AggregatedAppCategoryModel aggregatedCategory
    property list<DesktopEntry> desktopEntries: [...DesktopEntries.applications.values.filter(app => {
        const appCategories = app.categories;
        const gridCategories = root.aggregatedCategory.categories;
        return appCategories.some(cat => gridCategories.indexOf(cat) !== -1);
    })].sort((a, b) => a.name.localeCompare(b.name));

    property Item windowRootItem: {
        var item = root;
        // print("FINDING ROOT")
        while (item.parent != null) {
            if (item.parent.toString().includes("ProxyWindow"))
                break;
            item = item.parent;
        }
        // print(item.width, item.height)
        return item;
    }
    function openCategoryFolder() {
        categoryFolderPopup.open();
    }

    radius: Looks.radius.large
    color: Looks.colors.bg1
    border.width: 1
    border.color: ColorUtils.transparentize(Looks.colors.ambientShadow, 0.7)
    implicitWidth: 156
    implicitHeight: 156

    GridLayout {
        id: categoryAppsGrid
        anchors.fill: parent
        anchors.margins: 10
        columns: 2
        rows: 2
        columnSpacing: 0
        rowSpacing: 0
        uniformCellHeights: true
        uniformCellWidths: true

        Repeater {
            model: ScriptModel {
                values: root.desktopEntries.slice(0, 3)
            }
            delegate: SmallGridAppButton {
                required property DesktopEntry modelData
                desktopEntry: modelData
            }
        }
        Loader {
            id: categoryOpenButtonLoader
            // It's like this on the real thing - you get an invisible button if there's not enough items
            opacity: root.desktopEntries.length > 3 ? 1 : 0
            active: true
            sourceComponent: CategoryOpenButton {
                aggregatedCategory: root.aggregatedCategory
            }
        }
    }

    Popup {
        id: categoryFolderPopup
        // I don't even know what the fuck is going on at this point
        // I hate point mapping
        property point originPoint: categoryOpenButtonLoader.mapToItem(root, categoryOpenButtonLoader.width / 2, categoryOpenButtonLoader.height / 2)
        property point windowCenterPoint: {
            const rootContentItem = root.windowRootItem;
            const canvasPosInRoot = root.mapFromItem(rootContentItem, rootContentItem.width / 2, rootContentItem.height / 2);
            const sectionItem = root.parent.parent.parent;
            const positionInSection = sectionItem.mapFromItem(categoryOpenButtonLoader, categoryOpenButtonLoader.x, categoryOpenButtonLoader.y);
            const targetY = Math.max(-positionInSection.y + 212, canvasPosInRoot.y);
            return Qt.point(canvasPosInRoot.x, targetY);
        }

        enter: Transition {
            NumberAnimation {
                target: categoryFolderPopup
                property: "x"
                from: categoryFolderPopup.originPoint.x - categoryOpenButtonLoader.width * 5 / 2
                to: categoryFolderPopup.windowCenterPoint.x - categoryFolderPopup.width / 2
                duration: 300
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Looks.transition.easing.bezierCurve.easeIn
            }
            NumberAnimation {
                target: categoryFolderPopup
                property: "y"
                from: categoryFolderPopup.originPoint.y - categoryOpenButtonLoader.height * 3 / 2
                to: categoryFolderPopup.windowCenterPoint.y - categoryFolderPopup.height / 2
                duration: 300
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Looks.transition.easing.bezierCurve.easeIn
            }
            NumberAnimation {
                target: categoryFolderPopup
                property: "scale"
                from: 0
                to: 1
                duration: 300
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Looks.transition.easing.bezierCurve.easeIn
            }
        }

        exit: Transition {
            NumberAnimation {
                target: categoryFolderPopup
                property: "x"
                to: categoryFolderPopup.originPoint.x - categoryOpenButtonLoader.width * 5 / 2
                duration: 200
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Looks.transition.easing.bezierCurve.easeOut
            }
            NumberAnimation {
                target: categoryFolderPopup
                property: "y"
                to: categoryFolderPopup.originPoint.y - categoryOpenButtonLoader.height * 3 / 2
                duration: 200
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Looks.transition.easing.bezierCurve.easeOut
            }
            NumberAnimation {
                target: categoryFolderPopup
                property: "scale"
                from: 1
                to: 0
                duration: 200
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Looks.transition.easing.bezierCurve.easeOut
            }
        }

        background: null

        Loader {
            id: folderContentLoader
            active: categoryFolderPopup.visible
            sourceComponent: WRectangularShadowThis {
                CategoryFolderContent {
                    title: root.aggregatedCategory.name
                    desktopEntries: root.desktopEntries
                }
            }
        }
    }

    component CategoryFolderContent: WToolTipContent {
        id: categoryFolderContent
        property string title
        property list<DesktopEntry> desktopEntries: root.desktopEntries
        horizontalPadding: 0
        verticalPadding: 0
        radius: Looks.radius.large
        realContentItem: Item {
            implicitWidth: 448
            implicitHeight: 376
            ColumnLayout {
                anchors {
                    fill: parent
                    leftMargin: 32
                    rightMargin: 32
                    topMargin: 40
                    bottomMargin: 32
                }
                spacing: 28
                WText {
                    Layout.fillWidth: true
                    text: categoryFolderContent.title
                    font.pixelSize: Looks.font.pixelSize.xlarger
                    font.weight: Looks.font.weight.stronger
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                }
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    SwipeView {
                        id: categoryFolderSwipeView
                        anchors.fill: parent
                        orientation: Qt.Vertical
                        clip: true

                        Repeater {
                            model: Math.ceil(root.desktopEntries.length / 12)
                            delegate: Item {
                                id: folderPage
                                required property int index
                                width: SwipeView.view.width
                                height: SwipeView.view.height
                                BigAppGrid {
                                    anchors {
                                        top: parent.top
                                        left: parent.left
                                    }
                                    columns: 4
                                    rows: 3
                                    desktopEntries: root.desktopEntries.slice(folderPage.index * 12, (folderPage.index + 1) * 12)
                                }
                            }
                        }
                    }
                    VerticalPageIndicator {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: categoryFolderSwipeView.right
                        anchors.rightMargin: -19

                        showArrows: false
                        currentIndex: categoryFolderSwipeView.currentIndex
                        count: Math.ceil(root.desktopEntries.length / 12)
                        onClicked: index => categoryFolderSwipeView.currentIndex = index
                    }
                }
            }
            FocusedScrollMouseArea {
                z: 999
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                hoverEnabled: false
                onScrollUp: categoryFolderSwipeView.decrementCurrentIndex()
                onScrollDown: categoryFolderSwipeView.incrementCurrentIndex()
            }
        }
    }

    component CategoryOpenButton: SmallGridButton {
        id: categoryOpenButton
        property AggregatedAppCategoryModel aggregatedCategory

        onClicked: root.openCategoryFolder()
        contentItem: Item {
            Behavior on scale {
                NumberAnimation {
                    id: scaleAnim
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Looks.transition.easing.bezierCurve.easeIn
                }
            }
            GridLayout {
                anchors.centerIn: parent
                rows: 2
                columns: 2
                rowSpacing: 2
                columnSpacing: 2

                Repeater {
                    model: root.desktopEntries.slice(3, 7)
                    delegate: WAppIcon {
                        required property DesktopEntry modelData
                        tryCustomIcon: false
                        iconName: modelData.icon
                        implicitSize: 16
                    }
                }
            }
        }
    }

    component SmallGridAppButton: SmallGridButton {
        id: smallGridAppButton
        property DesktopEntry desktopEntry

        property bool pinnedStart: LauncherApps.isPinned(smallGridAppButton.desktopEntry.id);
        property bool pinnedTaskbar: TaskbarApps.isPinned(smallGridAppButton.desktopEntry.id);

        onClicked: {
            GlobalStates.searchOpen = false;
            desktopEntry.execute();
        }

        contentItem: Item {
            Behavior on scale {
                NumberAnimation {
                    id: scaleAnim
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Looks.transition.easing.bezierCurve.easeIn
                }
            }
            WAppIcon {
                anchors.centerIn: parent
                tryCustomIcon: false
                iconName: smallGridAppButton.desktopEntry.icon
                implicitSize: 34
            }
        }

        WToolTip {
            text: smallGridAppButton.desktopEntry.name
        }

        altAction: () => {
            appMenu.popup();
        }

        WMenu {
            id: appMenu
            downDirection: true

            WMenuItem {
                icon.name: smallGridAppButton.pinnedStart ? "pin-off" : "pin"
                text: smallGridAppButton.pinnedStart ? Translation.tr("Unpin from Start") : Translation.tr("Pin to Start")
                onTriggered: {
                    LauncherApps.togglePin(smallGridAppButton.desktopEntry.id);
                }
            }
            WMenuItem {
                icon.name: smallGridAppButton.pinnedTaskbar ? "pin-off" : "pin"
                text: smallGridAppButton.pinnedTaskbar ? Translation.tr("Unpin from taskbar") : Translation.tr("Pin to taskbar")
                onTriggered: {
                    TaskbarApps.togglePin(smallGridAppButton.desktopEntry.id);
                }
            }
        }
    }

    component SmallGridButton: WButton {
        id: root
        implicitWidth: 68
        implicitHeight: 68

        property real pressedScale: 5 / 6

        onDownChanged: {
            contentItem.scale = root.down ? root.pressedScale : 1; // If/When we do dragging, the scale is 1.25
        }
    }
}
