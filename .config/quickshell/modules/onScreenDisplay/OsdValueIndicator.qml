import "root:/services"
import "root:/modules/common"
import "root:/modules/common/widgets"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Qt5Compat.GraphicalEffects

Item {
    id: root
    required property real value
    required property string icon
    required property string name

    property real valueIndicatorVerticalPadding: 5
    property real valueIndicatorLeftPadding: 10
    property real valueIndicatorRightPadding: 20 // An icon is circle ish, a column isn't, hence the extra padding

    Layout.margins: Appearance.sizes.elevationMargin
    implicitWidth: valueIndicator.implicitWidth
    implicitHeight: valueIndicator.implicitHeight

    WrapperRectangle {
        id: valueIndicator
        radius: Appearance.rounding.full
        color: Appearance.colors.colLayer0
        implicitWidth: valueRow.implicitWidth

        RowLayout { // Icon on the left, stuff on the right
            id: valueRow
            spacing: 5
            Layout.margins: 10

            MaterialSymbol { // Icon
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: valueIndicatorLeftPadding
                Layout.topMargin: valueIndicatorVerticalPadding
                Layout.bottomMargin: valueIndicatorVerticalPadding
                text: root.icon
                font.pixelSize: 30
            }
            ColumnLayout { // Stuff
                Layout.alignment: Qt.AlignVCenter
                Layout.rightMargin: valueIndicatorRightPadding
                spacing: 5

                RowLayout { // Name fill left, value on the right end
                    Layout.leftMargin: valueBarHeight / 2 // Align text with progressbar radius curve's left end
                    Layout.rightMargin: valueBarHeight / 2 // Align text with progressbar radius curve's left end

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
                    value: root.value
                }
            }
        }
    }

    DropShadow {
        id: valueShadow
        anchors.fill: valueIndicator
        source: valueIndicator
        radius: Appearance.sizes.elevationMargin
        samples: radius * 2 + 1
        color: Appearance.colors.colShadow
        verticalOffset: 2
        horizontalOffset: 0
    }
}