// From https://github.com/rafzby/circular-progressbar
// License: LGPL-3.0 - A copy can be found in `licenses` folder of repo
// Modified so it looks like in Material 3: https://m3.material.io/components/progress-indicators/specs
import QtQuick 2.9

Item {
    id: root

    property int size: 30
    property int lineWidth: 2
    property real value: 0
    property color primaryColor: "#70585D"
    property color secondaryColor: "#FFF8F7"
    property real gapAngle: Math.PI / 10
    property bool fill: false
    property int fillOverflow: 2
    property int animationDuration: 1000

    width: size
    height: size
    onValueChanged: {
        canvas.degree = value * 360;
    }
    onPrimaryColorChanged: {
        canvas.requestPaint();
    }
    onSecondaryColorChanged: {
        canvas.requestPaint();
    }

    Canvas {
        id: canvas

        property real degree: 0

        anchors.fill: parent
        antialiasing: true

        onDegreeChanged: {
            requestPaint();
        }

        onPaint: {
            var ctx = getContext("2d");
            var x = root.width / 2;
            var y = root.height / 2;
            var radius = root.size / 2 - root.lineWidth;
            var startAngle = (Math.PI / 180) * 270;
            var fullAngle = (Math.PI / 180) * (270 + 360);
            var progressAngle = (Math.PI / 180) * (270 + degree);
            var epsilon = 0.01; // Small angle in radians
            
            ctx.reset();
            if (root.fill) {
                ctx.fillStyle = root.secondaryColor;
                ctx.beginPath();
                ctx.arc(x, y, radius + fillOverflow, startAngle, fullAngle);
                ctx.fill();
            }
            ctx.lineCap = 'round';
            ctx.lineWidth = root.lineWidth;

            // Secondary
            ctx.beginPath();
            ctx.arc(x, y, radius, progressAngle + gapAngle, startAngle - gapAngle);
            ctx.strokeStyle = root.secondaryColor;
            ctx.stroke();

            // Primary (value indication)
            var endAngle = (progressAngle === startAngle) ? startAngle + epsilon : progressAngle;
            ctx.beginPath();
            ctx.arc(x, y, radius, startAngle, endAngle);
            ctx.strokeStyle = root.primaryColor;
            ctx.stroke();
        }

        Behavior on degree {
            NumberAnimation {
                duration: root.animationDuration
                easing.type: Easing.OutCubic
            }

        }

    }

}
