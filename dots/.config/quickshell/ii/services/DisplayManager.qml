
pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string scriptPath: Quickshell.shellPath(
        "scripts/displays/display_persistent.py"
    )

    property bool busy: false
    property bool confirming: false
    property int secondsRemaining: 0
    property string lastError: ""
    property string operation: ""
    property real deadline: 0

    signal applied()
    signal confirmed()
    signal reverted()
    signal failed(string message)
    signal positionsApplied()
    signal positionsFailed(string message)

    function execute(action, argument) {
        if (root.busy || (root.confirming && action === "positions"))
            return false;

        root.busy = true;
        root.lastError = "";
        root.operation = action;

        const args = ["python3", root.scriptPath, action];

        if (argument !== undefined)
            args.push(JSON.stringify(argument));

        worker.command = args;
        worker.running = true;

        return true;
    }

    function apply(monitors) {
        if (root.confirming || root.busy)
            return false;

        return execute("apply", monitors);
    }

    function applyPositions(positions) {
        if (root.confirming || root.busy)
            return false;

        return execute("positions", positions);
    }

    function keep() {
        if (!root.confirming)
            return false;

        return execute("confirm");
    }

    function rollback() {
        if (root.busy)
            return false;

        return execute("revert");
    }

    function checkStatus() {
        return execute("status");
    }

    function updateCountdown() {
        if (!root.confirming)
            return;

        root.secondsRemaining = Math.max(
            0,
            Math.ceil(root.deadline - Date.now() / 1000)
        );

        if (root.secondsRemaining === 0 && !root.busy)
            root.checkStatus();
    }

    function finish(action, data, exitCode) {
        root.busy = false;

        if (exitCode !== 0 || !data || data.ok !== true) {
            root.lastError = data?.error
                ?? "Display operation failed";

            if (action === "positions") {
                root.positionsFailed(root.lastError);
            } else {
                root.failed(root.lastError);

                if (action !== "status")
                    recoveryTimer.restart();
            }

            return;
        }

        if (action === "positions") {
            root.positionsApplied();

        } else if (action === "apply") {
            root.deadline = Number(data.deadline);
            root.confirming = true;
            root.updateCountdown();
            countdown.start();
            root.applied();

        } else if (action === "confirm") {
            root.confirming = false;
            root.secondsRemaining = 0;
            countdown.stop();
            root.confirmed();

        } else if (action === "revert") {
            root.confirming = false;
            root.secondsRemaining = 0;
            countdown.stop();
            root.reverted();

        } else if (action === "status") {
            root.confirming = Boolean(data.active);

            if (root.confirming) {
                root.deadline = Number(data.deadline);
                root.updateCountdown();
                countdown.start();
            } else {
                const wasConfirming = countdown.running;
                countdown.stop();
                root.secondsRemaining = 0;

                if (wasConfirming)
                    root.reverted();
            }
        }
    }

    Process {
        id: worker
        running: false

        stdout: StdioCollector {
            id: output
        }

        stderr: StdioCollector {
            id: errors
        }

        onExited: (exitCode, exitStatus) => {
            let data = null;

            try {
                data = JSON.parse(output.text.trim());
            } catch (error) {
                root.lastError = errors.text.trim()
                    || output.text.trim()
                    || String(error);
            }

            root.finish(root.operation, data, exitCode);
        }
    }

    Timer {
        id: countdown
        interval: 200
        repeat: true

        onTriggered: root.updateCountdown()
    }

    Timer {
        id: recoveryTimer
        interval: 500
        repeat: false

        onTriggered: {
            if (!root.busy)
                root.checkStatus();
        }
    }

    Component.onCompleted: checkStatus()
}
