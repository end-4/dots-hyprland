import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "root:/modules/common/"
import "root:/modules/common/widgets/"

RippleButton {
    id: buttonWithIconRoot
    property string nerdIcon
    property string iconText
    property string mainText: "Button text"
    property Component mainContentComponent: Component {
        StyledText {
            text: buttonWithIconRoot.mainText
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnSecondaryContainer
        }
    }
    implicitHeight: 35
    horizontalPadding: 15
    buttonRadius: Appearance.rounding.small
    colBackground: Appearance.colors.colLayer2

    contentItem: RowLayout {
        Item {
            implicitWidth: Math.max(materialIconLoader.implicitWidth, nerdIconLoader.implicitWidth)
            Loader {
                id: materialIconLoader
                anchors.centerIn: parent
                active: !nerdIcon
                sourceComponent: MaterialSymbol {
                    text: buttonWithIconRoot.iconText
                    iconSize: Appearance.font.pixelSize.larger
                    color: Appearance.colors.colOnSecondaryContainer
                    fill: 1
                }
            }
            Loader {
                id: nerdIconLoader
                anchors.centerIn: parent
                active: nerdIcon
                sourceComponent: StyledText {
                    text: buttonWithIconRoot.nerdIcon
                    font.pixelSize: Appearance.font.pixelSize.larger
                    font.family: Appearance.font.family.iconNerd
                    color: Appearance.colors.colOnSecondaryContainer
                }
            }
        }
        Loader {
            sourceComponent: buttonWithIconRoot.mainContentComponent
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
