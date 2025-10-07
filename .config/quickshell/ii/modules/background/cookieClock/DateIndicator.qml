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
    property color colBackground: Appearance.colors.colOnSecondaryContainer
    property real dateSquareSize: 64

    Loader {
        anchors.fill: parent
        opacity: root.style === "rotating" ? 1.0 : 0
        Behavior on opacity {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }

        active: opacity > 0
        sourceComponent: Canvas {
            z: 0
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
    }

    // Square date (only today's number) in right side of the clock
    Loader {
        anchors {
            verticalCenter: parent.verticalCenter
            right: parent.right
            rightMargin: 10
        }
        width: root.style === "rect" ? 45 : 0
        height: root.style === "rect" ? 30 : 0
        Behavior on width {
            animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
        }
        Behavior on height {
            animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
        }
        active: height > 0
        sourceComponent: Rectangle {
            z: 1
            color: root.colBackground
            radius: Appearance.rounding.small
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
    }

    // Date bubble style left side
    Loader {
        anchors {
            left: parent.left
            bottom: parent.bottom
            topMargin: 50
        }
        property real targetSize: root.style === "bubble" ? root.dateSquareSize : 0
        width: targetSize
        height: targetSize
        Behavior on targetSize {
            animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
        }
        active: targetSize > 0
        sourceComponent: Item {
            MaterialCookie {
                z: 5
                sides: 4
                anchors.centerIn: parent
                color: Appearance.colors.colPrimaryContainer
                implicitSize: root.style === "bubble" ? root.dateSquareSize : 0
                constantlyRotate: Config.options.background.clock.cookie.constantlyRotate
                Behavior on implicitSize {
                    animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
                }
            }
            StyledText {
                z: 6
                anchors.centerIn: parent
                text: DateTime.date.substring(5, 7)
                color: Appearance.colors.colPrimary
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

    // Date bubble style right side
    Loader {
        anchors {
            right: parent.right
            top: parent.top
            bottomMargin: 50
        }
        property real targetSize: root.style === "bubble" ? root.dateSquareSize : 0
        width: targetSize
        height: targetSize
        Behavior on targetSize {
            animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
        }

        active: targetSize > 0
        sourceComponent: Item {
            MaterialCookie {
                z: 5
                sides: 1
                anchors.centerIn: parent
                color: Appearance.colors.colTertiaryContainer
                implicitSize: root.style === "bubble" ? root.dateSquareSize : 0
                constantlyRotate: Config.options.background.clock.cookie.constantlyRotate
                Behavior on implicitSize {
                    animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
                }
            }
            StyledText {
                z: 6
                anchors.centerIn: parent
                text: DateTime.date.substring(8, 10)
                color: Appearance.colors.colTertiary
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
}
