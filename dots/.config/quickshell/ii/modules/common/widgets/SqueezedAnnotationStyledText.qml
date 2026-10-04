pragma ComponentBehavior: Bound
import QtQuick
import qs.modules.common

// Annotation similar to how Google Lens does it.
Item {
    id: root

    property real scaleFactor: 1.0
    property alias font: textWidget.font
    property alias color: textWidget.color
    property string text: ""

    property bool rotate90: false
    property real maxFontPixelSize: 100
    visible: false

    Component.onCompleted: updateText()
    onTextChanged: updateText()
    // The box is sized by its parent, so a resize after creation must re-fit;
    // otherwise the font stays fitted to the old dimensions.
    onWidthChanged: updateText()
    onHeightChanged: updateText()

    property bool searching: false
    property real searchPixelSize: Appearance.font.pixelSize.small
    property real renderPixelSize: Appearance.font.pixelSize.small
    font.pixelSize: searching ? searchPixelSize : (renderPixelSize * scaleFactor)

    function updateText() {
        // Nothing to fit into yet. Happens before the first layout pass, and
        // the divisions below would otherwise produce NaN/Infinity targets.
        if (root.width <= 0 || root.height <= 0 || root.text.length === 0) return;

        // Do we rotate?

        root.rotate90 = false;
        const textAspectRatio = textMetrics.width / textMetrics.height
        const areaAspectRatio = root.width / root.height
        if ((textAspectRatio > 1 && areaAspectRatio < 1) || (textAspectRatio < 1 && areaAspectRatio > 1)) {
            root.rotate90 = true;
        }
        const targetWidth = (root.rotate90 ? root.height : root.width) / root.scaleFactor;
        const targetHeight = (root.rotate90 ? root.width : root.height) / root.scaleFactor;

        // Binary search to find the correct font size
        var lower = 0
        var upper = maxFontPixelSize
        root.searching = true;
        while (upper - lower > 0.00001) {
            var mid = (lower + upper) / 2;
            // print("bin searching", mid, "target", targetWidth, targetHeight, "actual", textWidget.contentWidth, textWidget.contentHeight);
            root.searchPixelSize = mid
            // Width matters too: wrapMode cannot break a single word that is
            // wider than the box, so a height-only test lets it overflow.
            if (textWidget.contentHeight > targetHeight || textWidget.contentWidth > targetWidth) {
                upper = mid
            } else {
                lower = mid
            }
        }
        root.renderPixelSize = lower
        root.searching = false;
        root.visible = true
    }

    TextMetrics {
        id: textMetrics
        text: root.text
        font: root.font
    }

    StyledText {
        id: textWidget

        anchors.centerIn: parent
        width: root.rotate90 ? parent.height : parent.width
        text: root.text
        rotation: root.rotate90 ? 90 : 0

        renderType: Text.QtRendering
        wrapMode: Text.Wrap
    }    
}
