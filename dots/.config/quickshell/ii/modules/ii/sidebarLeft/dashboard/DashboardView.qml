import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import "Fmt.js" as Fmt

// Contenido del sidebar izquierdo: fila de 4 mini-tarjetas del sistema + tarjetas apiladas.
// Al pulsar una tarjeta, su vista completa reemplaza la pila dentro del mismo panel.
Item {
    id: root
    property string expanded: ""   // "" | aria | updates | vms | portsvc | cpu | mem | net | gpu
    readonly property var sysModes: ["cpu", "mem", "net", "gpu"]

    function open(id) {
        expanded = id;
        DashStats.setMode(sysModes.indexOf(id) >= 0 ? id : "summary");
        if (id === "portsvc") PortsServices.setMode("ports");
    }
    function close() {
        expanded = "";
        DashStats.setMode("summary");
        PortsServices.setMode("summary");
    }

    function syncActive() {
        DashStats.active = visible;
        Aria2.active = visible;
        Vms.active = visible;
        PortsServices.active = visible;
        if (visible) Updates.active = true;   // las actualizaciones siguen en segundo plano (cache de 30 min)
    }
    Component.onCompleted: syncActive()
    onVisibleChanged: syncActive()

    // -------- pila de tarjetas
    ColumnLayout {
        anchors.fill: parent
        spacing: 10
        opacity: root.expanded === "" ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 150 } }

        AriaCard {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 190
                    onClicked: root.open("aria")
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: false      // las filas anidadas rellenan por defecto; las tarjetas tienen fillHeight
            Layout.preferredHeight: 92    // y eso le daba a la fila altura maxima infinita
            Layout.maximumHeight: 92
            spacing: 6

            MiniCard {
                Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: 1
                title: "CPU"; icon: "memory"
                accent: Appearance.m3colors.m3primary
                value: Fmt.pct(DashStats.cpuPct)
                history: DashStats.cpuHist; histMax: 100
                onClicked: root.open("cpu")
            }
            MiniCard {
                Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: 1
                title: "RAM"; icon: "developer_board"
                accent: Appearance.m3colors.m3secondary
                value: Fmt.pct(DashStats.memPct)
                history: DashStats.memHist; histMax: 100
                onClicked: root.open("mem")
            }
            MiniCard {
                Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: 1
                title: "NET"; icon: "swap_vert"
                accent: Appearance.m3colors.m3tertiary
                value: "↓" + Fmt.rateShort(DashStats.netRx)
                history: DashStats.rxHist; histMax: DashStats.netPeak
                onClicked: root.open("net")
            }
            MiniCard {
                Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: 1
                title: "GPU"; icon: "videogame_asset"
                accent: Appearance.m3colors.m3primary
                value: Fmt.pct(DashStats.gpuUtil)
                history: DashStats.gpuHist; histMax: 100
                onClicked: root.open("gpu")
            }
        }

        UpdatesCard {
            Layout.fillWidth: true
            Layout.preferredHeight: 72
            onClicked: root.open("updates")
        }

        VmsCard {
            Layout.fillWidth: true
            Layout.preferredHeight: 72
            onClicked: root.open("vms")
        }

        PortsCard {
            Layout.fillWidth: true
            Layout.preferredHeight: 72
            onClicked: root.open("portsvc")
        }

        Item { Layout.fillHeight: true }
    }

    // -------- vista expandida
    Loader {
        anchors.fill: parent
        active: root.expanded !== ""
        sourceComponent: root.expanded === "aria" ? ariaView
            : root.expanded === "updates" ? updatesView
            : root.expanded === "vms" ? vmsView
            : root.expanded === "portsvc" ? portsView : sysView
    }
    Component {
        id: ariaView
        AriaExpanded { onBack: root.close() }
    }
    Component {
        id: updatesView
        UpdatesExpanded { onBack: root.close() }
    }
    Component {
        id: vmsView
        VmsExpanded { onBack: root.close() }
    }
    Component {
        id: portsView
        PortsServicesExpanded { onBack: root.close() }
    }
    Component {
        id: sysView
        SysExpanded { mode: root.expanded; onBack: root.close() }
    }
}
