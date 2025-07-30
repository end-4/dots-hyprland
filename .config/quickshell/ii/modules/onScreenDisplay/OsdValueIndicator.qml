import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
// import Qt5Compat.GraphicalEffects

Item {
    id: root
    required property real value
    required property string icon
    required property string name
    property bool rotateIcon: false
    property bool scaleIcon: false

    property real valueIndicatorVerticalPadding: 9
    property real valueIndicatorLeftPadding: 10
    property real valueIndicatorRightPadding: 20 // An icon is circle ish, a column isn't, hence the extra padding

    Layout.margins: Appearance.sizes.elevationMargin
    implicitWidth: Appearance.sizes.osdWidth
    implicitHeight: valueIndicator.implicitHeight

    StyledRectangularShadow {
        target: valueIndicator
    }
    WrapperRectangle {
        id: valueIndicator
        anchors.fill: parent
        radius: Appearance.rounding.full
        color: Appearance.colors.colLayer0
        implicitWidth: valueRow.implicitWidth

        RowLayout { // Icon on the left, stuff on the right
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
                MaterialSymbol { // Icon
                    anchors {
                        centerIn: parent
                        alignWhenCentered: !root.rotateIcon
                    }
                    color: Appearance.colors.colOnLayer0
                    renderType: Text.QtRendering

                    text: root.icon
                    iconSize: 20 + 10 * (root.scaleIcon ? value : 1)
                    rotation: 180 * (root.rotateIcon ? value : 0)

                    Behavior on iconSize {
                        animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
                    }
                    Behavior on rotation {
                        animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
                    }
                
                }
            }
            ColumnLayout { // Stuff
                Layout.alignment: Qt.AlignVCenter
                Layout.rightMargin: valueIndicatorRightPadding
                spacing: 5

                RowLayout { // Name fill left, value on the right end
                    Layout.leftMargin: valueProgressBar.height / 2 // Align text with progressbar radius curve's left end
                    Layout.rightMargin: valueProgressBar.height / 2 // Align text with progressbar radius curve's left end

                    StyledText {
                        color: Appearance.colors.colOnLayer0
                        font.pixelSize: Appearance.font.pixelSize.small
                        Layout.fillWidth: true
                        text: root.name
                    }

                    StyledText {
                        color: Appearance.colors.colOnLayer0
                        font.pixelSize: Appearance.font.pixelSize.small
                        Layout.fillWidth: false
                        text: Math.round(root.value * 100)
                    }
                }
                
                StyledProgressBar {
                    id: valueProgressBar
                    Layout.fillWidth: true
                    value: root.value
                }
            }
        }
    }
}