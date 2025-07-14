import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Widgets

StyledSlider {
    id: root
    property real valueBarWidth: 120
    property real valueBarHeight: 4
    property real valueBarGap: 4
    property color highlightColor: Appearance?.colors.colPrimary ?? "#685496"
    property color trackColor: Appearance?.m3colors.m3secondaryContainer ?? "#F1D3F9"
    property bool sperm: false // If true, the progress bar will have a wavy fill effect
    property bool animateSperm: true
    property real spermAmplitudeMultiplier: sperm ? 0.5 : 0
    property real spermFrequency: 6
    property real spermFps: 60

    // Seeking-related properties
    property bool showHandleOnHover: true
    property bool enlargeOnHover: true
    property real hoverScale: 1.2

    // Signals for media seeking
    signal seekStarted
    signal seekEnded
    signal seeking(real position)

    // Override StyledSlider properties to make it look like a progress bar
    handleHeight: valueBarHeight + 6
    handlePressedWidth: 5
    trackWidth: valueBarHeight
    handleMargins: 0
    handleColor: root.highlightColor

    // Make the slider more responsive for seeking
    snapMode: Slider.NoSnap
    live: true

    // Internal seeking state
    property bool isSeeking: false

    // Connect the seeking signals using proper Slider signals
    onPressedChanged: {
        if (pressed) {
            root.seekStarted();
            isSeeking = true;
        } else {
            root.seekEnded();
            isSeeking = false;
        }
    }

    onValueChanged: {
        if (pressed) {
            root.seeking(value);
        }
    }

    // Override the background to implement the wavy effect and better seeking

    background: Item {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: valueBarHeight // Use trackWidth instead of implicitHeight

        // Enhanced hover area for better seeking
        MouseArea {
            anchors.fill: parent
            anchors.margins: -8 // Extend the clickable area
            hoverEnabled: true
            onPressed: mouse => mouse.accepted = false // Let the slider handle the press

            property bool isHovered: containsMouse

            onIsHoveredChanged: {
                if (root.showHandleOnHover) {
                    root.handleMargins = isHovered ? 2 : 0;
                }
            }
        }

        Canvas {
            id: wavyFill
            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
            }
            height: trackWidth * 2  // Reduce the height multiplier for cleaner look
            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);

                var progress = root.visualPosition;
                var fillWidth = progress * width;
                var amplitude = trackWidth * root.spermAmplitudeMultiplier;  // Use trackWidth for amplitude
                var frequency = root.spermFrequency;
                var phase = Date.now() / 400.0;
                var centerY = height / 2;

                ctx.strokeStyle = root.highlightColor;
                ctx.lineWidth = trackWidth;  // Use trackWidth for line width
                ctx.lineCap = "round";
                ctx.beginPath();
                for (var x = ctx.lineWidth / 2; x <= fillWidth; x += 1) {
                    var waveY = centerY + amplitude * Math.sin(frequency * 2 * Math.PI * x / width + phase);
                    if (x === 0)
                        ctx.moveTo(x, waveY);
                    else
                        ctx.lineTo(x, waveY);
                }
                ctx.stroke();
            }
            Connections {
                target: root
                function onValueChanged() {
                    wavyFill.requestPaint();
                }
                function onHighlightColorChanged() {
                    wavyFill.requestPaint();
                }
            }
            Timer {
                interval: 1000 / root.spermFps
                running: root.animateSperm && root.sperm
                repeat: true
                onTriggered: wavyFill.requestPaint()
            }
        }

        Rectangle {
            // Right remaining part fill
            anchors.right: parent.right
            width: (1 - root.visualPosition) * parent.width - valueBarGap
            height: parent.height
            radius: Appearance?.rounding.full ?? 9999
            color: root.trackColor
        }

        Rectangle {
            // Stop point
            anchors.right: parent.right
            width: valueBarGap
            height: valueBarGap
            radius: Appearance?.rounding.full ?? 9999
            color: root.highlightColor
        }
    }

    // Enhanced handle for better seeking experience
    handle: Rectangle {
        implicitWidth: root.pressed ? root.handlePressedWidth : (mouseArea.containsMouse ? root.handleDefaultWidth + 2 : root.handleDefaultWidth)
        implicitHeight: root.pressed ? root.handleHeight : (mouseArea.containsMouse ? root.handleHeight + 2 : root.handleHeight)
        x: root.handleMargins + (root.visualPosition * root.effectiveDraggingWidth) - (implicitWidth / 2)
        anchors.verticalCenter: parent.verticalCenter
        radius: implicitWidth / 2
        color: root.handleColor

        // Smooth transitions for better user experience
        Behavior on implicitWidth {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }

        Behavior on implicitHeight {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }

        Behavior on border.width {
            NumberAnimation {
                duration: 100
                easing.type: Easing.OutCubic
            }
        }

        // Enhance the mouse area for better interaction
        MouseArea {
            id: mouseArea
            anchors.fill: parent
            anchors.margins: -4
            hoverEnabled: true
            onPressed: mouse => mouse.accepted = false // Let the slider handle the press
            cursorShape: root.pressed ? Qt.ClosedHandCursor : Qt.PointingHandCursor
        }
    }
}
