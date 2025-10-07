pragma ComponentBehavior: Bound

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick

Canvas {
    z: 0

    opacity: root.style === "rotating" ? 1.0 : 0
    Behavior on opacity {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    rotation: {
        if (!Config.options.time.secondPrecision)
            return 0;
        return (secondHandLoader.item.rotation + 45);  // +45 degrees to align text's center
    }
    onPaint: {
        var ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);
        ctx.font = "700 30px " + Appearance.font.family.title;

        var text = Qt.locale().toString(DateTime.clock.date, "ddd dd");
        var radius = 65;
        var angleStep = Math.PI / 2.35 / text.length;

        for (var i = 0; i < text.length; i++) {
            var angle = i * angleStep - Math.PI / 2;
            var x = width / 2 + radius * Math.cos(angle);
            var y = height / 2 + radius * Math.sin(angle);

            ctx.save();
            ctx.translate(x, y);
            ctx.rotate(angle + Math.PI / 2);

            if (i >= 3)
                ctx.fillStyle = root.colOnBackground;
            else
                ctx.fillStyle = Appearance.colors.colSecondaryHover;

            ctx.fillText(text[i], 0, 0);
            ctx.restore();
        }
    }
}