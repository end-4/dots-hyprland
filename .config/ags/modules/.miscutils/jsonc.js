export function parseJSONC(jsoncString) {
    let result = "";
    let inString = false;
    let inSingleQuote = false;
    let inMultiLineComment = false;
    let inSingleLineComment = false;

    for (let i = 0; i < jsoncString.length; i++) {
        let char = jsoncString[i];
        let nextChar = jsoncString[i + 1];

        // Handle string start/end
        if (!inSingleLineComment && !inMultiLineComment) {
            if (char === '"' && !inSingleQuote) {
                inString = !inString;
            } else if (char === "'" && !inString) {
                inSingleQuote = !inSingleQuote;
            }
        }

        // Handle single-line comments //
        if (!inString && !inSingleQuote && !inMultiLineComment && char === '/' && nextChar === '/') {
            inSingleLineComment = true;
            i++; // Skip next '/'
            continue;
        }

        // Handle multi-line comments /*
        if (!inString && !inSingleQuote && !inSingleLineComment && char === '/' && nextChar === '*') {
            inMultiLineComment = true;
            i++; // Skip next '*'
            continue;
        }

        // End single-line comment at newline
        if (inSingleLineComment && (char === '\n' || char === '\r')) {
            inSingleLineComment = false;
        }

        // End multi-line comment */
        if (inMultiLineComment && char === '*' && nextChar === '/') {
            inMultiLineComment = false;
            i++; // Skip next '/'
            continue;
        }

        // Only append characters if not inside a comment
        if (!inSingleLineComment && !inMultiLineComment) {
            result += char;
        }
    }

    // Remove trailing commas from objects and arrays
    result = result.replace(/,\s*([\]}])/g, '$1');

    // Parse as JSON
    return JSON.parse(result);
}
