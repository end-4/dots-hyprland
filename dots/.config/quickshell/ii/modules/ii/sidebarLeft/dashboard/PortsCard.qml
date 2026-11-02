import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

// Resumen de puertos en escucha y servicios con fallo.
DashCard {
    id: root

    RowLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        MaterialSymbol {
            text: PortsServices.ok ? "lan" : "cloud_off"
            iconSize: 26
            color: !PortsServices.ok ? Appearance.colors.colSubtext
                : PortsServices.exposedCount > 0 ? Appearance.m3colors.m3tertiary : Appearance.m3colors.m3primary
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            StyledText {
                Layout.fillWidth: true
                elide: Text.ElideRight
                color: Appearance.colors.colOnLayer1
                font.pixelSize: Appearance.font.pixelSize.normal
                text: !PortsServices.ok ? Translation.tr("Could not check")
                    : Translation.tr("%1 listening · %2 exposed").arg(PortsServices.portCount).arg(PortsServices.exposedCount)
            }
            StyledText {
                Layout.fillWidth: true
                elide: Text.ElideRight
                color: PortsServices.ok && PortsServices.failedCount > 0 ? Appearance.m3colors.m3error : Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.smaller
                text: !PortsServices.ok ? PortsServices.errorText
                    : PortsServices.failedCount > 0 ? Translation.tr("Failed services: %1").arg(PortsServices.failedCount)
                    : Translation.tr("No failed services")
            }
        }
    }
}
