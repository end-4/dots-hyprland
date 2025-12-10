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
import qs.modules.common.widgets.widgetCanvas

Rectangle {
    id: root

    property real padding: 8
    property bool settingsMenuOpen: false

    opacity: GlobalStates.overlayOpen ? 1 : 0
    implicitWidth: contentRow.implicitWidth + (padding * 2)
    implicitHeight: contentRow.implicitHeight + (padding * 2)
    color: Appearance.m3colors.m3surfaceContainer
    radius: Appearance.rounding.large
    border.color: Appearance.colors.colOutlineVariant
    border.width: 1

    component FastAnimation: NumberAnimation {
        duration: Appearance.animation.elementMoveFast.duration
        easing.type: Appearance.animation.elementMoveFast.type
        easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
    }

    component BackgroundAnimation: NumberAnimation {
        duration: Appearance.animation.elementMoveFast.duration * 0.2
        easing.type: Appearance.animation.elementMoveFast.type
        easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
    }

    Behavior on opacity { FastAnimation {} }
    Behavior on implicitHeight { FastAnimation {} }
    Behavior on implicitWidth { BackgroundAnimation {} }

    RowLayout {
        id: contentRow
        x: root.padding
        y: root.padding
        spacing: 6

        GearButton {}
        Separator {}
        ListView {
            id: widgetList
            orientation: ListView.Horizontal
            spacing: 4
            implicitWidth: contentWidth
            implicitHeight: contentItem.childrenRect.height
            interactive: false
            clip: true

            Behavior on implicitWidth { FastAnimation {} }

            model: ScriptModel {
                values: OverlayContext.availableWidgets
            }

            add: Transition {
                NumberAnimation {
                    properties: "scale,opacity"
                    from: 0
                    to: 1
                    duration: Appearance.animation.elementMoveFast.duration
                    easing.type: Appearance.animation.elementMoveFast.type
                    easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                }
            }

            remove: Transition {
                NumberAnimation {
                    properties: "scale,opacity"
                    to: 0
                    duration: Appearance.animation.elementMoveFast.duration
                    easing.type: Appearance.animation.elementMoveFast.type
                    easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                }
            }

            displaced: Transition {
                NumberAnimation {
                    properties: "x"
                    duration: Appearance.animation.elementMoveFast.duration
                    easing.type: Appearance.animation.elementMoveFast.type
                    easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                }
            }

            delegate: WidgetButton {
                required property var modelData
                identifier: modelData.identifier
                materialSymbol: modelData.materialSymbol
            }
        }

        Separator {}
        TimeWidget {}

        Separator {
            visible: Battery.available
        }
        BatteryWidget {
            visible: Battery.available
        }
    }

    Rectangle {
        id: settingsPopup
        visible: opacity > 0
        opacity: root.settingsMenuOpen ? 1 : 0

        anchors {
            top: root.bottom
            left: root.left
            topMargin: 8
        }

        width: 260
        implicitHeight: settingsLoader.item ? settingsLoader.item.implicitHeight : 0

        color: Appearance.m3colors.m3surfaceContainer
        radius: Appearance.rounding.large
        border.color: Appearance.colors.colOutlineVariant
        border.width: 1

        scale: root.settingsMenuOpen ? 1 : 0.95
        transformOrigin: Item.Top

        Behavior on opacity { FastAnimation {} }
        Behavior on scale { FastAnimation {} }

        Loader {
            id: settingsLoader
            anchors.fill: parent
            active: root.settingsMenuOpen
            sourceComponent: SettingsMenu {}
        }
    }

    component Separator: Rectangle {
        implicitWidth: 1
        color: Appearance.colors.colOutlineVariant
        Layout.fillHeight: true
        Layout.topMargin: 10
        Layout.bottomMargin: 10
    }

    component TimeWidget: StyledText {
        Layout.alignment: Qt.AlignVCenter
        Layout.leftMargin: 8
        Layout.rightMargin: 6

        text: DateTime.time
        color: Appearance.colors.colOnSurface
        font {
            family: Appearance.font.family.numbers
            variableAxes: Appearance.font.variableAxes.numbers
            pixelSize: 22
        }
    }

    component BatteryWidget: Row {
        id: batteryWidget
        Layout.alignment: Qt.AlignVCenter
        Layout.leftMargin: 6
        Layout.rightMargin: 6
        spacing: 2
        property color colText: Battery.isLowAndNotCharging ? Appearance.colors.colError : Appearance.colors.colOnSurface

        MaterialSymbol {
            anchors.verticalCenter: parent.verticalCenter
            fill: 1
            text: Battery.isCharging ? "bolt" : "battery_android_full"
            color: batteryWidget.colText
            iconSize: 24
            animateChange: true
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round(Battery.percentage * 100) + "%"
            color: batteryWidget.colText
            font {
                family: Appearance.font.family.numbers
                variableAxes: Appearance.font.variableAxes.numbers
                pixelSize: 18
            }
        }
    }

    component WidgetButton: RippleButton {
        required property string identifier
        required property string materialSymbol

        implicitWidth: implicitHeight

        toggled: Persistent.states.overlay.open.includes(identifier)
        buttonRadius: Appearance.rounding.small

        colBackgroundToggled: Appearance.colors.colSecondaryContainer
        colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
        colRippleToggled: Appearance.colors.colSecondaryContainerActive

        onClicked: {
            const openWidgets = Persistent.states.overlay.open
            Persistent.states.overlay.open = toggled ?
            openWidgets.filter(type => type !== identifier) :
            [...openWidgets, identifier]
        }

        contentItem: Item {
            implicitWidth: 32
            implicitHeight: 32

            MaterialSymbol {
                anchors.centerIn: parent
                iconSize: 24
                text: parent.parent.materialSymbol
                color: parent.parent.toggled ?
                Appearance.colors.colOnSecondaryContainer :
                Appearance.colors.colOnSurfaceVariant
            }
        }
    }

    component GearButton: MaterialSymbol {
        Layout.alignment: Qt.AlignVCenter
        Layout.leftMargin: 4
        Layout.rightMargin: 4

        iconSize: 22
        text: "settings"
        fill: root.settingsMenuOpen ? 1 : 0
        color: Appearance.colors.colOnSurfaceVariant

        MouseArea {
            anchors.centerIn: parent
            width: parent.width + 8
            height: parent.height + 8
            cursorShape: Qt.PointingHandCursor
            onClicked: root.settingsMenuOpen = !root.settingsMenuOpen
        }
    }


    component SettingsMenu: Item {
        implicitHeight: Math.min(menuContent.implicitHeight + 16, 340)
        implicitWidth: 260

        ScrollView {
            anchors {
                fill: parent
                topMargin: 8
                bottomMargin: 8
            }
            clip: true
            contentWidth: -1

            Column {
                id: menuContent
                width: 260
                leftPadding: 8
                rightPadding: 8
                spacing: 2

                Repeater {
                    model: Object.keys(OverlayContext.widgetSymbols).map(key => ({
                        identifier: key,
                        materialSymbol: OverlayContext.widgetSymbols[key],
                        widgetName: key.replace(/([A-Z])/g, ' $1').trim().replace(/^\w/, c => c.toUpperCase())
                    }))

                    delegate: SettingsMenuItem {
                        required property var modelData
                        identifier: modelData.identifier
                        materialSymbol: modelData.materialSymbol
                        widgetName: modelData.widgetName
                    }
                }
            }
        }
    }

    component SettingsMenuItem: RippleButton {
        required property string identifier
        required property string materialSymbol
        required property string widgetName

        property bool isActive: Config.options.overlay.buttons.includes(identifier)

        width: 244
        height: 36

        toggled: isActive
        buttonRadius: Appearance.rounding.small

        colBackgroundToggled: Appearance.colors.colSecondaryContainer
        colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
        colRippleToggled: Appearance.colors.colSecondaryContainerActive

        onClicked: {
            const buttons = Config.options.overlay.buttons
            Config.options.overlay.buttons = isActive ?
            buttons.filter(id => id !== identifier) :
            [...buttons, identifier]
        }

        contentItem: RowLayout {
            spacing: 8
            anchors {
                fill: parent
                leftMargin: 12
                rightMargin: 12
            }

            MaterialSymbol {
                Layout.alignment: Qt.AlignVCenter
                iconSize: 20
                text: parent.parent.materialSymbol
                color: parent.parent.isActive ?
                Appearance.colors.colOnSecondaryContainer :
                Appearance.colors.colOnSurfaceVariant
            }

            StyledText {
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
                text: parent.parent.widgetName
                elide: Text.ElideRight
                color: parent.parent.isActive ?
                Appearance.colors.colOnSecondaryContainer :
                Appearance.colors.colOnSurface
                font.pixelSize: Appearance.font.pixelSize.small
            }

            MaterialSymbol {
                Layout.alignment: Qt.AlignVCenter
                iconSize: 18
                text: "star"
                fill: parent.parent.isActive ? 1 : 0
                color: parent.parent.isActive ?
                Appearance.colors.colOnSecondaryContainer :
                Appearance.colors.colOnSurfaceVariant
            }
        }
    }
}
