import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.functions

Process {
    id: root

    signal done(string path, int width, int height);
    required property string filePath;
    required property string sourceUrl;
    property string downloadUserAgent: Config.options?.networking.userAgent ?? ""
    
    function processFilePath() {
        return StringUtils.shellSingleQuoteEscape(FileUtils.trimFileProtocol(filePath));
    }

    running: true
    command: ["bash", "-c", 
        `mkdir -p $(dirname '${processFilePath(filePath)}'); [ -f '${processFilePath(filePath)}' ] || curl -sSL '${sourceUrl}' -o '${processFilePath(filePath)}' && magick identify -format '%w %h' '${processFilePath(filePath)}'[0]`
    ]
    stdout: StdioCollector {
        id: imageSizeOutputCollector
        onStreamFinished: {
            const output = imageSizeOutputCollector.text.trim();
            const [width, height] = output.split(" ").map(Number);
            root.done(root.filePath, width, height);
        }
    }
}
