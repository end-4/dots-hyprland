import Quickshell
import Quickshell.Io
pragma Singleton
pragma ComponentBehavior: Bound

Singleton {
    id: root

    property string brightness
    property int value: 0

    function refresh() {
        getBrightness.running = true;
    }

    onValueChanged: () => {
        if (value > 0) {
            increaseBrightness.running = true;
            root.value = 0;
        } else if (value < 0) {
            decreaseBrightness.running = true;
            root.value = 0;
        }
        getBrightness.running = true;
    }

    Process {
        id: getBrightness

        command: ["sh", "-c", "brightnessctl -m i | cut -d, -f4"]
        running: true
        onExited: {
            running = false;
        }

        stdout: SplitParser {
            onRead: (data) => {
                root.brightness = data;
            }
        }

    }

    Process {
        id: decreaseBrightness

        command: ["brightnessctl", "set", "5%-"]
        running: false
        onExited: {
            running = false;
        }
    }

    Process {
        id: increaseBrightness

        command: ["brightnessctl", "set", "5%+"]
        running: false
        onExited: {
            running = false;
        }
    }

}
