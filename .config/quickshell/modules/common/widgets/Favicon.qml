import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import "root:/modules/common/functions/string_utils.js" as StringUtils
import "root:/modules/common/functions/file_utils.js" as FileUtils
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

    property real size: 32
    property string downloadUserAgent: ConfigOptions?.networking.userAgent ?? ""
    property string faviconDownloadPath: FileUtils.trimFileProtocol(`${XdgDirectories.cache}/media/favicons`)
    property string domainName: url.includes("vertexaisearch") ? displayText : StringUtils.getBaseUrl(url)
    property string faviconUrl: `https://www.google.com/s2/favicons?domain=${domainName}&sz=32`
    property string fileName: `${domainName}.ico`
    property string faviconFilePath: `${faviconDownloadPath}/${fileName}`

    Process {
        id: faviconDownloadProcess
        running: false
        command: ["bash", "-c", `[ -f ${faviconFilePath} ] || curl -s '${root.faviconUrl}' -o '${faviconFilePath}' -L -H 'User-Agent: ${downloadUserAgent}'`]
        onExited: (exitCode, exitStatus) => {
            console.log("Favicon download process exited with code:", exitCode, "and status:", exitStatus)
            console.log("Favicon file path:", faviconFilePath)
            root.faviconUrl = root.faviconFilePath
        }
    }

    Component.onCompleted: {
        console.log("faviconDownloadPath: ", faviconDownloadPath)
        console.log("faviconFilePath: ", faviconFilePath)
        console.log("faviconUrl: ", root.faviconUrl)
        console.log("domainName: ", root.domainName)
        console.log("fileName: ", root.fileName)
        console.log("downloading to ", faviconFilePath, "from", root.faviconUrl)
        faviconDownloadProcess.running = true
    }

    source: Qt.resolvedUrl(root.faviconUrl)
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