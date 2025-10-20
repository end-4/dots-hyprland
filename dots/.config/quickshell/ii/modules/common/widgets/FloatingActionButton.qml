import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

/**
 * Material 3 FAB.
 */
RippleButton {
    id: root
    property string iconText: "add"
    property bool expanded: false
    property real baseSize: 56
    property real elementSpacing: 5
    implicitWidth: Math.max(contentRowLayout.implicitWidth + 10 * 2, baseSize)
    implicitHeight: baseSize
    buttonRadius: Appearance.rounding.small
    colBackground: Appearance.colors.colPrimaryContainer
    colBackgroundHover: Appearance.colors.colPrimaryContainerHover
    colRipple: Appearance.colors.colPrimaryContainerActive
    contentItem: RowLayout {
        id: contentRowLayout
        property real horizontalMargins: (root.baseSize - icon.width) / 2
        anchors {
            verticalCenter: parent?.verticalCenter
            left: parent?.left
            leftMargin: contentRowLayout.horizontalMargins
        }
        spacing: 0

        MaterialSymbol {
            id: icon
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            iconSize: 24
            color: Appearance.colors.colOnPrimaryContainer
            text: root.iconText
        }
        Loader {
            active: true
            sourceComponent: Revealer {
                visible: root.expanded || implicitWidth > 0
                reveal: root.expanded
                implicitWidth: reveal ? (buttonText.implicitWidth + root.elementSpacing + contentRowLayout.horizontalMargins) : 0
                StyledText {
                    id: buttonText
                    anchors {
                        left: parent.left
                        leftMargin: root.elementSpacing
                    }
                    text: root.buttonText
                    color: Appearance.colors.colOnPrimaryContainer
                    font.pixelSize: 14
                    font.weight: 450
                }
            }
        }
    }
}
