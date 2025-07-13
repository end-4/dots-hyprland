import "root:/"
import "root:/services"
import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/modules/common/functions/string_utils.js" as StringUtils
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Rectangle {
    id: root
    property bool isInput: true // true for input, false for output
    property string placeholderText
    property string text: ""
    property var inputTextArea: isInput ? inputLoader.item : undefined
    readonly property string displayedText: isInput ? inputLoader.item.text : 
        root.text.length > 0 ? outputLoader.item.text : ""
    default property alias actionButtons: actions.data
    Layout.fillWidth: true
    implicitHeight: Math.max(150, inputColumn.implicitHeight)
    color: isInput ? Appearance.colors.colLayer1 : Appearance.colors.colSurfaceContainer
    radius: Appearance.rounding.normal
    border.color: isInput ? Appearance.colors.colOutlineVariant : "transparent"
    border.width: isInput ? 1 : 0

    signal inputTextChanged(); // Signal emitted when text changes

    ColumnLayout {
        id: inputColumn
        anchors.fill: parent
        spacing: 0

        Loader {
            id: inputLoader
            active: root.isInput
            visible: root.isInput
            Layout.fillWidth: true
            sourceComponent: StyledTextArea { // Input area
                id: inputTextArea
                placeholderText: root.placeholderText
                wrapMode: TextEdit.Wrap
                textFormat: TextEdit.PlainText
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnLayer1
                padding: 15
                background: null
                onTextChanged: root.inputTextChanged()
            }
        }

        Loader {
            id: outputLoader
            active: !root.isInput
            visible: !root.isInput
            Layout.fillWidth: true
            sourceComponent: StyledText { // Output area
                id: outputTextArea
                padding: 15
                wrapMode: Text.Wrap
                font.pixelSize: Appearance.font.pixelSize.small
                color: root.text.length > 0 ? Appearance.colors.colOnLayer1 : Appearance.colors.colSubtext
                text: root.text.length > 0 ? root.text : root.placeholderText
            }
        }

        Item { Layout.fillHeight: true } 

        RowLayout { // Status row
            Layout.fillWidth: true
            Layout.margins: 10
            spacing: 10

            Loader {
                active: root.isInput
                visible: root.isInput
                Layout.leftMargin: 10
                sourceComponent: Text {
                    text: qsTr("%1 characters").arg(inputLoader.item.text.length)
                    color: Appearance.colors.colOnLayer1
                    font.pixelSize: Appearance.font.pixelSize.smaller
                }
            }
            Item { Layout.fillWidth: true }
            ButtonGroup {
                id: actions
            }
        }
    }
}