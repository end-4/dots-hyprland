import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas
import qs.modules.ii.background.widgets

AbstractBackgroundWidget {
    id: root
    configEntryName: "stats"
    implicitHeight: backgroundShape.implicitHeight
    implicitWidth: backgroundShape.implicitWidth

    property string githubUsername: Config.options.background.widgets.stats.githubUsername
    property string codeforcesUsername: Config.options.background.widgets.stats.codeforcesUsername
    property bool showGraphs: Config.options.background.widgets.stats.showGraphs || false

    property int ghFollowers: 0
    property int ghRepos: 0
    property string cfRank: "--"
    property int cfRating: 0
    property var githubActivityArray: []
    property var cfActivityArray: []
    property int maxGithubActivity: 1
    property int maxCfActivity: 1

    function fetchGithub() {
        if (!githubUsername) return;
        var req = new XMLHttpRequest();
        req.onreadystatechange = function() {
            if (req.readyState === 4 && req.status === 200) {
                var data = JSON.parse(req.responseText);
                ghFollowers = data.followers || 0;
                ghRepos = data.public_repos || 0;
            }
        }
        req.open("GET", "https://api.github.com/users/" + githubUsername, true);
        req.send();

        if (showGraphs) {
            var ereq = new XMLHttpRequest();
            ereq.onreadystatechange = function() {
                if (ereq.readyState !== 4 || ereq.status !== 200) return;
                var events = JSON.parse(ereq.responseText);
                var bins = new Array(30).fill(0), maxV = 0, now = new Date();
                for (var i = 0; i < events.length; i++) {
                    var d = Math.floor(Math.abs(now - new Date(events[i].created_at)) / 86400000);
                    if (d < 30) { bins[29-d]++; if (bins[29-d] > maxV) maxV = bins[29-d]; }
                }
                maxGithubActivity = Math.max(1, maxV);
                githubActivityArray = bins;
            }
            ereq.open("GET", "https://api.github.com/users/" + githubUsername + "/events/public?per_page=100", true);
            ereq.send();
        }
    }

    function fetchCodeforces() {
        if (!codeforcesUsername) return;
        var req = new XMLHttpRequest();
        req.onreadystatechange = function() {
            if (req.readyState === 4 && req.status === 200) {
                var data = JSON.parse(req.responseText);
                if (data.status === "OK" && data.result.length > 0) {
                    cfRank = data.result[0].rank || "--";
                    cfRating = data.result[0].rating || 0;
                }
            }
        }
        req.open("GET", "https://codeforces.com/api/user.info?handles=" + codeforcesUsername, true);
        req.send();

        if (showGraphs) {
            var sreq = new XMLHttpRequest();
            sreq.onreadystatechange = function() {
                if (sreq.readyState !== 4 || sreq.status !== 200) return;
                var data = JSON.parse(sreq.responseText);
                if (data.status !== "OK") return;
                var bins = new Array(30).fill(0), maxV = 0, nowS = Date.now()/1000;
                for (var i = 0; i < data.result.length; i++) {
                    var d = Math.floor((nowS - data.result[i].creationTimeSeconds) / 86400);
                    if (d < 30) { bins[29-d]++; if (bins[29-d] > maxV) maxV = bins[29-d]; }
                }
                maxCfActivity = Math.max(1, maxV);
                cfActivityArray = bins;
            }
            sreq.open("GET", "https://codeforces.com/api/user.status?handle=" + codeforcesUsername + "&from=1&count=200", true);
            sreq.send();
        }
    }

    Timer { interval: 600000; running: true; repeat: true; triggeredOnStart: true; onTriggered: { fetchGithub(); fetchCodeforces(); } }
    onGithubUsernameChanged: fetchGithub()
    onCodeforcesUsernameChanged: fetchCodeforces()
    onShowGraphsChanged: { if (showGraphs) { fetchGithub(); fetchCodeforces(); } }

    StyledDropShadow { target: backgroundShape }

    Rectangle {
        id: backgroundShape
        anchors.fill: parent
        radius: Appearance.rounding.windowRounding
        color: Appearance.colors.colPrimaryContainer
        implicitWidth: 320
        implicitHeight: contentCol.implicitHeight + 40

        Column {
            id: contentCol
            anchors.centerIn: parent
            spacing: 20
            width: parent.width - 40

            // GitHub
            Row {
                spacing: 15
                MaterialSymbol { iconSize: 40; color: Appearance.colors.colOnPrimaryContainer; text: "code"; anchors.verticalCenter: parent.verticalCenter }
                Column {
                    StyledText { font.pixelSize: 18; font.weight: Font.Bold; color: Appearance.colors.colOnPrimaryContainer; text: "GitHub: " + (githubUsername || "Not set") }
                    StyledText { font.pixelSize: 14; color: Appearance.colors.colPrimary; text: ghFollowers + " Followers  •  " + ghRepos + " Repos" }
                }
            }
            Canvas {
                width: parent.width; height: root.showGraphs ? 40 : 0; visible: root.showGraphs
                onPaint: {
                    var ctx = getContext("2d"); ctx.clearRect(0,0,width,height);
                    var arr = root.githubActivityArray;
                    if (!arr || arr.length < 2) return;
                    ctx.beginPath(); ctx.strokeStyle = Appearance.colors.colSecondary;
                    ctx.lineWidth = 2; ctx.lineCap = "round"; ctx.lineJoin = "round";
                    var step = width/(arr.length-1);
                    ctx.moveTo(0, height - (arr[0]/root.maxGithubActivity)*(height-4)-2);
                    for(var i=1;i<arr.length;i++){
                        var cpx=((i-1)*step+i*step)/2;
                        var py=height-(arr[i-1]/root.maxGithubActivity)*(height-4)-2;
                        var cy=height-(arr[i]/root.maxGithubActivity)*(height-4)-2;
                        ctx.bezierCurveTo(cpx,py,cpx,cy,i*step,cy);
                    }
                    ctx.stroke();
                }
                Timer { interval: 1000; running: root.showGraphs; repeat: true; onTriggered: parent.requestPaint() }
            }

            // Codeforces
            Row {
                spacing: 15
                MaterialSymbol { iconSize: 40; color: Appearance.colors.colOnPrimaryContainer; text: "bar_chart"; anchors.verticalCenter: parent.verticalCenter }
                Column {
                    StyledText { font.pixelSize: 18; font.weight: Font.Bold; color: Appearance.colors.colOnPrimaryContainer; text: "Codeforces: " + (codeforcesUsername || "Not set") }
                    StyledText { font.pixelSize: 14; color: Appearance.colors.colPrimary; text: "Rating: " + cfRating + "  •  " + cfRank }
                }
            }
            Canvas {
                width: parent.width; height: root.showGraphs ? 40 : 0; visible: root.showGraphs
                onPaint: {
                    var ctx = getContext("2d"); ctx.clearRect(0,0,width,height);
                    var arr = root.cfActivityArray;
                    if (!arr || arr.length < 2) return;
                    ctx.beginPath(); ctx.strokeStyle = Appearance.colors.colError;
                    ctx.lineWidth = 2; ctx.lineCap = "round"; ctx.lineJoin = "round";
                    var step = width/(arr.length-1);
                    ctx.moveTo(0, height - (arr[0]/root.maxCfActivity)*(height-4)-2);
                    for(var i=1;i<arr.length;i++){
                        var cpx=((i-1)*step+i*step)/2;
                        var py=height-(arr[i-1]/root.maxCfActivity)*(height-4)-2;
                        var cy=height-(arr[i]/root.maxCfActivity)*(height-4)-2;
                        ctx.bezierCurveTo(cpx,py,cpx,cy,i*step,cy);
                    }
                    ctx.stroke();
                }
                Timer { interval: 1000; running: root.showGraphs; repeat: true; onTriggered: parent.requestPaint() }
            }
        }
    }
}
