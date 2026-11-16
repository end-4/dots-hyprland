import QtQuick
import qs.services

QtObject {
    id: root

    property string name: ""
    property string type: ""
    property string device: ""
    property string state: ""
    property bool isActive: false
    property bool askingPassword: false

    function updateFromObject(data) {
        if (!data) return;
        
        name = data.name || "";
        type = data.type || "";
        device = data.device || "";
        state = data.state || "";
        isActive = data.isActive || false;
    }

    function toggle(): void {
        if (Network) {
            Network.toggleVpnConnection(name, isActive);
        }
    }
}