import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell.Io
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Hyprland

import "../bar/weather"
import "../overview"

Item {
    id: root
    height: 50
    implicitWidth: rowLayout.implicitWidth
    property bool pinned: Config.options?.dock.pinnedOnStartup ?? false
    property var updatePinned

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.color: "black"
        border.width: 1
    }

    Component.onCompleted: {
        console.log("Root Item width:", implicitWidth, "height:", height)
    }
    Rectangle {
              anchors.fill : rowLayout
              color: "transparent"
              border.color: "pink"
          }

    RowLayout {
        id: rowLayout
        anchors {
            top: parent.top
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
        }
        spacing: 3
        property real padding: 5
        implicitWidth: root.implicitWidth + spacing * 2 // Account for content + spacing
        implicitHeight: Math.max(childrenRect.height, 50)

        Component.onCompleted: {
            console.log("RowLayout width:", implicitWidth, "height:", implicitHeight)
        }



        function componentFor(type) {
            if (type === "pin") return pinComponent
            if (type === "separator") return separatorComponent
            if (type === "pinnedApps") return pinnedAppsComponent
            if (type === "overview") return overviewComponent
            if (type === "search") return searchComponent
            if (type === "spacer") return spacerComponent
            if (type === "weather") return weatherComponent
            return null
        }


        Component {
            id: pinComponent
            VerticalButtonGroup {
                Layout.topMargin: Appearance.sizes.hyprlandGapsOut // why does this work
                GroupButton {
                    // Pin button
                    baseWidth: 35
                    baseHeight: 35
                    clickedWidth: baseWidth
                    clickedHeight: baseHeight + 20
                    buttonRadius: Appearance.rounding.normal
                    toggled: root.pinned
                    onClicked:
                    root.pinned = updatePinned()
                    contentItem: MaterialSymbol {
                        text: "keep"
                        horizontalAlignment: Text.AlignHCenter
                        iconSize: Appearance.font.pixelSize.larger
                        color: root.pinned ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer0
                    }
                }
            }
        }

        Component {
            id: separatorComponent
            DockSeparator {
                width: 1
                height: root.height / 2.5
            }
        }

        Component {
            id: spacerComponent
            Rectangle {
                width: 80
                color: "yellow"
                height: root.height / 2.5
            }
        }



        Component {
            id: overviewComponent
            Rectangle {
                implicitWidth: button.width
                implicitHeight: root.height
                color: "transparent"
                border.color: "yellow"
                border.width: 1
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                Component.onCompleted: {
                    console.log("Rectangle width:", implicitWidth, "height:", implicitHeight)
                }
                    DockButton {
                        id: button
                        onClicked: GlobalStates.overviewOpen = !GlobalStates.overviewOpen
                        topInset: Appearance.sizes.hyprlandGapsOut + rowLayout.padding
                        bottomInset: Appearance.sizes.hyprlandGapsOut + rowLayout.padding
                        contentItem: MaterialSymbol {
                            anchors.fill: parent
                            horizontalAlignment: Text.AlignHCenter
                            font.pixelSize: root.height / 2.2
                            text: "apps"
                            color: Appearance.colors.colOnLayer0
                        }
                    }
            }

        }

        Component {
            id: searchComponent
            SearchWidget {}
        }

        Component {
            id: weatherComponent
            WeatherBar {}
        }

        Component {
            id: pinnedAppsComponent
            Rectangle {
                implicitWidth: apps.implicitWidth
                implicitHeight: root.height
                color: "transparent"
                border.color: "yellow"
                border.width: 1
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                Component.onCompleted: {
                    console.log("Rectangle width:", implicitWidth, "height:", implicitHeight)
                }
                RowLayout {
                    id: row
                    anchors.fill: parent


                    DockApps {
                        id: apps
                    }

                }
            }
        }


        Repeater {
            model: ["overview","pin", "separator","pinnedApps", "spacer", "spacer" ,"weather" ]
            delegate:
            Loader {
                id: loader
                required property string modelData
                required property int index
                sourceComponent: rowLayout.componentFor(modelData)
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                Component.onCompleted: {
                   // root.implicitWidth += this.implicitWidth
                    console.log("Loader width:", implicitWidth, "height:", implicitHeight, "modelData:", modelData)
                }
            }
        }
    }
}
