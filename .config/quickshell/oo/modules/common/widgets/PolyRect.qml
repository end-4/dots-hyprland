import QtQuick

/**
 * Draws an octagon when width == height. 
 * Otherwise it's a rectangle "rounded" with two edges each corner (like 1/4 of an octagon)
 */
Item {
    id: root
    property real radius: Math.min(width, height) / 2
    property color color: "#b7eb34"

    onWidthChanged: polyRect.requestPaint()
    onHeightChanged: polyRect.requestPaint()
    onRadiusChanged: polyRect.requestPaint()
    onColorChanged: polyRect.requestPaint()

    Canvas {
        id: polyRect
        anchors.fill: parent

        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);

            var r = root.radius;
            var r45 = r * Math.SQRT2 / 2;
            ctx.beginPath();
            ctx.moveTo(r, 0);
            ctx.lineTo(width - r, 0);
            ctx.lineTo(width - r + r45, r - r45);
            ctx.lineTo(width, r);
            ctx.lineTo(width, height - r);
            ctx.lineTo(width - r + r45, height - r + r45);
            ctx.lineTo(width - r, height);
            ctx.lineTo(r, height);
            ctx.lineTo(r - r45, height - r + r45);
            ctx.lineTo(0, height - r);
            ctx.lineTo(0, r);
            ctx.lineTo(r - r45, r - r45);
            ctx.closePath();

            ctx.fillStyle = root.color;
            ctx.fill();
        }
    }
}
