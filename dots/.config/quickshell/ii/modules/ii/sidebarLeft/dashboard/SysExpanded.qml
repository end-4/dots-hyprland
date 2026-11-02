import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import "Fmt.js" as Fmt

// Vista expandida de CPU / RAM / red / GPU: grafica grande + procesos de mayor a menor.
Item {
    id: root
    required property string mode   // cpu | mem | net | gpu
    signal back()

    NumberAnimation on opacity { from: 0; to: 1; duration: 180 }

    property real topWeight: 1
    LiveListModel {
        id: rowsModel
        key: "n"
        template: ({ n: "", c: 1, v: 0, v2: 0 })
        sortDesc: true
        smoothing: root.mode === "mem" ? 0 : 0.5     // la RAM es estable; CPU/red/GPU se suavizan
        onSynced: root.topWeight = count > 0 ? root.weight(get(0)) : 1
    }
    Connections {
        target: DashStats
        function onRowsChanged() { rowsModel.sync(DashStats.rows) }
    }
    Component.onCompleted: rowsModel.sync(DashStats.rows)

    readonly property var meta: ({
        cpu: { title: "CPU", icon: "memory", color: Appearance.m3colors.m3primary },
        mem: { title: Translation.tr("Memory"), icon: "developer_board", color: Appearance.m3colors.m3secondary },
        net: { title: Translation.tr("Network"), icon: "swap_vert", color: Appearance.m3colors.m3tertiary },
        gpu: { title: "GPU", icon: "videogame_asset", color: Appearance.m3colors.m3primary }
    })
    readonly property var m: meta[mode]

    readonly property string headline: mode === "cpu" ? Fmt.pct(DashStats.cpuPct)
        : mode === "mem" ? Fmt.mem(DashStats.memUsed) + " / " + Fmt.mem(DashStats.memTotal)
        : mode === "net" ? "↓ " + Fmt.rate(DashStats.netRx)
        : Fmt.pct(DashStats.gpuUtil)
    readonly property string subline: mode === "cpu" ? (DashStats.cpuTemp > 0 ? DashStats.cpuTemp.toFixed(0) + " °C" : "")
        : mode === "mem" ? Translation.tr("Swap %1 / %2").arg(Fmt.mem(DashStats.swapUsed)).arg(Fmt.mem(DashStats.swapTotal))
        : mode === "net" ? "↑ " + Fmt.rate(DashStats.netTx)
        : (DashStats.gpuFreq > 0 ? DashStats.gpuFreq + " / " + DashStats.gpuMax + " MHz" : "")

    function rowText(r) {
        if (mode === "mem") return Fmt.mem(r.v);
        if (mode === "net") return "↓ " + Fmt.rateKB(r.v) + "   ↑ " + Fmt.rateKB(r.v2);
        return Fmt.pct(r.v);
    }
    function weight(r) { return mode === "net" ? r.v + (r.v2 || 0) : r.v; }

    readonly property string emptyText: DashStats.errorText !== "" ? DashStats.errorText
        : mode === "net" ? Translation.tr("Measuring traffic…")
        : mode === "gpu" ? Translation.tr("None of your processes are using the GPU right now")
        : Translation.tr("Measuring…")

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Rectangle {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                radius: 18
                color: backArea.containsMouse ? Appearance.colors.colLayer1Hover : Appearance.colors.colLayer1
                scale: backArea.pressed ? 0.92 : 1
                Behavior on scale { NumberAnimation { duration: 80 } }
                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "arrow_back"
                    iconSize: 20
                    color: Appearance.colors.colOnLayer1
                }
                MouseArea {
                    id: backArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.back()
                }
            }
            MaterialSymbol { text: root.m.icon; iconSize: 22; color: root.m.color }
            StyledText {
                Layout.fillWidth: true
                text: root.m.title
                color: Appearance.colors.colOnLayer1
                font.pixelSize: Appearance.font.pixelSize.larger
            }
        }

        DashCard {
            Layout.fillWidth: true
            Layout.preferredHeight: 170
            hoverable: false

            Column {
                anchors { left: parent.left; top: parent.top; margins: 14 }
                StyledText {
                    text: root.headline
                    color: Appearance.colors.colOnLayer1
                    font.pixelSize: Appearance.font.pixelSize.huge
                }
                StyledText {
                    text: root.subline
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.small
                }
            }
            Sparkline {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height: 80
                values: root.mode === "cpu" ? DashStats.cpuHist
                    : root.mode === "mem" ? DashStats.memHist
                    : root.mode === "net" ? DashStats.rxHist
                    : DashStats.gpuHist
                maxValue: root.mode === "net" ? DashStats.netPeak : 100
                lineColor: root.m.color
            }
            Sparkline {   // segunda curva: subida (solo red)
                visible: root.mode === "net"
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height: 80
                values: DashStats.txHist
                maxValue: DashStats.netPeak
                lineColor: Appearance.m3colors.m3primary
            }
        }

        DashCard {
            Layout.fillWidth: true
            Layout.fillHeight: true
            hoverable: false

            StyledText {
                anchors.centerIn: parent
                width: parent.width - 40
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                visible: DashStats.rows.length === 0
                text: root.emptyText
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.small
            }

            ListView {
                anchors.fill: parent
                anchors.margins: 8
                clip: true
                spacing: 2
                model: rowsModel
                displaced: Transition { NumberAnimation { properties: "y"; duration: 300; easing.type: Easing.OutCubic } }
                move: Transition { NumberAnimation { properties: "y"; duration: 300; easing.type: Easing.OutCubic } }
                add: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 250 } }
                remove: Transition { NumberAnimation { property: "opacity"; to: 0; duration: 150 } }
                delegate: Item {
                    id: del
                    required property var model
                    width: ListView.view.width
                    height: 38

                    Rectangle {   // barra proporcional al mayor consumidor
                        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                        width: parent.width * Math.min(1, root.weight(del.model) / Math.max(root.topWeight, 0.0001))
                        Behavior on width { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
                        radius: 8
                        color: Qt.rgba(root.m.color.r, root.m.color.g, root.m.color.b, 0.16)
                    }
                    RowLayout {
                        anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                        StyledText {
                            Layout.fillWidth: true
                            text: del.model.n + (del.model.c > 1 ? "  ×" + del.model.c : "")
                            elide: Text.ElideRight
                            color: Appearance.colors.colOnLayer1
                            font.pixelSize: Appearance.font.pixelSize.small
                        }
                        StyledText {
                            text: root.rowText(del.model)
                            color: Appearance.colors.colSubtext
                            font.pixelSize: Appearance.font.pixelSize.small
                        }
                    }
                }
            }
        }
    }
}
