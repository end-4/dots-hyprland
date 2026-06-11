.pragma library

function queryTokens(query) {
    if (!query) return [];
    return query.trim().toLowerCase().split(/\s+/).filter(token => token.length > 0);
}

function matchesQuery(haystack, query) {
    const tokens = queryTokens(query);
    if (tokens.length === 0) return true;
    return tokens.every(token => String(haystack).toLowerCase().includes(token));
}

function matchesElement(element, query) {
    if (!element || element.type === "empty") return false;
    if (queryTokens(query).length === 0) return true;
    const haystack = [element.name, element.symbol, String(element.weight)].join(" ");
    return matchesQuery(haystack, query);
}
