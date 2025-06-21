import "../../../modules/common"
import "../../../modules/common/widgets"
import "../../../services"
import "../../../modules/common/functions/string_utils.js" as StringUtils
import "../../../modules/common/functions/file_utils.js" as FileUtils
import Qt5Compat.GraphicalEffects
import Qt.labs.platform
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Hyprland

IconImage {
    id: root
    property string url
    property string displayText

    property real size: 32
    property string downloadUserAgent: ConfigOptions?.networking.userAgent ?? ""
    property string faviconDownloadPath: Directories.favicons
    property string domainName: url.includes("vertexaisearch") ? displayText : StringUtils.getDomain(url)
    property string faviconUrl: `https://www.google.com/s2/favicons?domain=${domainName}&sz=32`
    property string fileName: `${domainName}.ico`
    property string faviconFilePath: `${faviconDownloadPath}/${fileName}`
    property string urlToLoad

    Process {
        id: faviconDownloadProcess
        running: false
        command: ["bash", "-c", `[ -f ${faviconFilePath} ] || curl -s '${root.faviconUrl}' -o '${faviconFilePath}' -L -H 'User-Agent: ${downloadUserAgent}'`]
        onExited: (exitCode, exitStatus) => {
            root.urlToLoad = root.faviconFilePath
        }
    }

    Component.onCompleted: {
        faviconDownloadProcess.running = true
    }

    source: Qt.resolvedUrl(root.urlToLoad)
    implicitSize: root.size

    layer.enabled: true
    layer.effect: OpacityMask {
        maskSource: Rectangle {
            width: root.implicitSize
            height: root.implicitSize
            radius: Appearance.rounding.full
        }
    }
}