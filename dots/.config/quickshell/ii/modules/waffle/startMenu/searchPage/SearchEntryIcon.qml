import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.models
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.waffle.looks

Item {
    id: root
    required property LauncherSearchResult entry
    property int iconSize: 24
    implicitWidth: Math.max(iconSize, textIconLoader.implicitWidth)
    implicitHeight: iconSize
    Loader {
        anchors.centerIn: parent
        active: root.entry.iconType === LauncherSearchResult.IconType.System && root.entry.iconName !== ""
        sourceComponent: WAppIcon {
            implicitSize: root.iconSize
            iconName: root.entry.iconName
            tryCustomIcon: false
            animated: false
        }
    }
    Loader {
        id: textIconLoader
        anchors.centerIn: parent
        active: root.entry.iconType === LauncherSearchResult.IconType.Text
        sourceComponent: WText {
            text: root.entry.iconName
            font.pixelSize: root.iconSize
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }
    Loader {
        anchors.centerIn: parent
        active: root.entry.iconType === LauncherSearchResult.IconType.Material || root.entry.iconType === LauncherSearchResult.IconType.None || root.entry.iconName === ""
        sourceComponent: FluentIcon {
            icon: root.entry.iconName ? WIcons.fluentFromMaterial(root.entry.iconName) : WIcons.guessIconForName(root.entry.name)
            implicitSize: root.iconSize
            animated: false
        }
    }
}
