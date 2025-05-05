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
import Quickshell.Hyprland

Button {
    id: root
    property var entry
    property bool entryShown: entry?.shown ?? true
    property string itemType: entry?.type
    property string itemName: entry?.name
    property string itemIcon: entry?.icon ?? ""
    property var itemExecute: entry?.execute
    property string fontType: entry?.fontType ?? "main"
    property string itemClickActionName: entry?.clickActionName
    property string materialSymbol: entry?.materialSymbol ?? ""
    
    visible: root.entryShown
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
        Hyprland.dispatch("global quickshell:overviewClose")
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

        // Icon
        IconImage {
            visible: root.materialSymbol == ""
            source: Quickshell.iconPath(root.itemIcon);
            width: 35
            height: 35
        }
        MaterialSymbol {
            visible: root.materialSymbol != ""
            text: root.materialSymbol
            iconSize: 30
            fill: (root.hovered || root.focus) ? 1 : 0
            color: Appearance.m3colors.m3onSurface
        }

        // Main text
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 0
            StyledText {
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colSubtext
                visible: root.itemType && root.itemType != "App"
                text: root.itemType
            }
            StyledText {
                Layout.fillWidth: true
                id: nameText
                font.pixelSize: Appearance.font.pixelSize.normal
                font.family: Appearance.font.family[root.fontType]
                color: Appearance.m3colors.m3onSurface
                horizontalAlignment: Text.AlignLeft
                elide: Text.ElideRight
                text: `${root.itemName}`
            }
        }

        // Action text
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
}