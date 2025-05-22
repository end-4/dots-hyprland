import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import "root:/modules/common/functions/string_utils.js" as StringUtils
import Qt5Compat.GraphicalEffects
import Qt.labs.platform
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Hyprland

RippleButton {
    id: root
    property string displayText
    property string url

    property string downloadUserAgent: ConfigOptions.networking.userAgent
    property string faviconDownloadPath
    property string domainName: url.includes("vertexaisearch") ? displayText : StringUtils.getBaseUrl(url)
    property string faviconUrl: `https://www.google.com/s2/favicons?domain=${domainName}&sz=32`
    property string fileName: `${domainName}.ico`
    property string faviconFilePath: `${faviconDownloadPath}/${fileName}`

    property real faviconSize: 20
    implicitHeight: 30
    leftPadding: (implicitHeight - faviconSize) / 2
    rightPadding: 10
    buttonRadius: Appearance.rounding.full
    colBackground: Appearance.m3colors.m3surfaceContainerHighest
    colBackgroundHover: Appearance.colors.colSurfaceContainerHighestHover
    colRipple: Appearance.colors.colSurfaceContainerHighestActive

    Process {
        id: faviconDownloadProcess
        running: false
        command: ["bash", "-c", `[ -f ${faviconFilePath} ] || curl -s '${root.faviconUrl}' -o '${faviconFilePath}' -L -H 'User-Agent: ${downloadUserAgent}'`]
        onExited: (exitCode, exitStatus) => {
            root.faviconUrl = root.faviconFilePath
        }
    }

    Component.onCompleted: {
        faviconDownloadProcess.running = true
    }

    PointingHandInteraction {}
    onClicked: {
        if (url) {
            Qt.openUrlExternally(url)
            Hyprland.dispatch("global quickshell:sidebarLeftClose")
        }
    }

    contentItem: RowLayout {
        spacing: 5
        IconImage {
            id: iconImage
            source: Qt.resolvedUrl(root.faviconUrl)
            implicitSize: root.faviconSize

            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: iconImage.implicitSize
                    height: iconImage.implicitSize
                    radius: Appearance.rounding.full
                }
            }
        }
        StyledText {
            id: text
            horizontalAlignment: Text.AlignHCenter
            text: displayText
            color: Appearance.m3colors.m3onSurface
        }
    }
}
