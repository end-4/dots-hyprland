import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Fusion
import Qt5Compat.GraphicalEffects

Rectangle {
    id: root
    required property LockContext context

    // Monitor name where the login field (centralBox) should appear
    readonly property string simplifiedMonitorName: "DP-1"
    readonly property bool isSimplifiedMonitor: screen?.name === root.simplifiedMonitorName

    property real lockScreenScale: 0

    Component.onCompleted: {
        lockScreenScale = 1.0;
    }

    // Behavior on lockScreenScale {
    //     animation: Appearance.animation.elementMove.numberAnimation.createObject(this);
    // } @vaguesyntax way o animate, thx bro :)

    Behavior on lockScreenScale {
        NumberAnimation {
            duration: 2000
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves.expressiveSlowSpatial
        }
    }

    opacity: lockScreenScale
    // #######################

    // Base wallpaper, same crop as the workspace
    Image {
        id: wallpaperLayer
        anchors.fill: parent
        source: Config.options.background.wallpaperPath
        fillMode: Image.PreserveAspectCrop
        smooth: true
        opacity: 0    // invisible but still renders for blur
    }

    // Main Blur
    FastBlur {
        id: globalBlur
        anchors.fill: parent
        source: wallpaperLayer
        radius: 35
    }

    // Darkening
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: 0.6
    }

    // NOISE
    Image {
        anchors.fill: parent
        source: "noise.png"
        fillMode: Image.Tile
        opacity: 0.04
        smooth: false
    }

    color: "transparent"

    // Function to force focus on the password field (kept)
    function forceFieldFocus() {
        passwordBox.forceActiveFocus();
    }

    // FORCE UNLOCK
    RippleButton {
        visible: Wayland.outputName === root.targetMonitor // Fixed visibility using targetMonitor
        anchors {
            top: parent.top
            left: parent.left
            leftMargin: 10
            topMargin: 10
        }
        implicitHeight: 40
        // Background color using the Appearance.qml theme
        colBackground: Appearance.colors.colLayer2
        onClicked: {
            context.unlocked(LockContext.ActionEnum.Unlock);
            GlobalStates.screenLocked = false;
        }
        contentItem: StyledText {
            // Text color using the Appearance.qml theme
            color: Appearance.colors.colOnLayer2
            text: "[[ DEBUG BYPASS ]]"
        }
    }

    Rectangle {
        id: centralBox

        // show only in the main monitor
        visible: !root.isSimplifiedMonitor

        property int spacingRow: 40
        property int sqrsize: 450 // makes the image fit snugly with centralBox

        width: sqrsize + spacingRow + rightColumn.implicitWidth
        height: sqrsize
        radius: 0                        // rounding corners of the centralBox

        // Dynamic background color (using Appearance.colors.colLayer0 with transparency)
        color: Appearance.colors.colBackgroundSurfaceContainer
        anchors.centerIn: parent
        border.color: Appearance.colors.colOutlineVariant
        border.width: 2

        RowLayout {
            id: mainRow
            anchors.fill: parent
            anchors.margins: centralBox.border.width
            spacing: centralBox.spacingRow

            // Dynamic Wallpaper
            // LockSurface.qml - inside Image { id: preview }
            Item {
                id: container
                width: centralBox.sqrsize - centralBox.border.width * 2
                height: centralBox.sqrsize - centralBox.border.width * 2 // ensures a square aspect
                // p.s.: I didn't want the border underneath the image, so I used this workaround
                // the "- centralBox.border.width * 2" can be removed and anchors.margins should be changed to zero
                clip: true

                Image {
                    id: preview
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop   // <-- center-cropped, no stretching
                    asynchronous: true
                    smooth: true

                    source: Config.options.background.wallpaperPath
                }
            }

            ColumnLayout {
                id: rightColumn

                Layout.fillWidth: false
                Layout.preferredWidth: implicitWidth
                Layout.minimumWidth: implicitWidth
                Layout.maximumWidth: implicitWidth

                spacing: 20

                // Clock (using dynamic font from Appearance.qml)
                Label {
                    id: clock

                    Layout.topMargin: -10 // workaround, can be removed freely
                    Layout.bottomMargin: -5 // workaround, can be removed freely

                    property var date: new Date()
                    renderType: Text.NativeRendering
                    font {
                        // Using the title/clock font
                        family: Appearance.font.family.monospace
                        pixelSize: 60 // Keep large size for the clock
                        variableAxes: Appearance.font.variableAxes.title
                    }

                    color: Appearance.colors.colOnSurface // Main text color

                    Timer {
                        running: true
                        repeat: true
                        interval: 60
                        onTriggered: clock.date = new Date()
                    }

                    text: {
                        const h = clock.date.getHours().toString().padStart(2, "0");
                        const m = clock.date.getMinutes().toString().padStart(2, "0");
                        return `${h}:${m}`;
                    }
                }

                // System Information (using dynamic font from Appearance.qml)
                Label {
                    textFormat: Text.RichText
                    wrapMode: Text.NoWrap
                    rightPadding: centralBox.spacingRow
                    Layout.bottomMargin: 13 // workaround, can be removed freely

                    // Using the monospace font (if Iosevka is configured as such)
                    font {
                        family: Appearance.font.family.monospace
                        pixelSize: Appearance.font.pixelSize.small
                        variableAxes: Appearance.font.variableAxes.numbers
                    }

                    // Get the primary color from your Appearance.qml theme
                    readonly property string accentColor: Appearance.colors.colPrimary

                    // Build the text using <font color='...'> tags
                    text: `
                    <font color='${accentColor}'>CPU:</font> Intel Xeon E5-2650 v4 @2.90 GHz<br>
                    <font color='${accentColor}'>GPU:</font> AMD Radeon RX 580 2048SP<br>
                    <br>
                    <font color='${accentColor}'>OS:</font> Arch Linux x86_64<br>
                    <font color='${accentColor}'>Kernel:</font> Linux 6.17.8-arch1-1<br>
                    <font color='${accentColor}'>WM:</font> Hyprland 0.52.1 (Wayland)<br>
                    <br>
                    <font color='${accentColor}'>Shell:</font> fish 4.2.1<br>
                    <font color='${accentColor}'>Terminal:</font> kitty 0.44.0<br><br>
                    <font color='${accentColor}'>masthierryi</font> @masthierryi-arch
                    `
                    // Dynamic color (fallback, if tag fails or for untagged text)
                    color: Appearance.colors.colSubtext
                }

                RowLayout {
                    spacing: 0
                    TextField {
                        id: passwordBox
                        implicitWidth: rightColumn.implicitWidth - centralBox.spacingRow
                        Layout.leftMargin: -4

                        // Style
                        padding: 12
                        clip: true
                        font.pixelSize: Appearance.font.pixelSize.scritsize

                        Component.onCompleted: {
                            forceFieldFocus();
                        }

                        focus: true
                        enabled: !root.context.unlockInProgress
                        echoMode: TextInput.Password
                        inputMethodHints: Qt.ImhSensitiveData

                        onTextChanged: root.context.currentText = this.text
                        onAccepted: root.context.tryUnlock()
                        Connections {
                            target: root.context
                            function onCurrentTextChanged() {
                                passwordBox.text = root.context.currentText
                            }
                        }

                        Keys.onPressed: event => {
                            root.context.resetClearTimer();
                        }

                        // Shake when wrong password
                        SequentialAnimation {
                            id: wrongPasswordShakeAnim
                            // Using dynamic animation properties (Duration and Easing)
                            NumberAnimation { target: passwordBox; property: "Layout.leftMargin"; to: -30; duration: Appearance.animation.elementMoveFast.duration / 3 }
                            NumberAnimation { target: passwordBox; property: "Layout.leftMargin"; to: 30; duration: Appearance.animation.elementMoveFast.duration / 3 }
                            NumberAnimation { target: passwordBox; property: "Layout.leftMargin"; to: -15; duration: Appearance.animation.elementMoveFast.duration / 4 }
                            NumberAnimation { target: passwordBox; property: "Layout.leftMargin"; to: 15; duration: Appearance.animation.elementMoveFast.duration / 4 }
                            NumberAnimation { target: passwordBox; property: "Layout.leftMargin"; to: 0; duration: Appearance.animation.elementMoveFast.duration / 5 }
                        }

                        Connections {
                            target: GlobalStates
                            function onScreenUnlockFailedChanged() {
                                if (GlobalStates.screenUnlockFailed) wrongPasswordShakeAnim.restart();
                            }
                        }

                        background: Rectangle {
                            // Semi-transparent black background
                            color: ColorUtils.transparentize(Appearance.m3colors.m3surfaceContainerLowest, 0.4)
                            border.color: "transparent"
                            radius: Appearance.rounding.verysmall

                            Behavior on border.width {
                                NumberAnimation { duration: 150 }
                            }
                        }

                        property bool materialShapeChars: Config.options.lock.materialShapeChars
                        // Dynamic color, using ColorUtils from Appearance.qml and colOnLayer1
                        color: ColorUtils.transparentize(Appearance.colors.colOnLayer1, materialShapeChars ? 1 : 0)
                        Loader {
                            active: passwordBox.materialShapeChars
                            anchors {
                                fill: parent
                                leftMargin: passwordBox.padding
                                rightMargin: passwordBox.padding
                            }
                            sourceComponent: PasswordChars {
                                length: root.context.currentText.length
                            }
                        }
                    }

                }

            }
        }
    }
}
