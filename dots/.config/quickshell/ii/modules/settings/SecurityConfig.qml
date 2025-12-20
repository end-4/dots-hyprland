import QtQuick
import Quickshell
import Quickshell.Io
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

ContentPage {
    forceWidth: true

    property string currentUser: Qt.environment.value("USER") || ""
    property bool deviceAvailable: false

    // Process to check device and list fingerprints
    Process {
        id: listFingerprintsProc
        command: ["fprintd-list", currentUser]
        running: false
        property string output: ""
        property bool shouldVerifyAfter: false // Flag to trigger verification after refresh
        stdout: SplitParser {
            onRead: data => {
                listFingerprintsProc.output += data + "\n";
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                // Check if device is available
                deviceAvailable = listFingerprintsProc.output.includes("found") && 
                                   listFingerprintsProc.output.includes("Device");
                parseFingerprints(listFingerprintsProc.output);
                
                // If we just completed enrollment, start verification
                if (listFingerprintsProc.shouldVerifyAfter && enrollmentState === "completed") {
                    listFingerprintsProc.shouldVerifyAfter = false;
                    Qt.callLater(() => startVerification());
                }
            } else {
                deviceAvailable = false;
                fingerprintListModel.clear();
            }
            listFingerprintsProc.output = "";
        }
    }

    // Process to enroll fingerprint (automatic finger detection)
    Process {
        id: enrollFingerprintProc
        command: ["fprintd-enroll", currentUser]
        running: false
        property string output: ""
        property string errorOutput: ""
        property int stageCount: 0
        property int totalStages: 0
        stdout: SplitParser {
            onRead: data => {
                enrollFingerprintProc.output += data + "\n";
                const line = data.trim();
                const lineLower = line.toLowerCase();
                
                // Parse enrollment progress based on actual fprintd-enroll output
                if (lineLower.includes("enrolling")) {
                    enrollmentState = "scanning";
                    enrollmentError = "";
                    enrollmentTip = Translation.tr("Place your finger on the sensor");
                    showError = false;
                }
                
                // Track stages passed
                if (line.includes("Enroll result: enroll-stage-passed")) {
                    enrollmentState = "scanning";
                    enrollFingerprintProc.stageCount++;
                    enrollFingerprintProc.totalStages = Math.max(enrollFingerprintProc.totalStages, enrollFingerprintProc.stageCount);
                    enrollmentError = "";
                    enrollmentTip = Translation.tr("Keep placing your finger on the sensor");
                    showError = false;
                }
                
                // Handle retry (not a failure, just need to retry)
                if (line.includes("Enroll result: enroll-remove-and-retry")) {
                    enrollmentState = "scanning";
                    enrollmentError = "";
                    enrollmentTip = Translation.tr("Remove your finger and place it again");
                    showError = false;
                }
                
                // Success
                if (line.includes("Enroll result: enroll-completed")) {
                    enrollmentState = "completed";
                    enrollFingerprintProc.running = false;
                    enrollmentError = "";
                    enrollmentTip = Translation.tr("Enrollment completed! Verifying...");
                    showError = false;
                    listFingerprintsProc.shouldVerifyAfter = true;
                    Qt.callLater(() => refreshFingerprints());
                }
                
                // Failure
                if (line.includes("Enroll result: enroll-failed") || lineLower.includes("enrollment failed")) {
                    enrollmentState = "error";
                    enrollmentError = Translation.tr("Enrollment failed. Please try again.");
                    enrollmentTip = Translation.tr("Make sure your finger is clean and dry");
                    showError = true;
                    shakeAnimation.start();
                }
            }
        }
        stderr: SplitParser {
            onRead: data => {
                // Don't process stderr if already completed
                if (enrollmentState === "completed") {
                    return;
                }
                
                enrollFingerprintProc.errorOutput += data + "\n";
                const line = data.trim().toLowerCase();
                if (line.includes("enrolling")) {
                    enrollmentState = "scanning";
                    enrollmentError = "";
                    showError = false;
                } else if (line.includes("error") || line.includes("failed")) {
                    // Only set error if not already completed
                    if (enrollmentState !== "completed") {
                        enrollmentState = "error";
                        enrollmentError = data.trim() || Translation.tr("An error occurred during enrollment");
                        enrollmentTip = Translation.tr("Check your fingerprint device connection");
                        showError = true;
                        shakeAnimation.start();
                    }
                }
            }
        }
        onExited: (exitCode, exitStatus) => {
            // Don't override if already completed
            if (enrollmentState === "completed") {
                enrollFingerprintProc.output = "";
                enrollFingerprintProc.errorOutput = "";
                return;
            }
            
            if (exitCode === 0) {
                // Only set to completed if still scanning (in case we missed the completion message)
                if (enrollmentState === "scanning") {
                    enrollmentState = "completed";
                    enrollmentTip = Translation.tr("Enrollment completed! Verifying...");
                    showError = false;
                    listFingerprintsProc.shouldVerifyAfter = true;
                    Qt.callLater(() => refreshFingerprints());
                }
            } else {
                // Only set error if not already completed
                if (enrollmentState !== "completed") {
                    enrollmentState = "error";
                    enrollmentError = enrollFingerprintProc.errorOutput.trim() || enrollFingerprintProc.output.trim() || Translation.tr("Enrollment failed. Please try again.");
                    enrollmentTip = Translation.tr("Please try again");
                    showError = true;
                    shakeAnimation.start();
                }
            }
            enrollFingerprintProc.output = "";
            enrollFingerprintProc.errorOutput = "";
            enrollFingerprintProc.stageCount = 0;
            enrollFingerprintProc.totalStages = 0;
        }
    }

    // Process to verify fingerprint
    Process {
        id: verifyFingerprintProc
        command: ["fprintd-verify"]
        running: false
        property string output: ""
        property string errorOutput: ""
        property string enrolledFinger: "" // Store the finger that was just enrolled
        stdout: SplitParser {
            onRead: data => {
                verifyFingerprintProc.output += data + "\n";
                const line = data.trim();
                
                // Check for verify result
                if (line.includes("Verify result: verify-match")) {
                    // Good result - verification successful
                    enrollmentState = "verified";
                    enrollmentError = "";
                    enrollmentTip = Translation.tr("Fingerprint verified successfully!");
                    showError = false;
                    Qt.callLater(() => refreshFingerprints());
                } else if (line.includes("Verify result: verify-no-match")) {
                    // Good result - no match but enrollment is valid
                    enrollmentState = "verified";
                    enrollmentError = "";
                    enrollmentTip = Translation.tr("Fingerprint enrollment verified!");
                    showError = false;
                    Qt.callLater(() => refreshFingerprints());
                } else if (line.includes("Verify result: verify-unknown-error") || 
                          line.includes("Verify result: verify-retry-scan") ||
                          line.includes("Verify result: verify-retry-center") ||
                          line.includes("Verify result: verify-retry-remove")) {
                    // Bad result - need cleanup
                    enrollmentState = "verify-failed";
                    enrollmentError = Translation.tr("Verification failed. Cleaning up...");
                    enrollmentTip = Translation.tr("The fingerprint data may be corrupted");
                    showError = true;
                    Qt.callLater(() => cleanupFailedFingerprint());
                }
            }
        }
        stderr: SplitParser {
            onRead: data => {
                verifyFingerprintProc.errorOutput += data + "\n";
                const line = data.trim().toLowerCase();
                if (line.includes("error") || line.includes("failed")) {
                    if (enrollmentState !== "verified") {
                        enrollmentState = "verify-failed";
                        enrollmentError = Translation.tr("Verification error. Cleaning up...");
                        enrollmentTip = Translation.tr("The fingerprint data may be corrupted");
                        showError = true;
                        Qt.callLater(() => cleanupFailedFingerprint());
                    }
                }
            }
        }
        onExited: (exitCode, exitStatus) => {
            // If we haven't already handled the result, check the output
            if (enrollmentState === "verifying") {
                const output = verifyFingerprintProc.output + verifyFingerprintProc.errorOutput;
                if (output.includes("verify-match") || output.includes("verify-no-match")) {
                    enrollmentState = "verified";
                    enrollmentError = "";
                    enrollmentTip = Translation.tr("Fingerprint verified successfully!");
                    showError = false;
                    Qt.callLater(() => refreshFingerprints());
                } else if (output.includes("verify-unknown-error") || 
                          output.includes("error") || 
                          exitCode !== 0) {
                    enrollmentState = "verify-failed";
                    enrollmentError = Translation.tr("Verification failed. Cleaning up...");
                    enrollmentTip = Translation.tr("The fingerprint data may be corrupted");
                    showError = true;
                    Qt.callLater(() => cleanupFailedFingerprint());
                }
            }
            verifyFingerprintProc.output = "";
            verifyFingerprintProc.errorOutput = "";
        }
    }

    // Process to delete fingerprint
    Process {
        id: deleteFingerprintProc
        property string fingerprint: ""
        command: ["fprintd-delete", currentUser, "-f", fingerprint]
        running: false
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                refreshFingerprints();
            }
        }
    }

    // Process to cleanup failed fingerprint (delete + rm + restart)
    Process {
        id: cleanupProc
        property int step: 0 // 0=delete, 1=rm, 2=restart
        property string fingerprintToDelete: ""
        property string errorOutput: ""
        function getCommand() {
            if (step === 0) {
                return ["fprintd-delete", currentUser, "-f", fingerprintToDelete];
            } else if (step === 1) {
                return ["sudo", "rm", "-rf", "/var/lib/fprint/"];
            } else {
                return ["sudo", "systemctl", "restart", "fprintd"];
            }
        }
        command: getCommand()
        running: false
        stderr: SplitParser {
            onRead: data => {
                cleanupProc.errorOutput += data + "\n";
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                // Command failed - log error and try to continue or abort
                console.warn("Cleanup step", step, "failed with exit code", exitCode, ":", cleanupProc.errorOutput);
                if (step === 0) {
                    // If delete fails, still try to clean up the directory
                    cleanupProc.step = 1;
                    cleanupProc.errorOutput = "";
                    cleanupProc.command = cleanupProc.getCommand();
                    cleanupProc.running = true;
                } else if (step === 1) {
                    // If rm fails, still try to restart
                    cleanupProc.step = 2;
                    cleanupProc.errorOutput = "";
                    cleanupProc.command = cleanupProc.getCommand();
                    cleanupProc.running = true;
                } else {
                    // If restart fails, show error but mark as cleaned up
                    enrollmentState = "error";
                    enrollmentError = Translation.tr("Fingerprint cleanup completed, but service restart failed. You may need to restart fprintd manually.");
                    enrollmentTip = Translation.tr("Run: sudo systemctl restart fprintd");
                    showError = true;
                    shakeAnimation.start();
                    Qt.callLater(() => refreshFingerprints());
                    cleanupProc.step = 0;
                    cleanupProc.errorOutput = "";
                }
                return;
            }
            
            // Command succeeded, proceed to next step
            if (step === 0) {
                // Delete completed, move to rm step
                cleanupProc.step = 1;
                cleanupProc.errorOutput = "";
                cleanupProc.command = cleanupProc.getCommand();
                cleanupProc.running = true;
            } else if (step === 1) {
                // rm completed, move to restart step
                cleanupProc.step = 2;
                cleanupProc.errorOutput = "";
                cleanupProc.command = cleanupProc.getCommand();
                cleanupProc.running = true;
            } else if (step === 2) {
                // All cleanup done, reset enrollment state
                enrollmentState = "error";
                enrollmentError = Translation.tr("Fingerprint data was corrupted and has been cleaned up. Please enroll again.");
                enrollmentTip = Translation.tr("The fingerprint database has been reset");
                showError = true;
                shakeAnimation.start();
                Qt.callLater(() => refreshFingerprints());
                cleanupProc.step = 0;
                cleanupProc.errorOutput = "";
            }
        }
    }

    // Fingerprint list model
    ListModel {
        id: fingerprintListModel
    }

    // Enrollment state
    property string enrollmentState: "idle" // idle, scanning, completed, verifying, verified, verify-failed, error
    property string enrollmentError: ""
    property string enrollmentTip: ""
    property bool showError: false

    function parseFingerprints(output) {
        fingerprintListModel.clear();
        const lines = output.split('\n');
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim();
            // Match lines like: " - #0: right-index-finger"
            const match = line.match(/^-\s*#(\d+):\s*(.+)$/);
            if (match) {
                fingerprintListModel.append({
                    index: match[1],
                    finger: match[2],
                    displayName: formatFingerName(match[2])
                });
            }
        }
    }

    function formatFingerName(finger) {
        // Convert "right-index-finger" to "Right Index Finger"
        return finger.split('-').map(word => 
            word.charAt(0).toUpperCase() + word.slice(1)
        ).join(' ');
    }

    function refreshFingerprints() {
        listFingerprintsProc.running = false;
        listFingerprintsProc.running = true;
    }

    function startEnrollment() {
        if (!deviceAvailable) {
            enrollmentError = Translation.tr("No fingerprint device found. Please check your hardware.");
            enrollmentState = "error";
            enrollmentTip = Translation.tr("Connect a fingerprint reader device");
            showError = true;
            return;
        }
        enrollmentState = "scanning";
        enrollmentError = "";
        enrollmentTip = Translation.tr("Place your finger on the sensor");
        showError = false;
        enrollFingerprintProc.stageCount = 0;
        enrollFingerprintProc.totalStages = 0;
        enrollFingerprintProc.output = "";
        enrollFingerprintProc.errorOutput = "";
        enrollFingerprintProc.running = false;
        enrollFingerprintProc.running = true;
    }

    function cancelEnrollment() {
        if (enrollFingerprintProc.running) {
            enrollFingerprintProc.running = false;
        }
        enrollmentState = "idle";
        enrollmentError = "";
        enrollmentTip = "";
        showError = false;
    }

    function deleteFingerprint(finger) {
        deleteFingerprintProc.fingerprint = finger;
        deleteFingerprintProc.running = false;
        deleteFingerprintProc.running = true;
    }

    function getMostRecentFingerprint() {
        // Get the most recently enrolled fingerprint (highest index)
        if (fingerprintListModel.count === 0) {
            return "";
        }
        let maxIndex = -1;
        let mostRecentFinger = "";
        for (let i = 0; i < fingerprintListModel.count; i++) {
            const index = parseInt(fingerprintListModel.get(i).index);
            if (index > maxIndex) {
                maxIndex = index;
                mostRecentFinger = fingerprintListModel.get(i).finger;
            }
        }
        return mostRecentFinger;
    }

    function startVerification() {
        // Wait a bit for fingerprint list to refresh, then start verification
        Qt.callLater(() => {
            const finger = getMostRecentFingerprint();
            if (finger) {
                verifyFingerprintProc.enrolledFinger = finger;
                enrollmentState = "verifying";
                enrollmentTip = Translation.tr("Verifying fingerprint...");
                enrollmentError = "";
                showError = false;
                verifyFingerprintProc.output = "";
                verifyFingerprintProc.errorOutput = "";
                verifyFingerprintProc.running = false;
                verifyFingerprintProc.running = true;
            } else {
                // If we can't find the fingerprint, assume verification failed
                enrollmentState = "verify-failed";
                enrollmentError = Translation.tr("Could not find enrolled fingerprint. Cleaning up...");
                enrollmentTip = Translation.tr("The fingerprint data may be corrupted");
                showError = true;
                Qt.callLater(() => cleanupFailedFingerprint());
            }
        });
    }

    function cleanupFailedFingerprint() {
        const finger = getMostRecentFingerprint();
        if (finger) {
            cleanupProc.fingerprintToDelete = finger;
            cleanupProc.step = 0;
            cleanupProc.running = false;
            cleanupProc.running = true;
        } else {
            // No fingerprint to delete, just do rm and restart
            cleanupProc.step = 1;
            cleanupProc.running = false;
            cleanupProc.running = true;
        }
    }

    Component.onCompleted: {
        refreshFingerprints();
    }

    ContentSection {
        icon: "fingerprint"
        title: Translation.tr("Fingerprint")

        ContentSubsection {
            title: Translation.tr("Enrolled Fingerprints")
            tooltip: Translation.tr("Manage your enrolled fingerprints")

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Repeater {
                    model: fingerprintListModel
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 60
                        radius: Appearance.rounding.medium
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        border.width: 1
                        border.color: Appearance.colors.colLayer1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 12

                            MaterialSymbol {
                                text: "fingerprint"
                                iconSize: 28
                                color: Appearance.m3colors.m3primary
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                StyledText {
                                    text: model.displayName
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    font.weight: Font.Medium
                                    color: Appearance.colors.colOnLayer0
                                }

                                StyledText {
                                    text: `#${model.index}`
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    color: Appearance.colors.colSubtext
                                }
                            }

                            RippleButton {
                                implicitWidth: 40
                                implicitHeight: 40
                                buttonRadius: Appearance.rounding.full
                                colBackground: Appearance.m3colors.m3errorContainer
                                onClicked: {
                                    deleteFingerprint(model.finger);
                                }
                                contentItem: MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "delete"
                                    iconSize: 20
                                    color: Appearance.m3colors.m3onErrorContainer
                                }
                                StyledToolTip {
                                    text: Translation.tr("Delete fingerprint")
                                }
                            }
                        }
                    }
                }

                StyledText {
                    visible: fingerprintListModel.count === 0
                    Layout.fillWidth: true
                    Layout.topMargin: 8
                    text: Translation.tr("No fingerprints enrolled")
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colSubtext
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Enroll New Fingerprint")
            tooltip: Translation.tr("Add a new fingerprint for authentication")

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 16

                // Device status
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 50
                    radius: Appearance.rounding.medium
                    color: deviceAvailable ? Appearance.m3colors.m3primaryContainer : Appearance.m3colors.m3errorContainer
                    border.width: 1
                    border.color: Appearance.colors.colLayer1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12

                        MaterialSymbol {
                            text: deviceAvailable ? "check_circle" : "error"
                            iconSize: 24
                            color: deviceAvailable ? Appearance.m3colors.m3onPrimaryContainer : Appearance.m3colors.m3onErrorContainer
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: deviceAvailable ? Translation.tr("Fingerprint device ready") : Translation.tr("No fingerprint device found")
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: deviceAvailable ? Appearance.m3colors.m3onPrimaryContainer : Appearance.m3colors.m3onErrorContainer
                        }
                    }
                }

                // Enroll button
                RippleButton {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 56
                    enabled: deviceAvailable && (enrollmentState === "idle" || enrollmentState === "error" || enrollmentState === "verify-failed" || enrollmentState === "verified")
                    buttonRadius: Appearance.rounding.medium
                    colBackground: enabled ? Appearance.m3colors.m3primary : Appearance.colors.colLayer1
                    onClicked: {
                        if (enabled) {
                            startEnrollment();
                        }
                    }
                    contentItem: RowLayout {
                        anchors.centerIn: parent
                        spacing: 12

                        MaterialSymbol {
                            text: "fingerprint"
                            iconSize: 28
                            color: enabled ? Appearance.m3colors.m3onPrimary : Appearance.colors.colSubtext
                        }

                        StyledText {
                            text: Translation.tr("Enroll Fingerprint")
                            font.pixelSize: Appearance.font.pixelSize.larger
                            font.weight: Font.Medium
                            color: enabled ? Appearance.m3colors.m3onPrimary : Appearance.colors.colSubtext
                        }
                    }
                }

                // Enrollment status card
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: enrollmentState === "idle" ? 0 : 180
                    visible: enrollmentState !== "idle"
                    radius: Appearance.rounding.large
                    color: {
                        if (enrollmentState === "error" || enrollmentState === "verify-failed") return Appearance.m3colors.m3errorContainer;
                        if (enrollmentState === "completed" || enrollmentState === "verifying") return Appearance.m3colors.m3surfaceContainerHigh;
                        if (enrollmentState === "verified") return Appearance.m3colors.m3primaryContainer;
                        return Appearance.m3colors.m3surfaceContainerHigh;
                    }
                    border.width: 1
                    border.color: Appearance.colors.colLayer1

                    Behavior on Layout.preferredHeight {
                        NumberAnimation {
                            duration: 300
                            easing.type: Easing.OutCubic
                        }
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 24
                        spacing: 16

                        // Large fingerprint icon with shake animation
                        Item {
                            id: iconContainer
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: 64
                            Layout.preferredHeight: 64
                            property real shakeOffset: 0
                            
                            MaterialSymbol {
                                id: fingerprintIcon
                                anchors.centerIn: parent
                                x: parent.shakeOffset
                                text: {
                                    if (enrollmentState === "error" || enrollmentState === "verify-failed") return "error";
                                    if (enrollmentState === "verified") return "check_circle";
                                    if (enrollmentState === "verifying") return "fingerprint";
                                    if (enrollmentState === "completed") return "fingerprint";
                                    return "fingerprint";
                                }
                                iconSize: 64
                                color: {
                                    if (showError) return Appearance.m3colors.m3error;
                                    if (enrollmentState === "verified") return Appearance.m3colors.m3onPrimaryContainer;
                                    if (enrollmentState === "verifying" || enrollmentState === "completed") return Appearance.m3colors.m3primary;
                                    return Appearance.m3colors.m3primary;
                                }
                                
                                Behavior on color {
                                    ColorAnimation {
                                        duration: 200
                                    }
                                }
                                
                                // Pulsing animation during scanning and verifying
                                SequentialAnimation on opacity {
                                    running: (enrollmentState === "scanning" || enrollmentState === "verifying" || enrollmentState === "completed") && !showError
                                    loops: Animation.Infinite
                                    NumberAnimation {
                                        from: 0.5
                                        to: 1.0
                                        duration: 1000
                                        easing.type: Easing.InOutQuad
                                    }
                                    NumberAnimation {
                                        from: 1.0
                                        to: 0.5
                                        duration: 1000
                                        easing.type: Easing.InOutQuad
                                    }
                                }
                            }
                            
                            // Shake animation on error
                            SequentialAnimation {
                                id: shakeAnimation
                                running: false
                                NumberAnimation {
                                    target: iconContainer
                                    property: "shakeOffset"
                                    from: 0
                                    to: -20
                                    duration: 50
                                    easing.type: Easing.InOutQuad
                                }
                                NumberAnimation {
                                    target: iconContainer
                                    property: "shakeOffset"
                                    from: -20
                                    to: 20
                                    duration: 50
                                    easing.type: Easing.InOutQuad
                                }
                                NumberAnimation {
                                    target: iconContainer
                                    property: "shakeOffset"
                                    from: 20
                                    to: -15
                                    duration: 40
                                    easing.type: Easing.InOutQuad
                                }
                                NumberAnimation {
                                    target: iconContainer
                                    property: "shakeOffset"
                                    from: -15
                                    to: 15
                                    duration: 40
                                    easing.type: Easing.InOutQuad
                                }
                                NumberAnimation {
                                    target: iconContainer
                                    property: "shakeOffset"
                                    from: 15
                                    to: 0
                                    duration: 30
                                    easing.type: Easing.InOutQuad
                                }
                            }
                        }

                        // Status text
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            StyledText {
                                Layout.fillWidth: true
                                text: {
                                    if (enrollmentState === "error" || enrollmentState === "verify-failed") return Translation.tr("Enrollment Failed");
                                    if (enrollmentState === "verified") return Translation.tr("Fingerprint Verified");
                                    if (enrollmentState === "verifying") return Translation.tr("Verifying...");
                                    if (enrollmentState === "completed") return Translation.tr("Enrollment Complete");
                                    return Translation.tr("Place Your Finger");
                                }
                                font.pixelSize: Appearance.font.pixelSize.hugeass
                                font.weight: Font.Medium
                                horizontalAlignment: Text.AlignHCenter
                                color: {
                                    if (enrollmentState === "error" || enrollmentState === "verify-failed") return Appearance.m3colors.m3onErrorContainer;
                                    if (enrollmentState === "verified") return Appearance.m3colors.m3onPrimaryContainer;
                                    if (enrollmentState === "verifying" || enrollmentState === "completed") return Appearance.colors.colOnLayer0;
                                    return Appearance.colors.colOnLayer0;
                                }
                            }

                            // Tip/Instruction text
                            StyledText {
                                visible: enrollmentTip && enrollmentTip.length > 0
                                Layout.fillWidth: true
                                text: enrollmentTip
                                font.pixelSize: Appearance.font.pixelSize.normal
                                horizontalAlignment: Text.AlignHCenter
                                color: {
                                    if (showError) return Appearance.m3colors.m3onErrorContainer;
                                    if (enrollmentState === "verified") return Appearance.m3colors.m3onPrimaryContainer;
                                    if (enrollmentState === "verifying" || enrollmentState === "completed") return Appearance.colors.colSubtext;
                                    return Appearance.colors.colSubtext;
                                }
                                wrapMode: Text.WordWrap
                            }

                            // Error message
                            StyledText {
                                visible: (enrollmentState === "error" || enrollmentState === "verify-failed") && enrollmentError && enrollmentError.length > 0
                                Layout.fillWidth: true
                                text: enrollmentError
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: Font.Medium
                                horizontalAlignment: Text.AlignHCenter
                                color: Appearance.m3colors.m3onErrorContainer
                                wrapMode: Text.WordWrap
                            }
                        }

                        // Progress indicator with stage tracking
                        Rectangle {
                            visible: enrollmentState === "scanning" || enrollmentState === "verifying" || enrollmentState === "completed"
                            Layout.fillWidth: true
                            Layout.preferredHeight: 8
                            radius: 4
                            color: Appearance.colors.colLayer1

                            Rectangle {
                                anchors {
                                    left: parent.left
                                    top: parent.top
                                    bottom: parent.bottom
                                }
                                // Calculate progress based on stages (typically 15-20 stages)
                                width: {
                                    if (enrollFingerprintProc.totalStages > 0) {
                                        return parent.width * Math.min(enrollFingerprintProc.stageCount / Math.max(enrollFingerprintProc.totalStages, 20), 1.0);
                                    }
                                    // Fallback: estimate based on stage count
                                    return parent.width * Math.min(enrollFingerprintProc.stageCount / 20, 1.0);
                                }
                                radius: 4
                                color: showError ? Appearance.m3colors.m3error : Appearance.m3colors.m3primary

                                Behavior on width {
                                    NumberAnimation {
                                        duration: 300
                                        easing.type: Easing.OutCubic
                                    }
                                }
                                
                                Behavior on color {
                                    ColorAnimation {
                                        duration: 200
                                    }
                                }
                            }
                        }
                        
                        // Progress text
                        StyledText {
                            visible: (enrollmentState === "scanning" && enrollFingerprintProc.stageCount > 0) || enrollmentState === "verifying" || enrollmentState === "completed"
                            Layout.fillWidth: true
                            text: {
                                if (enrollmentState === "verifying" || enrollmentState === "completed") {
                                    return Translation.tr("Verifying fingerprint...");
                                }
                                return Translation.tr("Progress: %1 stages").arg(enrollFingerprintProc.stageCount);
                            }
                            font.pixelSize: Appearance.font.pixelSize.small
                            horizontalAlignment: Text.AlignHCenter
                            color: Appearance.colors.colSubtext
                        }

                        // Action button
                            RippleButton {
                                Layout.alignment: Qt.AlignHCenter
                                Layout.topMargin: 8
                                implicitHeight: 44
                                horizontalPadding: 32
                                buttonRadius: Appearance.rounding.medium
                                colBackground: {
                                    if (enrollmentState === "scanning" || enrollmentState === "verifying" || enrollmentState === "completed") return Appearance.m3colors.m3errorContainer;
                                    if (enrollmentState === "error" || enrollmentState === "verify-failed") return Appearance.m3colors.m3primaryContainer;
                                    return Appearance.m3colors.m3primaryContainer;
                                }
                                onClicked: {
                                    if (enrollmentState === "scanning" || enrollmentState === "verifying" || enrollmentState === "completed") {
                                        if (enrollmentState === "scanning") {
                                            cancelEnrollment();
                                        } else {
                                            // Cancel verification
                                            verifyFingerprintProc.running = false;
                                            enrollmentState = "idle";
                                            enrollmentError = "";
                                            enrollmentTip = "";
                                            showError = false;
                                        }
                                    } else {
                                        enrollmentState = "idle";
                                        enrollmentError = "";
                                        enrollmentTip = "";
                                        showError = false;
                                    }
                                }
                                contentItem: StyledText {
                                    anchors.centerIn: parent
                                    text: {
                                        if (enrollmentState === "scanning") return Translation.tr("Cancel");
                                        if (enrollmentState === "verifying" || enrollmentState === "completed") return Translation.tr("Cancel");
                                        if (enrollmentState === "error" || enrollmentState === "verify-failed") return Translation.tr("Try Again");
                                        return Translation.tr("Done");
                                    }
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    font.weight: Font.Medium
                                    color: {
                                        if (enrollmentState === "scanning" || enrollmentState === "verifying" || enrollmentState === "completed") return Appearance.m3colors.m3onErrorContainer;
                                        return Appearance.m3colors.m3onPrimaryContainer;
                                    }
                                }
                            }
                    }
                }
            }
        }
    }
}

