pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs.modules.common.utils

Singleton {
    id: root

    property var keyContent: ({})
    property string keyProjectId: keyContent.project_id
    property bool keyError: false
    property bool keyReady: false
    property string token: ""
    property bool tokenError: false
    property bool tokenReady: false
    readonly property string projectId: keyProjectId

    readonly property bool loaded: keyReady && tokenReady

    readonly property string tokenForKeyScriptPath: Quickshell.shellPath("services/gCloud/token-from-key-venv.sh")

    function load() {
        // Dummy for init
    }

    function setKeyJson(str: string): bool {
        try {
            var keyData = JSON.parse(str)
            KeyringStorage.setNestedField(["googleCloud", "serviceAccountKey"], keyData);
            return true;
        } catch(e) {
            return false;
        }
    }

    function getToken() {
        if (root.keyError) {
            root.tokenError = true;
            root.tokenReady = true;
            return;
        }
        tokenProc.runSequence([(() => { // prep token fetcher
                    tokenProc.environment.SERVICE_KEY_CONTENT = JSON.stringify(root.keyContent);
                    tokenProc.command = [ //
                        "bash", "-c" //
                        , `${tokenForKeyScriptPath} "$SERVICE_KEY_CONTENT"`];
                }), [] // run token fetcher
            , (out => {
                    if (out.startsWith("Error")) {
                        root.tokenError = true;
                    } else {
                        root.tokenError = false;
                        root.token = out.trim();
                    }
                    root.tokenReady = true;
                })]);
    }

    function loadKeyIfPossible() {
        if (KeyringStorage.loaded) {
            root.keyContent = KeyringStorage.keyringData?.googleCloud?.serviceAccountKey;
            if (!root.keyContent?.project_id) {
                root.keyError = true;
            } else {
                root.keyError = false;
                root.keyProjectId = root.keyContent.project_id;
            }
            root.keyReady = true;
            root.getToken();
        } else {
            KeyringStorage.fetchKeyringData();
        }
    }

    Component.onCompleted: {
        loadKeyIfPossible();
    }

    Connections {
        target: KeyringStorage
        function onLoadedChanged() {
            root.loadKeyIfPossible();
        }
        function onDataChanged() {
            root.loadKeyIfPossible();
        }
    }

    MultiTurnProcess {
        id: tokenProc
    }
}
