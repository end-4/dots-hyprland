import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

// Puertos en escucha (con exposicion) y servicios de systemd, con acciones.
Item {
    id: root
    signal back()
    property string tab: "ports"            // ports | services
    property string svcFilter: "running"    // running | failed | all
    property string search: ""
    property string openKey: ""             // fila desplegada (solo una a la vez)

    NumberAnimation on opacity { from: 0; to: 1; duration: 180 }

    readonly property var filteredServices: PortsServices.services.filter(s => {
        if (svcFilter === "running" && s.sub !== "running") return false;
        if (svcFilter === "failed" && s.active !== "failed") return false;
        return search === "" || s.name.toLowerCase().indexOf(search) >= 0 || s.desc.toLowerCase().indexOf(search) >= 0;
    })

    LiveListModel {
        id: portsModel
        key: "key"
        template: ({ key: "", proto: "", port: 0, addrs: "", exposure: "local", proc: "", pid: 0,
                     own: false, comm: "", unit: "", uscope: "", critical: false })
    }
    LiveListModel {
        id: svcModel
        key: "key"
        template: ({ key: "", name: "", unit: "", scope: "", desc: "", active: "", sub: "", enabled: "",
                     frozen: false, mem: 0, critical: false })
    }
    Connections {
        target: PortsServices
        function onPortsChanged() { portsModel.sync(PortsServices.ports) }
    }
    onFilteredServicesChanged: svcModel.sync(filteredServices)
    onTabChanged: {
        openKey = "";
        PortsServices.setMode(tab);
    }
    Component.onCompleted: {
        PortsServices.setMode(tab);
        portsModel.sync(PortsServices.ports);
        svcModel.sync(filteredServices);
    }

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
            MaterialSymbol { text: "lan"; iconSize: 22; color: Appearance.m3colors.m3primary }
            StyledText {
                Layout.fillWidth: true
                text: Translation.tr("Ports & services")
                color: Appearance.colors.colOnLayer1
                font.pixelSize: Appearance.font.pixelSize.larger
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            FilterChip {
                label: Translation.tr("Ports") + " (" + PortsServices.portCount + ")"
                selected: root.tab === "ports"
                onClicked: root.tab = "ports"
            }
            FilterChip {
                label: Translation.tr("Services")
                selected: root.tab === "services"
                onClicked: root.tab = "services"
            }
            Item { Layout.fillWidth: true }
        }

        RowLayout {   // filtros y buscador (solo servicios)
            visible: root.tab === "services"
            Layout.fillWidth: true
            spacing: 6
            FilterChip {
                label: Translation.tr("Running")
                selected: root.svcFilter === "running"
                onClicked: root.svcFilter = "running"
            }
            FilterChip {
                label: Translation.tr("Failed") + (PortsServices.failedCount > 0 ? " (" + PortsServices.failedCount + ")" : "")
                selected: root.svcFilter === "failed"
                onClicked: root.svcFilter = "failed"
            }
            FilterChip {
                label: Translation.tr("All")
                selected: root.svcFilter === "all"
                onClicked: root.svcFilter = "all"
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                radius: 16
                color: Appearance.colors.colLayer1
                RowLayout {
                    anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                    spacing: 6
                    MaterialSymbol { text: "search"; iconSize: 16; color: Appearance.colors.colSubtext }
                    TextInput {
                        id: searchInput
                        Layout.fillWidth: true
                        clip: true
                        selectByMouse: true
                        color: Appearance.colors.colOnLayer1
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        onTextChanged: root.search = text.toLowerCase()
                        StyledText {
                            visible: searchInput.text === ""
                            anchors.verticalCenter: parent.verticalCenter
                            text: Translation.tr("Search services…")
                            color: Appearance.colors.colSubtext
                            font.pixelSize: Appearance.font.pixelSize.smaller
                        }
                    }
                }
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
                visible: root.tab === "ports" ? portsModel.count === 0 : svcModel.count === 0
                text: !PortsServices.ok ? PortsServices.errorText
                    : root.tab === "ports" ? Translation.tr("No listening ports") : Translation.tr("No services match")
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.small
            }

            ListView {
                anchors.fill: parent
                anchors.margins: 8
                visible: root.tab === "ports"
                clip: true
                spacing: 2
                model: portsModel
                displaced: Transition { NumberAnimation { properties: "y"; duration: 250; easing.type: Easing.OutCubic } }
                add: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 } }
                remove: Transition { NumberAnimation { property: "opacity"; to: 0; duration: 150 } }
                delegate: PortRow {
                    open: root.openKey === model.key
                    onToggle: root.openKey = open ? "" : model.key
                }
            }

            ListView {
                anchors.fill: parent
                anchors.margins: 8
                visible: root.tab === "services"
                clip: true
                spacing: 2
                model: svcModel
                displaced: Transition { NumberAnimation { properties: "y"; duration: 250; easing.type: Easing.OutCubic } }
                add: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 } }
                remove: Transition { NumberAnimation { property: "opacity"; to: 0; duration: 150 } }
                delegate: ServiceRow {
                    open: root.openKey === model.key
                    onToggle: root.openKey = open ? "" : model.key
                }
            }
        }
    }
}
