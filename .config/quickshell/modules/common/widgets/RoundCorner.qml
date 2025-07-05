import QtQuick 2.9

Item {
    id: root

    enum CornerEnum { TopLeft, TopRight, BottomLeft, BottomRight }
    property var corner: RoundCorner.CornerEnum.TopLeft // Default to TopLeft

    property int size: 25
    property color color: "#000000"

    onColorChanged: {
        canvas.requestPaint();
    }
    onCornerChanged: {
        canvas.requestPaint();
    }

    implicitWidth: size
    implicitHeight: size

    Canvas {
        id: canvas

        anchors.fill: parent
        antialiasing: true
        
        onPaint: {
            var ctx = getContext("2d");
            var r = root.size;
            ctx.clearRect(0, 0, canvas.width, canvas.height);
            ctx.beginPath();
            switch (root.corner) {
                case RoundCorner.CornerEnum.TopLeft:
                    ctx.arc(r, r, r, Math.PI, 3 * Math.PI / 2);
                    ctx.lineTo(0, 0);
                    break;
                case RoundCorner.CornerEnum.TopRight:
                    ctx.arc(0, r, r, 3 * Math.PI / 2, 2 * Math.PI);
                    ctx.lineTo(r, 0);
                    break;
                case RoundCorner.CornerEnum.BottomLeft:
                    ctx.arc(r, 0, r, Math.PI / 2, Math.PI);
                    ctx.lineTo(0, r);
                    break;
                case RoundCorner.CornerEnum.BottomRight:
                    ctx.arc(0, 0, r, 0, Math.PI / 2);
                    ctx.lineTo(r, r);
                    break;
            }
            ctx.closePath();
            ctx.fillStyle = root.color;
            ctx.fill();
        }
    }

    Behavior on size {
        animation: Appearance?.animation.elementMoveFast.numberAnimation.createObject(this)
    }

}
