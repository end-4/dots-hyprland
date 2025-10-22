//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

// Adjust this to make the app smaller or larger
//@ pragma Env QT_SCALE_FACTOR=1

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

ApplicationWindow {
    id: root
    property int conflictCount: 0
    onConflictCountChanged: {
        if (conflictCount === 0) {
            root.close();
        }
    }

    property real contentPadding: 8
    visible: true
    onClosing: {
        Qt.quit()
    }
    title: Translation.tr("Shell conflicts killer")

    Component.onCompleted: {
        Config.readWriteDelay = 0;
        Config.blockWrites = true;
        MaterialThemeLoader.reapplyTheme();
    }

    minimumWidth: 400
    minimumHeight: 300
    maximumWidth: 400
    maximumHeight: 300
    width: 400
    height: 300
    color: Appearance.m3colors.m3background

    component ConflictingProgramGroup: ColumnLayout {
        id: conflictGroup
        required property list<string> programs
        required property string description
        visible: false
        onVisibleChanged: {
            conflictCount += visible ? 1 : -1
        }

        signal alwaysSelected()

        Process {
            running: true
            command: ["pidof", ...conflictGroup.programs]
            onExited: (exitCode, exitStatus) => {
                if (exitCode === 0) {
                    conflictGroup.visible = true
                }
            }
        }

        StyledText {
            text: conflictGroup.programs.join(", ")
            font.pixelSize: Appearance.font.pixelSize.normal
        }
        StyledText {
            font {
                pixelSize: Appearance.font.pixelSize.smaller
                italic: true
            }
            text: conflictGroup.description
            color: Appearance.colors.colSubtext
        }
        RowLayout {
            Layout.alignment: Qt.AlignRight

            RippleButton {
                colBackground: Appearance.colors.colLayer2
                contentItem: StyledText {
                    text: Translation.tr("Always")
                }
                onClicked: {
                    Quickshell.execDetached(["killall", ...conflictGroup.programs])
                    conflictGroup.alwaysSelected()
                    conflictGroup.visible = false
                }
            }
            RippleButton {
                colBackground: Appearance.colors.colLayer2
                contentItem: StyledText {
                    text: Translation.tr("Yes")
                }
                onClicked: {
                    Quickshell.execDetached(["killall", ...conflictGroup.programs])
                    conflictGroup.visible = false
                }
            }
            RippleButton {
                colBackground: Appearance.colors.colLayer2
                contentItem: StyledText {
                    text: Translation.tr("No")
                }
                onClicked: conflictGroup.visible = false
            }
        }
    }

    ColumnLayout {
        anchors {
            fill: parent
            margins: contentPadding
        }

        Item {
            // Titlebar
            visible: Config.options?.windows.showTitlebar
            Layout.fillWidth: true
            implicitHeight: Math.max(welcomeText.implicitHeight, windowControlsRow.implicitHeight)
            StyledText {
                id: welcomeText
                anchors {
                    left: Config.options.windows.centerTitle ? undefined : parent.left
                    horizontalCenter: Config.options.windows.centerTitle ? parent.horizontalCenter : undefined
                    verticalCenter: parent.verticalCenter
                    leftMargin: 12
                }
                color: Appearance.colors.colOnLayer0
                text: Translation.tr("Kill conflicting programs?")
                font.pixelSize: Appearance.font.pixelSize.title
                font.family: Appearance.font.family.title
            }
            RowLayout { // Window controls row
                id: windowControlsRow
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                RippleButton {
                    buttonRadius: Appearance.rounding.full
                    implicitWidth: 35
                    implicitHeight: 35
                    onClicked: root.close()
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        text: "close"
                        iconSize: 20
                    }
                }
            }
        }
        Rectangle {
            // Content container
            color: Appearance.m3colors.m3surfaceContainerLow
            radius: Appearance.rounding.windowRounding - root.contentPadding
            implicitHeight: contentColumn.implicitHeight
            implicitWidth: contentColumn.implicitWidth
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                id: contentColumn
                anchors.fill: parent
                spacing: 12

                ConflictingProgramGroup {
                    id: kded6Group
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillHeight: false
                    programs: ["kded6"]
                    description: Translation.tr("Conflicts with the shell's system tray implementation")
                    onAlwaysSelected: Config.options.conflictKiller.autoKillTrays = true
                }

                ConflictingProgramGroup {
                    id: notificationDaemons
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillHeight: false
                    programs: ["mako", "dunst"]
                    description: Translation.tr("Conflicts with the shell's notification implementation")
                    onAlwaysSelected: Config.options.conflictKiller.autoKillNotificationDaemons = true
                }
                
            }
        }
    }
}
