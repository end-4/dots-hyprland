import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.waffle.looks
import qs.modules.waffle.bar

BarPopup {
    id: root

    closeOnFocusLost: false
    onFocusCleared: {
        print("uwu")
        print(contentItem.children)
        const hasMenuOpen = contentItem.children.some(c => (c.menuOpen));
        if (!hasMenuOpen) root.close();
        else root.grabFocus();
    }

    contentItem: GridLayout {
        id: contentItem
        anchors.centerIn: parent
        columns: Math.ceil(Math.sqrt(TrayService.unpinnedItems.length))
        columnSpacing: 0
        rowSpacing: 0

        Repeater {
            model: TrayService.unpinnedItems
            delegate: TrayButton {
                required property var modelData
                item: modelData

                topInset: 0
                bottomInset: 0
                implicitWidth: 40
                implicitHeight: 40

                colBackground: ColorUtils.transparentize(Looks.colors.bg2)
                colBackgroundHover: Looks.colors.bg2Hover
                colBackgroundActive: Looks.colors.bg2Active

                onMenuOpenChanged: {
                    // The overflow menu should only be closed when the user clicks outside
                    // However the focus grab refuses to reactivate, so we can't have that
                    // But most of the time the user dismisses the menu by clicking outside anyway,
                    // so this is acceptable.
                    if (!menuOpen) { 
                        root.close();
                    }
                }
            }
        }
    }
}

