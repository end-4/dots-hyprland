import "../common"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
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
                anchors.top: parent.top
                anchors.bottom: parent.top
                anchors.centerIn: parent

                // Rectangle {
                    
                // }

                // ClockWidget {
                //     Layout.fillHeight: true
                // }

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
