import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell.Services.UPower
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.common.panels.lock
import qs.modules.ii.bar as Bar
import qs.modules.ii.mediaControls
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Services.Mpris
import Quickshell.Io
import Quickshell.Widgets

MouseArea {
    id: root
    required property LockContext context
    property bool active: false
    property bool showInputField: active || context.currentText.length > 0
    readonly property bool requirePasswordToPower: Config.options.lock.security.requirePasswordToPower

    // Force focus on entry
    function forceFieldFocus() {
        passwordBox.forceActiveFocus();
    }
    Connections {
        target: context
        function onShouldReFocus() {
            forceFieldFocus();
        }
    }
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton
    onPressed: mouse => {
        forceFieldFocus();
    }
    onPositionChanged: mouse => {
        forceFieldFocus();
    }

    // Toolbar appearing animation
    property real toolbarScale: 0.9
    property real toolbarOpacity: 0
    Behavior on toolbarScale {
        NumberAnimation {
            duration: Appearance.animation.elementMove.duration
            easing.type: Appearance.animation.elementMove.type
            easing.bezierCurve: Appearance.animationCurves.expressiveFastSpatial
        }
    }
    Behavior on toolbarOpacity {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    // Music player state
    readonly property MprisPlayer activePlayer: MprisController.activePlayer
    readonly property bool hasActivePlayer: activePlayer && activePlayer.isPlaying
    property list<real> visualizerPoints: []
    
    // Cava process for audio visualization
    Process {
        id: cavaProc
        running: root.hasActivePlayer && GlobalStates.screenLocked
        onRunningChanged: {
            if (!cavaProc.running) {
                root.visualizerPoints = [];
            }
        }
        command: ["cava", "-p", `${FileUtils.trimFileProtocol(Directories.scriptPath)}/cava/raw_output_config.txt`]
        stdout: SplitParser {
            onRead: data => {
                let points = data.split(";").map(p => parseFloat(p.trim())).filter(p => !isNaN(p));
                root.visualizerPoints = points;
            }
        }
    }

    // Init
    Component.onCompleted: {
        forceFieldFocus();
        toolbarScale = 1;
        toolbarOpacity = 1;
    }

    // Key presses
    property bool ctrlHeld: false
    Keys.onPressed: event => {
        root.context.resetClearTimer();
        if (event.key === Qt.Key_Control) {
            root.ctrlHeld = true;
        }
        if (event.key === Qt.Key_Escape) { // Esc to clear
            root.context.currentText = "";
        } 
        forceFieldFocus();
    }
    Keys.onReleased: event => {
        if (event.key === Qt.Key_Control) {
            root.ctrlHeld = false;
        }
        forceFieldFocus();
    }

    // RippleButton {
    //     anchors {
    //         top: parent.top
    //         left: parent.left
    //         leftMargin: 10
    //         topMargin: 10
    //     }
    //     implicitHeight: 40
    //     colBackground: Appearance.colors.colLayer2
    //     onClicked: {
    //         context.unlocked(LockContext.ActionEnum.Unlock);
    //         GlobalStates.screenLocked = false;
    //     }
    //     contentItem: StyledText {
    //         text: "[[ DEBUG BYPASS ]]"
    //     }
    // }

    // SysTray at the top
    Item {
        id: sysTrayContainer
        anchors {
            top: parent.top
            horizontalCenter: parent.horizontalCenter
            topMargin: 20
        }
        implicitWidth: sysTrayLayout.implicitWidth
        implicitHeight: sysTrayLayout.implicitHeight
        scale: root.toolbarScale
        opacity: root.toolbarOpacity
        
        // Transparent background (no Toolbar background)
        RowLayout {
            id: sysTrayLayout
            anchors.centerIn: parent
            spacing: 8
            
            // Show all system tray items (no pin logic, read-only on lock screen)
            Repeater {
                model: ScriptModel {
                    values: SystemTray.items.values.filter(i => i.status !== Status.Passive)
                }
                
                delegate: Item {
                    required property SystemTrayItem modelData
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    
                    // Get notification count for this app
                    readonly property int notificationCount: {
                        if (!modelData) return 0;
                        // Try to match by app name or id
                        const appName = modelData.title || modelData.id || "";
                        return Notifications.list.filter(n => {
                            return n.appName && (
                                n.appName.toLowerCase().includes(appName.toLowerCase()) ||
                                appName.toLowerCase().includes(n.appName.toLowerCase())
                            );
                        }).length;
                    }
                    
                    // Disable all interactions - only show icon
                    MouseArea {
                        id: lockTrayMouseArea
                        anchors.fill: parent
                        acceptedButtons: Qt.NoButton
                        hoverEnabled: true
                    }
                    
                    // Show icon only (no interaction) - use same approach as SysTrayItem
                    IconImage {
                        id: trayIcon
                        visible: !Config.options.bar.tray.monochromeIcons
                        source: modelData.icon
                        anchors.centerIn: parent
                        width: parent.width
                        height: parent.height
                    }
                    
                    // Monochrome icon fallback
                    Loader {
                        active: Config.options.bar.tray.monochromeIcons
                        anchors.fill: trayIcon
                        sourceComponent: Item {
                            Desaturate {
                                id: desaturatedIcon
                                visible: false
                                anchors.fill: parent
                                source: trayIcon
                                desaturation: 0.8
                            }
                            ColorOverlay {
                                anchors.fill: desaturatedIcon
                                source: desaturatedIcon
                                color: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.9)
                            }
                        }
                    }
                    
                    // Notification/Message count badge
                    Rectangle {
                        id: badge
                        visible: notificationCount > 0
                        anchors {
                            right: parent.right
                            top: parent.top
                            rightMargin: -4
                            topMargin: -4
                        }
                        width: badgeText.visible ? Math.max(badgeText.implicitWidth + 4, 16) : 10
                        height: badgeText.visible ? Math.max(badgeText.implicitHeight + 2, 16) : 10
                        radius: height / 2
                        color: Appearance.colors.colError
                        z: 10
                        
                        StyledText {
                            id: badgeText
                            visible: notificationCount > 0 && notificationCount <= 99
                            anchors.centerIn: parent
                            font.pixelSize: Appearance.font.pixelSize.smallest
                            font.weight: Font.Bold
                            color: Appearance.colors.colOnError
                            text: notificationCount > 99 ? "99+" : notificationCount.toString()
                        }
                    }
                    
                    // Tooltip for viewing info
                    PopupToolTip {
                        extraVisibleCondition: lockTrayMouseArea.containsMouse
                        alternativeVisibleCondition: extraVisibleCondition
                        anchorEdges: Edges.Bottom
                        text: {
                            let text = modelData.tooltipTitle.length > 0 ? modelData.tooltipTitle
                                    : (modelData.title.length > 0 ? modelData.title : modelData.id);
                            if (modelData.tooltipDescription.length > 0) {
                                text += " • " + modelData.tooltipDescription;
                            }
                            if (notificationCount > 0) {
                                text += `\n${Translation.tr("Notifications")}: ${notificationCount}`;
                            }
                            return text;
                        }
                    }
                }
            }
        }
    }


    // Music box (positioned below clock, only visible when music is playing)
    Item {
        id: musicBoxContainer
        anchors {
            horizontalCenter: parent.horizontalCenter
            verticalCenter: parent.verticalCenter
            verticalCenterOffset: root.hasActivePlayer ? 180 : 0
        }
        width: Math.min(Appearance.sizes.mediaControlsWidth, parent.width * 0.85)
        height: root.hasActivePlayer ? Appearance.sizes.mediaControlsHeight : 0
        visible: root.hasActivePlayer && root.activePlayer !== null
        opacity: root.hasActivePlayer && root.activePlayer !== null ? 1 : 0
        
        Behavior on anchors.verticalCenterOffset {
            NumberAnimation {
                duration: Appearance.animation.elementMove.duration
                easing.type: Appearance.animation.elementMove.type
                easing.bezierCurve: Appearance.animationCurves.expressiveFastSpatial
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: Appearance.animation.elementMoveFast.duration
                easing.type: Appearance.animation.elementMoveFast.type
            }
        }
        Behavior on height {
            NumberAnimation {
                duration: Appearance.animation.elementMove.duration
                easing.type: Appearance.animation.elementMove.type
            }
        }
        Behavior on width {
            NumberAnimation {
                duration: Appearance.animation.elementMove.duration
                easing.type: Appearance.animation.elementMove.type
            }
        }
        
        Loader {
            id: playerControlLoader
            anchors.fill: parent
            active: root.hasActivePlayer && root.activePlayer !== null
            sourceComponent: PlayerControl {
                id: playerControl
                anchors.fill: parent
                player: root.activePlayer
                visualizerPoints: root.visualizerPoints
                maxVisualizerValue: 1000
                visualizerSmoothing: 2
                radius: Appearance.rounding.normal
                implicitWidth: musicBoxContainer.width
                implicitHeight: musicBoxContainer.height
            }
        }
    }

    // Main toolbar: password box
    Toolbar {
        id: mainIsland
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: 20
        }
        Behavior on anchors.bottomMargin {
            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
        }

        scale: root.toolbarScale
        opacity: root.toolbarOpacity

        // Fingerprint
        Loader {
            Layout.leftMargin: 10
            Layout.rightMargin: 6
            Layout.alignment: Qt.AlignVCenter
            active: root.context.fingerprintsConfigured
            visible: active

            sourceComponent: Item {
                id: fingerprintContainer
                implicitWidth: fingerprintIcon.implicitWidth
                implicitHeight: fingerprintIcon.implicitHeight
                x: 0
                
                MaterialSymbol {
                    id: fingerprintIcon
                    anchors.centerIn: parent
                    fill: 1
                    text: "fingerprint"
                    iconSize: Appearance.font.pixelSize.hugeass
                    color: {
                        if (root.context.fingerprintVerifyResult === "no-match") {
                            return Appearance.colors.colError;
                        } else if (root.context.fingerprintVerifyResult === "unknown-error") {
                            return Appearance.colors.colError;
                        } else {
                            return Appearance.colors.colOnSurfaceVariant;
                        }
                    }
                    
                    Behavior on color {
                        ColorAnimation {
                            duration: Appearance.animation.elementMoveFast.duration
                            easing.type: Appearance.animation.elementMoveFast.type
                        }
                    }
                }
                
                // Shake animation for no-match
                SequentialAnimation {
                    id: fingerprintShakeAnim
                    NumberAnimation { 
                        target: fingerprintContainer; 
                        property: "x"; 
                        from: 0; 
                        to: -10; 
                        duration: 50 
                        easing.type: Easing.OutQuad
                    }
                    NumberAnimation { 
                        target: fingerprintContainer; 
                        property: "x"; 
                        to: 10; 
                        duration: 50 
                        easing.type: Easing.InOutQuad
                    }
                    NumberAnimation { 
                        target: fingerprintContainer; 
                        property: "x"; 
                        to: -8; 
                        duration: 40 
                        easing.type: Easing.InOutQuad
                    }
                    NumberAnimation { 
                        target: fingerprintContainer; 
                        property: "x"; 
                        to: 8; 
                        duration: 40 
                        easing.type: Easing.InOutQuad
                    }
                    NumberAnimation { 
                        target: fingerprintContainer; 
                        property: "x"; 
                        to: 0; 
                        duration: 30 
                        easing.type: Easing.InQuad
                    }
                    onStopped: {
                        // Ensure x is reset to 0 when animation stops
                        fingerprintContainer.x = 0;
                    }
                }
                
                // Property to track last state to prevent duplicate triggers
                property string lastVerifyResult: ""
                property bool animationCooldown: false
                
                // Timer for animation cooldown (prevents animation from playing multiple times rapidly)
                Timer {
                    id: animationCooldownTimer
                    interval: 1500 // 1.5 second cooldown between animations
                    onTriggered: {
                        fingerprintContainer.animationCooldown = false;
                    }
                }
                
                // Trigger animation only once when state changes to no-match
                Connections {
                    target: root.context
                    function onFingerprintVerifyResultChanged() {
                        const currentResult = root.context.fingerprintVerifyResult;
                        // Only trigger if state changed to no-match and wasn't already no-match
                        if (currentResult === "no-match" && fingerprintContainer.lastVerifyResult !== "no-match") {
                            // Only start if not already running and cooldown has passed
                            if (!fingerprintShakeAnim.running && !fingerprintContainer.animationCooldown) {
                                fingerprintContainer.x = 0;
                                fingerprintContainer.animationCooldown = true;
                                fingerprintShakeAnim.start();
                                animationCooldownTimer.restart();
                            }
                        } else if (currentResult !== "no-match" && fingerprintContainer.lastVerifyResult === "no-match") {
                            // Reset position when leaving no-match state
                            if (!fingerprintShakeAnim.running) {
                                fingerprintContainer.x = 0;
                            }
                        }
                        fingerprintContainer.lastVerifyResult = currentResult;
                    }
                }
                
                // Behavior to smoothly return x to 0 when not animating (safety net)
                Behavior on x {
                    enabled: !fingerprintShakeAnim.running
                    NumberAnimation {
                        duration: 100
                        easing.type: Easing.OutQuad
                    }
                }
                
                // Error tooltip for unknown-error
                PopupToolTip {
                    extraVisibleCondition: root.context.fingerprintVerifyResult === "unknown-error"
                    alternativeVisibleCondition: extraVisibleCondition
                    anchorEdges: Edges.Bottom
                    text: Translation.tr("Fingerprint verification error. Please delete old fingerprint and enroll again.")
                }
            }
        }

        ToolbarTextField {
            id: passwordBox
            Layout.rightMargin: -Layout.leftMargin
            placeholderText: GlobalStates.screenUnlockFailed ? Translation.tr("Incorrect password") : Translation.tr("Enter password")

            // Style
            clip: true
            font.pixelSize: Appearance.font.pixelSize.small

            // Password
            enabled: !root.context.unlockInProgress
            echoMode: TextInput.Password
            inputMethodHints: Qt.ImhSensitiveData

            // Synchronizing (across monitors) and unlocking
            onTextChanged: root.context.currentText = this.text
            onAccepted: {
                root.context.tryUnlock(ctrlHeld);
            }
            Connections {
                target: root.context
                function onCurrentTextChanged() {
                    passwordBox.text = root.context.currentText;
                }
            }

            Keys.onPressed: event => {
                root.context.resetClearTimer();
            }
            
            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: passwordBox.width - 8
                    height: passwordBox.height
                    radius: height / 2
                }
            }

            // Shake when wrong password
            SequentialAnimation {
                id: wrongPasswordShakeAnim
                NumberAnimation { target: passwordBox; property: "Layout.leftMargin"; to: -30; duration: 50 }
                NumberAnimation { target: passwordBox; property: "Layout.leftMargin"; to: 30; duration: 50 }
                NumberAnimation { target: passwordBox; property: "Layout.leftMargin"; to: -15; duration: 40 }
                NumberAnimation { target: passwordBox; property: "Layout.leftMargin"; to: 15; duration: 40 }
                NumberAnimation { target: passwordBox; property: "Layout.leftMargin"; to: 0; duration: 30 }
            }
            Connections {
                target: GlobalStates
                function onScreenUnlockFailedChanged() {
                    if (GlobalStates.screenUnlockFailed) wrongPasswordShakeAnim.restart();
                }
            }

            // We're drawing dots manually
            property bool materialShapeChars: Config.options.lock.materialShapeChars
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

        ToolbarButton {
            id: confirmButton
            implicitWidth: height
            toggled: true
            enabled: !root.context.unlockInProgress
            colBackgroundToggled: Appearance.colors.colPrimary

            onClicked: root.context.tryUnlock()

            contentItem: MaterialSymbol {
                anchors.centerIn: parent
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                iconSize: 24
                text: {
                    if (root.context.targetAction === LockContext.ActionEnum.Unlock) {
                        return root.ctrlHeld ? "emoji_food_beverage" : "arrow_right_alt";
                    } else if (root.context.targetAction === LockContext.ActionEnum.Poweroff) {
                        return "power_settings_new";
                    } else if (root.context.targetAction === LockContext.ActionEnum.Reboot) {
                        return "restart_alt";
                    }
                }
                color: confirmButton.enabled ? Appearance.colors.colOnPrimary : Appearance.colors.colSubtext
            }
        }
    }

    // Left toolbar
    Toolbar {
        id: leftIsland
        anchors {
            right: mainIsland.left
            top: mainIsland.top
            bottom: mainIsland.bottom
            rightMargin: 10
        }
        scale: root.toolbarScale
        opacity: root.toolbarOpacity

        // Username
        IconAndTextPair {
            Layout.leftMargin: 8
            icon: "account_circle"
            text: SystemInfo.username
        }

        // Keyboard layout (Xkb)
        Loader {
            Layout.rightMargin: 8
            Layout.fillHeight: true

            active: true
            visible: active

            sourceComponent: Row {
                spacing: 8

                MaterialSymbol {
                    id: keyboardIcon
                    anchors.verticalCenter: parent.verticalCenter
                    fill: 1
                    text: "keyboard_alt"
                    iconSize: Appearance.font.pixelSize.huge
                    color: Appearance.colors.colOnSurfaceVariant
                }
                Loader {
                    anchors.verticalCenter: parent.verticalCenter
                    sourceComponent: StyledText {
                        text: HyprlandXkb.currentLayoutCode
                        color: Appearance.colors.colOnSurfaceVariant
                        animateChange: true
                    }
                }
            }
        }

        // Keyboard layout (Fcitx)
        Bar.SysTray {
            Layout.rightMargin: 10
            Layout.alignment: Qt.AlignVCenter
            showSeparator: false
            showOverflowMenu: false
            pinnedItems: SystemTray.items.values.filter(i => i.id == "Fcitx")
            visible: pinnedItems.length > 0
        }
    }

    // Right toolbar
    Toolbar {
        id: rightIsland
        anchors {
            left: mainIsland.right
            top: mainIsland.top
            bottom: mainIsland.bottom
            leftMargin: 10
        }

        scale: root.toolbarScale
        opacity: root.toolbarOpacity

        IconAndTextPair {
            visible: Battery.available
            icon: Battery.isCharging ? "bolt" : "battery_android_full"
            text: Math.round(Battery.percentage * 100)
            color: (Battery.isLow && !Battery.isCharging) ? Appearance.colors.colError : Appearance.colors.colOnSurfaceVariant
        }

        IconToolbarButton {
            id: sleepButton
            onClicked: Session.suspend()
            text: "dark_mode"
        }

        PasswordGuardedIconToolbarButton {
            id: powerButton
            text: "power_settings_new"
            targetAction: LockContext.ActionEnum.Poweroff
        }

        PasswordGuardedIconToolbarButton {
            id: rebootButton
            text: "restart_alt"
            targetAction: LockContext.ActionEnum.Reboot
        }
    }

    component PasswordGuardedIconToolbarButton: IconToolbarButton {
        id: guardedBtn
        required property var targetAction

        toggled: root.context.targetAction === guardedBtn.targetAction

        onClicked: {
            if (!root.requirePasswordToPower) {
                root.context.unlocked(guardedBtn.targetAction);
                return;
            }
            if (root.context.targetAction === guardedBtn.targetAction) {
                root.context.resetTargetAction();
            } else {
                root.context.targetAction = guardedBtn.targetAction;
                root.context.shouldReFocus();
            }
        }
    }

    component IconAndTextPair: Row {
        id: pair
        required property string icon
        required property string text
        property color color: Appearance.colors.colOnSurfaceVariant

        spacing: 4
        Layout.fillHeight: true
        Layout.leftMargin: 10
        Layout.rightMargin: 10
        

        MaterialSymbol {
            anchors.verticalCenter: parent.verticalCenter
            fill: 1
            text: pair.icon
            iconSize: Appearance.font.pixelSize.huge
            animateChange: true
            color: pair.color
        }
        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: pair.text
            color: pair.color
        }
    }
}

