import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

// Resumen de actualizaciones pendientes.
DashCard {
    id: root

    RowLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        MaterialSymbol {
            text: !Updates.ok ? "cloud_off" : Updates.count > 0 ? "system_update_alt" : "check_circle"
            iconSize: 26
            color: !Updates.ok ? Appearance.colors.colSubtext
                : Updates.count > 0 ? Appearance.m3colors.m3primary : Appearance.m3colors.m3tertiary
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            StyledText {
                Layout.fillWidth: true
                text: !Updates.ok ? Translation.tr("Could not check")
                    : Updates.count === 0 ? (Updates.ts > 0 ? Translation.tr("System up to date") : Translation.tr("Checking…"))
                    : Updates.count === 1 ? Translation.tr("%1 update pending").arg(Updates.count)
                    : Translation.tr("%1 updates pending").arg(Updates.count)
                elide: Text.ElideRight
                color: Appearance.colors.colOnLayer1
                font.pixelSize: Appearance.font.pixelSize.normal
            }
            StyledText {
                Layout.fillWidth: true
                elide: Text.ElideRight
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.smaller
                text: !Updates.ok ? Updates.errorText
                    : Updates.busy ? Translation.tr("Searching…")
                    : Translation.tr("Last update %1").arg(Updates.ago(Updates.lastUpgrade))
                        + (Updates.needsReboot ? " · " + Translation.tr("Includes kernel/systemd") : "")
            }
        }
    }
}
