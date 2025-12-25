import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.ii.sidebarLeft.encoderDecoder
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

/**
 * Base64 encoder/decoder widget.
 */
Item {
    id: root

    // Sizes
    property real padding: 4

    // Widgets
    property var inputField: inputCanvas.inputTextArea
    property var outputField: outputCanvas

    // Widget variables
    property string encodedText: ""
    property string decodedText: ""
    property bool isEncodeMode: true

    onIsEncodeModeChanged: {
        root.processText();
    }

    onFocusChanged: (focus) => {
        if (focus) {
            root.inputField.forceActiveFocus()
        }
    }

    function encodeBase64(text) {
        if (text.length === 0) {
            return "";
        }
        let encoded = "";
        try {
            // Use btoa-like encoding through Qt's Base64 encoding
            encoded = Qt.btoa(text);
        } catch (e) {
            encoded = "Error: " + e.toString();
        }
        return encoded;
    }

    function decodeBase64(text) {
        if (text.length === 0) {
            return "";
        }
        let decoded = "";
        try {
            decoded = Qt.atob(text);
        } catch (e) {
            decoded = "Error: Invalid Base64 string";
        }
        return decoded;
    }

    function processText() {
        const inputText = root.inputField.text;
        if (root.isEncodeMode) {
            root.encodedText = root.encodeBase64(inputText);
            root.decodedText = "";
        } else {
            root.decodedText = root.decodeBase64(inputText);
            root.encodedText = "";
        }
    }

    ColumnLayout {
        anchors {
            fill: parent
            margins: root.padding
        }

        // Mode selector
        RowLayout {
            Layout.fillWidth: true
            Layout.margins: 5
            spacing: 10

            StyledText {
                text: Translation.tr("Mode:")
                color: Appearance.colors.colOnLayer1
                font.pixelSize: Appearance.font.pixelSize.normal
            }

            GroupButton {
                id: encodeButton
                text: Translation.tr("Encode")
                toggled: root.isEncodeMode
                onClicked: {
                    root.isEncodeMode = true;
                }
            }

            GroupButton {
                id: decodeButton
                text: Translation.tr("Decode")
                toggled: !root.isEncodeMode
                onClicked: {
                    root.isEncodeMode = false;
                }
            }

            Item { Layout.fillWidth: true }
        }

        StyledFlickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: contentColumn.implicitHeight

            ColumnLayout {
                id: contentColumn
                anchors.fill: parent

                EncodingCanvas { // Output
                    id: outputCanvas
                    isInput: false
                    placeholderText: root.isEncodeMode ? 
                        Translation.tr("Base64 encoded text will appear here...") :
                        Translation.tr("Decoded text will appear here...")
                    text: root.isEncodeMode ? root.encodedText : root.decodedText
                    
                    GroupButton {
                        id: copyButton
                        baseWidth: height
                        buttonRadius: Appearance.rounding.small
                        enabled: outputCanvas.displayedText.trim().length > 0
                        contentItem: MaterialSymbol {
                            anchors.centerIn: parent
                            horizontalAlignment: Text.AlignHCenter
                            iconSize: Appearance.font.pixelSize.larger
                            text: "content_copy"
                            color: copyButton.enabled ? Appearance.colors.colOnLayer1 : Appearance.colors.colSubtext
                        }
                        onClicked: {
                            Quickshell.clipboardText = outputCanvas.displayedText
                        }
                    }
                }

            }    
        }

        EncodingCanvas { // Input
            id: inputCanvas
            isInput: true
            placeholderText: root.isEncodeMode ? 
                Translation.tr("Enter text to encode to Base64...") :
                Translation.tr("Enter Base64 text to decode...")
            onInputTextChanged: {
                root.processText();
            }
            GroupButton {
                id: pasteButton
                baseWidth: height
                buttonRadius: Appearance.rounding.small
                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    horizontalAlignment: Text.AlignHCenter
                    iconSize: Appearance.font.pixelSize.larger
                    text: "content_paste"
                    color: Appearance.colors.colOnLayer1
                }
                onClicked: {
                    root.inputField.text = Quickshell.clipboardText
                }
            }
            GroupButton {
                id: deleteButton
                baseWidth: height
                buttonRadius: Appearance.rounding.small
                enabled: inputCanvas.inputTextArea.text.length > 0
                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    horizontalAlignment: Text.AlignHCenter
                    iconSize: Appearance.font.pixelSize.larger
                    text: "close"
                    color: deleteButton.enabled ? Appearance.colors.colOnLayer1 : Appearance.colors.colSubtext
                }
                onClicked: {
                    root.inputField.text = ""
                    root.encodedText = ""
                    root.decodedText = ""
                }
            }
        }
    }
}
