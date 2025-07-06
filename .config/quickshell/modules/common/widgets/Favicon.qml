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
    property string displayText

    property real size: 32
    property string downloadUserAgent: Config.options?.networking.userAgent ?? "Quickshell-Favicon-Downloader/1.0"
    property string faviconDownloadPath: Directories.favicons
    property string domainName: (url && url.includes("vertexaisearch")) ? displayText : StringUtils.getDomain(url)
    // Sanitize domainName for use in URL and filename
    property string sanitizedDomainName: (domainName || "unknown_domain").replace(/[^a-zA-Z0-9.-]/g, "_").substring(0, 100)
    property string faviconUrl: `https://www.google.com/s2/favicons?domain=${sanitizedDomainName}&sz=32`
    property string sanitizedFileName: `${sanitizedDomainName}.ico`
    property string faviconFilePathFull: `${faviconDownloadPath}/${sanitizedFileName}` // Changed from faviconFilePath to avoid conflict with a potential future property
    property string urlToLoad: "" // Initialize to empty, will be set after download or if file exists

    Process {
        id: faviconDownloadProcess
        running: false
        // command will be set before running
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                // TODO: Check if file exists and is not empty
                root.urlToLoad = "file:///" + root.faviconFilePathFull;
            } else {
                console.log(`[Favicon] Download failed for ${root.sanitizedDomainName} (URL: ${root.faviconUrl}, Code: ${exitCode})`);
                // Optionally, try loading the original URL directly as a fallback, or a default icon
                // For now, if download fails, urlToLoad remains empty or previous value, image might not load.
            }
        }
    }

    Component.onCompleted: {
        // Ensure faviconDownloadPath exists (should be done by Directories.qml on startup too)
        // Quickshell.execDetached(["mkdir", "-p", root.faviconDownloadPath]); // Consider if needed repeatedly

        // TODO: Implement a Quickshell.fileExists(path) or use FileInfo QML element
        // if (Quickshell.fileExists(root.faviconFilePathFull)) {
        //     root.urlToLoad = "file:///" + root.faviconFilePathFull;
        // } else {
        if (root.sanitizedDomainName && root.sanitizedDomainName !== "unknown_domain") {
            faviconDownloadProcess.command = [
                "curl",
                "-sSL", // Silent, follow redirects
                "--connect-timeout", "5",
                "--max-time", "15",
                "-H", `User-Agent: ${downloadUserAgent}`,
                root.faviconUrl,
                "-o", root.faviconFilePathFull
            ];
            faviconDownloadProcess.running = true;
        } else {
            console.log("[Favicon] Cannot download favicon due to invalid domain:", root.domainName);
        }
        // }
    }

    source: Qt.resolvedUrl(root.urlToLoad) // urlToLoad will trigger image load when set
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