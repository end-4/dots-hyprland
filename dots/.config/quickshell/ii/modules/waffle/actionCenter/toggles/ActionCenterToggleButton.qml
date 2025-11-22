pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.models.quickToggles
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.waffle.looks
import qs.modules.waffle.actionCenter

// It should be perfectly fine to use just a Column here, but somehow
// using ColumnLayout prevents weird opening anim stutter
ColumnLayout { 
    id: root

    required property QuickToggleModel toggleModel
    property string name: toggleModel?.name ?? ""
    property string statusText: (toggleModel?.hasStatusText) ? (toggleModel?.statusText || (toggled ? Translation.tr("Active") : Translation.tr("Inactive"))) : ""
    property string tooltipText: toggleModel?.tooltipText ?? ""
    required property string icon
    property bool available: toggleModel?.available ?? true
    property bool toggled: toggleModel?.toggled ?? false
    property var mainAction: toggleModel?.mainAction ?? null
    property var altAction: toggleModel?.hasMenu ? (() => root.openMenu()) : (toggleModel?.altAction ?? null)
    property bool hasMenu: toggleModel?.hasMenu ?? false
    property Component menu

    property color colBackground: toggled ? Looks.colors.accent : Looks.colors.bg2
    property color colBackgroundHovered: toggled ? Looks.colors.accentHover : Looks.colors.bg2Hover
    property color colBackgroundActive: toggled ? Looks.colors.accentActive : Looks.colors.bg2Active
    property color colBorder: toggled ? Looks.colors.accentHover : Looks.colors.bg2Border
    property color colForeground: toggled ? Looks.colors.accentFg : Looks.colors.fg1

    spacing: 0
    property real wholeToggleWidth: 96

    AcrylicRectangle {
        Layout.fillWidth: true
        implicitWidth: root.wholeToggleWidth
        implicitHeight: 48
        color: root.colBackground
        radius: Looks.radius.medium

        RowLayout {
            anchors.fill: parent
            spacing: 0

            ToggleFragment {
                topLeftRadius: Looks.radius.medium
                bottomLeftRadius: Looks.radius.medium
                topRightRadius: root.hasMenu ? 0 : Looks.radius.medium
                bottomRightRadius: root.hasMenu ? 0 : Looks.radius.medium
                iconName: root.icon
                onClicked: root.mainAction && root.mainAction()
            }
            FadeLoader {
                Layout.fillHeight: true
                Layout.fillWidth: true
                shown: root.hasMenu
                sourceComponent: ToggleFragment {
                    topLeftRadius: 0
                    bottomLeftRadius: 0
                    topRightRadius: Looks.radius.medium
                    bottomRightRadius: Looks.radius.medium
                    iconName: "chevron-right"
                    onClicked: {
                        ActionCenterContext.stackView.push(root.menu)
                    }
                }
            }
        }
    }

    Item {
        id: toggleNameWidget
        implicitWidth: root.wholeToggleWidth
        implicitHeight: 36
        WText {
            id: toggleNameText
            anchors {
                verticalCenter: parent.verticalCenter
                left: parent.left
                right: parent.right
            }
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: root.name
        }
    }

    component ToggleFragment: WButton {
        id: toggleFragment
        required property string iconName
        Layout.fillHeight: true
        Layout.fillWidth: true
        inset: 0
        backgroundOpacity: 0.8
        checked: root.toggled
        border.width: 1
        border.color: root.colBorder

        contentItem: Item {
            anchors.centerIn: parent
            FluentIcon {
                anchors.centerIn: parent
                icon: toggleFragment.iconName
                implicitSize: 18
                monochrome: true
                filled: root.toggled
                color: root.colForeground
            }
        }
    }
}
