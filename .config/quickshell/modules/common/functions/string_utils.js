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
    const regex = /```(\w+)?\n([\s\S]*?)```/g;
    let result = [];
    let lastIndex = 0;
    let match;
    while ((match = regex.exec(markdown)) !== null) {
        if (match.index > lastIndex) {
            result.push({ type: "text", content: markdown.slice(lastIndex, match.index) });
        }
        result.push({ type: "code", lang: match[1] || "", content: match[2] });
        lastIndex = regex.lastIndex;
    }
    if (lastIndex < markdown.length) {
        result.push({ type: "text", content: markdown.slice(lastIndex) });
    }
    return result;
}

function trimFileProtocol(str) {
    return str.startsWith("file://") ? str.slice(7) : str;
}

function escapeBackslashes(str) {
    return str.replace(/\\/g, '\\\\');
}