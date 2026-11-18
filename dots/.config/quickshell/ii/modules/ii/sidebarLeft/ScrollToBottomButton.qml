import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

RippleButton {
    id: root
    required property ListView target

    anchors {
        bottom: parent.bottom
        horizontalCenter: parent.horizontalCenter
        bottomMargin: 10
    }

    // Show only when the user scrolled away, not during auto-follow; key off followBottom
    // (not raw distance, which the 70ms follow lags) and require a meaningful gap
    property real showThreshold: Math.max(200, target.height * 0.3)
    readonly property real distanceFromBottom: target.contentHeight - target.height - target.contentY
    readonly property bool following: target.followBottom === true
    readonly property bool shouldShow: !following && distanceFromBottom > showThreshold

    opacity: shouldShow ? 1 : 0
    scale: shouldShow ? 1 : 0.7
    visible: opacity > 0
    Behavior on opacity {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }
    Behavior on scale {
        animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
    }

    implicitWidth: contentItem.implicitWidth + 8 * 2
    implicitHeight: contentItem.implicitHeight + 4 * 2

    colBackground: Appearance.colors.colSecondary
    colBackgroundHover: Appearance.colors.colSecondaryHover
    colRipple: Appearance.colors.colSecondaryActive
    buttonRadius: Appearance.rounding.verysmall

    downAction: () => {
        target.positionViewAtEnd()
        if (target.followBottom !== undefined) target.followBottom = true // re-engage auto-follow
    }

    contentItem: Row {
        id: contentItem
        spacing: 4
        MaterialSymbol {
            anchors.verticalCenter: parent.verticalCenter
            text: "arrow_downward"
            font.pixelSize: Appearance.font.pixelSize.larger
            color: Appearance.colors.colOnSecondary
            verticalAlignment: Text.AlignVCenter
        }
        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: Translation.tr("Scroll to Bottom")
            font.pixelSize: Appearance.font.pixelSize.smallie
            color: Appearance.colors.colOnSecondary
            verticalAlignment: Text.AlignVCenter
        }
    }
}
