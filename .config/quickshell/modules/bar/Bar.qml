import "../common"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

Scope {
    id: bar

    readonly property int barHeight: 40
    readonly property int sideCenterModuleWidth: 360

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: barRoot

            property var modelData

            screen: modelData
            height: barHeight
            color: Appearance.colors.colLayer0

            // Left section
            RowLayout {
                anchors.left: parent.left
                implicitHeight: barHeight

                ActiveWindow {
                    bar: barRoot
                }

            }

            // Middle section
            RowLayout {
                anchors.centerIn: parent
                spacing: 8

                RowLayout {
                    Layout.preferredWidth: sideCenterModuleWidth
                    spacing: 4
                    Layout.fillHeight: true
                    implicitWidth: 350

                    Resources {
                    }

                    Media {
                        Layout.fillWidth: true
                    }

                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 4

                    Workspaces {
                        bar: barRoot
                    }

                }

                RowLayout {
                    Layout.preferredWidth: sideCenterModuleWidth
                    Layout.fillHeight: true
                    spacing: 4

                    ClockWidget {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.fillWidth: true
                    }

                    UtilButtons {
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Battery {
                        Layout.alignment: Qt.AlignVCenter
                    }

                }

            }

            // Right section
            RowLayout {
                anchors.right: parent.right
            }

            anchors {
                top: true
                left: true
                right: true
            }

        }

    }

}
