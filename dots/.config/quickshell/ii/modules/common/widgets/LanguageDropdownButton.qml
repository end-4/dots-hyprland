import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

ColumnLayout {
    id: root
    Layout.fillWidth: true
    spacing: 4

    property list<var> options: []
    property var currentValue: null

    signal selected(var newValue)

    function getCurrentDisplayName() {
        for (let i = 0; i < options.length; i++) {
            if (options[i].value === currentValue) {
                return options[i].displayName;
            }
        }
        return "Select language";
    }

    GroupButton {
        id: dropdownButton
        Layout.fillWidth: true
        buttonRadius: height / 2
        buttonRadiusPressed: height / 2
        leftRadius: height / 2
        rightRadius: height / 2
        horizontalPadding: 16
        verticalPadding: 10
        colBackground: Appearance.colors.colSecondaryContainer
        colBackgroundHover: Appearance.colors.colSecondaryContainerHover
        colBackgroundActive: Appearance.colors.colSecondaryContainerActive

        contentItem: RowLayout {
            spacing: 8

            MaterialSymbol {
                Layout.alignment: Qt.AlignVCenter
                text: "language"
                iconSize: Appearance.font.pixelSize.larger
                color: Appearance.colors.colOnSecondaryContainer
            }

            StyledText {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                color: Appearance.colors.colOnSecondaryContainer
                text: root.getCurrentDisplayName()
            }

            MaterialSymbol {
                Layout.alignment: Qt.AlignVCenter
                text: dropdownPopup.visible ? "arrow_drop_up" : "arrow_drop_down"
                iconSize: Appearance.font.pixelSize.larger
                color: Appearance.colors.colOnSecondaryContainer

                Behavior on text {
                    enabled: Appearance.animation.elementMoveFast.numberAnimation !== undefined
                }
            }
        }

        onClicked: {
            dropdownPopup.visible = !dropdownPopup.visible;
        }
    }

    Item {
        id: dropdownPopup
        visible: false
        Layout.fillWidth: true
        implicitHeight: visible ? Math.min(optionColumn.implicitHeight + 16, 300) : 0
        clip: true

        Rectangle {
            anchors.fill: parent
            radius: Appearance.rounding.normal
            color: Appearance.colors.colSurfaceContainerHigh
            border.width: 1
            border.color: Appearance.colors.colOutline

            Flickable {
                id: scrollView
                anchors.fill: parent
                anchors.margins: 8
                contentHeight: optionColumn.implicitHeight
                clip: true

                ColumnLayout {
                    id: optionColumn
                    width: parent.width
                    spacing: 2

                    Repeater {
                        model: root.options

                        delegate: GroupButton {
                            id: optionButton
                            required property var modelData
                            required property int index
                            Layout.fillWidth: true

                            buttonText: modelData.displayName
                            toggled: modelData.value === root.currentValue
                            buttonRadius: Appearance.rounding.small
                            buttonRadiusPressed: Appearance.rounding.small
                            leftRadius: Appearance.rounding.small
                            rightRadius: Appearance.rounding.small
                            horizontalPadding: 12
                            verticalPadding: 8
                            colBackground: "transparent"
                            colBackgroundHover: Appearance.colors.colSecondaryContainerHover
                            colBackgroundActive: Appearance.colors.colSecondaryContainerActive
                            colBackgroundToggled: Appearance.colors.colPrimary
                            colBackgroundToggledHover: Appearance.colors.colPrimaryHover
                            colBackgroundToggledActive: Appearance.colors.colPrimaryActive

                            contentItem: RowLayout {
                                spacing: 8

                                MaterialSymbol {
                                    Layout.alignment: Qt.AlignVCenter
                                    text: "check"
                                    iconSize: Appearance.font.pixelSize.normal
                                    color: optionButton.toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSecondaryContainer
                                    opacity: optionButton.toggled ? 1 : 0

                                    Behavior on opacity {
                                        enabled: Appearance.animation.elementMoveFast.numberAnimation !== undefined
                                        NumberAnimation {
                                            duration: 200
                                            easing.type: Easing.OutCubic
                                        }
                                    }
                                }

                                StyledText {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    color: optionButton.toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSecondaryContainer
                                    text: optionButton.buttonText
                                }
                            }

                            onClicked: {
                                root.selected(modelData.value);
                                dropdownPopup.visible = false;
                            }
                        }
                    }
                }
            }
        }

        Behavior on implicitHeight {
            enabled: Appearance.animation.elementMoveFast.numberAnimation !== undefined
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }

        opacity: visible ? 1 : 0

        Behavior on opacity {
            enabled: Appearance.animation.elementMoveFast.numberAnimation !== undefined
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }
    }
}
