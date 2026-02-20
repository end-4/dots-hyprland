import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common

QtObject {
    id: root
    
    property var vpnSizes: ({})
    property var vpnHidden: ({})
    
    // Path to vpn_state.json in the same directory as config.json
    property string filePath: Directories.shellConfigPath.substring(0, Directories.shellConfigPath.lastIndexOf("/")) + "/vpn_state.json"

    Component.onCompleted: {
        console.log("[VpnState] Component completed. Calculated filePath:", root.filePath);
    }

    property FileView _fileView: FileView {
        id: fileView
        path: root.filePath
        
        onLoaded: {
            console.log("[VpnState] Loaded file:", root.filePath);
            try {
                var content = fileView.text().trim();
                console.log("[VpnState] Content: " + content);
                if (content === "") {
                    root.vpnSizes = {};
                    root.vpnHidden = {};
                } else {
                    var data = JSON.parse(content);
                    // Check if it's the old format (just sizes) or new format (wrapper)
                    // If keys contain "Cefetra" directly, it's just sizes.
                    // Let's migrate if necessary.
                    // Assuming old format was just the sizes object.
                    // New format structure suggestion: { sizes: {...}, hidden: {...} }
                    // BUT for backward compatibility, I can try to sniff.
                    // Or I can keep sizes at root and handle hidden separately? 
                    // No, keeping it clean is better.
                    
                    if (data.sizes !== undefined) {
                        root.vpnSizes = data.sizes;
                        root.vpnHidden = data.hidden || {};
                    } else {
                        // Migration from old format (root keys are names)
                        var looksLikeSizes = true; // Primitive heuristic
                        // Assume old format if no 'sizes' key
                        root.vpnSizes = data;
                        root.vpnHidden = {};
                    }
                }
            } catch(e) {
                console.warn("[VpnState] Failed to parse vpn_state.json, resetting.", e);
                root.vpnSizes = {};
                root.vpnHidden = {};
            }
        }
        
        onLoadFailed: (error) => {
            console.warn("[VpnState] Load failed with error:", error);
            if (error === FileViewError.FileNotFound) {
                console.log("[VpnState] File not found, creating new one.");
                save();
            }
        }
    }
    
    function setSize(name, size) {
        var newSizes = Object.assign({}, root.vpnSizes);
        newSizes[name] = size;
        root.vpnSizes = newSizes;
        save();
    }

    function setHidden(name, hidden) {
        var newHidden = Object.assign({}, root.vpnHidden);
        if (hidden) {
            newHidden[name] = true;
        } else {
            delete newHidden[name]; // Cleanup
        }
        root.vpnHidden = newHidden;
        save();
    }
    
    function save() {
        var data = {
            sizes: root.vpnSizes,
            hidden: root.vpnHidden
        };
        console.log("[VpnState] Saving state:", JSON.stringify(data));
        if (!root.filePath || root.filePath === "") {
            console.error("[VpnState] filePath is empty! cannot save.");
            return;
        }
        _fileView.path = root.filePath;
        _fileView.setText(JSON.stringify(data, null, 4));
    }
}
