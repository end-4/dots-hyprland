function format(str, ...args) {
    return str.replace(/{(\d+)}/g, (match, index) =>
        typeof args[index] !== 'undefined' ? args[index] : match
    );
}

function getDomain(url) {
    const match = url.match(/^(?:https?:\/\/)?(?:www\.)?([^\/]+)/);
    return match ? match[1] : null;
}

function shellSingleQuoteEscape(str) {
    //  escape single quotes
    return String(str)
        // .replace(/\\/g, '\\\\')
        .replace(/'/g, "'\\''");
}

function splitMarkdownBlocks(markdown) {
    const regex = /```(\w+)?\n([\s\S]*?)```|<think>([\s\S]*?)<\/think>/g;
    let result = [];
    let lastIndex = 0;
    let match;
    while ((match = regex.exec(markdown)) !== null) {
        if (match.index > lastIndex) {
            const text = markdown.slice(lastIndex, match.index);
            if (text.trim()) {
                result.push({ type: "text", content: text });
            }
        }
        if (match[0].startsWith('```')) {
            if (match[2] && match[2].trim()) {
                result.push({ type: "code", lang: match[1] || "", content: match[2], completed: true });
            }
        } else if (match[0].startsWith('<think>')) {
            if (match[3] && match[3].trim()) {
                result.push({ type: "think", content: match[3], completed: true });
            }
        }
        lastIndex = regex.lastIndex;
    }
    // Handle any remaining text after the last match
    if (lastIndex < markdown.length) {
        const text = markdown.slice(lastIndex);
        // Check for unfinished <think> block
        const thinkStart = text.indexOf('<think>');
        const codeStart = text.indexOf('```');
        if (
            thinkStart !== -1 &&
            (codeStart === -1 || thinkStart < codeStart)
        ) {
            const beforeThink = text.slice(0, thinkStart);
            if (beforeThink.trim()) {
                result.push({ type: "text", content: beforeThink });
            }
            const thinkContent = text.slice(thinkStart + 7);
            if (thinkContent.trim()) {
                result.push({ type: "think", content: thinkContent, completed: false });
            }
        } else if (codeStart !== -1) {
            const beforeCode = text.slice(0, codeStart);
            if (beforeCode.trim()) {
                result.push({ type: "text", content: beforeCode });
            }
            // Try to detect language after ```
            const codeLangMatch = text.slice(codeStart + 3).match(/^(\w+)?\n/);
            let lang = "";
            let codeContentStart = codeStart + 3;
            if (codeLangMatch) {
                lang = codeLangMatch[1] || "";
                codeContentStart += codeLangMatch[0].length;
            } else if (text[codeStart + 3] === '\n') {
                codeContentStart += 1;
            }
            const codeContent = text.slice(codeContentStart);
            if (codeContent.trim()) {
                result.push({ type: "code", lang, content: codeContent, completed: false });
            }
        } else if (text.trim()) {
            result.push({ type: "text", content: text });
        }
    }
    // console.log(JSON.stringify(result, null, 2));
    return result;
}

function trimFileProtocol(str) {
    return str.startsWith("file://") ? str.slice(7) : str;
}

function escapeBackslashes(str) {
    return str.replace(/\\/g, '\\\\');
}