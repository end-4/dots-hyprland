pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Polkit

Singleton {
    id: root
    property alias agent: polkitAgent
    property alias active: polkitAgent.isActive
    property alias flow: polkitAgent.flow
    property bool interactionAvailable: false
    property bool fingerprintAvailable: false
    property bool isFingerprintCurrentlyOffered: false
    property string cleanMessage: {
        if (!root.flow) return "";
        return root.flow.message.endsWith(".")
            ? root.flow.message.slice(0, -1)
            : root.flow.message
    }
    property string cleanPrompt: {
        const inputPrompt = PolkitService.flow?.inputPrompt.trim() ?? "";
        const cleanedInputPrompt = inputPrompt.endsWith(":") ? inputPrompt.slice(0, -1) : inputPrompt;
        const usePasswordChars = !PolkitService.flow?.responseVisible ?? true
        return cleanedInputPrompt || (usePasswordChars ? Translation.tr("Password") : Translation.tr("Input"))
    }

    function cancel() {
        root.flow.cancelAuthenticationRequest()
    }

    function submit(string) {
        root.flow.submit(string)
        root.interactionAvailable = false
    }

    Connections {
        target: root.flow
        function onAuthenticationFailed() {
            root.interactionAvailable = true;
        }
        function onInputPromptChanged() {
            if (root.flow) {
                root.isFingerprintCurrentlyOffered = root.fingerprintAvailable && root.flow.inputPrompt.toLowerCase().includes("fingerprint");
            } else {
                root.isFingerprintCurrentlyOffered = false;
            }
        }
    }

    PolkitAgent {
        id: polkitAgent
        onAuthenticationRequestStarted: {
            root.interactionAvailable = true;
            root.isFingerprintCurrentlyOffered = root.fingerprintAvailable;
        }
    }

    Process {
        id: fingerprintCheckProc
        running: true
        command: ["bash", "-c", "fprintd-list $(whoami)"]
        stdout: StdioCollector {
            id: fingerprintOutputCollector
            onStreamFinished: {
                root.fingerprintAvailable = fingerprintOutputCollector.text.includes("Fingerprints for user");
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                console.warn("fprintd-list command exited with error:", exitCode, exitStatus);
                root.fingerprintAvailable = false;
            }
        }
    }
}
