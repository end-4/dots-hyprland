pragma ComponentBehavior: Bound
import QtQuick
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

    opacity: GlobalStates.overlayOpen ? 1 : 0
    implicitWidth: contentRow.implicitWidth + (padding * 2)
    implicitHeight: contentRow.implicitHeight + (padding * 2)
    color: Appearance.m3colors.m3surfaceContainer
    radius: Appearance.rounding.large
    border.color: Appearance.colors.colOutlineVariant
    border.width: 1

    Behavior on opacity {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    RowLayout {
        id: contentRow
        anchors {
            fill: parent
            margins: root.padding
        }
        spacing: 6

        Row {
            spacing: 4
            Repeater {
                model: ScriptModel {
                    values: OverlayContext.availableWidgets
                }
                delegate: WidgetButton {
                    required property var modelData
                    identifier: modelData.identifier
                    materialSymbol: modelData.materialSymbol
                }
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
            id: boltIcon
            anchors.verticalCenter: parent.verticalCenter
            fill: 1
            text: Battery.isCharging ? "bolt" : "battery_android_full"
            color: batteryWidget.colText
            iconSize: 24
            animateChange: true
        }
        
        StyledText {
            id: batteryText
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
        id: widgetButton
        required property string identifier
        required property string materialSymbol

        Layout.alignment: Qt.AlignVCenter

        toggled: Persistent.states.overlay.open.includes(identifier)
        onClicked: {
            if (widgetButton.toggled) {
                Persistent.states.overlay.open = Persistent.states.overlay.open.filter(type => type !== identifier);
            } else {
                Persistent.states.overlay.open.push(identifier);
            }
        }
        implicitWidth: implicitHeight

        colBackgroundToggled: Appearance.colors.colSecondaryContainer
        colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
        colRippleToggled: Appearance.colors.colSecondaryContainerActive

        buttonRadius: root.radius - (root.height - height) / 2

        contentItem: Item {
            anchors.centerIn: parent
            implicitWidth: 32
            implicitHeight: 32
            MaterialSymbol {
                id: iconWidget
                anchors.centerIn: parent
                iconSize: 24
                text: widgetButton.materialSymbol
                color: widgetButton.toggled ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnSurfaceVariant
            }
        }
    }
}
