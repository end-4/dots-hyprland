import qs
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services


AndroidQuickToggleButton {
    id: root

    property int timeoutInterval: 5
    property int timeoutDuration: Config.options.resources.musicRecognitionTimeout
    name: Translation.tr("Identify Music")
    statusText: toggled ? Translation.tr("Listening...") : Translation.tr("Inactive")  
    toggled: false
    buttonIcon: toggled ? "cadence" : "graphic_eq"

    property var recognizedTrack: ({ title:"", subtitle:"", url:""})

    function handleRecognition(jsonText) {
        try {
            var obj = JSON.parse(jsonText)
            root.recognizedTrack = {
                title: obj.track.title,
                subtitle: obj.track.subtitle,
                url: obj.track.url
            }
            musicReconizedProc.running = true
        } catch(e) {
            Quickshell.execDetached(["notify-send", "Unable to recognize music", "Please make sure your music is playing and try again", "-a", "Shell"])
        } finally {
            root.toggled = false
        }
    }

    StyledToolTip {
        text: Translation.tr("Identifies the song that’s currently playing")
    }

     onClicked: {
        root.toggled = !root.toggled
        recognizeMusicProc.running = root.toggled
        musicReconizedProc.running = false
    }

    Process {
        id: recognizeMusicProc
        running: false
        command: [`${Directories.scriptPath}/musicRecognition/musicRecognition.sh`, "-i", root.timeoutInterval, "-t", root.timeoutDuration]
        stdout: StdioCollector {
            onStreamFinished: {
                handleRecognition(this.text)
            }
        }
    }

    Process {
        id: musicReconizedProc
        running: false
        command: [
            "notify-send",
            Translation.tr("Music Recognized"), 
            root.recognizedTrack.title + " - " + root.recognizedTrack.subtitle, 
            "-A", "Shazam",
            "-a", "Shell"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text !== ""){
                    Qt.openUrlExternally(root.recognizedTrack.url);
                }
            }
        }
    }
}
