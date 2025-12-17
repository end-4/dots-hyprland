import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.waffle.looks

Rectangle {
    id: root

    color: "#000000"
    readonly property bool usePasswordChars: !PolkitService.flow?.responseVisible ?? true

    Keys.onPressed: event => { // Esc to close
        if (event.key === Qt.Key_Escape) {
            PolkitService.cancel();
        }
    }

    StyledImage {
        anchors.fill: parent
        source: Config.options.background.wallpaperPath
        fillMode: Image.PreserveAspectCrop

        Rectangle {
            anchors.fill: parent
            color: ColorUtils.transparentize("#000000", 0.31)

            PolkitDialog {
                id: dialog
                DragHandler {
                    target: null
                    property real startX: dialog.x
                    property real startY: dialog.y
                    onActiveChanged: {
                        if (!active) return;
                        startX = dialog.x;
                        startY = dialog.y;
                    }
                    xAxis.onActiveValueChanged: {
                        dialog.x = Math.round(startX + xAxis.activeValue);
                    }
                    yAxis.onActiveValueChanged: {
                        dialog.y = Math.round(startY + yAxis.activeValue);
                    }
                }
                x: Math.round((parent.width - width) / 2)
                y: Math.round((parent.height - height) / 2)
            }
        }
    }

    component PolkitDialog: WPane {
        borderColor: Looks.colors.ambientShadow

        contentItem: WPanelPageColumn {
            PolkitDialogHeader {
                Layout.fillWidth: true
            }
            BodyRectangle {
                id: dialogBody
                implicitHeight: bodyContent.implicitHeight + 48
                implicitWidth: 434
                color: Looks.colors.bg1Base

                ColumnLayout {
                    id: bodyContent
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 20

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 15

                        WAppIcon {
                            iconName: PolkitService.flow?.iconName ?? "window-shield"
                            fallback: PolkitService.flow?.iconName == "" ? `${Looks.iconsPath}/window-shield` : PolkitService.flow.iconName
                            isMask: PolkitService.flow?.iconName === ""
                            tryCustomIcon: false
                        }
                        WText {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignLeft
                            font.pixelSize: Looks.font.pixelSize.larger
                            font.weight: Looks.font.weight.strongest
                            text: {
                                const iconName = PolkitService.flow?.iconName ?? "";
                                if (iconName === "")
                                    return Translation.tr("Command-line-invoked Action");
                                const desktopEntry = DesktopEntries.applications.values.find(entry => {
                                    return entry.icon == iconName;
                                });
                                return desktopEntry ? desktopEntry.name : Translation.tr("Unknown Application");
                            }
                        }
                    }

                    WText {
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        horizontalAlignment: Text.AlignLeft
                        text: PolkitService.cleanMessage
                    }

                    WTextField {
                        id: inputField
                        Layout.fillWidth: true
                        focus: true
                        enabled: PolkitService.interactionAvailable
                        placeholderText: PolkitService.cleanPrompt
                        echoMode: root.usePasswordChars ? TextInput.Password : TextInput.Normal
                        onAccepted: PolkitService.submit(inputField.text)

                        Keys.onPressed: event => { // Esc to close
                            if (event.key === Qt.Key_Escape) {
                                PolkitService.cancel();
                            }
                        }

                        Component.onCompleted: forceActiveFocus()
                        Connections {
                            target: PolkitService
                            function onInteractionAvailableChanged() {
                                if (!PolkitService.interactionAvailable)
                                    return;
                                inputField.text = "";
                                inputField.forceActiveFocus();
                            }
                        }
                    }
                }
            }
            BodyRectangle {
                implicitHeight: 80
                color: Looks.colors.bgPanelFooterBase
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 8
                    uniformCellSizes: true

                    WButton {
                        Layout.fillWidth: true
                        implicitHeight: 32
                        colBackground: Looks.colors.bg1
                        horizontalAlignment: Text.AlignHCenter
                        text: Translation.tr("Yes")
                        onClicked: PolkitService.submit(inputField.text)
                    }
                    WButton {
                        Layout.fillWidth: true
                        implicitHeight: 32
                        horizontalAlignment: Text.AlignHCenter
                        checked: true
                        text: Translation.tr("No")
                        onClicked: PolkitService.cancel()
                    }
                }
            }
        }
    }

    component PolkitDialogHeader: BodyRectangle {
        implicitHeight: headerContent.implicitHeight
        color: Looks.colors.bg2Base

        CloseButton {
            anchors {
                top: parent.top
                right: parent.right
            }
            radius: 0
            implicitWidth: 32
            implicitHeight: 32

            onClicked: {
                PolkitService.cancel();
            }
        }

        ColumnLayout {
            id: headerContent
            anchors.fill: parent
            anchors.leftMargin: 24
            anchors.rightMargin: 24
            spacing: 18

            WText {
                Layout.topMargin: 20
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignLeft
                text: Translation.tr("Polkit")
            }
            WText {
                Layout.fillWidth: true
                Layout.bottomMargin: 12
                horizontalAlignment: Text.AlignLeft
                wrapMode: Text.Wrap
                text: Translation.tr("Do you want to allow this app to make changes to your device?")
                font.pixelSize: Looks.font.pixelSize.xlarger
                font.weight: Looks.font.weight.strongest
            }
        }
    }
}
