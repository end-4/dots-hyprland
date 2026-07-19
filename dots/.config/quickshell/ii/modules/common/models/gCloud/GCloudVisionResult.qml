pragma ComponentBehavior: Bound
import QtQuick
import ".."

NestableObject {
    id: root

    property real confidenceThreshold: 0.5 // TODO tune this

    property var rawData
    property var rawBlocks
    property var rawParagraphs
    property var coherentParagraphs

    function initializeWithData(apiOutputData: var): void {
        // Null check
        if (!apiOutputData) {
            print("[GCloudVisionResult] Data is null/undefined")
            return;
        }

        // Raw data
        root.rawData = apiOutputData

        // Raw blocks
        var pages = apiOutputData.responses[0].fullTextAnnotation.pages
        var blocks = [];
        for (var i = 0; i < pages.length; i++) {
            // print("this page", JSON.stringify(pages[i]))
            var blocksThisPage = pages[i].blocks;
            for (var j = 0; j < blocksThisPage.length; j++) {
                const block = blocksThisPage[j];
                // print("new block with confidence", block.confidence, ":", JSON.stringify(block, null, 2))
                if (block.confidence > root.confidenceThreshold) {
                    blocks.push(block);
                }
            }
        }
        
        root.rawBlocks = blocks
        // print("RAW BLOCKS:", blocks)

        // Raw paragraphs
        var paragraphs = []
        for (var i = 0; i < blocks.length; i++) {
            var blockParagraphs = blocks[i].paragraphs;
            for (var j = 0; j < blockParagraphs.length; j++) {
                const para = blockParagraphs[j];
                // print("new paragraph", JSON.stringify(para))
                paragraphs.push(para);
            }
        }
        root.rawParagraphs = [...paragraphs];

        // print("RAW PARAGRAPHS", paragraphs)

        // Coherent paragraphs
        // (raw data can be as granular as symbols)
        // We're interested in paragraph level of granularity as it's good for translations
        for (var i = 0; i < paragraphs.length; i++) {
            const paragraph = paragraphs[i];
            const words = paragraph.words;
            var strList = []
            for (var j = 0; j < words.length; j++) {
                const symbols = words[j].symbols;
                for (var k = 0; k < symbols.length; k++) {
                    const sym = symbols[k];
                    strList.push(sym.text);
                    // print("CHAR:", JSON.stringify(sym, null, 2));
                    // Breaks
                    // Reference: https://docs.cloud.google.com/vision/docs/reference/rpc/google.cloud.vision.v1#breaktype
                    if (sym.property?.detectedBreak.type == "SPACE" || sym.property?.detectedBreak.type == "UNKNOWN") {
                        strList.push(" ");
                    } else if (sym.property?.detectedBreak.type == "SURE_SPACE") {
                        strList.push("　");
                    } else if (sym.property?.detectedBreak.type == "EOL_SURE_SPACE" || sym.property?.detectedBreak.type == "LINE_BREAK") {
                        strList.push("\n");
                    } else if (sym.property?.detectedBreak.type == "HYPHEN") {
                        strList.push("-\n");
                    }
                }
            }
            // print("STR LIST:", strList)
            paragraphs[i].text = strList.join("").trim();
            // print("PARA TEXT:", paragraphs[i].text)
        }
        root.coherentParagraphs = paragraphs
        // print("COHERENT PARAGRAPHS", JSON.stringify(paragraphs))
    }
}
