
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions as CF

ContentPage {
    forceWidth: true

    property string confFile: CF.FileUtils.trimFileProtocol(Directories.config) + "/hypr/custom/animations.conf"
    property bool animations_enabled: true

    function loadSettings() {
        var content = FileUtils.read(confFile);
        if (!content) {
            console.log("Could not read animations config file.");
            return;
        }

        var lines = content.split('\n');
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim();
            if (line.startsWith("enabled")) {
                var value = line.split('=')[1].trim();
                animations_enabled = (value.toLowerCase() === 'yes' || value.toLowerCase() === 'true');
                break;
            }
        }
    }

    Component.onCompleted: {
        loadSettings();
    }

    function writeConfig() {
        var content = `
animations {
    enabled = ${animations_enabled ? 'yes' : 'no'}
}
`;
        FileUtils.write(confFile, content);
        Quickshell.execDetached(["hyprctl", "reload"]);
    }

    ContentSection {
        icon: "animation"
        title: "Animations"

        ConfigSwitch {
            text: "Enable animations"
            checked: animations_enabled
            onCheckedChanged: {
                animations_enabled = checked
                Quickshell.execDetached(["hyprctl", "keyword", "animations:enabled", checked ? "yes" : "no"]);
                writeConfig()
            }
        }
    }
}
