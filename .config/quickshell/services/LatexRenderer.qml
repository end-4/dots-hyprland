pragma Singleton
pragma ComponentBehavior: Bound

import "root:/modules/common/functions/string_utils.js" as StringUtils
import "root:/modules/common/functions/file_utils.js" as FileUtils
import "root:/modules/common"
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Qt.labs.platform

/**
* Renders LaTeX snippets with MicroTeX.
* For every request:
*   1. Hash it
*   2. Check if the hash is already processed
*   3. If not, render it with MicroTeX and mark as processed
*/
Singleton {
    id: root
    
    readonly property var renderPadding: 4 // This is to prevent cutoff in the rendered images

    property list<string> processedHashes: []
    property var processedExpressions: ({})
    property var renderedImagePaths: ({})
    property string microtexBinaryPath: Qt.resolvedUrl("/opt/MicroTeX/LaTeX")
    property string latexOutputPath: FileUtils.trimFileProtocol(`${XdgDirectories.cache}/latex`)

    signal renderFinished(string hash, string imagePath)

    Component.onCompleted: {
        Hyprland.dispatch(`exec rm -rf ${latexOutputPath} && mkdir -p ${latexOutputPath}`)
    }

    /**
    * Requests rendering of a LaTeX expression.
    * Returns the [hash, isNew]
    */
    function requestRender(expression) {
        // 1. Hash it and initialize necessary variables
        const hash = Qt.md5(expression)
        const imagePath = `${latexOutputPath}/${hash}.svg`
        
        // 2. Check if the hash is already processed
        if (processedHashes.includes(hash)) {
            // console.log("Already processed: " + hash)
            renderFinished(hash, imagePath)
            return [hash, false]
        } else {
            root.processedHashes.push(hash)
            root.processedExpressions[hash] = expression
            // console.log("Rendering expression: " + expression)
        }

        // 3. If not, render it with MicroTeX and mark as processed
        const processQml = `
            import Quickshell.Io
            Process {
                id: microtexProcess${hash}
                running: true
                command: [ "${microtexBinaryPath}", "-headless", 
                    "-input=${StringUtils.escapeBackslashes(expression)}", 
                    "-output=${imagePath}", 
                    "-textsize=${Appearance.font.pixelSize.normal}", 
                    "-padding=${renderPadding}", 
                    "-foreground=${Appearance.colors.colOnLayer1}",
                    "-maxwidth=0.85" ]
                // stdout: SplitParser {
                //     onRead: data => { console.log("MicroTeX: " + data) }
                // }
                onExited: (exitCode, exitStatus) => {
                    renderedImagePaths["${hash}"] = "${imagePath}"
                    root.renderFinished("${hash}", "${imagePath}")
                    microtexProcess${hash}.destroy()
                }
            }
        `
        // console.log("MicroTeX: " + processQml)
        Qt.createQmlObject(processQml, root, `MicroTeXProcess_${hash}`)
        return [hash, true]
    }
}