import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

// Resource Card Component for displaying system resource usage
Rectangle {
    id: card
    
    property string title
    property string icon
    property string value
    property real progress: 0
    property string subtitle
    property color progressColor: Appearance.m3colors.m3primary
    property list<real> history: []
    property bool showProgress: true
    property bool showGraph: true
    
    property var pills: []
    property int activePillIndex: 0
    signal pillClicked(int index)

    implicitHeight: 140
    radius: Appearance.rounding.normal
    color: Appearance.colors.colLayer1

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            MaterialSymbol {
                text: card.icon
                iconSize: 24
                color: card.progressColor
            }

            StyledText {
                text: card.title
                font.pixelSize: Appearance.font.pixelSize.normal
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer1
            }

            Item { Layout.fillWidth: true }

            RowLayout {
                visible: card.pills.length > 0
                spacing: 4
                
                Repeater {
                    model: card.pills
                    delegate: Rectangle {
                        height: 20
                        width: pillText.implicitWidth + 16
                        radius: 10
                        color: index === card.activePillIndex ? card.progressColor : Appearance.colors.colLayer2
                        
                        StyledText {
                            id: pillText
                            anchors.centerIn: parent
                            text: modelData
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: index === card.activePillIndex ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer2
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            onClicked: card.pillClicked(index)
                            cursorShape: Qt.PointingHandCursor
                        }
                    }
                }
            }

            StyledText {
                text: card.value
                font.pixelSize: Appearance.font.pixelSize.larger
                font.weight: Font.Bold
                font.family: Appearance.font.family.numbers
                color: Appearance.colors.colOnLayer1
                Layout.minimumWidth: 60
                horizontalAlignment: Text.AlignRight
            }
        }

        Rectangle {
            visible: card.showProgress
            Layout.fillWidth: true
            height: 8
            radius: 4
            color: Appearance.colors.colLayer2

            Rectangle {
                width: parent.width * Math.min(1, card.progress)
                height: parent.height
                radius: 4
                color: card.progressColor

                Behavior on width {
                    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                }
            }
        }

        Canvas {
            id: graphCanvas
            visible: card.showGraph && card.history.length > 1
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 40

            onPaint: {
                const ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                
                if (card.history.length < 2) return
                
                ctx.strokeStyle = Qt.rgba(card.progressColor.r, card.progressColor.g, card.progressColor.b, 0.8)
                ctx.lineWidth = 2
                ctx.beginPath()
                
                const stepX = width / (card.history.length - 1)
                for (let i = 0; i < card.history.length; i++) {
                    const x = i * stepX
                    const y = height - (card.history[i] * height)
                    if (i === 0) ctx.moveTo(x, y)
                    else ctx.lineTo(x, y)
                }
                ctx.stroke()
                
                ctx.lineTo(width, height)
                ctx.lineTo(0, height)
                ctx.closePath()
                ctx.fillStyle = Qt.rgba(card.progressColor.r, card.progressColor.g, card.progressColor.b, 0.1)
                ctx.fill()
            }

            Connections {
                target: card
                function onHistoryChanged() {
                    graphCanvas.requestPaint()
                }
            }
        }

        StyledText {
            visible: !card.showGraph || card.history.length <= 1
            Layout.fillHeight: true
            text: card.subtitle
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
            elide: Text.ElideRight
        }

        StyledText {
            visible: card.showGraph && card.history.length > 1
            text: card.subtitle
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
            elide: Text.ElideRight
        }
    }
}
