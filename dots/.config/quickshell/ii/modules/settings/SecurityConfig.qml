import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.functions as CF
import qs.modules.common.widgets

Item {
    id: root

    property bool showEnrollDialog: false
    property string selectedFingerToEnroll: "right-index-finger"

    property string currentPasswordInput: ""
    property string newPasswordInput: ""
    property string confirmPasswordInput: ""
    property bool showCurrentPassword: false
    property bool showNewPassword: false
    property bool showConfirmPassword: false

    property string deleteConfirmFinger: ""
    property bool showDeleteDialog: false

    function getPasswordStrength(pass) {
        if (!pass || pass.length === 0) return 0;
        let score = 0;
        if (pass.length >= 6) score++;
        if (pass.length >= 10) score++;
        if (/[A-Z]/.test(pass) && /[a-z]/.test(pass)) score++;
        if (/[0-9]/.test(pass) || /[^A-Za-z0-9]/.test(pass)) score++;
        return Math.min(4, Math.max(1, score));
    }

    readonly property int passStrength: getPasswordStrength(newPasswordInput)
    readonly property color passStrengthColor: {
        if (passStrength <= 1) return Appearance.colors.colError;
        if (passStrength === 2) return "#E5A04B";
        if (passStrength === 3) return "#E5C07B";
        return Appearance.colors.colPrimary;
    }
    readonly property string passStrengthLabel: {
        if (newPasswordInput.length === 0) return "";
        if (passStrength <= 1) return Translation.tr("Weak");
        if (passStrength === 2) return Translation.tr("Fair");
        if (passStrength === 3) return Translation.tr("Good");
        return Translation.tr("Strong");
    }

    Component.onCompleted: {
        SecurityService.refresh();
    }

    ContentPage {
        anchors.fill: parent
        forceWidth: false
        baseWidth: Math.min(840, root.width - 40)

        // ================= HERO BENTO CARD: USER & SECURITY STATUS =================
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: heroRow.implicitHeight + 28
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer1Base
            border.width: 1
            border.color: Appearance.colors.colLayer0Border

            RowLayout {
                id: heroRow
                anchors.fill: parent
                anchors.margins: 16
                spacing: 16

                // User Avatar with Ring
                Rectangle {
                    implicitWidth: 54
                    implicitHeight: 54
                    radius: Appearance.rounding.full
                    color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.82)
                    border.width: 2
                    border.color: Appearance.colors.colPrimary

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "person"
                        iconSize: 32
                        color: Appearance.colors.colPrimary
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    RowLayout {
                        spacing: 8
                        StyledText {
                            text: SystemInfo.username
                            font.pixelSize: Appearance.font.pixelSize.large + 2
                            font.weight: Font.DemiBold
                            color: Appearance.colors.colOnLayer0
                        }

                        Rectangle {
                            implicitWidth: adminChipText.implicitWidth + 14
                            implicitHeight: 22
                            radius: Appearance.rounding.full
                            color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.85)
                            border.width: 1
                            border.color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.6)

                            RowLayout {
                                id: adminChipText
                                anchors.centerIn: parent
                                spacing: 4

                                MaterialSymbol {
                                    text: "shield"
                                    iconSize: 12
                                    color: Appearance.colors.colPrimary
                                }

                                StyledText {
                                    text: Translation.tr("Local Administrator")
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    font.weight: Font.Medium
                                    color: Appearance.colors.colPrimary
                                }
                            }
                        }
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: Translation.tr("Biometric Authentication & System Security Hub")
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colOutlineVariant
                        elide: Text.ElideRight
                    }
                }

                // Minimalist Icon-Based Security Status Dock
                RowLayout {
                    spacing: 10
                    Layout.alignment: Qt.AlignVCenter

                    // 1. Biometrics / Fingerprint Status Icon
                    Rectangle {
                        implicitWidth: 42
                        implicitHeight: 42
                        radius: Appearance.rounding.full
                        color: SecurityService.enrolledFingers.length > 0
                            ? ColorUtils.transparentize(Appearance.colors.colPrimary, 0.85)
                            : Appearance.colors.colLayer2Base
                        border.width: 1
                        border.color: SecurityService.enrolledFingers.length > 0
                            ? ColorUtils.transparentize(Appearance.colors.colPrimary, 0.6)
                            : Appearance.colors.colLayer0Border

                        MouseArea {
                            id: fpIconMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.showEnrollDialog = true
                        }

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "fingerprint"
                            iconSize: 22
                            color: SecurityService.enrolledFingers.length > 0
                                ? Appearance.colors.colPrimary
                                : Appearance.colors.colOutlineVariant
                        }

                        // Status Badge Micro-Dot
                        Rectangle {
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.margins: 1
                            implicitWidth: 12
                            implicitHeight: 12
                            radius: Appearance.rounding.full
                            color: SecurityService.enrolledFingers.length > 0 ? Appearance.colors.colPrimary : Appearance.colors.colOutlineVariant
                            border.width: 2
                            border.color: Appearance.colors.colLayer1Base

                            MaterialSymbol {
                                anchors.centerIn: parent
                                visible: SecurityService.enrolledFingers.length > 0
                                text: "check"
                                iconSize: 8
                                color: Appearance.colors.colOnPrimary
                            }
                        }

                        StyledToolTip {
                            extraVisibleCondition: fpIconMouse.containsMouse
                            text: SecurityService.enrolledFingers.length > 0
                                ? Translation.tr("Fingerprint: %1 active • Click to enroll more").arg(SecurityService.enrolledFingers.length)
                                : Translation.tr("Fingerprint: None enrolled • Click to enroll")
                        }
                    }

                    // 2. Password Status Icon
                    Rectangle {
                        implicitWidth: 42
                        implicitHeight: 42
                        radius: Appearance.rounding.full
                        color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.85)
                        border.width: 1
                        border.color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.6)

                        MouseArea {
                            id: passIconMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: curPassInput.forceActiveFocus()
                        }

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "lock"
                            iconSize: 20
                            color: Appearance.colors.colPrimary
                        }

                        // Verified Status Micro-Dot
                        Rectangle {
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.margins: 1
                            implicitWidth: 12
                            implicitHeight: 12
                            radius: Appearance.rounding.full
                            color: Appearance.colors.colPrimary
                            border.width: 2
                            border.color: Appearance.colors.colLayer1Base

                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "check"
                                iconSize: 8
                                color: Appearance.colors.colOnPrimary
                            }
                        }

                        StyledToolTip {
                            extraVisibleCondition: passIconMouse.containsMouse
                            text: Translation.tr("Password: Protected • Click to change password")
                        }
                    }

                    // 3. Sensor Hardware Status Icon
                    Rectangle {
                        implicitWidth: 42
                        implicitHeight: 42
                        radius: Appearance.rounding.full
                        color: SecurityService.available
                            ? ColorUtils.transparentize(Appearance.colors.colPrimary, 0.85)
                            : ColorUtils.transparentize(Appearance.colors.colError, 0.85)
                        border.width: 1
                        border.color: SecurityService.available
                            ? ColorUtils.transparentize(Appearance.colors.colPrimary, 0.6)
                            : ColorUtils.transparentize(Appearance.colors.colError, 0.6)

                        MouseArea {
                            id: sensorIconMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: SecurityService.refresh()
                        }

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: SecurityService.available ? "sensors" : "sensors_off"
                            iconSize: 20
                            color: SecurityService.available ? Appearance.colors.colPrimary : Appearance.colors.colError
                        }

                        StyledToolTip {
                            extraVisibleCondition: sensorIconMouse.containsMouse
                            text: SecurityService.available
                                ? Translation.tr("Sensor: %1 (Ready)\nClick to refresh hardware").arg(SecurityService.deviceName)
                                : Translation.tr("Sensor: Offline or not detected\nClick to refresh hardware")
                        }
                    }
                }
            }
        }

        // ================= TWO-COLUMN BENTO GRID =================
        GridLayout {
            Layout.fillWidth: true
            columns: (root.width > 780) ? 2 : 1
            rowSpacing: 14
            columnSpacing: 14

            // ---------------- BENTO TILE 1: BIOMETRICS HUB ----------------
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                implicitHeight: bentoTile1Col.implicitHeight + 28
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer1Base
                border.width: 1
                border.color: Appearance.colors.colLayer0Border

                ColumnLayout {
                    id: bentoTile1Col
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    // Card Title
                    RowLayout {
                        Layout.fillWidth: true

                        MaterialSymbol {
                            text: "fingerprint"
                            iconSize: 22
                            color: Appearance.colors.colPrimary
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: Translation.tr("Fingerprint Sensor")
                            font.pixelSize: Appearance.font.pixelSize.normal + 1
                            font.weight: Font.DemiBold
                            color: Appearance.colors.colOnLayer0
                        }

                        RippleButton {
                            implicitWidth: 28
                            implicitHeight: 28
                            buttonRadius: Appearance.rounding.full
                            colBackground: Appearance.colors.colLayer2Base
                            onClicked: SecurityService.refresh()

                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                text: "refresh"
                                iconSize: 16
                                color: Appearance.colors.colOnLayer0
                            }
                            StyledToolTip { text: Translation.tr("Refresh sensor status") }
                        }
                    }

                    // Hardware Sensor Mini-Card
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: sensorInfoCol.implicitHeight + 16
                        radius: Appearance.rounding.small
                        color: Appearance.colors.colLayer2Base
                        border.width: 1
                        border.color: SecurityService.available
                            ? ColorUtils.transparentize(Appearance.colors.colPrimary, 0.75)
                            : Appearance.colors.colLayer0Border

                        ColumnLayout {
                            id: sensorInfoCol
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 4

                            RowLayout {
                                Layout.fillWidth: true

                                MaterialSymbol {
                                    text: SecurityService.available ? "sensors" : "sensors_off"
                                    iconSize: 18
                                    color: SecurityService.available ? Appearance.colors.colPrimary : Appearance.colors.colOutlineVariant
                                }

                                StyledText {
                                    Layout.fillWidth: true
                                    text: SecurityService.available ? SecurityService.deviceName : Translation.tr("No sensor detected")
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    font.weight: Font.Medium
                                    color: Appearance.colors.colOnLayer0
                                    elide: Text.ElideRight
                                }

                                Rectangle {
                                    implicitWidth: readyChipText.implicitWidth + 10
                                    implicitHeight: 18
                                    radius: Appearance.rounding.full
                                    color: SecurityService.available
                                        ? ColorUtils.transparentize(Appearance.colors.colPrimary, 0.8)
                                        : ColorUtils.transparentize(Appearance.colors.colError, 0.8)

                                    StyledText {
                                        id: readyChipText
                                        anchors.centerIn: parent
                                        text: SecurityService.available ? Translation.tr("Ready") : Translation.tr("Offline")
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                        font.weight: Font.DemiBold
                                        color: SecurityService.available ? Appearance.colors.colPrimary : Appearance.colors.colError
                                    }
                                }
                            }

                            StyledText {
                                visible: SecurityService.available
                                text: Translation.tr("%1 sensor • %2 stages • Driver: fprintd").arg(SecurityService.scanType).arg(SecurityService.numStages)
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colOutlineVariant
                            }
                        }
                    }

                    // Enrolled Fingerprints Deck
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        StyledText {
                            text: Translation.tr("Enrolled Fingerprints (%1)").arg(SecurityService.enrolledFingers.length)
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer0
                        }

                        // Empty State
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 44
                            radius: Appearance.rounding.small
                            color: Appearance.colors.colLayer2Base
                            visible: SecurityService.enrolledFingers.length === 0

                            StyledText {
                                anchors.centerIn: parent
                                text: Translation.tr("No fingerprints enrolled yet.")
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colOutlineVariant
                            }
                        }

                        // List of Enrolled Fingers Cards
                        Repeater {
                            model: SecurityService.enrolledFingers
                            delegate: Rectangle {
                                required property string modelData
                                required property int index

                                Layout.fillWidth: true
                                implicitHeight: 42
                                radius: Appearance.rounding.small
                                color: Appearance.colors.colLayer2Base
                                border.width: 1
                                border.color: Appearance.colors.colLayer0Border

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 6
                                    spacing: 8

                                    MaterialSymbol {
                                        text: "fingerprint"
                                        iconSize: 20
                                        color: Appearance.colors.colPrimary
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 0

                                        StyledText {
                                            text: SecurityService.getFingerDisplayName(modelData)
                                            font.pixelSize: Appearance.font.pixelSize.small
                                            font.weight: Font.Medium
                                            color: Appearance.colors.colOnLayer0
                                        }

                                        StyledText {
                                            text: modelData
                                            font.pixelSize: Appearance.font.pixelSize.smaller
                                            color: Appearance.colors.colOutlineVariant
                                        }
                                    }

                                    // Verify Button
                                    RippleButton {
                                        implicitWidth: 28
                                        implicitHeight: 28
                                        buttonRadius: Appearance.rounding.verysmall
                                        colBackground: Appearance.colors.colLayer1Base
                                        onClicked: SecurityService.startVerify(modelData)

                                        contentItem: MaterialSymbol {
                                            anchors.centerIn: parent
                                            text: "check_circle"
                                            iconSize: 16
                                            color: Appearance.colors.colOutlineVariant
                                        }
                                        StyledToolTip { text: Translation.tr("Test verify") }
                                    }

                                    // Delete Button
                                    RippleButton {
                                        implicitWidth: 28
                                        implicitHeight: 28
                                        buttonRadius: Appearance.rounding.verysmall
                                        colBackground: Appearance.colors.colLayer1Base
                                        onClicked: {
                                            root.deleteConfirmFinger = modelData;
                                            root.showDeleteDialog = true;
                                        }

                                        contentItem: MaterialSymbol {
                                            anchors.centerIn: parent
                                            text: "delete_outline"
                                            iconSize: 16
                                            color: Appearance.colors.colError
                                        }
                                        StyledToolTip { text: Translation.tr("Delete fingerprint") }
                                    }
                                }
                            }
                        }
                    }

                    // Live Verification Result Strip
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: verifyResLayout.implicitHeight + 10
                        visible: SecurityService.isVerifying
                        radius: Appearance.rounding.verysmall
                        color: SecurityService.verifyMatched
                            ? ColorUtils.transparentize(Appearance.colors.colPrimary, 0.85)
                            : (SecurityService.verifyFailed
                                ? ColorUtils.transparentize(Appearance.colors.colError, 0.85)
                                : Appearance.colors.colLayer2Base)
                        border.width: 1
                        border.color: SecurityService.verifyMatched
                            ? Appearance.colors.colPrimary
                            : (SecurityService.verifyFailed ? Appearance.colors.colError : Appearance.colors.colOutlineVariant)

                        RowLayout {
                            id: verifyResLayout
                            anchors.fill: parent
                            anchors.margins: 6
                            spacing: 6

                            MaterialSymbol {
                                text: SecurityService.verifyMatched ? "check_circle" : (SecurityService.verifyFailed ? "error" : "sensors")
                                iconSize: 16
                                color: SecurityService.verifyMatched
                                    ? Appearance.colors.colPrimary
                                    : (SecurityService.verifyFailed ? Appearance.colors.colError : Appearance.colors.colOnLayer0)
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: SecurityService.verifyMessage
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colOnLayer0
                                elide: Text.ElideRight
                            }

                            RippleButton {
                                implicitWidth: 20
                                implicitHeight: 20
                                buttonRadius: Appearance.rounding.verysmall
                                colBackground: "transparent"
                                onClicked: SecurityService.cancelVerify()

                                contentItem: MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "close"
                                    iconSize: 14
                                    color: Appearance.colors.colOutlineVariant
                                }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    // Action Buttons Row
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        visible: SecurityService.available

                        RippleButton {
                            Layout.fillWidth: true
                            implicitHeight: 38
                            buttonRadius: Appearance.rounding.small
                            colBackground: Appearance.colors.colPrimary
                            colBackgroundHover: Appearance.colors.colPrimaryHover
                            onClicked: root.showEnrollDialog = true

                            contentItem: RowLayout {
                                anchors.centerIn: parent
                                spacing: 6

                                MaterialSymbol {
                                    text: "add"
                                    iconSize: 18
                                    color: Appearance.colors.colOnPrimary
                                }

                                StyledText {
                                    text: Translation.tr("Enroll Fingerprint")
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    font.weight: Font.Medium
                                    color: Appearance.colors.colOnPrimary
                                }
                            }
                        }

                        RippleButton {
                            implicitHeight: 38
                            implicitWidth: 42
                            buttonRadius: Appearance.rounding.small
                            colBackground: Appearance.colors.colLayer2Base
                            colBackgroundHover: Appearance.colors.colLayer2Hover
                            visible: SecurityService.enrolledFingers.length > 0
                            onClicked: SecurityService.startVerify()

                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                text: "check"
                                iconSize: 18
                                color: Appearance.colors.colOnLayer0
                            }
                            StyledToolTip { text: Translation.tr("Test Scanner Recognition") }
                        }
                    }
                }
            }

            // ---------------- BENTO TILE 2: PASSWORD MANAGEMENT ----------------
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                implicitHeight: bentoTile2Col.implicitHeight + 28
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer1Base
                border.width: 1
                border.color: Appearance.colors.colLayer0Border

                ColumnLayout {
                    id: bentoTile2Col
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    // Card Title
                    RowLayout {
                        Layout.fillWidth: true

                        MaterialSymbol {
                            text: "lock"
                            iconSize: 22
                            color: Appearance.colors.colPrimary
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: Translation.tr("Change Password")
                            font.pixelSize: Appearance.font.pixelSize.normal + 1
                            font.weight: Font.DemiBold
                            color: Appearance.colors.colOnLayer0
                        }

                        MaterialSymbol {
                            text: "security"
                            iconSize: 18
                            color: Appearance.colors.colOutlineVariant

                            MouseArea {
                                id: secInfoMouse
                                anchors.fill: parent
                                hoverEnabled: true
                            }

                            StyledToolTip {
                                extraVisibleCondition: secInfoMouse.containsMouse
                                text: Translation.tr("Secured via system PAM authentication")
                            }
                        }
                    }

                    // Current Password
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3

                        StyledText {
                            text: Translation.tr("Current Password")
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer0
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 38
                            radius: Appearance.rounding.small
                            color: Appearance.colors.colLayer2Base
                            border.width: 1
                            border.color: curPassInput.activeFocus
                                ? Appearance.colors.colPrimary
                                : Appearance.colors.colLayer0Border

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 6
                                spacing: 4

                                TextField {
                                    id: curPassInput
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    verticalAlignment: Text.AlignVCenter
                                    echoMode: root.showCurrentPassword ? TextInput.Normal : TextInput.Password
                                    placeholderText: Translation.tr("Enter current password")
                                    placeholderTextColor: Appearance.colors.colOutlineVariant
                                    color: Appearance.colors.colOnLayer0
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    selectByMouse: true
                                    background: null
                                    text: root.currentPasswordInput
                                    onTextChanged: root.currentPasswordInput = text
                                }

                                RippleButton {
                                    implicitWidth: 26
                                    implicitHeight: 26
                                    buttonRadius: Appearance.rounding.verysmall
                                    colBackground: "transparent"
                                    onClicked: root.showCurrentPassword = !root.showCurrentPassword

                                    contentItem: MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: root.showCurrentPassword ? "visibility_off" : "visibility"
                                        iconSize: 16
                                        color: Appearance.colors.colOutlineVariant
                                    }
                                    StyledToolTip { text: root.showCurrentPassword ? Translation.tr("Hide password") : Translation.tr("Show password") }
                                }
                            }
                        }
                    }

                    // New Password
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3

                        StyledText {
                            text: Translation.tr("New Password")
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer0
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 38
                            radius: Appearance.rounding.small
                            color: Appearance.colors.colLayer2Base
                            border.width: 1
                            border.color: newPassInput.activeFocus
                                ? Appearance.colors.colPrimary
                                : Appearance.colors.colLayer0Border

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 6
                                spacing: 4

                                TextField {
                                    id: newPassInput
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    verticalAlignment: Text.AlignVCenter
                                    echoMode: root.showNewPassword ? TextInput.Normal : TextInput.Password
                                    placeholderText: Translation.tr("Enter new password")
                                    placeholderTextColor: Appearance.colors.colOutlineVariant
                                    color: Appearance.colors.colOnLayer0
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    selectByMouse: true
                                    background: null
                                    text: root.newPasswordInput
                                    onTextChanged: root.newPasswordInput = text
                                }

                                RippleButton {
                                    implicitWidth: 26
                                    implicitHeight: 26
                                    buttonRadius: Appearance.rounding.verysmall
                                    colBackground: "transparent"
                                    onClicked: root.showNewPassword = !root.showNewPassword

                                    contentItem: MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: root.showNewPassword ? "visibility_off" : "visibility"
                                        iconSize: 16
                                        color: Appearance.colors.colOutlineVariant
                                    }
                                    StyledToolTip { text: root.showNewPassword ? Translation.tr("Hide password") : Translation.tr("Show password") }
                                }
                            }
                        }

                        // Password Strength Meter
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            visible: root.newPasswordInput.length > 0

                            Repeater {
                                model: 4
                                delegate: Rectangle {
                                    required property int index
                                    Layout.fillWidth: true
                                    implicitHeight: 4
                                    radius: 2
                                    color: (index < root.passStrength) ? root.passStrengthColor : Appearance.colors.colLayer0Border
                                }
                            }

                            StyledText {
                                text: root.passStrengthLabel
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                font.weight: Font.Medium
                                color: root.passStrengthColor
                            }
                        }
                    }

                    // Confirm Password
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3

                        StyledText {
                            text: Translation.tr("Confirm New Password")
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer0
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 38
                            radius: Appearance.rounding.small
                            color: Appearance.colors.colLayer2Base
                            border.width: 1
                            border.color: confirmPassInput.activeFocus
                                ? Appearance.colors.colPrimary
                                : Appearance.colors.colLayer0Border

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 6
                                spacing: 4

                                TextField {
                                    id: confirmPassInput
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    verticalAlignment: Text.AlignVCenter
                                    echoMode: root.showConfirmPassword ? TextInput.Normal : TextInput.Password
                                    placeholderText: Translation.tr("Re-enter new password")
                                    placeholderTextColor: Appearance.colors.colOutlineVariant
                                    color: Appearance.colors.colOnLayer0
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    selectByMouse: true
                                    background: null
                                    text: root.confirmPasswordInput
                                    onTextChanged: root.confirmPasswordInput = text
                                }

                                RippleButton {
                                    implicitWidth: 26
                                    implicitHeight: 26
                                    buttonRadius: Appearance.rounding.verysmall
                                    colBackground: "transparent"
                                    onClicked: root.showConfirmPassword = !root.showConfirmPassword

                                    contentItem: MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: root.showConfirmPassword ? "visibility_off" : "visibility"
                                        iconSize: 16
                                        color: Appearance.colors.colOutlineVariant
                                    }
                                    StyledToolTip { text: root.showConfirmPassword ? Translation.tr("Hide password") : Translation.tr("Show password") }
                                }
                            }
                        }

                        // Match indicator
                        RowLayout {
                            spacing: 4
                            visible: root.confirmPasswordInput.length > 0

                            MaterialSymbol {
                                text: (root.newPasswordInput === root.confirmPasswordInput) ? "check" : "close"
                                iconSize: 13
                                color: (root.newPasswordInput === root.confirmPasswordInput)
                                    ? Appearance.colors.colPrimary
                                    : Appearance.colors.colError
                            }

                            StyledText {
                                text: (root.newPasswordInput === root.confirmPasswordInput)
                                    ? Translation.tr("Passwords match")
                                    : Translation.tr("Passwords do not match")
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: (root.newPasswordInput === root.confirmPasswordInput)
                                    ? Appearance.colors.colPrimary
                                    : Appearance.colors.colError
                            }
                        }
                    }

                    // Status / Error Banner
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: passMsgCol.implicitHeight + 10
                        visible: SecurityService.passwordChangeSuccess || SecurityService.passwordChangeError.length > 0
                        radius: Appearance.rounding.verysmall
                        color: SecurityService.passwordChangeSuccess
                            ? ColorUtils.transparentize(Appearance.colors.colPrimary, 0.85)
                            : ColorUtils.transparentize(Appearance.colors.colError, 0.85)
                        border.width: 1
                        border.color: SecurityService.passwordChangeSuccess
                            ? Appearance.colors.colPrimary
                            : Appearance.colors.colError

                        RowLayout {
                            id: passMsgCol
                            anchors.fill: parent
                            anchors.margins: 6
                            spacing: 6

                            MaterialSymbol {
                                text: SecurityService.passwordChangeSuccess ? "check_circle" : "error"
                                iconSize: 16
                                color: SecurityService.passwordChangeSuccess
                                    ? Appearance.colors.colPrimary
                                    : Appearance.colors.colError
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: SecurityService.passwordChangeSuccess
                                    ? SecurityService.passwordChangeMessage
                                    : SecurityService.passwordChangeError
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colOnLayer0
                                wrapMode: Text.WordWrap
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    // Submit Button
                    RippleButton {
                        Layout.fillWidth: true
                        implicitHeight: 38
                        buttonRadius: Appearance.rounding.small
                        colBackground: Appearance.colors.colPrimary
                        colBackgroundHover: Appearance.colors.colPrimaryHover
                        enabled: root.currentPasswordInput.length > 0 &&
                                 root.newPasswordInput.length > 0 &&
                                 root.newPasswordInput === root.confirmPasswordInput &&
                                 !SecurityService.isChangingPassword
                        opacity: enabled ? 1.0 : 0.4
                        onClicked: {
                            SecurityService.changePassword(root.currentPasswordInput, root.newPasswordInput);
                        }

                        contentItem: RowLayout {
                            anchors.centerIn: parent
                            spacing: 6

                            MaterialSymbol {
                                text: SecurityService.isChangingPassword ? "hourglass_empty" : "key"
                                iconSize: 18
                                color: Appearance.colors.colOnPrimary
                            }

                            StyledText {
                                text: SecurityService.isChangingPassword
                                    ? Translation.tr("Updating Password...")
                                    : Translation.tr("Update Password")
                                font.pixelSize: Appearance.font.pixelSize.small
                                font.weight: Font.Medium
                                color: Appearance.colors.colOnPrimary
                            }
                        }
                    }
                }
            }
        }

        // ================= BENTO TILE 3: SYSTEM INTEGRATION BANNER =================
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: pamRow.implicitHeight + 24
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer1Base
            border.width: 1
            border.color: Appearance.colors.colLayer0Border

            RowLayout {
                id: pamRow
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 14
                spacing: 12

                Rectangle {
                    implicitWidth: 38
                    implicitHeight: 38
                    radius: Appearance.rounding.full
                    color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.85)

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "verified_user"
                        iconSize: 20
                        color: Appearance.colors.colPrimary
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    spacing: 2

                    StyledText {
                        Layout.fillWidth: true
                        text: Translation.tr("Biometric Lock Screen & SDDM Integration")
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer0
                        elide: Text.ElideRight
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: Translation.tr("Quickshell Lock Screen and SDDM are configured to unlock automatically using enrolled fingerprints via pam_fprintd.so.")
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colOutlineVariant
                        wrapMode: Text.WordWrap
                    }
                }

                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    implicitWidth: pamBadgeRow.implicitWidth + 18
                    implicitHeight: 26
                    radius: Appearance.rounding.full
                    color: SecurityService.enrolledFingers.length > 0
                        ? ColorUtils.transparentize(Appearance.colors.colPrimary, 0.8)
                        : Appearance.colors.colLayer2Base
                    border.width: 1
                    border.color: SecurityService.enrolledFingers.length > 0
                        ? ColorUtils.transparentize(Appearance.colors.colPrimary, 0.6)
                        : Appearance.colors.colLayer0Border

                    MouseArea {
                        id: pamBadgeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                    }

                    RowLayout {
                        id: pamBadgeRow
                        anchors.centerIn: parent
                        spacing: 5

                        MaterialSymbol {
                            text: SecurityService.enrolledFingers.length > 0 ? "verified" : "lock"
                            iconSize: 13
                            color: SecurityService.enrolledFingers.length > 0
                                ? Appearance.colors.colPrimary
                                : Appearance.colors.colOutlineVariant
                        }

                        StyledText {
                            text: SecurityService.enrolledFingers.length > 0
                                ? Translation.tr("Biometrics Active")
                                : Translation.tr("Password Only")
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            font.weight: Font.Medium
                            color: SecurityService.enrolledFingers.length > 0
                                ? Appearance.colors.colPrimary
                                : Appearance.colors.colOutlineVariant
                        }
                    }

                    StyledToolTip {
                        extraVisibleCondition: pamBadgeMouse.containsMouse
                        text: SecurityService.enrolledFingers.length > 0
                            ? Translation.tr("Biometrics Active: PAM fprintd module is enabled for Lock Screen and SDDM login.")
                            : Translation.tr("Password Only: No fingerprints enrolled. PAM will fallback to password authentication.")
                    }
                }
            }
        }
    }

    // ================= SOLID OPAQUE ENROLLMENT MODAL DIALOG =================
    Rectangle {
        id: enrollModalOverlay
        anchors.fill: parent
        visible: root.showEnrollDialog
        color: "#CC000000" // 80% solid dark overlay
        z: 99

        MouseArea {
            anchors.fill: parent
            onClicked: {} // Block underlying clicks
        }

        // 100% Solid Opaque Bento Modal Card
        Rectangle {
            anchors.centerIn: parent
            width: Math.min(520, parent.width - 32)
            implicitHeight: modalMainCol.implicitHeight + 36
            radius: Appearance.rounding.normal
            color: Appearance.m3colors.m3surfaceContainerHigh // 100% Solid Opaque
            border.width: 1
            border.color: Appearance.colors.colLayer0Border

            ColumnLayout {
                id: modalMainCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 20
                spacing: 16

                // Modal Header
                RowLayout {
                    Layout.fillWidth: true

                    Rectangle {
                        implicitWidth: 32
                        implicitHeight: 32
                        radius: Appearance.rounding.full
                        color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.8)

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "fingerprint"
                            iconSize: 18
                            color: Appearance.colors.colPrimary
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        StyledText {
                            text: SecurityService.isEnrolling
                                ? Translation.tr("Enrolling %1").arg(SecurityService.getFingerDisplayName(SecurityService.enrollingFinger))
                                : Translation.tr("Select Finger to Enroll")
                            font.pixelSize: Appearance.font.pixelSize.normal + 1
                            font.weight: Font.DemiBold
                            color: Appearance.colors.colOnLayer0
                        }

                        StyledText {
                            text: SecurityService.isEnrolling
                                ? Translation.tr("Follow the on-screen steps to register your fingerprint.")
                                : Translation.tr("Choose a finger to associate with biometric login.")
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colOutlineVariant
                        }
                    }

                    RippleButton {
                        implicitWidth: 30
                        implicitHeight: 30
                        buttonRadius: Appearance.rounding.full
                        colBackground: Appearance.m3colors.m3surfaceContainer
                        onClicked: {
                            if (SecurityService.isEnrolling) {
                                SecurityService.cancelEnrollment();
                            }
                            root.showEnrollDialog = false;
                        }

                        contentItem: MaterialSymbol {
                            anchors.centerIn: parent
                            text: "close"
                            iconSize: 16
                            color: Appearance.colors.colOnLayer0
                        }
                    }
                }

                // ================= VIEW 1: FINGER SELECTION =================
                ColumnLayout {
                    Layout.fillWidth: true
                    visible: !SecurityService.isEnrolling
                    spacing: 12

                    // Two Column Hand Layout (Left Hand / Right Hand)
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        // Left Hand Column
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            RowLayout {
                                spacing: 4
                                MaterialSymbol {
                                    text: "back_hand"
                                    iconSize: 14
                                    color: Appearance.colors.colOutlineVariant
                                }
                                StyledText {
                                    text: Translation.tr("Left Hand")
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    font.weight: Font.DemiBold
                                    color: Appearance.colors.colOutlineVariant
                                }
                            }

                            Repeater {
                                model: SecurityService.supportedFingers.filter(f => f.hand === "left")
                                delegate: Rectangle {
                                    required property var modelData
                                    required property int index
                                    readonly property bool isEnrolled: SecurityService.isFingerEnrolled(modelData.id)
                                    readonly property bool isSelected: root.selectedFingerToEnroll === modelData.id

                                    Layout.fillWidth: true
                                    implicitHeight: 38
                                    radius: Appearance.rounding.small
                                    color: isSelected
                                        ? Appearance.colors.colPrimary
                                        : (leftFingerMouse.containsMouse ? Appearance.m3colors.m3surfaceContainerHighest : Appearance.m3colors.m3surfaceContainer)
                                    border.width: 1
                                    border.color: isSelected
                                        ? Appearance.colors.colPrimary
                                        : (leftFingerMouse.containsMouse ? ColorUtils.transparentize(Appearance.colors.colPrimary, 0.5) : Appearance.colors.colLayer0Border)

                                    MouseArea {
                                        id: leftFingerMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.selectedFingerToEnroll = modelData.id;
                                        }
                                    }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        spacing: 8

                                        MaterialSymbol {
                                            text: isEnrolled ? "check_circle" : "fingerprint"
                                            iconSize: 16
                                            color: isSelected ? Appearance.colors.colOnPrimary : (isEnrolled ? Appearance.colors.colPrimary : Appearance.colors.colOutlineVariant)
                                        }

                                        StyledText {
                                            Layout.fillWidth: true
                                            text: modelData.name
                                            font.pixelSize: Appearance.font.pixelSize.smaller
                                            font.weight: isSelected ? Font.Medium : Font.Normal
                                            color: isSelected ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer0
                                            elide: Text.ElideRight
                                        }

                                        Rectangle {
                                            visible: isEnrolled
                                            implicitWidth: 18
                                            implicitHeight: 18
                                            radius: Appearance.rounding.full
                                            color: isSelected ? ColorUtils.transparentize(Appearance.colors.colOnPrimary, 0.75) : ColorUtils.transparentize(Appearance.colors.colPrimary, 0.8)

                                            MaterialSymbol {
                                                anchors.centerIn: parent
                                                text: "check"
                                                iconSize: 12
                                                color: isSelected ? Appearance.colors.colOnPrimary : Appearance.colors.colPrimary
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Right Hand Column
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            RowLayout {
                                spacing: 4
                                MaterialSymbol {
                                    text: "front_hand"
                                    iconSize: 14
                                    color: Appearance.colors.colOutlineVariant
                                }
                                StyledText {
                                    text: Translation.tr("Right Hand")
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    font.weight: Font.DemiBold
                                    color: Appearance.colors.colOutlineVariant
                                }
                            }

                            Repeater {
                                model: SecurityService.supportedFingers.filter(f => f.hand === "right")
                                delegate: Rectangle {
                                    required property var modelData
                                    required property int index
                                    readonly property bool isEnrolled: SecurityService.isFingerEnrolled(modelData.id)
                                    readonly property bool isSelected: root.selectedFingerToEnroll === modelData.id

                                    Layout.fillWidth: true
                                    implicitHeight: 38
                                    radius: Appearance.rounding.small
                                    color: isSelected
                                        ? Appearance.colors.colPrimary
                                        : (rightFingerMouse.containsMouse ? Appearance.m3colors.m3surfaceContainerHighest : Appearance.m3colors.m3surfaceContainer)
                                    border.width: 1
                                    border.color: isSelected
                                        ? Appearance.colors.colPrimary
                                        : (rightFingerMouse.containsMouse ? ColorUtils.transparentize(Appearance.colors.colPrimary, 0.5) : Appearance.colors.colLayer0Border)

                                    MouseArea {
                                        id: rightFingerMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.selectedFingerToEnroll = modelData.id;
                                        }
                                    }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        spacing: 8

                                        MaterialSymbol {
                                            text: isEnrolled ? "check_circle" : "fingerprint"
                                            iconSize: 16
                                            color: isSelected ? Appearance.colors.colOnPrimary : (isEnrolled ? Appearance.colors.colPrimary : Appearance.colors.colOutlineVariant)
                                        }

                                        StyledText {
                                            Layout.fillWidth: true
                                            text: modelData.name
                                            font.pixelSize: Appearance.font.pixelSize.smaller
                                            font.weight: isSelected ? Font.Medium : Font.Normal
                                            color: isSelected ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer0
                                            elide: Text.ElideRight
                                        }

                                        Rectangle {
                                            visible: isEnrolled
                                            implicitWidth: 18
                                            implicitHeight: 18
                                            radius: Appearance.rounding.full
                                            color: isSelected ? ColorUtils.transparentize(Appearance.colors.colOnPrimary, 0.75) : ColorUtils.transparentize(Appearance.colors.colPrimary, 0.8)

                                            MaterialSymbol {
                                                anchors.centerIn: parent
                                                text: "check"
                                                iconSize: 12
                                                color: isSelected ? Appearance.colors.colOnPrimary : Appearance.colors.colPrimary
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Start Enrollment Action
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 4
                        spacing: 8

                        Item { Layout.fillWidth: true }

                        RippleButton {
                            implicitHeight: 38
                            implicitWidth: startEnrollBtnLayout.implicitWidth + 24
                            buttonRadius: Appearance.rounding.small
                            colBackground: Appearance.colors.colPrimary
                            colBackgroundHover: Appearance.colors.colPrimaryHover
                            onClicked: {
                                SecurityService.startEnrollment(root.selectedFingerToEnroll);
                            }

                            contentItem: RowLayout {
                                id: startEnrollBtnLayout
                                anchors.centerIn: parent
                                spacing: 6

                                MaterialSymbol {
                                    text: "play_arrow"
                                    iconSize: 18
                                    color: Appearance.colors.colOnPrimary
                                }

                                StyledText {
                                    text: Translation.tr("Start Enrollment")
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    font.weight: Font.Medium
                                    color: Appearance.colors.colOnPrimary
                                }
                            }
                        }
                    }
                }

                // ================= VIEW 2: INTERACTIVE LIVE ENROLLMENT =================
                ColumnLayout {
                    Layout.fillWidth: true
                    visible: SecurityService.isEnrolling
                    spacing: 16

                    // Central Sensor Animation & Circular Progress
                    Item {
                        Layout.alignment: Qt.AlignHCenter
                        implicitWidth: 130
                        implicitHeight: 130

                        CircularProgress {
                            anchors.fill: parent
                            lineWidth: 6
                            implicitSize: 130
                            value: SecurityService.enrollTotalStages > 0
                                ? (SecurityService.enrollStage / SecurityService.enrollTotalStages)
                                : 0
                            colPrimary: Appearance.colors.colPrimary
                            colSecondary: Appearance.m3colors.m3surfaceContainer
                        }

                        Rectangle {
                            anchors.centerIn: parent
                            implicitWidth: 104
                            implicitHeight: 104
                            radius: Appearance.rounding.full
                            color: SecurityService.enrollCompleted
                                ? ColorUtils.transparentize(Appearance.colors.colPrimary, 0.8)
                                : Appearance.m3colors.m3surfaceContainer

                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: SecurityService.enrollCompleted ? "check_circle" : "fingerprint"
                                iconSize: 52
                                color: SecurityService.enrollCompleted
                                    ? Appearance.colors.colPrimary
                                    : (SecurityService.enrollStage > 0 ? Appearance.colors.colPrimary : Appearance.colors.colOutlineVariant)

                                Behavior on color {
                                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                                }
                            }
                        }
                    }

                    // Stage Counter Badge
                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        implicitWidth: stageBadgeText.implicitWidth + 20
                        implicitHeight: 28
                        radius: Appearance.rounding.full
                        color: Appearance.m3colors.m3surfaceContainer

                        StyledText {
                            id: stageBadgeText
                            anchors.centerIn: parent
                            text: SecurityService.enrollCompleted
                                ? Translation.tr("Enrollment Complete!")
                                : Translation.tr("Stage %1 of %2").arg(SecurityService.enrollStage).arg(SecurityService.enrollTotalStages)
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: Font.DemiBold
                            color: SecurityService.enrollCompleted ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer0
                        }
                    }

                    // Prompt message
                    StyledText {
                        Layout.fillWidth: true
                        Layout.leftMargin: 16
                        Layout.rightMargin: 16
                        horizontalAlignment: Text.AlignHCenter
                        text: SecurityService.enrollMessage
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer0
                        wrapMode: Text.WordWrap
                    }

                    // Error text if any
                    StyledText {
                        Layout.fillWidth: true
                        visible: SecurityService.enrollError.length > 0
                        horizontalAlignment: Text.AlignHCenter
                        text: SecurityService.enrollError
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colError
                        wrapMode: Text.WordWrap
                    }

                    // Modal Action Buttons
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 4

                        Item { Layout.fillWidth: true }

                        RippleButton {
                            implicitHeight: 38
                            implicitWidth: 96
                            buttonRadius: Appearance.rounding.small
                            colBackground: SecurityService.enrollCompleted ? Appearance.colors.colPrimary : Appearance.m3colors.m3surfaceContainer
                            colBackgroundHover: SecurityService.enrollCompleted ? Appearance.colors.colPrimaryHover : Appearance.colors.colLayer2Hover
                            onClicked: {
                                if (SecurityService.isEnrolling) {
                                    SecurityService.cancelEnrollment();
                                }
                                root.showEnrollDialog = false;
                            }

                            contentItem: StyledText {
                                anchors.centerIn: parent
                                text: SecurityService.enrollCompleted ? Translation.tr("Done") : Translation.tr("Cancel")
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: Font.Medium
                                color: SecurityService.enrollCompleted ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer0
                            }
                        }
                    }
                }
            }
        }
    }

    // ================= SOLID OPAQUE DELETE CONFIRMATION DIALOG =================
    Rectangle {
        id: deleteModalOverlay
        anchors.fill: parent
        visible: root.showDeleteDialog
        color: "#CC000000"
        z: 99

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        Rectangle {
            anchors.centerIn: parent
            width: Math.min(400, parent.width - 32)
            implicitHeight: deleteModalCol.implicitHeight + 36
            radius: Appearance.rounding.normal
            color: Appearance.m3colors.m3surfaceContainerHigh // 100% Solid Opaque
            border.width: 1
            border.color: Appearance.colors.colLayer0Border

            ColumnLayout {
                id: deleteModalCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 18
                spacing: 12

                RowLayout {
                    spacing: 8
                    MaterialSymbol {
                        text: "warning"
                        iconSize: 22
                        color: Appearance.colors.colError
                    }
                    StyledText {
                        text: Translation.tr("Delete Fingerprint?")
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colOnLayer0
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    text: Translation.tr("Are you sure you want to remove \"%1\"? You will no longer be able to unlock your system with this finger.").arg(SecurityService.getFingerDisplayName(root.deleteConfirmFinger))
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOutlineVariant
                    wrapMode: Text.WordWrap
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 6
                    spacing: 8

                    Item { Layout.fillWidth: true }

                    RippleButton {
                        implicitHeight: 34
                        implicitWidth: 80
                        buttonRadius: Appearance.rounding.small
                        colBackground: Appearance.m3colors.m3surfaceContainer
                        onClicked: root.showDeleteDialog = false

                        contentItem: StyledText {
                            anchors.centerIn: parent
                            text: Translation.tr("Cancel")
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnLayer0
                        }
                    }

                    RippleButton {
                        implicitHeight: 34
                        implicitWidth: 80
                        buttonRadius: Appearance.rounding.small
                        colBackground: Appearance.colors.colError
                        colBackgroundHover: Appearance.colors.colError
                        onClicked: {
                            SecurityService.deleteFingerprint(root.deleteConfirmFinger);
                            root.showDeleteDialog = false;
                        }

                        contentItem: StyledText {
                            anchors.centerIn: parent
                            text: Translation.tr("Delete")
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnError
                        }
                    }
                }
            }
        }
    }
}
