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
    property string resultsJSON

    property string recognizedTrackTitle
    property string recognizedTrackSubtitle
    property string recognizedTrackURL

    name: Translation.tr("Identify Music")
    statusText: toggled ? Translation.tr("Listening...") : Translation.tr("Inactive") 
    toggled: false
    buttonIcon: toggled ? "cadence" : "graphic_eq"
    onClicked: {
        if (!toggled){
            recognizeMusicProc.running = true
        } else {
            recognizeMusicProc.running = false
        }
        
        root.toggled = !root.toggled
    }

    Process {
        id: recognizeMusicProc
        running: false
        command: [`${Directories.scriptPath}/musicRecognition/musicRecognition.sh`, "-i", root.timeoutInterval, "-t", root.timeoutDuration]
        stdout: StdioCollector {
            onStreamFinished: {
                root.resultsJSON = this.text
                if (this.text.length < 100) {
                    Quickshell.execDetached(["notify-send", "Unable to recognize music", "Please make sure your music is playing and try again", "-a", "Shell"])
                    toggled = false
                    return
                }
                var obj = JSON.parse(root.resultsJSON)
                root.recognizedTrackTitle = obj.track.title
                root.recognizedTrackSubtitle = obj.track.subtitle
                root.recognizedTrackURL = obj.track.url
                musicReconizedProc.running = true
                toggled = false
            }
        }
    }


    Process {
        id: musicReconizedProc
        running: false
        command: [ "notify-send" , "Music Recognized" , root.recognizedTrackTitle + " by " + root.recognizedTrackSubtitle , "-A" , "Shazam Link" , "-a" , "Shell"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text !== ""){
                    Qt.openUrlExternally(root.recognizedTrackURL);
                }
            }
        }
    }



    StyledToolTip {
        //text: Translation.tr("Identifies the song that’s playing right now")
        text: "Identifies the song that’s playing right now"
    }
}
