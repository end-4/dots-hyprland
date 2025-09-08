import qs
import QtQuick
import Quickshell
import Quickshell.Services.Pam

Scope {
    id: root
    signal shouldReFocus()
    signal unlocked()
    signal failed()

    // These properties are in the context and not individual lock surfaces
    // so all surfaces can share the same state.
    property string currentText: ""
    property bool unlockInProgress: false
    property bool showFailure: false

    function resetClearTimer() {
        passwordClearTimer.restart();
    }

    Timer {
        id: passwordClearTimer
        interval: 10000
        onTriggered: {
            root.currentText = "";
        }
    }

    onCurrentTextChanged: {
        if (currentText.length > 0) {
            showFailure = false;
            GlobalStates.screenUnlockFailed = false;
        }
        GlobalStates.screenLockContainsCharacters = currentText.length > 0;
        passwordClearTimer.restart();
    }

    function tryUnlock() {
        root.unlockInProgress = true;
        pam.start();
    }

    PamContext {
        id: pam

        // pam_unix will ask for a response for the password prompt
        onPamMessage: {
            if (this.responseRequired) {
                this.respond(root.currentText);
            }
        }

        // pam_unix won't send any important messages so all we need is the completion status.
        onCompleted: result => {
            if (result == PamResult.Success) {
                root.unlocked();
            } else {
                root.showFailure = true;
                GlobalStates.screenUnlockFailed = true;
            }

            root.currentText = "";
            root.unlockInProgress = false;
        }
    }
}
