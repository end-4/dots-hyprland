import qs.modules.common
import QtQuick

Canvas {
    id: root
    property real amplitudeMultiplier: 0.5
    property real frequency: 6
    property color color: Appearance?.colors.colPrimary ?? "#685496"
    property real lineWidth: 4
    property real fullLength: width

    onPaint: {
        var ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);

        var amplitude = root.lineWidth * root.amplitudeMultiplier;
        var frequency = root.frequency;
        var phase = Date.now() / 400.0;
        var centerY = height / 2;

        ctx.strokeStyle = root.color;
        ctx.lineWidth = root.lineWidth;
        ctx.lineCap = "round";
        ctx.beginPath();
        for (var x = ctx.lineWidth / 2; x <= root.width - ctx.lineWidth / 2; x += 1) {
            var waveY = centerY + amplitude * Math.sin(frequency * 2 * Math.PI * x / root.fullLength + phase);
            if (x === 0)
                ctx.moveTo(x, waveY);
            else
                ctx.lineTo(x, waveY);
        }
        ctx.stroke();
    }
}
