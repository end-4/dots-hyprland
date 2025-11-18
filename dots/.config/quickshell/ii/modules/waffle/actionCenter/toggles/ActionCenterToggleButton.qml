pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.models.quickToggles
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.waffle.looks

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

    property color colBackground: toggled ? Looks.colors.accent : Looks.colors.bg2
    property color colBackgroundHovered: toggled ? Looks.colors.accentHover : Looks.colors.bg2Hover
    property color colBackgroundActive: toggled ? Looks.colors.accentActive : Looks.colors.bg2Active
    property color colBorder: toggled ? Looks.colors.accentHover : Looks.colors.bg0Border
    property color colForeground: toggled ? Looks.colors.accentFg : Looks.colors.fg1

    spacing: 0
    property real wholeToggleWidth: 96

    Rectangle {
        Layout.fillWidth: true
        implicitWidth: root.wholeToggleWidth
        implicitHeight: 48
        color: root.colBackground
        radius: Looks.radius.medium

        RowLayout {
            anchors.fill: parent
            spacing: 0

            WButton {
                Layout.fillHeight: true
                Layout.fillWidth: true
                inset: 0
                backgroundOpacity: 0.8
                checked: root.toggled
                border.width: 1
                border.color: root.colBorder
                topLeftRadius: Looks.radius.medium
                bottomLeftRadius: Looks.radius.medium
                topRightRadius: root.hasMenu ? 0 : Looks.radius.medium
                bottomRightRadius: root.hasMenu ? 0 : Looks.radius.medium
                onClicked: root.mainAction && root.mainAction()
                contentItem: Item {
                    anchors.centerIn: parent
                    FluentIcon {
                        anchors.centerIn: parent
                        icon: root.icon
                        implicitSize: 18
                        monochrome: true
                        filled: root.toggled
                        color: root.colForeground
                    }
                }
            }
            FadeLoader {
                Layout.fillHeight: true
                Layout.fillWidth: true
                shown: root.hasMenu
                sourceComponent: WButton {
                    inset: 0
                    backgroundOpacity: 0.8
                    checked: root.toggled
                    border.width: 1
                    border.color: root.colBorder
                    topLeftRadius: 0
                    bottomLeftRadius: 0
                    topRightRadius: Looks.radius.medium
                    bottomRightRadius: Looks.radius.medium
                    contentItem: Item {
                        anchors.centerIn: parent
                        FluentIcon {
                            anchors.centerIn: parent
                            icon: "chevron-right"
                            implicitSize: 18
                            monochrome: true
                            color: root.colForeground
                        }
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
}
