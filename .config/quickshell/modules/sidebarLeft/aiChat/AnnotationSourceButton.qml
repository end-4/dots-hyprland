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

Button {
    id: root
    property string displayText
    property string url

    implicitHeight: 30
    leftPadding: 5
    rightPadding: 10

    property string downloadUserAgent: ConfigOptions.networking.userAgent
    property string faviconDownloadPath
    property string domainName: url.includes("vertexaisearch") ? displayText : StringUtils.getBaseUrl(url)
    // property string faviconUrl: `https://${domainName}/favicon.ico`
    property string faviconUrl: `https://www.google.com/s2/favicons?domain=${domainName}&sz=32`
    property string fileName: `${domainName}.ico`
    property string faviconFilePath: `${faviconDownloadPath}/${fileName}`

    Process {
        id: faviconDownloadProcess
        running: false
        command: ["bash", "-c", `[ -f ${faviconFilePath} ] || curl -s '${root.faviconUrl}' -o '${faviconFilePath}' -L -H 'User-Agent: ${downloadUserAgent}'`]
        onExited: (exitCode, exitStatus) => {
            root.faviconUrl = root.faviconFilePath
        }
    }

    Component.onCompleted: {
        // console.log("Favicon download:", faviconDownloadProcess.command.join(" "))
        faviconDownloadProcess.running = true
    }

    PointingHandInteraction {}
    onClicked: {
        if (url) {
            Qt.openUrlExternally(url)
            Hyprland.dispatch("global quickshell:sidebarLeftClose")
        }
    }

    background: Rectangle {
        radius: Appearance.rounding.full
        color: (root.down ? Appearance.colors.colSurfaceContainerHighestActive : 
            root.hovered ? Appearance.colors.colSurfaceContainerHighestHover :
            Appearance.m3colors.m3surfaceContainerHighest)
    }

    contentItem: RowLayout {
        spacing: 5
        IconImage {
            id: iconImage
            source: Qt.resolvedUrl(root.faviconUrl)
            implicitSize: 20

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
