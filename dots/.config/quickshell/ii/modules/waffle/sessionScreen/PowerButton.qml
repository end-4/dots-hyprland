import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.waffle.looks
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

WSessionScreenTextButton {
    id: root
    implicitWidth: 40
    implicitHeight: 40
    focusRingRadius: Looks.radius.large
    colBackground: ColorUtils.transparentize(Looks.darkColors.bg2)
    colBackgroundHover: Looks.applyContentTransparency(Looks.darkColors.bg2Hover)
    colBackgroundActive: Looks.applyContentTransparency(Looks.darkColors.bg2Active)
    property color color: {
        if (root.down) {
            return root.colBackgroundActive;
        } else if (root.hovered) {
            return root.colBackgroundHover;
        } else {
            return root.colBackground;
        }
    }
    background: Rectangle {
        id: background
        radius: Looks.radius.medium
        color: root.color
    }
    contentItem: Item {
        FluentIcon {
            anchors.centerIn: parent
            implicitSize: 20
            icon: "power"
            color: root.fgColor
        }
    }

    onClicked: {
        powerMenu.visible = !powerMenu.visible;
    }

    WMenu {
        id: powerMenu
        x: -powerMenu.implicitWidth / 2 + root.implicitWidth / 2
        y: -powerMenu.implicitHeight

        color: Looks.darkColors.bg1Base
        Component.onCompleted: {
            powerMenu.backgroundPane.borderColor = Looks.applyContentTransparency(Looks.darkColors.bg2Border);
        }
        delegate: WMenuItem {
            id: menuItemDelegate
            colBackground: ColorUtils.transparentize(Looks.darkColors.bg1Base)
            colBackgroundHover: Looks.applyContentTransparency(Looks.darkColors.bg2Hover)
            colBackgroundActive: Looks.applyContentTransparency(Looks.darkColors.bg2Active)
            colForeground: Looks.darkColors.fg
        }

        Action {
            icon.name: "power"
            text: Translation.tr("Shut down")
            onTriggered: Session.poweroff()
        }
        Action {
            icon.name: "arrow-counterclockwise"
            text: Translation.tr("Restart")
            onTriggered: Session.reboot()
        }
    }
}
