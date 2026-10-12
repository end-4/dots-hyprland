pragma Singleton
import Quickshell

Singleton {
    id: root

    /**
     * Formats a string according to the args that are passed inc
     * @param { string } str
     * @param  {...any} args
     * @returns { string }
     */
    function format(str, ...args) {
        return str.replace(/{(\d+)}/g, (match, index) => typeof args[index] !== 'undefined' ? args[index] : match);
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
        return String(str)
        // .replace(/\\/g, '\\\\')
        .replace(/'/g, "'\\''");
    }

    /**
     * Whether a block from splitMarkdownBlocks is a command fence
     * @param { {lang?: string} } block
     * @returns { boolean }
     */
    function isCommandFence(block) {
        return block.lang?.split(":")[0] === "command";
    }

    /**
     * All command markdown blocks in string
     * @param { string } content
     * @returns { Array<{content: string, lang: string, start: number, end: number}> }
     */
    function commandFences(content) {
        return root.splitMarkdownBlocks(content).filter(block => root.isCommandFence(block));
    }

    /**
     * Applies a transform to the nth command fence, passing it the whole fence text.
     * @param { string } content
     * @param { number } ordinal
     * @param { (fence: string) => string } transform
     * @returns { string }
     */
    function editCommandFence(content, ordinal, transform) {
        if (ordinal < 0) return content;
        const fence = root.commandFences(content)[ordinal];
        if (!fence) return content;
        return content.slice(0, fence.start)
            + transform(content.slice(fence.start, fence.end))
            + content.slice(fence.end);
    }

    /**
     * Lifecycle states a command fence's info string can end with, as command:<name>:<state>.
     */
    readonly property var commandFenceStates: ["streaming", "pending", "running", "done", "failed", "denied", "answered"]

    /**
     * Divides a command fence's body into the command and the output of the run. Output lives
     * in the fence rather than beside it so it survives saving and reloading the chat, which
     * keeps nothing but the message text.
     */
    readonly property string commandOutputSeparator: "\u001e"

    /**
     * @param { string } body
     * @returns { {command: string, output: string} }
     */
    function splitCommandFenceBody(body) {
        const parts = String(body ?? "").split(root.commandOutputSeparator);
        return {
            command: parts[0].replace(/\n$/, ""),
            output: parts.slice(1).join("").replace(/^\n/, "").replace(/\s+$/, "")
        };
    }

    /**
     * Character offset each line of the text starts at. Lets a caller ask a laid-out text item
     * where a given line ended up, without splitting the text a second way.
     * @param { string } text
     * @returns { list<int> }
     */
    function lineStartOffsets(text) {
        const lines = String(text ?? "").replace(/\n$/, "").split("\n");
        let offset = 0;
        return lines.map(line => {
            const start = offset;
            offset += line.length + 1;
            return start;
        });
    }

    /**
     * Swaps a command fence's state token, keeping whatever tool name it already carries
     * so states replace each other instead of stacking.
     * @param { string } fence
     * @param { string } state
     * @returns { string }
     */
    function withCommandFenceState(fence, state) {
        return fence.replace(/^```command((?::[\w-]+)*)/, (full, flags) => {
            const name = flags.split(":").filter(s => s.length > 0)
                .find(s => !root.commandFenceStates.includes(s));
            return "```command" + (name ? ":" + name : "") + ":" + state;
        });
    }

    /**
     * Splits markdown blocks into three different types: text, think, and code.
     * @param { string } markdown
     * @returns {Array<{type: "text" | "think" | "code", content: string, lang?: string, completed?: boolean}>}
     */
    function splitMarkdownBlocks(markdown) {
        /**
         * @type {{type: "text" | "think" | "code"; content: string; lang: string | undefined; completed: boolean | undefined}[]}
         */
        const result = [];
        let pos = 0;
        let textStart = 0;
        const pushText = end => {
            const text = markdown.slice(textStart, end);
            if (text.trim()) result.push({ type: "text", content: text, start: textStart, end: end });
        };
        while (pos < markdown.length) {
            const think = markdown.indexOf("<think>", pos);
            const fence = markdown.indexOf("```", pos);
            if (think === -1 && fence === -1) break;
            // Whichever of the two opens first owns everything up to its own terminator, and
            // its body is never scanned. A construct with no terminator runs to the end and
            // is reported incomplete
            if (fence === -1 || (think !== -1 && think < fence)) {
                pushText(think);
                const close = markdown.indexOf("</think>", think + 7);
                pos = close === -1 ? markdown.length : close + 8;
                const content = markdown.slice(think + 7, close === -1 ? markdown.length : close);
                if (content.trim()) {
                    result.push({
                        type: "think",
                        content: content,
                        completed: close !== -1,
                        start: think,
                        end: pos
                    });
                }
            } else {
                pushText(fence);
                const langMatch = markdown.slice(fence + 3).match(/^([\w:-]+)?\n/);
                const contentStart = fence + 3 + (langMatch?.[0].length ?? 0);
                const close = markdown.indexOf("```", contentStart);
                pos = close === -1 ? markdown.length : close + 3;
                const content = markdown.slice(contentStart, close === -1 ? markdown.length : close);
                if (content.trim()) {
                    result.push({
                        type: "code",
                        lang: langMatch?.[1] ?? "",
                        content: content,
                        completed: close !== -1,
                        start: fence,
                        end: pos
                    });
                }
            }
            textStart = pos;
        }
        pushText(markdown.length);
        return result;
    }

    /**
     * Closes the open strings and brackets of truncated JSON.
     * @param { string } s
     * @returns { string | null } null when the string is cut mid-escape
     */
    function closeJson(s) {
        let stack = [];
        let inStr = false;
        for (let i = 0; i < s.length; i++) {
            const c = s[i];
            if (inStr) {
                if (c === '\\') {
                    if (i + 1 >= s.length) return null;
                    i++;
                    continue;
                }
                if (c === '"') inStr = false;
                continue;
            }
            if (c === '"') inStr = true;
            else if (c === '{' || c === '[') stack.push(c);
            else if (c === '}' || c === ']') stack.pop();
        }
        let out = s;
        if (inStr) out += '"';
        out = out.replace(/,\s*$/, "");
        for (let i = stack.length - 1; i >= 0; i--) {
            out += stack[i] === '{' ? '}' : ']';
        }
        return out;
    }

    /**
     * Parses JSON that may still be streaming, chopping back past dangling keys, colons
     * and partial literals until closing the remainder succeeds.
     * @param { string } s
     * @returns { any } null when no prefix parses
     */
    function parsePartialJson(s) {
        for (let end = s.length; end > 0 && end > s.length - 64; end--) {
            const closed = root.closeJson(s.slice(0, end));
            if (closed === null) continue;
            try { return JSON.parse(closed); } catch (e) {}
        }
        return null;
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
        if (!str)
            return "";
        let words = str.split(" ");
        let lines = [];
        let current = "";
        for (let i = 0; i < words.length; ++i) {
            if ((current + (current.length > 0 ? " " : "") + words[i]).length > maxLen) {
                if (current.length > 0)
                    lines.push(current);
                current = words[i];
            } else {
                current += (current.length > 0 ? " " : "") + words[i];
            }
        }
        if (current.length > 0)
            lines.push(current);
        return lines.join("\n");
    }

    /**
     * Cleans up a music title by removing bracketed and special characters.
     * @param { string } title
     * @returns { string }
     */
    function cleanMusicTitle(title) {
        if (!title)
            return "";
        // Brackets
        title = title.replace(/^ *\([^)]*\) */g, " "); // Round brackets
        title = title.replace(/^ *\[[^\]]*\] */g, " "); // Square brackets
        title = title.replace(/^ *\{[^\}]*\} */g, " "); // Curly brackets
        // Japenis brackets
        title = title.replace(/^ *【[^】]*】/, ""); // Touhou
        title = title.replace(/^ *《[^》]*》/, ""); // ??
        title = title.replace(/^ *「[^」]*」/, ""); // OP/ED thingie
        title = title.replace(/^ *『[^』]*』/, ""); // OP/ED thingie

        return title.trim();
    }

    /**
     * Converts seconds to a friendly time string (e.g. 1:23 or 1:02:03).
     * @param { number } seconds
     * @returns { string }
     */
    function friendlyTimeForSeconds(seconds) {
        if (isNaN(seconds) || seconds < 0)
            return "0:00";
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

    /**
     * Duration as the units that carry information, largest first: 2d, 3h / 4h, 50m / 1m, 30s.
     * Seconds are dropped once the total runs to hours, where they say nothing; pass
     * includeSeconds false for a duration that is only ever read in minutes, like an uptime.
     * @param { number } seconds
     * @param { boolean } [includeSeconds]
     * @returns { string }
     */
    function friendlyDurationForSeconds(seconds, includeSeconds = true) {
        if (isNaN(seconds) || seconds < 0)
            return includeSeconds ? "0s" : "0m";
        seconds = Math.floor(seconds);
        const parts = [];
        const days = Math.floor(seconds / 86400);
        const hours = Math.floor((seconds % 86400) / 3600);
        const minutes = Math.floor((seconds % 3600) / 60);
        if (days > 0) parts.push(`${days}d`);
        if (hours > 0) parts.push(`${hours}h`);
        if (minutes > 0) parts.push(`${minutes}m`);
        if (includeSeconds && days === 0 && hours === 0 && seconds % 60 > 0) {
            parts.push(`${seconds % 60}s`);
        }
        if (parts.length === 0) parts.push(includeSeconds ? `${seconds}s` : "0m");
        return parts.join(", ");
    }

    /**
     * Escapes HTML special characters in a string.
     * @param { string } str
     * @returns { string }
     */
    function escapeHtml(str) {
        if (typeof str !== 'string')
            return str;
        return str.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&#39;');
    }

    /**
     * Cleans a cliphist entry by removing leading digits and tab.
     * @param { string } str
     * @returns { string }
     */
    function cleanCliphistEntry(str: string): string {
        return str.replace(/^\d+\t/, "");
    }

    /**
     * Checks if any substring in the list is contained in the string.
     * @param { string } str
     * @param { string[] } substrings
     * @returns { boolean }
     */
    function stringListContainsSubstring(str, substrings) {
        for (let i = 0; i < substrings.length; ++i) {
            if (str.includes(substrings[i])) {
                return true;
            }
        }
        return false;
    }

    /**
     * Removes the given prefix from the string if present.
     * @param { string } str
     * @param { string } prefix
     * @returns { string }
     */
    function cleanPrefix(str, prefix) {
        if (str.startsWith(prefix)) {
            return str.slice(prefix.length);
        }
        return str;
    }

    /**
     * Removes the first matching prefix from the string if present.
     * @param { string } str
     * @param { string[] } prefixes
     * @returns { string }
     */
    function cleanOnePrefix(str, prefixes) {
        for (let i = 0; i < prefixes.length; ++i) {
            if (str.startsWith(prefixes[i])) {
                return str.slice(prefixes[i].length);
            }
        }
        return str;
    }

    function toTitleCase(str) {
        // Replace "-" and "_" with space, then capitalize each word
        return str.replace(/[-_]/g, " ").replace(
            /\w\S*/g,
            function(txt) {
            return txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase();
            }
        );
    }
}
