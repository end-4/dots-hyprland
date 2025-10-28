import qs
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services


AndroidQuickToggleButton {
    id: root

    property int timeoutInterval: Config.options.musicRecognition.interval
    property int timeoutDuration: Config.options.musicRecognition.timeout


    property string monitorSource: "monitor" // "monitor" (system sound) , "input" (microphone)

    name: Translation.tr("Identify Music")
    statusText: toggled ? Translation.tr("Listening...") : monitorSource === "monitor" ? Translation.tr("System sound") : Translation.tr("Microphone")
    toggled: false
    buttonIcon: toggled ? "music_cast" : (monitorSource === "monitor" ? "music_note" : "frame_person_mic")

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
            Quickshell.execDetached(["notify-send", Translation.tr("Couldn't recognize music"), Translation.tr("Perhaps what you're listening to is too niche"), "-a", "Shell"])
        } finally {
            root.toggled = false
        }
    }
    

    StyledToolTip {
        text: Translation.tr("Recognize music | Right-click to toggle source")
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
        command: [`${Directories.scriptPath}/musicRecognition/recognize-music.sh`, "-i", root.timeoutInterval, "-t", root.timeoutDuration, "-s", root.monitorSource]
        stdout: StdioCollector {
            onStreamFinished: {
                handleRecognition(this.text)
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 1) {
                Quickshell.execDetached(["notify-send", Translation.tr("Couldn't recognize music"), Translation.tr("Make sure you have songrec installed"), "-a", "Shell"])
                root.toggled = false
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
