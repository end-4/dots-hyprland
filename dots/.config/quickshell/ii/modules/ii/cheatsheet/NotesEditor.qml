import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root

    property alias text: textArea.text
    property string filePath: ""
    property bool unlocked: false
    
    signal backRequested()
    signal saveRequested()
    signal renameRequested()
    signal encryptRequested()
    signal decryptRequested()
    signal deleteRequested()
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15

        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            
            ConfigButton {
                icon: "arrow_back"
                onClicked: root.backRequested()
            }

            MaterialSymbol {
                text: root.filePath.endsWith(".enc") ? "lock" : "lock_open"
                iconSize: 20
                color: root.filePath.endsWith(".enc") ? Appearance.colors.colPrimary : "#666666"
            }

            Label {
                text: root.filePath.split('/').pop().replace(/\.(txt|enc)$/, "")
                font.pixelSize: 18
                font.bold: true
                color: "#FFFFFF"
                Layout.fillWidth: true
                elide: Text.ElideLeft
            }

            Label {
                id: savedLabel
                text: "Saved"
                color: Appearance.colors.colPrimary
                opacity: 0
                font.bold: true
                Behavior on opacity { NumberAnimation { duration: 200 } }
                
                Timer { 
                    id: notifyTimer
                    interval: 1500
                    onTriggered: savedLabel.opacity = 0
                }
            }

            ConfigButton {
                icon: "edit"
                text: "Rename"
                enabled: root.unlocked
                onClicked: root.renameRequested()
            }

            ConfigButton {
                icon: "save"
                text: "Save"
                enabled: root.unlocked
                onClicked: root.saveRequested()
            }

            ConfigButton {
                icon: "enhanced_encryption"
                text: "Encrypt"
                visible: root.unlocked && !root.filePath.endsWith(".enc")
                onClicked: root.encryptRequested()
            }

            ConfigButton {
                icon: "lock_open"
                text: "Decrypt"
                visible: root.unlocked && root.filePath.endsWith(".enc")
                onClicked: root.decryptRequested()
            }

            ConfigButton {
                icon: "delete"
                text: "Delete"
                enabled: root.unlocked
                customColor: "#FF4444"
                onClicked: root.deleteRequested()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 12
            color: "#1A1A1A"
            border.width: 1
            border.color: "#333333"
            clip: true

            ScrollView {
                id: editorScroll
                anchors.fill: parent
                anchors.margins: 15

                Column {
                    y: textArea.topPadding
                    width: 20
                    spacing: 0
                    Repeater {
                        model: textArea.lineCount
                        delegate: Text {
                            text: "- "
                            font: textArea.font
                            color: "#666666"
                            height: textArea.cursorRectangle.height 
                            visible: index < textArea.lineCount
                        }
                    }
                }

                TextArea {
                    id: textArea
                    readOnly: !root.unlocked
                    placeholderText: root.unlocked ? "Start writing..." : "Locked"
                    color: "#E0E0E0"
                    selectionColor: Appearance.colors.colPrimary
                    selectedTextColor: Appearance.colors.colOnPrimary
                    font.pixelSize: 16
                    background: null
                    wrapMode: TextEdit.Wrap
                    leftPadding: 20 

                    Keys.onPressed: (event) => {
                        if (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_X) {
                            event.accepted = true
                            root.backRequested()
                        }
                    }
                }
            }
            
            Item {
                id: lockFeedback
                anchors.centerIn: parent
                width: 100; height: 100
                opacity: 0
                visible: opacity > 0
                property string iconName: "lock"

                Rectangle {
                    anchors.fill: parent
                    radius: 50
                    color: "#CC000000"
                }
                MaterialSymbol {
                    anchors.centerIn: parent
                    text: lockFeedback.iconName
                    iconSize: 48
                    color: Appearance.colors.colPrimary
                }
                SequentialAnimation {
                    id: lockAnim
                    PropertyAction { target: lockFeedback; property: "scale"; value: 0.5 }
                    PropertyAction { target: lockFeedback; property: "opacity"; value: 0 }
                    ParallelAnimation {
                        NumberAnimation { target: lockFeedback; property: "opacity"; to: 1; duration: 150 }
                        NumberAnimation { target: lockFeedback; property: "scale"; to: 1.2; duration: 200; easing.type: Easing.OutBack }
                    }
                    NumberAnimation { target: lockFeedback; property: "scale"; to: 1.0; duration: 100 }
                    PauseAnimation { duration: 800 }
                    NumberAnimation { target: lockFeedback; property: "opacity"; to: 0; duration: 200 }
                }
            }
        }
    }

    function notify(msg) {
        savedLabel.text = msg
        savedLabel.opacity = 1
        notifyTimer.start()
    }

    function triggerLockAnim(isLocking) {
        lockFeedback.iconName = isLocking ? "lock" : "lock_open"
        lockAnim.restart()
    }
}