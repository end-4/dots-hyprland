pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Polkit

Singleton {
    id: root
    property alias agent: polkitAgent
    property alias active: polkitAgent.isActive
    property alias flow: polkitAgent.flow
    property bool interactionAvailable: false

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
    }

    PolkitAgent {
        id: polkitAgent
        onAuthenticationRequestStarted: {
            root.interactionAvailable = true;
        }
    }
}
