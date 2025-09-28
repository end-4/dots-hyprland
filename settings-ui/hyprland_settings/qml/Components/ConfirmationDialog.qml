// hyprland-settings/qml/components/ConfirmationDialog.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import App 1.0
import Controls 1.0

Window {
    id: root
    visible: false
    modality: Qt.ApplicationModal
    width: 400
    height: 240 // Increased height
    color: Theme.surfaceContainerLow
    flags: Qt.Dialog | Qt.FramelessWindowHint

    property var callback: function() {}
    property alias text: dialogText.text

    function openWithCallback(cb) {
        callback = cb;
        visible = true;
        requestActivate()
    }
    
    function close() { visible = false }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        Label {
            text: qsTr("Confirmation")
            font.family: Theme.titleFont.family
            font.pixelSize: Theme.titleFont.pixelSize
            font.weight: Theme.titleFont.weight
            color: Theme.text
        }

        Label {
            id: dialogText
            text: qsTr("Are you sure?")
            color: Theme.subtext
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }
        
        Item { Layout.fillHeight: true }
        
        RowLayout {
            Layout.alignment: Qt.AlignRight | Qt.AlignBottom
            spacing: 8
            
            StyledButton {
                text: qsTr("Cancel")
                onClicked: root.close()
            }
            StyledButton {
                 text: qsTr("OK")
                highlighted: true
                onClicked: {
                    callback();
                    root.close();
                }
            }
        }
    }
}