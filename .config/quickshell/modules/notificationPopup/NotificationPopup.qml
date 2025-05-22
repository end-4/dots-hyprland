import "root:/"
import "root:/modules/common/"
import "root:/modules/common/widgets"
import "root:/services"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: notificationPopup

    LazyLoader {
        loading: true
        PanelWindow {
            id: root
            visible: (columnLayout.children.length > 0 || notificationWidgetList.length > 0)
            screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)

            property Component notifComponent: NotificationWidget {}
            property list<NotificationWidget> notificationWidgetList: []

            WlrLayershell.namespace: "quickshell:notificationPopup"
            WlrLayershell.layer: WlrLayer.Overlay
            exclusiveZone: 0

            anchors {
                top: true
                right: true
                bottom: true
            }

            mask: Region {
                item: listview.contentItem
            }

            color: "transparent"
            implicitWidth: Appearance.sizes.notificationPopupWidth

            ListView { // Scrollable window
                id: listview
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCente
                implicitWidth: parent.width - Appearance.sizes.elevationMargin * 2

                add: Transition {
                    animations: [
                        Appearance.animation.elementMove.numberAnimation.createObject(this, {
                            properties: "opacity,scale",
                            from: 0,
                            to: 1,
                        }),
                    ]
                }

                addDisplaced: Transition {
                    animations: [
                        Appearance.animation.elementMove.numberAnimation.createObject(this, {
                            property: "y",
                        }),
                        Appearance.animation.elementMove.numberAnimation.createObject(this, {
                            properties: "opacity,scale",
                            to: 1,
                        }),
                    ]
                }
                
                displaced: Transition {
                    animations: [
                        Appearance.animation.elementMove.numberAnimation.createObject(this, {
                            property: "y",
                        }),
                    ]
                }
                move: Transition {
                    animations: [
                        Appearance.animation.elementMove.numberAnimation.createObject(this, {
                            property: "y",
                        }),
                    ]
                }

                remove: Transition {
                    animations: [
                        Appearance.animation.elementMove.numberAnimation.createObject(this, {
                            property: "x",
                            to: listview.width,
                        }),
                        Appearance.animation.elementMove.numberAnimation.createObject(this, {
                            property: "opacity",
                            to: 0,
                        })
                    ]
                }

                model: ScriptModel {
                    values: Notifications.popupList.slice().reverse()
                }
                delegate: NotificationWidget {
                    required property var modelData
                    id: notificationWidget
                    popup: true
                    anchors.left: parent?.left
                    anchors.right: parent?.right
                    notificationObject: modelData
                }
            }

        }
    }

}
