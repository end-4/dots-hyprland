import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt.labs.folderlistmodel
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Rectangle {
    id: root
    required property var directory
    property bool showBreadcrumb: true
    onShowBreadcrumbChanged: {
        addressInput.text = root.directory;
    }

    signal navigateToDirectory(string path)

    property real padding: 6
    implicitWidth: mainLayout.implicitWidth + padding * 2
    implicitHeight: mainLayout.implicitHeight + padding * 2
    color: Appearance.colors.colLayer2

    function focusBreadcrumb() {
        root.showBreadcrumb = false;
        addressInput.forceActiveFocus();
    }

    property bool sortMenuOpen: false

    RowLayout {
        id: mainLayout
        anchors {
            fill: parent
            margins: root.padding
        }
        spacing: 8

        RippleButton {
            id: sortMenuButton
            downAction: () => {
                root.sortMenuOpen = !root.sortMenuOpen
                if (root.sortMenuOpen) sortMenuPopup.open()
                else sortMenuPopup.close()
            }
            contentItem: MaterialSymbol {
                text: "sort"
                iconSize: Appearance.font.pixelSize.larger
            }

            StyledToolTip {
                text: Translation.tr("Sort options")
            }

            Popup {
                id: sortMenuPopup
                transformOrigin: Item.TopLeft
                y: parent.height + 4
                width: 200
                padding: 8
                closePolicy: Popup.CloseOnPressOutside | Popup.CloseOnEscape
                onClosed: root.sortMenuOpen = false

                enter: Transition {
                    NumberAnimation {
                        properties: "opacity"
                        from: 0
                        to: 1
                        duration: 150
                    }
                    NumberAnimation {
                        properties: "scale"
                        from: 0.6
                        to: 1
                        duration: 200
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                    }
                }

                exit: Transition {
                    NumberAnimation {
                        properties: "opacity"
                        to: 0
                        duration: 100
                    }
                    NumberAnimation {
                        properties: "scale"
                        to: 0.6
                        duration: 150
                    }
                }

                background: Item {
                    StyledRectangularShadow {
                        target: popupBg
                    }
                    Rectangle {
                        id: popupBg
                        anchors.fill: parent
                        radius: Appearance.rounding.normal
                        color: Appearance.m3colors.m3surfaceContainerHigh
                    }
                }

                contentItem: ColumnLayout {
                    spacing: 2

                    StyledText {
                        Layout.leftMargin: 8
                        Layout.topMargin: 4
                        Layout.bottomMargin: 2
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer2
                        text: Translation.tr("Sort by")
                    }

                    Repeater {
                        model: [
                            { label: "Name", field: FolderListModel.Name },
                            { label: "Time modified", field: FolderListModel.Time },
                            { label: "Size", field: FolderListModel.Size },
                            { label: "Type", field: FolderListModel.Type },
                        ]

                        delegate: RippleButton {
                            required property var modelData
                            id: sortFieldBtn
                            Layout.fillWidth: true
                            implicitHeight: 32
                            buttonRadius: Appearance.rounding.small
                            toggled: Wallpapers.folderModel.sortField === modelData.field
                            onClicked: Wallpapers.folderModel.sortField = modelData.field
                            contentItem: RowLayout {
                                spacing: 8
                                Rectangle {
                                    implicitWidth: 16
                                    implicitHeight: 16
                                    radius: 8
                                    border.width: 2
                                    border.color: sortFieldBtn.toggled ? Appearance.colors.colSecondaryContainer : Appearance.colors.colOnLayer2
                                    color: "transparent"
                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 8
                                        height: 8
                                        radius: 4
                                        visible: sortFieldBtn.toggled
                                        color: Appearance.colors.colSecondaryContainer
                                    }
                                }
                                StyledText {
                                    Layout.fillWidth: true
                                    horizontalAlignment: Text.AlignLeft
                                    text: Translation.tr(modelData.label)
                                    color: sortFieldBtn.toggled ? Appearance.colors.colSecondaryContainer : Appearance.colors.colOnLayer2
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        Layout.topMargin: 4
                        Layout.bottomMargin: 4
                        color: Appearance.colors.colLayer1Border
                    }

                    StyledText {
                        Layout.leftMargin: 8
                        Layout.bottomMargin: 2
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer2
                        text: Translation.tr("Order")
                    }

                    RippleButton {
                        id: ascendBtn
                        Layout.fillWidth: true
                        implicitHeight: 32
                        buttonRadius: Appearance.rounding.small
                        toggled: !Wallpapers.folderModel.sortReversed
                        onClicked: Wallpapers.folderModel.sortReversed = false
                        contentItem: RowLayout {
                            spacing: 8
                            Rectangle {
                                implicitWidth: 16
                                implicitHeight: 16
                                radius: 8
                                border.width: 2
                                border.color: ascendBtn.toggled ? Appearance.colors.colSecondaryContainer : Appearance.colors.colOnLayer2
                                color: "transparent"
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 8
                                    height: 8
                                    radius: 4
                                    visible: ascendBtn.toggled
                                    color: Appearance.colors.colSecondaryContainer
                                }
                            }
                            StyledText {
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignLeft
                                text: Translation.tr("Ascending")
                                color: ascendBtn.toggled ? Appearance.colors.colSecondaryContainer : Appearance.colors.colOnLayer2
                            }
                        }
                    }

                    RippleButton {
                        id: descendBtn
                        Layout.fillWidth: true
                        implicitHeight: 32
                        buttonRadius: Appearance.rounding.small
                        toggled: Wallpapers.folderModel.sortReversed
                        onClicked: Wallpapers.folderModel.sortReversed = true
                        contentItem: RowLayout {
                            spacing: 8
                            Rectangle {
                                implicitWidth: 16
                                implicitHeight: 16
                                radius: 8
                                border.width: 2
                                border.color: descendBtn.toggled ? Appearance.colors.colSecondaryContainer : Appearance.colors.colOnLayer2
                                color: "transparent"
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 8
                                    height: 8
                                    radius: 4
                                    visible: descendBtn.toggled
                                    color: Appearance.colors.colSecondaryContainer
                                }
                            }
                            StyledText {
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignLeft
                                text: Translation.tr("Descending")
                                color: descendBtn.toggled ? Appearance.colors.colSecondaryContainer : Appearance.colors.colOnLayer2
                            }
                        }
                    }
                }
            }
        }

        RippleButton {
            id: parentDirButton
            downAction: () => root.navigateToDirectory(FileUtils.parentDirectory(root.directory))
            contentItem: MaterialSymbol {
                text: "drive_folder_upload"
                iconSize: Appearance.font.pixelSize.larger
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Rectangle {
                id: directoryEntry
                visible: !root.showBreadcrumb
                anchors.fill: parent
                color: Appearance.colors.colLayer1
                radius: Appearance.rounding.full
                implicitWidth: addressInput.implicitWidth
                implicitHeight: addressInput.implicitHeight

                Keys.onPressed: event => {
                    if (directoryEntry.visible && event.key === Qt.Key_Escape) {
                        root.showBreadcrumb = true;
                        event.accepted = true;
                        return;
                    }
                    event.accepted = false;
                }

                StyledTextInput {
                    id: addressInput
                    anchors.fill: parent
                    padding: 10
                    text: root.directory

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            root.navigateToDirectory(text);
                            root.showBreadcrumb = true;
                            event.accepted = true;
                        }
                    }

                    MouseArea {
                        // I-beam cursor
                        anchors.fill: parent
                        acceptedButtons: Qt.NoButton
                        hoverEnabled: true
                        cursorShape: Qt.IBeamCursor
                    }
                }
            }

            Loader {
                id: breadcrumbLoader
                active: root.showBreadcrumb
                visible: root.showBreadcrumb
                anchors.fill: parent
                sourceComponent: AddressBreadcrumb {
                    directory: root.directory
                    onNavigateToDirectory: dir => {
                        root.navigateToDirectory(dir);
                    }
                }
            }
        }

        RippleButton {
            id: dirEditButton
            toggled: !root.showBreadcrumb
            downAction: () => root.showBreadcrumb = !root.showBreadcrumb
            contentItem: MaterialSymbol {
                text: "edit"
                iconSize: Appearance.font.pixelSize.larger
                color: dirEditButton.toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer2
            }

            StyledToolTip {
                text: Translation.tr("Edit directory")
            }
        }
    }
}
