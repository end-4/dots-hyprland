pragma Singleton
pragma ComponentBehavior: Bound

import qs
import qs.modules.common
import qs.modules.common.functions as CF
import Quickshell
import Quickshell.Io
import QtQuick

/**
 * Service managing biometric fingerprint authentication and password management.
 */
Singleton {
    id: root

    // ================= Hardware / Device Status =================
    property bool available: false
    property string deviceName: Translation.tr("No device found")
    property string scanType: "press"
    property int numStages: 10
    property var enrolledFingers: []
    property bool loading: false
    property string error: ""

    // ================= Enrollment State =================
    property bool isEnrolling: false
    property string enrollingFinger: ""
    property int enrollStage: 0
    property int enrollTotalStages: 10
    property string enrollMessage: ""
    property string enrollError: ""
    property bool enrollCompleted: false

    // ================= Verification State =================
    property bool isVerifying: false
    property string verifyMessage: ""
    property bool verifyMatched: false
    property bool verifyFailed: false

    // ================= Password Change State =================
    property bool isChangingPassword: false
    property bool passwordChangeSuccess: false
    property string passwordChangeError: ""
    property string passwordChangeMessage: ""

    // List of standard supported fingers
    readonly property var supportedFingers: [
        { id: "right-thumb", name: Translation.tr("Right Thumb"), hand: "right" },
        { id: "right-index-finger", name: Translation.tr("Right Index"), hand: "right" },
        { id: "right-middle-finger", name: Translation.tr("Right Middle"), hand: "right" },
        { id: "right-ring-finger", name: Translation.tr("Right Ring"), hand: "right" },
        { id: "right-little-finger", name: Translation.tr("Right Little"), hand: "right" },
        { id: "left-thumb", name: Translation.tr("Left Thumb"), hand: "left" },
        { id: "left-index-finger", name: Translation.tr("Left Index"), hand: "left" },
        { id: "left-middle-finger", name: Translation.tr("Left Middle"), hand: "left" },
        { id: "left-ring-finger", name: Translation.tr("Left Ring"), hand: "left" },
        { id: "left-little-finger", name: Translation.tr("Left Little"), hand: "left" }
    ]

    function getFingerDisplayName(fingerId) {
        for (let i = 0; i < supportedFingers.length; i++) {
            if (supportedFingers[i].id === fingerId) {
                return supportedFingers[i].name;
            }
        }
        return fingerId ? fingerId.replace(/-/g, " ") : "";
    }

    function isFingerEnrolled(fingerId) {
        if (!enrolledFingers) return false;
        return enrolledFingers.indexOf(fingerId) !== -1;
    }

    // ================= REFRESH STATUS =================
    function refresh() {
        if (statusProc.running) return;
        root.loading = true;
        statusProc.running = true;
    }

    Process {
        id: statusProc
        command: ["python3", Directories.authManagerScriptPath, "status"]
        stdout: StdioCollector {
            id: statusCollector
            onStreamFinished: {
                root.loading = false;
                try {
                    const data = JSON.parse(statusCollector.text);
                    root.available = !!data.available;
                    if (data.available) {
                        root.deviceName = data.deviceName || Translation.tr("Fingerprint Sensor");
                        root.scanType = data.scanType || "press";
                        root.numStages = data.numStages || 10;
                        root.enrolledFingers = data.enrolledFingers || [];
                        root.error = "";
                    } else {
                        root.deviceName = Translation.tr("No device found");
                        root.enrolledFingers = [];
                        root.error = data.error || "";
                    }
                } catch (e) {
                    root.available = false;
                    root.error = e.toString();
                }
            }
        }
        onExited: (code, status) => {
            root.loading = false;
        }
    }

    // ================= ENROLLMENT =================
    function startEnrollment(fingerId) {
        if (root.isEnrolling) {
            cancelEnrollment();
        }
        root.enrollingFinger = fingerId || "right-index-finger";
        root.enrollStage = 0;
        root.enrollTotalStages = root.numStages;
        root.enrollMessage = Translation.tr("Initializing sensor...");
        root.enrollError = "";
        root.enrollCompleted = false;
        root.isEnrolling = true;

        enrollProc.command = ["python3", Directories.authManagerScriptPath, "enroll", "-f", root.enrollingFinger];
        enrollProc.running = true;
    }

    function cancelEnrollment() {
        if (enrollProc.running) {
            enrollProc.terminate();
        }
        root.isEnrolling = false;
        root.enrollingFinger = "";
        root.enrollStage = 0;
        root.enrollMessage = "";
        root.enrollError = "";
        root.refresh();
    }

    Process {
        id: enrollProc
        stdout: SplitParser {
            onRead: (line) => {
                const trimmed = line.trim();
                if (!trimmed) return;
                try {
                    const evt = JSON.parse(trimmed);
                    if (evt.event === "start") {
                        root.enrollTotalStages = evt.total || root.numStages;
                        root.enrollStage = 0;
                        root.enrollMessage = evt.message || Translation.tr("Place your finger on the sensor.");
                    } else if (evt.event === "stage") {
                        root.enrollStage = evt.stage || (root.enrollStage + 1);
                        root.enrollTotalStages = evt.total || root.numStages;
                        root.enrollMessage = evt.message || Translation.tr("Stage passed. Lift and place again.");
                    } else if (evt.event === "retry" || evt.event === "not_removed") {
                        root.enrollMessage = evt.message;
                    } else if (evt.event === "completed") {
                        root.enrollStage = root.enrollTotalStages;
                        root.enrollCompleted = true;
                        root.enrollMessage = evt.message || Translation.tr("Enrollment completed successfully!");
                        root.refresh();
                    } else if (evt.event === "error") {
                        root.enrollError = evt.message || Translation.tr("Enrollment failed.");
                    }
                } catch (e) {
                    console.warn("[SecurityService] JSON parse error on enroll line:", trimmed);
                }
            }
        }
        onExited: (code, status) => {
            if (!root.enrollCompleted && root.isEnrolling && !root.enrollError) {
                root.enrollError = Translation.tr("Enrollment process stopped.");
            }
            root.refresh();
        }
    }

    // ================= DELETION =================
    function deleteFingerprint(fingerId) {
        deleteProc.command = ["python3", Directories.authManagerScriptPath, "delete", "-f", fingerId];
        deleteProc.running = true;
    }

    function deleteAllFingerprints() {
        deleteProc.command = ["python3", Directories.authManagerScriptPath, "delete"];
        deleteProc.running = true;
    }

    Process {
        id: deleteProc
        onExited: (code, status) => {
            root.refresh();
        }
    }

    // ================= VERIFICATION =================
    function startVerify(fingerId) {
        if (root.isVerifying) {
            cancelVerify();
        }
        root.isVerifying = true;
        root.verifyMessage = Translation.tr("Place finger on sensor to verify...");
        root.verifyMatched = false;
        root.verifyFailed = false;

        const cmd = ["python3", Directories.authManagerScriptPath, "verify"];
        if (fingerId) {
            cmd.push("-f", fingerId);
        }
        verifyProc.command = cmd;
        verifyProc.running = true;
    }

    function cancelVerify() {
        if (verifyProc.running) {
            verifyProc.terminate();
        }
        root.isVerifying = false;
        root.verifyMessage = "";
        root.verifyMatched = false;
        root.verifyFailed = false;
    }

    Process {
        id: verifyProc
        stdout: SplitParser {
            onRead: (line) => {
                const trimmed = line.trim();
                if (!trimmed) return;
                try {
                    const evt = JSON.parse(trimmed);
                    if (evt.event === "matched") {
                        root.verifyMatched = true;
                        root.verifyFailed = false;
                        root.verifyMessage = evt.message;
                    } else if (evt.event === "no_match") {
                        root.verifyMatched = false;
                        root.verifyFailed = true;
                        root.verifyMessage = evt.message;
                    } else if (evt.event === "retry" || evt.event === "start") {
                        root.verifyMessage = evt.message;
                    } else if (evt.event === "error") {
                        root.verifyFailed = true;
                        root.verifyMessage = evt.message;
                    }
                } catch (e) {
                    console.warn("[SecurityService] JSON parse error on verify line:", trimmed);
                }
            }
        }
        onExited: (code, status) => {
            // Auto close verification state after 3 seconds
            autoCloseVerifyTimer.restart();
        }
    }

    Timer {
        id: autoCloseVerifyTimer
        interval: 3500
        repeat: false
        onTriggered: {
            root.isVerifying = false;
        }
    }

    // ================= PASSWORD CHANGE =================
    function changePassword(currentPassword, newPassword) {
        root.isChangingPassword = true;
        root.passwordChangeSuccess = false;
        root.passwordChangeError = "";
        root.passwordChangeMessage = "";

        const payload = JSON.stringify({
            currentPassword: currentPassword,
            newPassword: newPassword
        });

        changePasswordProc.command = [
            "bash", "-c",
            `python3 '${Directories.authManagerScriptPath}' change-password << 'EOF'\n${payload}\nEOF`
        ];
        changePasswordProc.running = true;
    }

    Process {
        id: changePasswordProc
        stdout: StdioCollector {
            id: passCollector
            onStreamFinished: {
                root.isChangingPassword = false;
                try {
                    const res = JSON.parse(passCollector.text);
                    root.passwordChangeSuccess = !!res.success;
                    if (res.success) {
                        root.passwordChangeMessage = res.message || Translation.tr("Password updated successfully.");
                        root.passwordChangeError = "";
                    } else {
                        root.passwordChangeError = res.error || Translation.tr("Failed to update password.");
                        root.passwordChangeMessage = "";
                    }
                } catch (e) {
                    root.passwordChangeSuccess = false;
                    root.passwordChangeError = e.toString();
                }
            }
        }
        onExited: (code, status) => {
            root.isChangingPassword = false;
        }
    }

    // Load hardware status on startup
    Component.onCompleted: {
        root.refresh();
    }
}
