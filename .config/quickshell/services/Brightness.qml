import Quickshell
import Quickshell.Io
pragma Singleton
pragma ComponentBehavior: Bound

Singleton {
    id: root

    property bool ready: false
    property real value
    property int increment: 0

    function refresh() {
        getBrightness.running = true;
    }

    onIncrementChanged: () => {
        if (increment > 0) {
            increaseBrightness.running = true;
            root.increment = 0;
        } else if (increment < 0) {
            decreaseBrightness.running = true;
            root.increment = 0;
        }
    }

    Process {
        id: getBrightness

        command: ["sh", "-c", "brightnessctl -m i | cut -d, -f4"]
        running: true
        onExited: {
            if (!ready) ready = true
        }

        stdout: SplitParser {
            onRead: (data) => {
                root.value = parseFloat(data.replace("%", "")) / 100;
                if (root.value < 0.01) {
                    preventPitchBlack.running = true;
                }
            }
        }

    }

    Process {
        id: decreaseBrightness

        command: ["brightnessctl", "set", "5%-"]
        running: false
        onExited: {
            running = false;
            getBrightness.running = true;
        }
    }

    Process {
        id: increaseBrightness

        command: ["brightnessctl", "set", "5%+"]
        running: false
        onExited: {
            running = false;
            getBrightness.running = true;
        }
    }

    Process {
        id: preventPitchBlack

        command: ["brightnessctl", "set", "1%+"]
        running: false
        onExited: {
            running = false;
            getBrightness.running = true;
        }
    }

}
