import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.modules.ii.onScreenDisplay

Item {
    id: root

    property bool locked: KeyboardLocks.numLockOn

    property real valueIndicatorVerticalPadding: 9
    property real valueIndicatorLeftPadding: 10
    property real valueIndicatorRightPadding: 20

    implicitWidth: osdWidth() + 2 * elevationMargin()
    implicitHeight: valueIndicator.implicitHeight + 2 * elevationMargin()

    function osdWidth() { return Appearance.sizes.osdWidth }
    function elevationMargin() { return Appearance.sizes.elevationMargin }

    StyledRectangularShadow {
        target: valueIndicator
    }
    Rectangle {
        id: valueIndicator
        anchors {
            fill: parent
            margins: elevationMargin()
        }
        radius: Appearance.rounding.full
        color: Appearance.colors.colLayer0

        implicitWidth: valueRow.implicitWidth
        implicitHeight: valueRow.implicitHeight

        RowLayout {
            id: valueRow
            Layout.margins: 10
            anchors.fill: parent
            spacing: 10

            Item {
                implicitWidth: 30
                implicitHeight: 30
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: valueIndicatorLeftPadding
                Layout.topMargin: valueIndicatorVerticalPadding
                Layout.bottomMargin: valueIndicatorVerticalPadding

                MaterialSymbol {
                    anchors {
                        centerIn: parent
                    }
                    color: Appearance.colors.colOnLayer0
                    opacity: root.locked ? 1.0 : 0.3
                    renderType: Text.QtRendering

                    text: "pin"
                    iconSize: 20
                }
            }
            RowLayout {
                Layout.alignment: Qt.AlignVCenter
                Layout.rightMargin: valueIndicatorRightPadding
                spacing: 5

                StyledText {
                    color: Appearance.colors.colOnLayer0
                    font.pixelSize: Appearance.font.pixelSize.small
                    Layout.fillWidth: true
                    text: Translation.tr("Num Lock")
                }
                StyledText {
                    color: Appearance.colors.colOnLayer0
                    font.pixelSize: Appearance.font.pixelSize.small
                    Layout.fillWidth: true
                    text: root.locked ? "ON" : "OFF"
                }
            }
        }
    }
}
