import QtQuick 2.15
import QtQuick.Window 2.15

Rectangle {
    id: root
    width: 800
    height: 600
    visible: true
    color: "lightskyblue"

    function findIndexAt(mx, my) {
        for (var i = 0; i < repeater.count; ++i) {
            var del = repeater.itemAt(i)
            if (del) {
                var pos = del.mapFromItem(root, mx, my)
                if (pos.x >= 0 && pos.x < del.width && pos.y >= 0 && pos.y < del.height) {
                    return i
                }
            }
        }
        return -1
    }

    ListModel {
        id: listModel
    }

    Component.onCompleted: {
        for (let i = 0; i < 100; ++i) {
            listModel.append({name: "Cell %1".arg(i), type: Math.random() < 0.5 ? 1 : 2, elementId: i})
        }
    }

    // Wrap in Flickable for scrolling if the content exceeds the view
    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: flow.height
        boundsBehavior: Flickable.StopAtBounds

        Flow {
            id: flow
            width: parent.width
            spacing: 0  // Adjust spacing as needed for visual separation

            Repeater {
                id: repeater
                model: listModel

                delegate: Item {
                    id: main

                    width: 100 * model.type
                    height: 100

                    // Placeholder visual feedback (semi-transparent overlay when hovered during drag)
                    Rectangle {
                        id: feedbackRect
                        anchors.fill: parent
                        color: "black"
                        opacity: 0
                    }

                    // The draggable content box, parented to root for free movement
                    Rectangle {
                        id: item

                        parent: root
                        x: main.x
                        y: main.y
                        width: main.width
                        height: main.height
                        color: "transparent"  // Or set a background color if desired

                        Text {
                            text: model.name
                            anchors.centerIn: parent
                        }

                        // Drag handle (small area for initiating drag)
                        MouseArea {
                            id: dragHandle

                            anchors { right: parent.right; bottom: parent.bottom; margins: 4 }
                            width: 14
                            height: 14
                            Rectangle { anchors.fill: parent; color: "blue" }
                            cursorShape: Qt.OpenHandCursor

                            onPressAndHold: {
                                loc.currentId = model.elementId
                                loc.newIndex = model.index
                            }
                        }

                        states: [
                            State {
                                name: "active"
                                when: loc.currentId === model.elementId
                                PropertyChanges {
                                    target: item
                                    x: loc.mouseX - item.width / 2
                                    y: loc.mouseY - item.height / 2
                                    scale: 0.9
                                    z: 10
                                    opacity: 0.8
                                }
                            }
                        ]

                        Behavior on x { enabled: item.state !== "active"; NumberAnimation { duration: 400; easing.type: Easing.OutBack } }
                        Behavior on y { enabled: item.state !== "active"; NumberAnimation { duration: 400; easing.type: Easing.OutBack } }
                    }

                    // Visual feedback state for the placeholder when hovered during drag
                    states: [
                        State {
                            when: loc.hoverIndex === model.index && loc.currentId !== model.elementId
                            PropertyChanges {
                                target: feedbackRect
                                opacity: 0.3
                            }
                        }
                    ]
                }
            }
        }
    }

    MouseArea {
        id: loc
        anchors.fill: parent

        property int currentId: -1
        property int newIndex: -1
        property int hoverIndex: -1

        onReleased: {
            if (currentId !== -1) {
                currentId = -1
                hoverIndex = -1
            }
        }

        onPositionChanged: {
            var idx = root.findIndexAt(mouseX, mouseY)
            hoverIndex = idx
            if (currentId !== -1 && idx !== -1 && idx !== newIndex) {
                console.log("Moving from", newIndex, "to", idx)
                listModel.move(newIndex, idx, 1)
                newIndex = idx
            }
        }
    }

    Shortcut { sequence: "ESC"; onActivated: Qt.quit() }
}
