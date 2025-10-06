pragma ComponentBehavior: Bound

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick

Item {
    id: root
    property string style: "rotating"
    property color colOnBackground: Appearance.colors.colOnSecondaryContainer
    
    Canvas {
        z: 0
        width: parent.width
        height: parent.height
        rotation: {
            if (!Config.options.time.secondPrecision) return 0;
            return secondHand.rotation + 45  // +45 degrees to align with minute hand
        }

        opacity: root.style === "rotating" ? 1.0 : 0
        Behavior on opacity {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }

        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            ctx.font = "700 30px " + Appearance.font.family.title;

            var text = Qt.locale().toString(DateTime.clock.date, "ddd dd");
            var radius = 78;
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

    // Date (only today's number) in right side of the clock
    Rectangle {
        z: 1
        implicitWidth: 45
        implicitHeight: root.style === "rect" ? 30 : 0
        color: root.colOnBackground
        radius: Appearance.rounding.small
        anchors {
            verticalCenter: parent.verticalCenter
            right: parent.right
            rightMargin: 10
        }
        Behavior on implicitHeight {
            animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
        }
        StyledText {
            opacity: root.style === "rect" ? 1.0 : 0
            Behavior on opacity {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
            anchors.centerIn: parent
            color: Appearance.colors.colSecondaryHover
            text: DateTime.date.substring(5, 7)
            font {
                family: Appearance.font.family.expressive
                pixelSize: 20
                weight: 1000
            }
        }
    }

    // Date bubble style left side
    Rectangle {
        z: 5
        implicitWidth: root.style === "bubble" ? dateSquareSize : 0
        implicitHeight: root.style === "bubble" ? dateSquareSize : 0
        color: Appearance.colors.colPrimaryContainer
        radius: Appearance.rounding.large
        anchors {
            left: parent.left
            bottom: parent.bottom
            bottomMargin: 5
        }
        Behavior on implicitWidth {
            animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
        }
        Behavior on implicitHeight {
            animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
        }
        StyledText {
            anchors.centerIn: parent
            text: DateTime.date.substring(5, 7)
            color: Appearance.colors.colOnPrimaryContainer
            opacity: root.style === "bubble" ? 1.0 : 0
            font {
                family: Appearance.font.family.expressive
                pixelSize: 30
                weight: 1000
            }
            Behavior on opacity {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
        }
    }

    // Date bubble style right side
    Rectangle {
        z: 5
        implicitWidth: root.style === "bubble" ? dateSquareSize : 0
        implicitHeight: root.style === "bubble" ? dateSquareSize : 0
        color: Appearance.colors.colTertiaryContainer
        radius: Appearance.rounding.verylarge
        anchors {
            right: parent.right
            top: parent.top
            topMargin: 5
        }
        Behavior on implicitWidth {
            animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
        }
        Behavior on implicitHeight {
            animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
        }
        StyledText {
            anchors.centerIn: parent
            text: DateTime.date.substring(8, 10)
            color: Appearance.colors.colOnPrimaryContainer
            opacity: root.style === "bubble" ? 1.0 : 0
            font {
                family: Appearance.font.family.expressive
                pixelSize: 30
                weight: 1000
            }
            Behavior on opacity {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
        }
    }
}
