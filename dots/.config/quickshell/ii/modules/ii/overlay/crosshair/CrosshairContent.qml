pragma ComponentBehavior: Bound
import QtQuick
import qs.modules.common
import qs.modules.common.functions

Item {
    id: root

    // Keys to props
    // f, 0f, 1f, m are irrelevant as they're firing error stuff
    // 0 is irrelevant because it's some profile stuff
    property var propertyMap: ({
        "c": "color",
        "u": "colorCode",
        "h": "outline",
        "o": "outlineOpacity",
        "t": "outlineThickness",
        "d": "centerDot",
        "a": "centerDotOpacity",
        "z": "centerDotSize",
        "0a": "innerLineOpacity",
        "0l": "innerLineLength",
        "0v": "innerLineVerticalLength",
        "0g": "innerLineUnbindAxesLengths",
        "0t": "innerLineThickness",
        "0o": "innerLineOffset",
        "1b": "outerLines",
        "1a": "outerLineOpacity",
        "1l": "outerLineLength",
        "1v": "outerLineVerticalLength",
        "1g": "outerLineUnbindAxesLengths",
        "1t": "outerLineThickness",
        "1o": "outerLineOffset",
    })
    property var colorMap: ({
        0: "#FFFFFF",
        1: "#00FF00",
        2: "#7FFF00",
        3: "#DFFF00",
        4: "#FFFF00",
        5: "#00FFFF",
        6: "#FF00FF",
        7: "#FF0000"
    })

    // Raw props
    property int color: 0
    property string colorCode: "#FFFFFF"
    property bool outline: true
    property real outlineOpacity: 0.5
    property int outlineThickness: 1
    property bool centerDot: false
    property real centerDotOpacity: 1
    property int centerDotSize: 2
    property bool innerLines: true
    property real innerLineOpacity: 0.8
    property int innerLineLength: 6
    property int innerLineVerticalLength: innerLineLength
    property bool innerLineUnbindAxesLengths: false
    property int innerLineThickness: 2
    property int innerLineOffset: 3
    property bool outerLines: true
    property real outerLineOpacity: 0.35
    property int outerLineLength: 2
    property int outerLineVerticalLength: outerLineLength
    property bool outerLineUnbindAxesLengths: false
    property int outerLineThickness: 2
    property int outerLineOffset: 10
    property string defaultCode: "c;0;u;FFFFFF;h;1;o;0.5;t;1;d;0;a;1;z;2;0a;0.8;0l;6;0v;6;0g;0;0t;2;0o;3;1b;1;1a;0.35;1l;2;1v;2;1g;0;1t;2;1o;10"

    function loadFromCode(code: string): void {
        let args = code.split(";");
        for (let i = 0; i < args.length; i+= 2) {
            let key = args[i];
            let value = args[i+1];
            let targetKey = root.propertyMap[key];
            let targetType = typeof root[targetKey];

            if (targetKey === undefined) continue;

            if (targetType === "number") {
                value = parseFloat(value);
            } else if (targetType === "boolean") {
                value = (value === "1");
            } 
            if (targetKey === "colorCode") {
                value = "#" + value.slice(0, 6);
            }
            root[targetKey] = value;
        }

        if (!root.innerLineUnbindAxesLengths) {
            root.innerLineVerticalLength = root.innerLineLength;
        }
        if (!root.outerLineUnbindAxesLengths) {
            root.outerLineVerticalLength = root.outerLineLength;
        }

    }

    // Update values from code
    property var code: Config.options.crosshair.code
    Component.onCompleted: reloadFromCode();
    onCodeChanged: reloadFromCode();
    function reloadFromCode() {
        root.loadFromCode(root.defaultCode);
        root.loadFromCode(root.code);
    }

    // Aggregated props
    property color crosshairColor: {
        if (colorMap[color] !== undefined) return root.colorMap[color];
        if (color === 8) return colorCode;
        return "#FFFFFF";
    }
    property int borderWidth: outline ? outlineThickness : 0
    property color borderColor: ColorUtils.transparentize("black", 1 - root.outlineOpacity)
    property color innerLineColor: ColorUtils.transparentize(root.crosshairColor, 1 - root.innerLineOpacity)
    property color outerLineColor: ColorUtils.transparentize(root.crosshairColor, 1 - root.outerLineOpacity)
    property int innerLineTotalOffset: root.centerDotSize / 2 + 1 + root.innerLineOffset
    property int outerLineTotalOffset: root.centerDotSize / 2 + 1 + root.outerLineOffset
    property real centerDotTotalSize: root.centerDotSize + root.borderWidth * 2
    property real innerLineTotalSize: (innerLineTotalOffset + root.innerLineLength + root.borderWidth) * 2
    property real outerLineTotalSize: (outerLineTotalOffset + root.outerLineLength + root.borderWidth) * 2
    implicitWidth: Math.max(centerDotTotalSize, innerLineTotalSize, outerLineTotalSize) + 2 // 2 for pixel correction
    implicitHeight: implicitWidth
    // width: implicitWidth
    // height: implicitHeight

    Rectangle {
        id: centerDot
        visible: root.centerDot
        anchors.centerIn: parent

        color: root.crosshairColor
        opacity: root.centerDotOpacity
        width: centerDotTotalSize
        height: width

        border.width: root.borderWidth
        border.color: root.borderColor
    }

    Repeater {
        id: innerLines
        model: 4
        Item {
            id: innerHair
            z: index % 2 // Vertical lines above horizontal lines
            required property int index
            property int pixelCorrection: (root.innerLineThickness % 2 === 1 && index > 1) ? 1 : 0
            property int hairLength: (innerHair.index % 2 === 0 ? root.innerLineLength : root.innerLineVerticalLength)
            visible: root.innerLines && hairLength > 0
            anchors.fill: parent
            rotation: index * 90
            Rectangle {
                x: parent.width / 2 + root.innerLineTotalOffset - root.borderWidth + innerHair.pixelCorrection
                y: parent.height / 2 - height / 2

                color: root.innerLineColor
                width: innerHair.hairLength + root.borderWidth * 2
                height: root.innerLineThickness + root.borderWidth * 2

                border.width: root.borderWidth
                border.color: root.borderColor
            }
        }
    }

    Repeater {
        id: outerLines
        model: 4
        Item {
            id: outerHair
            z: index % 2 + 2 // Vertical lines above horizontal lines, above inner lines
            required property int index
            property int pixelCorrection: (root.outerLineThickness % 2 === 1 && index > 1) ? 1 : 0
            property int hairLength: (outerHair.index % 2 === 0 ? root.outerLineLength : root.outerLineVerticalLength)
            visible: root.outerLines && hairLength > 0
            anchors.fill: parent
            rotation: index * 90
            Rectangle {
                x: parent.width / 2 + root.outerLineTotalOffset - root.borderWidth + outerHair.pixelCorrection
                y: parent.height / 2 - height / 2

                color: root.outerLineColor
                width: hairLength + root.borderWidth * 2
                height: root.outerLineThickness + root.borderWidth * 2

                border.width: root.borderWidth
                border.color: root.borderColor
            }
        }
    }

    
}
