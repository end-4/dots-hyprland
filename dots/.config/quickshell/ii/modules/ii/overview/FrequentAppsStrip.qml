pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services

Item {
    id: root

    required property real availableWidth
    signal appOpened()

    readonly property real margin: Appearance.sizes.elevationMargin
    readonly property int buttonSize: 44
    readonly property int visibleCount: Math.max(0, Math.floor((availableWidth - 2 * margin + appRow.spacing) / (buttonSize + appRow.spacing)))
    readonly property var apps: FrequentApps.entries.slice(0, visibleCount)

    implicitWidth: appRow.implicitWidth + 2 * margin
    implicitHeight: appRow.implicitHeight + 2 * margin

    Row {
        id: appRow
        anchors.centerIn: parent
        spacing: 6

        Repeater {
            model: root.apps
            RippleButton {
                id: appButton
                required property var modelData
                implicitWidth: root.buttonSize
                implicitHeight: root.buttonSize
                buttonRadius: Appearance.rounding.normal
                colBackground: Appearance.colors.colBackgroundSurfaceContainer
                colBackgroundHover: ColorUtils.transparentize(colBackground, 0.5)
                text: modelData.name
                contentItem: Item {
                    IconImage {
                        anchors.centerIn: parent
                        implicitSize: 28
                        source: Quickshell.iconPath(appButton.modelData.icon, "application-x-executable")
                    }
                }
                StyledToolTip {
                    text: appButton.text
                }
                onClicked: {
                    LauncherSearch.launchApp(modelData);
                    root.appOpened();
                }
            }
        }
    }
}
