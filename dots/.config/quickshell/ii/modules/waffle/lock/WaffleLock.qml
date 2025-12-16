pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.common.panels.lock
import qs.modules.waffle.looks
import qs.modules.waffle.sessionScreen as SessionScreen

LockScreen {
    id: root

    property bool passwordView: false

    lockSurface: Item {
        id: lockSurfaceItem

        Component.onCompleted: {
            root.passwordView = false;
            lockSurfaceItem.forceActiveFocus();
        }

        Keys.onPressed: {
            interactables.switchToFocusedView();
        }

        Image {
            id: bg
            z: 0
            width: parent.width
            height: parent.height
            onStatusChanged: {
                if (status === Image.Ready) {
                    print("Lock wallpaper loaded");
                    print(lockSurfaceItem.height);
                    y = -lockSurfaceItem.height;
                    openAnim.restart();
                }
            }
            sourceSize: Qt.size(lockSurfaceItem.width, lockSurfaceItem.height)
            source: Config.options.background.wallpaperPath
            fillMode: Image.PreserveAspectCrop

            PropertyAnimation {
                id: openAnim
                target: bg
                property: "y"
                to: 0
                duration: 350
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Looks.transition.easing.bezierCurve.easeIn
            }
        }

        GaussianBlur {
            z: 1
            anchors.fill: bg
            source: bg
            radius: 100
            samples: radius * 2 + 1
            scale: root.passwordView ? 1.1 : 1
            opacity: root.passwordView ? 1 : 0

            Behavior on opacity {
                animation: Looks.transition.opacity.createObject(this)
            }

            Behavior on scale {
                NumberAnimation {
                    duration: 400
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Looks.transition.easing.bezierCurve.easeIn
                }
            }
        }

        Interactables {
            id: interactables
            z: 2
            anchors.fill: bg
        }
    }

    component Interactables: Rectangle {
        id: interactablesComponent
        color: ColorUtils.transparentize("#000000", 0.8)
        // Button {
        //     onClicked: {
        //         root.context.unlocked(LockContext.ActionEnum.Unlock);
        //         GlobalStates.screenLocked = false;
        //     }
        //     text: "woah it doesnt work let me out pls uwu colon three"
        // }

        function switchToFocusedView() {
            switchToPasswordViewAnim.restart();
        }

        SequentialAnimation {
            id: switchToPasswordViewAnim
            PropertyAnimation {
                target: unfocusedContent
                property: "y"
                from: 0
                to: -height * 1.1
                duration: 250
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Looks.transition.easing.bezierCurve.easeIn
            }
            ScriptAction {
                script: {
                    root.passwordView = true;
                }
            }
        }

        Item {
            id: unfocusedContent
            width: parent.width
            height: parent.height
            visible: !root.passwordView
            ClockTextGroup {
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: parent.top
                    topMargin: interactablesComponent.height * 0.1
                }
            }
            RowLayout {
                anchors {
                    bottom: parent.bottom
                    right: parent.right
                    bottomMargin: 21
                    rightMargin: 31
                }
                IconIndicator {
                    baseIcon: "wifi-1"
                    icon: WIcons.internetIcon
                }
                IconIndicator {
                    baseIcon: WIcons.batteryIcon
                    icon: WIcons.batteryLevelIcon
                }
            }
        }

        Item {
            id: focusedContent
            anchors.fill: parent
            visible: root.passwordView

            PasswordGroup {
                visible: root.passwordView
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    verticalCenter: parent.verticalCenter
                }
            }

            RowLayout {
                visible: root.passwordView
                anchors {
                    bottom: parent.bottom
                    right: parent.right
                    bottomMargin: 21
                    rightMargin: 31
                }
                SessionScreen.PowerButton {
                    id: powerButton
                }
            }
        }
    }

    component IconIndicator: Item {
        id: iconIndicator
        required property string baseIcon
        required property string icon
        default property alias data: iconWidget.data
        implicitWidth: 40
        implicitHeight: 40
        FluentIcon {
            id: iconWidget
            anchors.centerIn: parent
            icon: iconIndicator.baseIcon
            color: Looks.darkColors.inactiveIcon
            implicitSize: 20
            FluentIcon {
                anchors.fill: parent
                icon: iconIndicator.icon
            }
        }
    }

    component ClockTextGroup: Column {
        id: clockTextGroup
        spacing: -3

        WText {
            anchors.horizontalCenter: parent.horizontalCenter
            color: Looks.darkColors.fg
            font.pixelSize: 133
            font.weight: Looks.font.weight.strong
            text: {
                // Don't take am/pm
                // Match groups of digits separated by non-digit chars (e.g., "12:34", "12.34", "12-34")
                let match = DateTime.time.match(/(\d{1,2})\D+(\d{2})/);
                return match ? `${match[1]}${DateTime.time.match(/\D+/)[0]}${match[2]}` : DateTime.time;
            }
        }

        WText {
            id: dateLabel
            color: Looks.darkColors.fg
            anchors.horizontalCenter: parent.horizontalCenter
            font.pixelSize: 28
            font.weight: Looks.font.weight.strong
            text: DateTime.collapsedCalendarFormat
        }
    }

    component PasswordGroup: ColumnLayout {
        id: passwordGroup
        spacing: 15

        WUserAvatar {
            Layout.alignment: Qt.AlignHCenter
            sourceSize: Qt.size(192, 192)
        }

        WText {
            Layout.alignment: Qt.AlignHCenter
            text: SystemInfo.username
            color: Looks.darkColors.fg
            font.pixelSize: 26
            font.weight: Looks.font.weight.strong
        }

        Rectangle {
            id: passwordInputWrapper
            Layout.topMargin: 10
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: 132
            color: "transparent"
            implicitWidth: 296
            implicitHeight: 36
            border.width: 2
            border.color: Looks.applyContentTransparency(Looks.darkColors.bg1Border)
            radius: Looks.radius.medium

            Rectangle {
                id: passwordInputBackground
                anchors.fill: parent
                anchors.margins: 2
                radius: Looks.radius.small + 1
                color: passwordInput.focus ? Looks.applyBackgroundTransparency(Looks.darkColors.bg1Base) : Looks.applyContentTransparency(Looks.darkColors.bg1)

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 3

                    WTextInput {
                        id: passwordInput
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        verticalAlignment: TextInput.AlignVCenter
                        inputMethodHints: Qt.ImhSensitiveData
                        echoMode: passwordVisibilityButton.pressed ? TextInput.Normal : TextInput.Password
                        color: Looks.darkColors.fg

                        font.pixelSize: 12
                        WText {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            visible: passwordInput.text.length === 0
                            text: Translation.tr("Password")
                            font.pixelSize: Looks.font.pixelSize.large
                            color: Looks.darkColors.fg
                            opacity: 0.8
                        }

                        onTextChanged: root.context.currentText = this.text
                        onAccepted: {
                            root.context.tryUnlock();
                        }
                        Connections {
                            target: root.context
                            function onCurrentTextChanged() {
                                passwordInput.text = root.context.currentText;
                            }
                        }
                        Connections {
                            target: root
                            function onPasswordViewChanged() {
                                passwordInput.forceActiveFocus();
                            }
                        }

                        Keys.onPressed: event => {
                            root.context.resetClearTimer();
                        }

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.NoButton
                            cursorShape: Qt.IBeamCursor
                        }
                    }

                    PasswordBoxButton {
                        id: passwordVisibilityButton
                        property bool passwordVisible: false
                        visible: passwordInput.text.length > 0
                        onPressed: passwordVisible = true
                        onReleased: passwordVisible = false
                        icon.name: passwordVisible ? "eye-off" : "eye"
                    }

                    PasswordBoxButton {
                        onClicked: {
                            root.context.tryUnlock();
                        }
                        icon.name: "arrow-right"
                    }
                }
            }
            Rectangle {
                id: activeIndicatorLine
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }
                implicitHeight: 2
                color: passwordInput.focus ? Looks.colors.accent : Looks.applyContentTransparency(Looks.darkColors.bg2Border)
            }

            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: passwordInputWrapper.width
                    height: passwordInputWrapper.height
                    radius: passwordInputWrapper.radius
                }
            }
        }

        Item {}
    }

    component PasswordBoxButton: WButton {
        id: pwBoxBtn
        implicitWidth: 28
        implicitHeight: 22

        property color colBackground: ColorUtils.transparentize(Looks.darkColors.bg1)
        property color colBackgroundHover: ColorUtils.transparentize(Looks.darkColors.bg2Hover)
        property color colBackgroundActive: ColorUtils.transparentize(Looks.darkColors.bg2Active)
        fgColor: checked ? Looks.colors.accentFg : Looks.darkColors.fg

        checked: hovered

        contentItem: Item {
            FluentIcon {
                color: pwBoxBtn.fgColor
                anchors.centerIn: parent
                icon: pwBoxBtn.icon.name
                implicitSize: 16
            }
        }
    }
}
