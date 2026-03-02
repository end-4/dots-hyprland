pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

import qs.modules.common as C
import qs.modules.common.functions as F
import qs.services as S
import qs.modules.common.widgets as W
import ".."

HBarWidgetContainer {
    id: root

    property bool showPopup: false
    readonly property bool vertical: C.Config.options.bar.vertical
    readonly property bool atBottom: C.Config.options.bar.bottom

    // Interactions
    property var morphedPanelParent: F.ObjectUtils.findParentWithProperty(root, "maskItems")
    onShowPopupChanged: {
        if (root.showPopup) {
            root.morphedPanelParent.addAttachedMaskItem(bgShape);
        } else {
            root.morphedPanelParent.removeAttachedMaskItem(bgShape);
        }
    }
    Connections {
        target: root.morphedPanelParent
        function onFocusGrabDismissed() {
            root.showPopup = false;
        }
    }

    // Background container shape
    background: HBarWidgetShapeBackground {
        id: bgShape

        vertical: root.vertical
        atBottom: root.atBottom
        showPopup: root.showPopup

        backgroundWidth: root.backgroundWidth
        backgroundHeight: root.backgroundHeight
        popupContentWidth: popupContent.implicitWidth
        popupContentHeight: popupContent.implicitHeight
        startRadius: root.getBackgroundRadius(root.startSide)
        endRadius: root.getBackgroundRadius(root.endSide)
    }

    // The button on the bar
    HBarWidgetContent {
        id: contentRoot

        vertical: root.vertical
        atBottom: root.atBottom
        showPopup: root.showPopup

        onClicked: root.showPopup = !showPopup
        contentImplicitWidth: vertical ? verticalContent.implicitWidth : horizontalContent.implicitWidth
        contentImplicitHeight: vertical ? verticalContent.implicitHeight : horizontalContent.implicitHeight

        // When horizontal
        W.FadeLoader {
            id: horizontalContent
            anchors.fill: parent
            shown: !contentRoot.vertical

            sourceComponent: Item {
                anchors.fill: parent
                implicitWidth: contentLayout.implicitWidth
                implicitHeight: contentLayout.implicitHeight

                RowLayout {
                    id: contentLayout
                    anchors.fill: parent

                    W.VisuallyCenteredStyledText {
                        Layout.leftMargin: contentRoot.layoutParentTopLeftRadius * contentRoot.parentRadiusToPaddingRatio
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                        Layout.fillHeight: true
                        font.pixelSize: C.Appearance.font.pixelSize.large
                        color: C.Appearance.colors.colOnLayer1
                        text: S.DateTime.time
                    }

                    W.StyledText {
                        Layout.alignment: Qt.AlignVCenter
                        font.pixelSize: C.Appearance.font.pixelSize.small
                        color: C.Appearance.colors.colOnLayer1
                        text: "•"
                    }

                    W.StyledText {
                        Layout.alignment: Qt.AlignVCenter
                        font.pixelSize: C.Appearance.font.pixelSize.small
                        color: C.Appearance.colors.colOnLayer1
                        text: S.DateTime.longDate
                    }
                }
            }
        }

        // When vertical
        W.FadeLoader {
            id: verticalContent
            anchors.fill: parent
        }

        // Popup content
        W.ChoreographerGrid {
            id: popupContent
            anchors {
                top: horizontalContent.bottom
                topMargin: bgShape.popupContentOffsetY
                left: horizontalContent.left
                leftMargin: bgShape.popupContentOffsetX
            }

            shown: root.showPopup

            W.FlyFadeEnterChoreographable {
                W.StyledText {
                    text: "Kalender"
                    font.pixelSize: 25
                }
            }
            W.FlyFadeEnterChoreographable {
                W.StyledText {
                    text: "Lorem ipsum okakumalum tung\ntung tung tung"
                }
            }
            W.FlyFadeEnterChoreographable {
                W.StyledText {
                    text: "BAJLANDO\nUUOOOUUUOOOUUOOUOU"
                }
            }
        }
    }
}
