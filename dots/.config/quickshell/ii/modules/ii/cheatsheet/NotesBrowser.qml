import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root
    
    property ListModel model
    property string currentFilter: "All"
    property bool isRefreshing: false
    
    signal filterChanged(string mode)
    signal noteOpened(string path, bool isEncrypted)
    signal noteFlipped(int index, string path)
    signal createRequested()
    signal refreshRequested()

    property var tileColors: [
        "#FFB7B2", "#FFDAC1", "#E2F0CB", "#B5EAD7", 
        "#C7CEEA", "#E0BBE4", '#d2b6ee', "#FEC8D8"
    ]

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        // --- Header ---
        RowLayout {
            Layout.fillWidth: true
            height: 40
            spacing: 15

            MaterialSymbol {
                text: "description"
                iconSize: 24
                color: Appearance.colors.colPrimary
            }

            Label {
                text: "Notes"
                font.pixelSize: 20
                font.bold: true
                color: "#FFFFFF"
            }
            
            ComboBox {
                id: filterCombo
                Layout.preferredWidth: 150
                Layout.preferredHeight: 40
                model: ["All", "Notes", "Encrypted"]
                currentIndex: 0
                
                onCurrentTextChanged: root.filterChanged(currentText)

                indicator: MaterialSymbol {
                    x: filterCombo.width - width - 10
                    y: filterCombo.topPadding + (filterCombo.availableHeight - height) / 2
                    text: "expand_more"
                    color: "#AAAAAA"
                    iconSize: 20
                    rotation: filterCombo.popup.visible ? 180 : 0
                    Behavior on rotation { NumberAnimation { duration: 200 } }
                }

                background: Rectangle {
                    implicitWidth: 150
                    implicitHeight: 36
                    color: filterCombo.pressed ? "#404040" : "#333333"
                    radius: 8
                    border.width: 1
                    border.color: filterCombo.activeFocus || filterCombo.popup.visible 
                                  ? Appearance.colors.colPrimary : "#555555"
                }

                contentItem: Text {
                    leftPadding: 12
                    rightPadding: filterCombo.indicator.width + 12
                    text: filterCombo.displayText
                    font.pixelSize: 12
                    font.bold: true
                    color: "#FFFFFF"
                    verticalAlignment: Text.AlignVCenter
                }

                popup: Popup {
                    y: filterCombo.height + 4
                    width: filterCombo.width
                    height: contentItem.implicitHeight + 10
                    padding: 5
                    
                    contentItem: ListView {
                        clip: true
                        implicitHeight: contentHeight
                        model: filterCombo.delegateModel
                        currentIndex: filterCombo.highlightedIndex
                        interactive: false 
                    }

                    background: Rectangle {
                        color: "#252525"
                        radius: 8
                        border.width: 1
                        border.color: "#444444"
                        layer.enabled: true
                        layer.effect: DropShadow {
                            transparentBorder: true
                            verticalOffset: 4
                            radius: 12
                            samples: 17
                            color: "#80000000"
                        }
                    }
                }
            }

            Item { Layout.fillWidth: true } 

            ConfigButton {
                icon: "add"
                text: "New"
                onClicked: root.createRequested()
            }

            ConfigButton {
                icon: "refresh"
                text: "Refresh"
                onClicked: root.refreshRequested()
            }
        }

        GridView {
            id: notesGrid
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            
            property int baseMargin: 0
            property int effectiveWidth: width
            property int columns: Math.floor(effectiveWidth / cellWidth)
            property int centeringMargin: Math.max(0, (effectiveWidth - (columns * cellWidth)) / 2)
            leftMargin: centeringMargin
            
            cellWidth: 150
            cellHeight: 170
            model: root.model

            add: Transition {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 300 }
                NumberAnimation { property: "scale"; from: 0.8; to: 1; duration: 300; easing.type: Easing.OutBack }
            }
            remove: Transition {
                NumberAnimation { property: "opacity"; to: 0; duration: 200 }
                NumberAnimation { property: "scale"; to: 0.8; duration: 200 }
            }

            delegate: Flipable {
                id: flipCard
                width: notesGrid.cellWidth - 10
                height: notesGrid.cellHeight - 10
                
                property bool flipped: false
                property bool isEncrypted: model.fileName.endsWith(".enc")

                transform: Rotation {
                    id: rotation
                    origin.x: flipCard.width / 2
                    origin.y: flipCard.height / 2
                    axis.x: 0; axis.y: 1; axis.z: 0   
                    angle: flipCard.flipped ? 180 : 0
                    Behavior on angle { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }
                }

                front: Rectangle {
                    anchors.fill: parent
                    radius: 12
                    color: root.tileColors[index % root.tileColors.length]
                    scale: (!flipCard.flipped && mouseArea.containsMouse) ? 1.02 : 1.0
                    Behavior on scale { NumberAnimation { duration: 100 } }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 15
                        spacing: 10

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            width: 60; height: 60; radius: 30
                            color: "#20000000" 
                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: flipCard.isEncrypted ? "lock" : "edit_note"
                                iconSize: 32
                                color: "#222222"
                            }
                        }

                        Label {
                            Layout.fillWidth: true
                            text: model.fileName.replace(/\.(txt|enc)$/, "")
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignHCenter
                            color: "#111111"
                            font.pixelSize: 14
                            font.bold: true
                        }
                        
                        Label {
                            Layout.fillWidth: true
                            text: flipCard.isEncrypted ? "Encrypted" : "Note"
                            horizontalAlignment: Text.AlignHCenter
                            color: "#444444"
                            font.pixelSize: 12
                        }
                    }
                }

                back: Rectangle {
                    anchors.fill: parent
                    radius: 12
                    color: "#333333"
                    border.color: root.tileColors[index % root.tileColors.length]
                    border.width: 2

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 5
                        Label {
                            text: "Details"
                            font.bold: true
                            color: root.tileColors[index % root.tileColors.length]
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Rectangle { height: 1; Layout.fillWidth: true; color: "#555555" }
                        Label {
                            text: model.fileDetails ? model.fileDetails : "Loading..."
                            color: "#CCCCCC"
                            font.pixelSize: 12
                            wrapMode: Text.Wrap
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                    onClicked: (mouse) => {
                        if (mouse.button === Qt.RightButton) {
                            flipCard.flipped = !flipCard.flipped
                            if (flipCard.flipped) root.noteFlipped(index, model.filePath)
                        } else {
                            if (flipCard.flipped) {
                                flipCard.flipped = false
                                return
                            }
                            root.noteOpened(model.filePath, flipCard.isEncrypted)
                        }
                    }
                }
            }
        }
    }
    
    ColumnLayout {
        anchors.centerIn: parent
        visible: root.model.count === 0 && !root.isRefreshing
        spacing: 10
        MaterialSymbol { 
            text: "sentiment_dissatisfied" 
            iconSize: 48 
            color: "#444444"
            Layout.alignment: Qt.AlignHCenter 
        }
        Label {
            text: "No notes found"
            color: "#666666"
            font.pixelSize: 16
        }
    }
}