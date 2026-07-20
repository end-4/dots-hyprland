import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property string letter: ""

    // Not focusable/clickable - purely a section label between app groups
    focus: false
    activeFocusOnTab: false

    implicitHeight: letterText.implicitHeight + topPadding + bottomPadding
    property int horizontalMargin: 10
    property int buttonHorizontalPadding: 10
    property int topPadding: 10
    property int bottomPadding: 2

    StyledText {
        id: letterText
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            leftMargin: root.horizontalMargin + root.buttonHorizontalPadding
            rightMargin: root.horizontalMargin + root.buttonHorizontalPadding
            topMargin: root.topPadding
        }
        text: root.letter.toUpperCase()
        font.pixelSize: Appearance.font.pixelSize.smaller
        font.weight: Font.DemiBold
        color: Appearance.colors.colSubtext
    }
}