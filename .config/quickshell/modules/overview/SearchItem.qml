// pragma NativeMethodBehavior: AcceptThisObject
import "root:/"
import "root:/modules/common"
import "root:/modules/common/widgets"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets

Button {
    id: root
    property DesktopEntry desktopEntry
    property string itemName: desktopEntry?.name
    property string itemIcon: desktopEntry?.icon
    property var itemExecute: desktopEntry?.execute
    property string itemClickActionName: desktopEntry?.clickActionName
    
    property int horizontalMargin: 10
    property int buttonHorizontalPadding: 10
    property int buttonVerticalPadding: 5
    property bool keyboardDown: false

    anchors.left: parent?.left
    anchors.right: parent?.right
    implicitHeight: rowLayout.implicitHeight + root.buttonVerticalPadding * 2
    implicitWidth: rowLayout.implicitWidth + root.buttonHorizontalPadding * 2

    PointingHandInteraction {}
    onClicked: {
        root.itemExecute()
        closeOverview.running = true
    }
    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.keyboardDown = true
            root.clicked()
            event.accepted = true;
        }
    }
    Keys.onReleased: (event) => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.keyboardDown = false
            event.accepted = true;
        }
    }

    background: Rectangle {
        anchors.fill: parent
        anchors.leftMargin: root.horizontalMargin
        anchors.rightMargin: root.horizontalMargin
        radius: Appearance.rounding.normal
        color: (root.down || root.keyboardDown) ? Appearance.colors.colLayer1Active : ((root.hovered || root.focus) ? Appearance.colors.colLayer1Hover : Appearance.transparentize(Appearance.m3colors.m3surfaceContainerHigh, 1))
    }

    RowLayout {
        id: rowLayout
        spacing: 10
        anchors.fill: parent
        anchors.leftMargin: root.horizontalMargin + root.buttonHorizontalPadding
        anchors.rightMargin: root.horizontalMargin + root.buttonHorizontalPadding

        IconImage {
            source: Quickshell.iconPath(root.itemIcon);
            width: 35
            height: 35
        }
        StyledText {
            Layout.fillWidth: true
            id: nameText
            font.pixelSize: Appearance.font.pixelSize.normal
            color: Appearance.m3colors.m3onSurface
            horizontalAlignment: Text.AlignLeft
            elide: Text.ElideRight
            text: root.itemName
        }
        StyledText {
            Layout.fillWidth: false
            visible: (root.hovered || root.focus)
            id: clickAction
            font.pixelSize: Appearance.font.pixelSize.normal
            color: Appearance.colors.colSubtext
            horizontalAlignment: Text.AlignRight
            text: root.itemClickActionName
        }
    }

    Process {
        id: closeOverview
        command: ["bash", "-c", "qs ipc call overview close &"] // Somehow has to be async to work?
    }
}