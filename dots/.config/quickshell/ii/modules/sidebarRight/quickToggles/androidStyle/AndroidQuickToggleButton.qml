import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import qs
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

GroupButton {
    id: root

    colBackground: Appearance.colors.colLayer2

    buttonRadius: (altAction && toggled) ? Appearance.rounding.normal : Math.min(baseHeight, baseWidth) / 2
    property int buttonToggledRadius: Appearance.rounding.normal
    toggledRadius: buttonToggledRadius
    buttonRadiusPressed: buttonToggledRadius

    readonly property real buttonIconSize: Appearance.font.pixelSize.hugeass
    readonly property real titleTextSize: columns == 4 ? 15 : 13
    readonly property real descTextSize: columns == 4 ? 13 : 12

    property color colText: root.toggled ? Appearance.colors.colLayer2 : Appearance.colors.colOnLayer1
    property int columns: Config.options.quickToggles.android.columns

    property string buttonIcon
    property real buttonSize: 1
    property bool expandedSize: buttonSize === 2
    property string titleText
    property string descText
    property int buttonIndex
    property string unusedName: ""

    property int unusedButtonSize: 48
    property int calculatedWidth: columns == 4 ? 95 : 75
    property int calculatedHeight: 55
    baseWidth: unusedName === "" ? calculatedWidth * buttonSize - 5 : unusedButtonSize * 1.6
    baseHeight: unusedName === "" ? calculatedHeight : unusedButtonSize

    property bool halfToggled: false
    toggled: false

    // There is probably better ways of changing these, but i think these makes sense
    scrollUpAction: () => {
        if (!Config.options.quickToggles.android.inEditMode || unusedName !== "")
            return;
        QuickTogglesUtils.moveOption(buttonIndex, -1);
    }

    scrollDownAction: () => {
        if (!Config.options.quickToggles.android.inEditMode || unusedName !== "")
            return;
        QuickTogglesUtils.moveOption(buttonIndex, +1);
    }

    altAction: () => {
        if (!Config.options.quickToggles.android.inEditMode || unusedName !== "")
            return;

        QuickTogglesUtils.toggleOptionSize(buttonIndex);
    }

    releaseAction: () => {
        if (!Config.options.quickToggles.android.inEditMode)
            return;
        if (unusedName === "")
            QuickTogglesUtils.removeOption(buttonIndex);
        else
            QuickTogglesUtils.addOption(unusedName);
    }

    mouseForwardAction: () => {
        if (!Config.options.quickToggles.android.inEditMode)
            return;
        if (unusedName !== "")
            QuickTogglesUtils.addOption(unusedName);
    }

    mouseBackAction: () => {
        if (!Config.options.quickToggles.android.inEditMode)
            return;
        if (unusedName === "")
            QuickTogglesUtils.removeOption(buttonIndex);
    }

    contentItem: RowLayout {
        id: contentItem
        anchors {
            centerIn: root.expandedSize ? undefined : parent
            fill: root.expandedSize ? parent : undefined
            leftMargin: 12
            rightMargin: 12
        }

        Rectangle {
            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter

            implicitWidth: Math.max(buttonIconItem.implicitWidth, buttonIconItem.implicitHeight) + 4 * 2
            implicitHeight: implicitWidth
            radius: buttonRadius
            color: (!root.expandedSize || toggled) ? ColorUtils.transparentize(root.color) : halfToggled ? Appearance.colors.colPrimary : Appearance.colors.colLayer2

            MaterialSymbol {
                id: buttonIconItem
                anchors.centerIn: parent
                iconSize: buttonIconSize
                fill: toggled ? 1 : 0
                color: toggled || halfToggled ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer1
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: buttonIcon

                Behavior on color {
                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                }
            }

        }
        Loader {
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true
            visible: root.expandedSize
            active: visible
            sourceComponent: Column {
                StyledText {
                    anchors {
                        left: parent.left
                        right: parent.right
                    }
                    font.pixelSize: Appearance.font.pixelSize.smallie
                    color: root.colText
                    elide: Text.ElideRight
                    text: titleText
                }

                StyledText {
                    anchors {
                        left: parent.left
                        right: parent.right
                    }
                    font {
                        pixelSize: Appearance.font.pixelSize.smaller
                        weight: Font.Normal
                    }
                    color: root.colText
                    elide: Text.ElideRight
                    text: root.descText
                }
            }
        }
    }
}
