import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root
    anchors.fill: parent
    z: 200

    property string mode: "none" // none, unlock, create, rename, encrypt, decrypt
    property bool unsavedVisible: false
    property bool deleteVisible: false

    signal actionConfirmed(string mode, string text1, string text2)
    signal unsavedAction(string action) 
    signal deleteConfirmed()
    
    function resetInputs() {
        input1.text = ""
        input2.text = ""
    }
    
    function focusInput() {
        input1.forceActiveFocus()
    }
    
    function setInput1(val) { input1.text = val }
    
    Rectangle {
        id: unsavedOverlay
        anchors.fill: parent
        color: "#D0000000"
        visible: root.unsavedVisible
        opacity: visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        
        MouseArea { anchors.fill: parent } 
        Rectangle {
            width: 320; height: 180
            anchors.centerIn: parent
            color: "#252525"
            radius: 16
            border.width: 1; border.color: "#444444"
            scale: unsavedOverlay.visible ? 1 : 0.8
            Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }

            ColumnLayout {
                anchors.centerIn: parent
                width: parent.width - 40
                spacing: 20
                
                ColumnLayout {
                    spacing: 8
                    Layout.fillWidth: true
                    MaterialSymbol { text: "save_as"; iconSize: 32; color: "#FFFFFF" }
                    Label { text: "Unsaved Changes"; font.bold: true; font.pixelSize: 18; color: "#FFFFFF" }
                    Label { text: "Save changes before closing?"; color: "#AAAAAA"; font.pixelSize: 14 }
                }
                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    ConfigButton {
                        text: "Discard"
                        Layout.fillWidth: true
                        onClicked: root.unsavedAction("discard")
                    }
                    ConfigButton {
                        text: "Save"
                        highlighted: true
                        Layout.fillWidth: true
                        onClicked: root.unsavedAction("save")
                    }
                }
            }
        }
    }

    Rectangle {
        id: deleteOverlay
        anchors.fill: parent
        color: "#D0000000"
        visible: root.deleteVisible
        opacity: visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        
        MouseArea { anchors.fill: parent }

        Rectangle {
            width: 320; height: 190
            anchors.centerIn: parent
            color: "#252525"
            radius: 16
            border.width: 1; border.color: '#ff7272'
            scale: deleteOverlay.visible ? 1 : 0.8
            Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }

            ColumnLayout {
                anchors.centerIn: parent
                width: parent.width - 40
                spacing: 20
                
                ColumnLayout {
                    spacing: 8
                    Layout.fillWidth: true
                    MaterialSymbol { text: "warning"; color: '#ff7272'; iconSize: 36 }
                    Label { text: "Delete Note"; font.bold: true; font.pixelSize: 18; color: "#FFFFFF" }
                    Label { text: "This action cannot be undone."; color: "#AAAAAA"; font.pixelSize: 14 }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    ConfigButton {
                        text: "Cancel"
                        Layout.fillWidth: true
                        onClicked: root.deleteVisible = false
                    }
                    ConfigButton {
                        text: "Delete"
                        customColor: '#ff7272'
                        Layout.fillWidth: true
                        onClicked: {
                            root.deleteVisible = false
                            root.deleteConfirmed()
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        id: unifiedOverlay
        anchors.fill: parent
        color: "#E6000000"
        visible: root.mode !== "none"
        opacity: visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        
        Keys.onEscapePressed: root.mode = "none"
        MouseArea { anchors.fill: parent }

        Rectangle {
            id: overlayCard
            width: 340
            height: overlayColumn.implicitHeight + 40
            anchors.centerIn: parent
            radius: 16
            color: "#252525"
            border.width: 1
            border.color: "#444444"
            
            scale: unifiedOverlay.visible ? 1 : 0.9
            Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }

            ColumnLayout {
                id: overlayColumn
                anchors.centerIn: parent
                width: parent.width - 40
                spacing: 15

                MaterialSymbol {
                    Layout.alignment: Qt.AlignHCenter
                    iconSize: 32
                    color: "#FFFFFF"
                    text: {
                        if (root.mode === "unlock") return "lock"
                        if (root.mode === "create") return "note_add"
                        if (root.mode === "rename") return "edit"
                        if (root.mode === "encrypt") return "security"
                        if (root.mode === "decrypt") return "no_encryption"
                        return "circle"
                    }
                }

                Label {
                    Layout.alignment: Qt.AlignHCenter
                    font.pixelSize: 18
                    font.bold: true
                    color: "#FFFFFF"
                    text: {
                        if (root.mode === "unlock") return "Unlock Note"
                        if (root.mode === "create") return "New Note"
                        if (root.mode === "rename") return "Rename Note"
                        if (root.mode === "encrypt") return "Set Password"
                        if (root.mode === "decrypt") return "Remove Password?"
                        return ""
                    }
                }

                TextField {
                    id: input1
                    Layout.fillWidth: true
                    color: "#FFFFFF"
                    placeholderTextColor: "#888888"
                    echoMode: (root.mode === "create" || root.mode === "rename") ? TextInput.Normal : TextInput.Password
                    
                    placeholderText: {
                        if (root.mode === "unlock") return "Enter password"
                        if (root.mode === "create") return "Note Name"
                        if (root.mode === "rename") return "New Name"
                        if (root.mode === "encrypt") return "New Password"
                        if (root.mode === "decrypt") return "Current Password"
                        return ""
                    }
                    
                    background: Rectangle {
                        color: "#151515"
                        radius: 8
                        border.width: 1
                        border.color: input1.activeFocus ? Appearance.colors.colPrimary : "#333333"
                    }
                    onAccepted: root.actionConfirmed(root.mode, input1.text, input2.text)
                    
                    SequentialAnimation {
                        id: shakeAnim
                        ParallelAnimation {
                            NumberAnimation { target: input1; property: "Layout.leftMargin"; to: -10; duration: 50 }
                            NumberAnimation { target: input1; property: "Layout.rightMargin"; to: 10; duration: 50 }
                        }
                        ParallelAnimation {
                            NumberAnimation { target: input1; property: "Layout.leftMargin"; to: 10; duration: 50 }
                            NumberAnimation { target: input1; property: "Layout.rightMargin"; to: -10; duration: 50 }
                        }
                        ParallelAnimation {
                            NumberAnimation { target: input1; property: "Layout.leftMargin"; to: 0; duration: 50 }
                            NumberAnimation { target: input1; property: "Layout.rightMargin"; to: 0; duration: 50 }
                        }
                    }
                }

                TextField {
                    id: input2
                    Layout.fillWidth: true
                    visible: root.mode === "encrypt"
                    placeholderText: "Confirm Password"
                    echoMode: TextInput.Password
                    color: "#FFFFFF"
                    placeholderTextColor: "#888888"
                    background: Rectangle {
                        color: "#151515"
                        radius: 8
                        border.width: 1
                        border.color: input2.activeFocus ? Appearance.colors.colPrimary : "#333333"
                    }
                    onAccepted: root.actionConfirmed(root.mode, input1.text, input2.text)
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 5
                    spacing: 10
                    
                    ConfigButton {
                        Layout.fillWidth: true
                        text: "Cancel"
                        icon: "close"
                        onClicked: root.mode = "none"
                    }
                    
                    ConfigButton {
                        Layout.fillWidth: true
                        highlighted: true 
                        icon: "check"
                        text: {
                            if (root.mode === "unlock") return "Open"
                            if (root.mode === "create") return "Create"
                            if (root.mode === "rename") return "Rename"
                            if (root.mode === "encrypt") return "Set"
                            if (root.mode === "decrypt") return "Remove"
                            return "OK"
                        }
                        onClicked: root.actionConfirmed(root.mode, input1.text, input2.text)
                    }
                }
            }
        }
    }
    
    function shake() {
        shakeAnim.restart()
    }
}