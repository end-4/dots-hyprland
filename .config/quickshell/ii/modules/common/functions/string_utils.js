/**
 * Formats a string according to the args that are passed in
 * @param { string } str 
 * @param  {...any} args 
 * @returns 
 */
function format(str, ...args) {
    return str.replace(/{(\d+)}/g, (match, index) =>
        typeof args[index] !== 'undefined' ? args[index] : match
    );
}

/**
 * Returns the domain of the passed in url or null
 * @param { string } url 
 * @returns { string| null } 
 */
function getDomain(url) {
    const match = url.match(/^(?:https?:\/\/)?(?:www\.)?([^\/]+)/);
    return match ? match[1] : null;
}

/**
 * Returns the base url of the passed in url or null
 * @param { string } url 
 * @returns { string | null } 
 */
function getBaseUrl(url) {
    const match = url.match(/^(https?:\/\/[^\/]+)(\/.*)?$/);
    return match ? match[1] : null;
}

/**
 * Escapes single quotes in shell commands
 * @param { string } str 
 * @returns { string }
 */
function shellSingleQuoteEscape(str) {
    //  escape single quotes
    return String(str)
        // .replace(/\\/g, '\\\\')
        .replace(/'/g, "'\\''");
}

/**
 * Splits markdown blocks into three different types: text, think, and code.
 * @param { string } markdown 
 */
function splitMarkdownBlocks(markdown) {
    const regex = /```(\w+)?\n([\s\S]*?)```|<think>([\s\S]*?)<\/think>/g;
    /**
     * @type {{type: "text" | "think" | "code"; content: string; lang: string | undefined; completed: boolean | undefined}[]}
     */
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

/**
 * Returns the original string with backslashes escaped
 * @param { string } str 
 * @returns { string }
 */
function escapeBackslashes(str) {
    return str.replace(/\\/g, '\\\\');
}

/**
 * Wraps words to supplied maximum length
 * @param { string | null } str 
 * @param { number } maxLen 
 * @returns { string }
 */
function wordWrap(str, maxLen) {
    if (!str) return "";
    let words = str.split(" ");
    let lines = [];
    let current = "";
    for (let i = 0; i < words.length; ++i) {
        if ((current + (current.length > 0 ? " " : "") + words[i]).length > maxLen) {
            if (current.length > 0) lines.push(current);
            current = words[i];
        } else {
            current += (current.length > 0 ? " " : "") + words[i];
        }
    }
    if (current.length > 0) lines.push(current);
    return lines.join("\n");
}

function cleanMusicTitle(title) {
    if (!title) return "";
    // Brackets
    title = title.replace(/^ *\([^)]*\) */g, " "); // Round brackets
    title = title.replace(/^ *\[[^\]]*\] */g, " "); // Square brackets
    title = title.replace(/^ *\{[^\}]*\} */g, " "); // Curly brackets
    // Japenis brackets
    title = title.replace(/^ *【[^】]*】/, "") // Touhou
    title = title.replace(/^ *《[^》]*》/, "") // ??
    title = title.replace(/^ *「[^」]*」/, "") // OP/ED thingie
    title = title.replace(/^ *『[^』]*』/, "") // OP/ED thingie

    return title.trim();
}

function friendlyTimeForSeconds(seconds) {
    if (isNaN(seconds) || seconds < 0) return "0:00";
    seconds = Math.floor(seconds);
    const h = Math.floor(seconds / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    const s = seconds % 60;
    if (h > 0) {
        return `${h}:${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
    } else {
        return `${m}:${s.toString().padStart(2, '0')}`;
    }
}

function escapeHtml(str) {
    if (typeof str !== 'string') return str;
    return str
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#39;');
}
