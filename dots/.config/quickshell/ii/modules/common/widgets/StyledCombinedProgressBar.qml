pragma ComponentBehavior: Bound
import QtQuick
import qs.modules.common

AbstractCombinedProgressBar {
    id: root

    property real valueBarWidth: 120
    property real valueBarHeight: 4
    property real valueBarGap: 4
    property real valueBarInnerRadius: Appearance.rounding.unsharpen
    valueHighlights: [Appearance.colors.colPrimary, Appearance.colors.colTertiary]
    valueTroughs: [Appearance.colors.colSecondaryContainer, Appearance.colors.colTertiaryContainer]

    background: Item {
        implicitWidth: root.valueBarWidth
        implicitHeight: root.valueBarHeight
    }

    // "negligible" = too small that it'd look weird when shown
    function isNegligibleSegment(seg: var): bool {
        const wdth = seg[1] - seg[0];
        const visualWidth = availableWidth * wdth;
        return (visualWidth <= valueBarGap + valueBarHeight)
    }

    contentItem: Item {
        Repeater {
            model: root.visualSegments

            delegate: Rectangle {
                required property int index
                required property var modelData

                visible: !root.isNegligibleSegment(modelData)
                property bool atStart: index == 0
                property bool atEnd: index == root.visualSegments.length - 1
                property real displaySegStart: { // swallow previous segments if they're "negligible"
                    var i = index;
                    while ((i > 0 && root.isNegligibleSegment(root.visualSegments[i-1])))
                        i--;
                    return root.visualSegments[i][0]
                }

                anchors {
                    top: parent.top
                    bottom: parent.bottom
                }

                x: {
                    var result = root.availableWidth * displaySegStart;
                    if (!atStart) result += root.valueBarGap / 2;
                    return result;
                }
                width: {
                    var result = root.availableWidth * (modelData[1] - displaySegStart)
                    if (atStart || atEnd) result -= root.valueBarGap / 2;
                    else result -= root.valueBarGap;
                    return result;
                }
                color: root.segmentColors[index % root.segmentColors.length]

                property real startRadius: atStart ? height / 2 : root.valueBarInnerRadius
                property real endRadius: atEnd ? height / 2 : root.valueBarInnerRadius

                topLeftRadius: startRadius
                bottomLeftRadius: startRadius
                topRightRadius: endRadius
                bottomRightRadius: endRadius
            }
        }
    }
}
