import QtQuick

Canvas {
    id: root
    property var values: []
    property real maxValue: 100
    property color lineColor: "#6ea8fe"
    property real lineWidth: 2
    property int capacity: 60

    onValuesChanged: requestPaint()
    onMaxValueChanged: requestPaint()
    onLineColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        const v = root.values;
        if (!v || v.length < 2 || width <= 0 || height <= 0) return;
        const max = root.maxValue > 0 ? root.maxValue : 1;
        const step = width / (root.capacity - 1);
        const pad = root.lineWidth;
        const usable = height - pad * 2;
        const x = i => width - (v.length - 1 - i) * step;
        const y = i => pad + usable * (1 - Math.min(v[i] / max, 1));
        ctx.beginPath();
        ctx.moveTo(x(0), y(0));
        for (let i = 1; i < v.length; i++) ctx.lineTo(x(i), y(i));
        ctx.lineWidth = root.lineWidth;
        ctx.lineJoin = "round";
        ctx.strokeStyle = root.lineColor;
        ctx.stroke();
        ctx.lineTo(x(v.length - 1), height);
        ctx.lineTo(x(0), height);
        ctx.closePath();
        const g = ctx.createLinearGradient(0, 0, 0, height);
        g.addColorStop(0, Qt.rgba(lineColor.r, lineColor.g, lineColor.b, 0.35));
        g.addColorStop(1, Qt.rgba(lineColor.r, lineColor.g, lineColor.b, 0.0));
        ctx.fillStyle = g;
        ctx.fill();
    }
}
