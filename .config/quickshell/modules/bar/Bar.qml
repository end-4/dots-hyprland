import "../common"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: barRoot
            property var modelData

            screen: modelData
            height: 40
            color: Appearance.colors.colLayer0

            // Left section
            RowLayout {
                anchors.left: parent.left
            }

            // Middle section
            RowLayout {
                anchors.centerIn: parent
                implicitWidth: 500
                spacing: 8 // TODO: Why is this halved when rendered??

                RowLayout {
                    spacing: 4
                    Layout.fillWidth: true
                    Layout.fillHeight: true
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
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 4

                    ClockWidget {
                        Layout.alignment: Qt.AlignVCenter
                    }

                    UtilButtons {
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
