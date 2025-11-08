import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item {
    id: root
    implicitWidth: dropdownButton.implicitWidth
    implicitHeight: dropdownButton.implicitHeight

    property list<var> options: []
    property var currentValue: null

    property string buttonText: ""
    property string buttonIcon: ""
    property string placeholder: "Select..."
    property Component buttonContent: null

    property Component itemDelegate: null
    property real maxPopupHeight: 300

    property real buttonRadius: dropdownButton.height / 2
    property color buttonBackground: Appearance.colors.colSecondaryContainer
    property color buttonBackgroundHover: Appearance.colors.colSecondaryContainerHover
    property color buttonBackgroundActive: Appearance.colors.colSecondaryContainerActive

    property bool popupVisible: false

    signal selected(var newValue)

    function findWindowRoot() {
        var p = root.parent;
        while (p && p.parent) {
            p = p.parent;
        }
        return p || root.parent;
    }

    function getGlobalPosition() {
        var windowRoot = findWindowRoot();
        if (windowRoot) {
            return root.mapToItem(windowRoot, 0, 0);
        }
        return {
            x: 0,
            y: 0
        };
    }

    function getCurrentDisplayName() {
        for (let i = 0; i < options.length; i++) {
            if (options[i].value === currentValue) {
                return options[i].displayName;
            }
        }
        return placeholder;
    }

    GroupButton {
        id: dropdownButton
        anchors.fill: parent
        buttonRadius: root.buttonRadius
        buttonRadiusPressed: root.buttonRadius
        leftRadius: root.buttonRadius
        rightRadius: root.buttonRadius
        horizontalPadding: 16
        verticalPadding: 10
        colBackground: root.buttonBackground
        colBackgroundHover: root.buttonBackgroundHover
        colBackgroundActive: root.buttonBackgroundActive

        contentItem: Loader {
            sourceComponent: root.buttonContent || defaultButtonContent
        }

        onClicked: {
            root.popupVisible = !root.popupVisible;
        }
    }

    Component {
        id: defaultButtonContent

        RowLayout {
            spacing: 8

            Loader {
                Layout.alignment: Qt.AlignVCenter
                active: root.buttonIcon.length > 0
                visible: active
                sourceComponent: MaterialSymbol {
                    text: root.buttonIcon
                    iconSize: Appearance.font.pixelSize.larger
                    color: Appearance.colors.colOnSecondaryContainer
                }
            }

            StyledText {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                color: Appearance.colors.colOnSecondaryContainer
                text: root.buttonText || root.getCurrentDisplayName()
            }

            MaterialSymbol {
                Layout.alignment: Qt.AlignVCenter
                text: root.popupVisible ? "arrow_drop_up" : "arrow_drop_down"
                iconSize: Appearance.font.pixelSize.larger
                color: Appearance.colors.colOnSecondaryContainer
            }
        }
    }

    Rectangle {
        id: scrim
        visible: root.popupVisible
        parent: root.findWindowRoot()
        anchors.fill: parent
        color: "transparent"
        z: 999

        MouseArea {
            anchors.fill: parent
            onClicked: {
                root.popupVisible = false;
            }
        }
    }

    Timer {
        id: positionTracker
        interval: 8 // is this smooth enough?
        repeat: true
        running: root.popupVisible
        onTriggered: {
            if (popupContent.visible) {
                var pos = root.getGlobalPosition();
                popupContent.x = pos.x;
                popupContent.y = pos.y + root.height + 4;
            }
        }
    }

    Rectangle {
        id: popupContent
        visible: root.popupVisible
        z: 1000

        parent: root.findWindowRoot()

        width: Math.max(dropdownButton.width, optionColumn.implicitWidth + 16)
        height: Math.min(optionColumn.implicitHeight + 16, root.maxPopupHeight)

        radius: Appearance.rounding.normal
        color: Appearance.colors.colSurfaceContainerHigh

        Flickable {
            id: scrollView
            anchors.fill: parent
            anchors.margins: 8
            contentWidth: optionColumn.implicitWidth
            contentHeight: optionColumn.implicitHeight
            clip: true

            ColumnLayout {
                id: optionColumn
                width: Math.max(implicitWidth, scrollView.width)
                spacing: 2

                Repeater {
                    model: root.options

                    delegate: Loader {
                        id: itemLoader
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true

                        sourceComponent: root.itemDelegate || defaultItemDelegate

                        onLoaded: {
                            if (item) {
                                item.modelData = Qt.binding(() => modelData);
                                item.index = Qt.binding(() => index);
                            }
                        }
                    }
                }
            }
        }

        opacity: visible ? 1 : 0
        scale: visible ? 1 : 0.95
        transformOrigin: Item.Top

        Behavior on opacity {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }

        Behavior on height {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }
    }

    Component {
        id: defaultItemDelegate

        GroupButton {
            id: optionButton
            property var modelData
            property int index

            buttonText: modelData?.displayName || ""
            toggled: modelData?.value === root.currentValue
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
                        NumberAnimation {
                            duration: 150
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
                root.popupVisible = false;
            }
        }
    }
}
