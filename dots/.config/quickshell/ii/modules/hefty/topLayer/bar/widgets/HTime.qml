pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
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

    readonly property string timeFormatString: C.Config.options.time.format
    readonly property bool is12h: timeFormatString.startsWith("h:")
    readonly property bool hasAmPm: timeFormatString.toLowerCase().includes("ap") || timeFormatString.toLowerCase().endsWith("a")
    readonly property bool capitalizedAmPm: timeFormatString.includes("AP") || timeFormatString.endsWith("A")

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

            sourceComponent: HorizontalClock {
                anchors.fill: parent
            }
        }

        // When vertical
        W.FadeLoader {
            id: verticalContent
            anchors.fill: parent
            shown: contentRoot.vertical

            sourceComponent: VerticalClock {
                anchors.fill: parent
            }
        }

        // Popup content
        PopupContent {
            id: popupContent
            anchors {
                top: root.vertical ? verticalContent.top : horizontalContent.top
                topMargin: bgShape.popupContentOffsetY
                left: root.vertical ? verticalContent.left : horizontalContent.left
                leftMargin: bgShape.popupContentOffsetX
            }

            shown: root.showPopup
        }
    }

    component HorizontalClock: Item {
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

            W.VisuallyCenteredStyledText {
                Layout.alignment: Qt.AlignVCenter
                font.pixelSize: C.Appearance.font.pixelSize.small
                color: C.Appearance.colors.colOnLayer1
                text: "•"
            }

            W.VisuallyCenteredStyledText {
                Layout.alignment: Qt.AlignVCenter
                font.pixelSize: C.Appearance.font.pixelSize.small
                color: C.Appearance.colors.colOnLayer1
                text: S.DateTime.longDate
            }
        }
    }

    component VerticalClock: Item {
        implicitWidth: contentLayoutVertical.implicitWidth
        implicitHeight: contentLayoutVertical.implicitHeight

        ColumnLayout {
            id: contentLayoutVertical
            anchors.fill: parent
            spacing: amPmText.visible ? -2 : -4

            ColumnLayout {
                id: verticalTime
                Layout.alignment: Qt.AlignHCenter
                spacing: -4

                W.StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    font.pixelSize: C.Appearance.font.pixelSize.large
                    color: C.Appearance.colors.colOnLayer1
                    text: {
                        var hrs = S.DateTime.clock.hours;
                        if (root.is12h && hrs != 12)
                            hrs %= 12;
                        return hrs.toString().padStart(2, '0');
                    }
                }
                W.StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    font.pixelSize: C.Appearance.font.pixelSize.large
                    color: C.Appearance.colors.colOnLayer1
                    text: S.DateTime.clock.minutes.toString().padStart(2, '0')
                }
                W.StyledText {
                    id: amPmText
                    visible: root.hasAmPm
                    Layout.topMargin: -2
                    Layout.alignment: Qt.AlignHCenter
                    font.pixelSize: C.Appearance.font.pixelSize.smaller
                    color: C.Appearance.colors.colOnLayer1
                    text: Qt.locale().toString(S.DateTime.clock.date, root.capitalizedAmPm ? "AP" : "ap")
                }
            }

            W.StyledText {
                Layout.alignment: Qt.AlignHCenter
                font.pixelSize: C.Appearance.font.pixelSize.smallest
                color: C.Appearance.colors.colOnLayer1
                text: S.DateTime.shortDate
            }
        }
    }

    component PopupContent: W.ChoreographerGridLayout {
        id: popupRoot

        property real buttonSize: C.Appearance.rounding.normal * 2
        property real buttonSpacing: 4

        rowSpacing: 0

        W.FlyFadeEnterChoreographable {
            Layout.fillWidth: true

            RowLayout {
                width: parent.width
                spacing: 0

                W.StyledText {
                    Layout.leftMargin: 6
                    Layout.alignment: Qt.AlignVCenter
                    Layout.fillWidth: true
                    text: calendarView.title
                    font.pixelSize: C.Appearance.font.pixelSize.larger
                    elide: Text.ElideRight
                    color: C.Appearance.colors.colSecondary
                }
                W.StyledIconButton {
                    implicitSize: 30
                    text: "chevron_left"
                    iconSize: 20
                    onClicked: calendarView.scrollMonthsAndSnap(-1)
                    colForeground: C.Appearance.colors.colPrimary
                }
                W.StyledIconButton {
                    implicitSize: 30
                    text: "chevron_right"
                    iconSize: 20
                    onClicked: calendarView.scrollMonthsAndSnap(1)
                    colForeground: C.Appearance.colors.colPrimary
                }
                W.StyledIconButton {
                    implicitSize: 30
                    text: "rotate_left"
                    iconSize: 20
                    onClicked: calendarView.scrollToToday()
                    colForeground: C.Appearance.colors.colPrimary
                    enabled: calendarView.targetWeekDiff != 0
                }
            }
        }
        W.FlyFadeEnterChoreographable {
            Layout.fillWidth: true

            DayOfWeekRow {
                id: dayOfWeekRow
                width: parent.width
                locale: calendarView.locale
                spacing: popupRoot.buttonSpacing
                delegate: Item {
                    id: dayOfWeekItem
                    required property var model
                    implicitHeight: popupRoot.buttonSize
                    implicitWidth: popupRoot.buttonSize

                    W.VisuallyCenteredStyledText {
                        anchors.centerIn: parent
                        text: {
                            var result = dayOfWeekItem.model.shortName;
                            if (C.Config.options.calendar.force2CharDayOfWeek)
                                result = result.substring(0, 2);
                            return result;
                        }
                    }
                }
            }
        }
        W.FlyFadeEnterChoreographable {
            Item {
                implicitWidth: calendarView.implicitWidth - calendarView.horizontalPadding * 2
                implicitHeight: calendarView.implicitHeight - calendarView.verticalPadding * 2
                W.CalendarView {
                    id: calendarView
                    anchors.centerIn: parent
                    locale: Qt.locale(C.Config.options.calendar.locale)
                    verticalPadding: 4
                    horizontalPadding: 4
                    buttonSize: popupRoot.buttonSize
                    buttonSpacing: popupRoot.buttonSpacing
                    buttonVerticalSpacing: popupRoot.buttonSpacing
                    Layout.fillWidth: true
                    
                    delegate: W.StyledButton {
                        id: dayButton
                        required property var model

                        focus: model.today
                        checked: model.today
                        enabled: model.month === calendarView.focusedMonth
                        implicitWidth: popupRoot.buttonSize
                        implicitHeight: popupRoot.buttonSize
                        width: implicitWidth
                        height: implicitHeight
                        text: model.day

                        Connections {
                            target: popupRoot
                            enabled: dayButton.model.today
                            function onShownChanged() {
                                if (popupRoot.shown) dayButton.forceActiveFocus();
                            }
                        }

                        contentItem: Item {
                            W.VisuallyCenteredStyledText {
                                anchors.centerIn: parent
                                text: dayButton.text
                                color: dayButton.colForeground
                            }
                        }
                    }
                }
            }
        }
    }
}
