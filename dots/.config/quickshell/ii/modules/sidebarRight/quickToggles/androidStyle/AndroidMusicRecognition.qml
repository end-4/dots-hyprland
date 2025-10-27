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
    property int timeoutDuration: Config.options.musicRecognition.timeout

    property string monitorSource: "monitor" // "monitor" (system sound) , "input" (microphone)

    name: Translation.tr("Identify Music")
    statusText: toggled ? Translation.tr("Listening...") : monitorSource === "monitor" ? Translation.tr("System sound") : Translation.tr("Microphone")
    toggled: false
    buttonIcon: toggled ? "music_cast" : "music_note"

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
            Quickshell.execDetached(["notify-send", Translation.tr("Unable to recognize music"), Translation.tr("Please make sure your music is playing and try again"), "-a", "Shell"])
        } finally {
            root.toggled = false
        }
    }
    

    StyledToolTip {
        text: Translation.tr("Identifies currently playing song | Right-click to change monitor source")
    }

     onClicked: {
        root.toggled = !root.toggled
        recognizeMusicProc.running = root.toggled
        musicReconizedProc.running = false
    }
    altAction: () => {
        if (root.monitorSource === "monitor"){
            root.monitorSource = "input"
            return
        }else {
            root.monitorSource = "monitor"
        }
        
    }

    Process {
        id: recognizeMusicProc
        running: false
        command: [`${Directories.scriptPath}/musicRecognition/musicRecognition.sh`, "-i", root.timeoutInterval, "-t", root.timeoutDuration, "-s", root.monitorSource]
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
            "-A", "YouTube",
            "-a", "Shell"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text === "") return
                if (this.text == 0){
                    Qt.openUrlExternally(root.recognizedTrack.url);
                } else {
                    Qt.openUrlExternally("https://www.youtube.com/results?search_query=" + root.recognizedTrack.title + " - " + root.recognizedTrack.subtitle);
                }
            }
        }
    }
}
