import "root:/services"
import "root:/modules/common"
import "root:/modules/common/widgets"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Qt5Compat.GraphicalEffects

/**
 * Material 3 progress bar. See https://m3.material.io/components/progress-indicators/overview
 */
ProgressBar {
    id: root
    property real valueBarWidth: 120
    property real valueBarHeight: 4
    property real valueBarGap: 4
    property color highlightColor: Appearance?.colors.colPrimary ?? "#685496"
    property color trackColor: Appearance?.m3colors.m3secondaryContainer ?? "#F1D3F9"
    property bool sperm: false // If true, the progress bar will have a wavy fill effect
    property real waveAmplitude: sperm ? 3 : 0
    property real frequency: 8
    property real spermFps: 60

    Behavior on waveAmplitude {
        animation: Appearance?.animation.elementMoveEnter.numberAnimation.createObject(this)
    }

    Behavior on value {
        animation: Appearance?.animation.elementMoveEnter.numberAnimation.createObject(this)
    }
    
    background: Rectangle {
        anchors.fill: parent
        color: "transparent"
        radius: Appearance?.rounding.full ?? 9999
        implicitHeight: valueBarHeight
        implicitWidth: valueBarWidth
    }

    contentItem: Item {
        implicitWidth: parent.width
        implicitHeight: parent.height

        Canvas {
            id: wavyFill
            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
            }
            height: parent.height * 6
            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);

                var progress = root.visualPosition;
                var fillWidth = progress * width;
                var amplitude = root.waveAmplitude
                var frequency = root.frequency;
                var phase = Date.now() / 400.0;
                var centerY = height / 2;

                ctx.beginPath();
                for (var x = 0; x <= fillWidth; x += 1) {
                    var waveY = centerY + amplitude * Math.sin(frequency * 2 * Math.PI * x / width + phase);
                    if (x === 0)
                        ctx.moveTo(x, waveY);
                    else
                        ctx.lineTo(x, waveY);
                }
                ctx.strokeStyle = root.highlightColor;
                ctx.lineWidth = parent.height;
                ctx.lineCap = "round";
                ctx.stroke();
            }
            Connections {
                target: root
                function onValueChanged() { wavyFill.requestPaint(); }
                function onHighlightColorChanged() { wavyFill.requestPaint(); }
            }
            Timer {
                interval: 1000 / root.spermFps
                running: root.sperm
                repeat: root.sperm
                onTriggered: wavyFill.requestPaint()
            }
        }
        Rectangle { // Right remaining part fill
            anchors.right: parent.right
            width: (1 - root.visualPosition) * parent.width - valueBarGap
            height: parent.height
            radius: Appearance?.rounding.full ?? 9999
            color: root.trackColor
        }
        Rectangle { // Stop point
            anchors.right: parent.right
            width: valueBarGap
            height: valueBarGap
            radius: Appearance?.rounding.full ?? 9999
            color: root.highlightColor
        }
    }
}