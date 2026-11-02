import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

// Resumen de maquinas virtuales (libvirt).
DashCard {
    id: root
    readonly property var runningNames: Vms.vms.filter(v => v.state === "running").map(v => v.name)

    RowLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        MaterialSymbol {
            text: Vms.ok ? "dns" : "cloud_off"
            iconSize: 26
            color: !Vms.ok ? Appearance.colors.colSubtext
                : Vms.runningCount > 0 ? Appearance.m3colors.m3primary : Appearance.colors.colSubtext
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            StyledText {
                Layout.fillWidth: true
                elide: Text.ElideRight
                color: Appearance.colors.colOnLayer1
                font.pixelSize: Appearance.font.pixelSize.normal
                text: !Vms.ok ? Translation.tr("Could not check")
                    : Vms.vms.length === 0 ? Translation.tr("No virtual machines")
                    : Translation.tr("%1 running · %2 total").arg(Vms.runningCount).arg(Vms.vms.length)
            }
            StyledText {
                Layout.fillWidth: true
                elide: Text.ElideRight
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.smaller
                text: !Vms.ok ? Vms.errorText
                    : root.runningNames.length > 0 ? root.runningNames.join(", ")
                    : Vms.vms.map(v => v.name).join(", ")
            }
        }
    }
}
