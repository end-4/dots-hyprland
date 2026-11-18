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

function lookupSubstitution(substitutions, key) {
    if (!key) return "";
    if (substitutions[key]) return substitutions[key];
    const title = key.charAt(0).toUpperCase() + key.slice(1).toLowerCase();
    if (substitutions[title]) return substitutions[title];
    if (substitutions[key.toUpperCase()]) return substitutions[key.toUpperCase()];
    if (substitutions[key.toLowerCase()]) return substitutions[key.toLowerCase()];
    return key;
}

function modMaskToStringList(modMask) {
    const list = [];
    if (modMask & (1 << 2)) list.push("Ctrl");
    if (modMask & (1 << 6)) list.push("Super");
    if (modMask & (1 << 0)) list.push("Shift");
    if (modMask & (1 << 3)) list.push("Alt");
    if (modMask & (1 << 1)) list.push("Caps");
    if (modMask & (1 << 4)) list.push("Mod2");
    if (modMask & (1 << 5)) list.push("Mod3");
    if (modMask & (1 << 7)) list.push("Mod5");
    return list;
}

function containsFirstRepetitive(key) {
    return key.includes("1") || /left/i.test(key);
}

function transformKey(key, substitutions) {
    const replaced = lookupSubstitution(substitutions, key);
    return replaced.replace("1", "<Number>").replace("Left", "<Direction>");
}

function transformDescription(bind, categoryName) {
    const description = bind.description || "";
    const decategorized = categoryName
        ? description.replace(new RegExp("\\s*" + categoryName + "\\s*:\\s*"), "")
        : description;
    const key = bind.key || "";
    if (!containsFirstRepetitive(key)) return decategorized;
    const denumbered = decategorized.replace("1", "<Number>");
    return denumbered.replace(/ \b(left|right|up|down)\b/i, " <Direction>");
}

function mouseKeySearchTerms(rawKey) {
    switch (rawKey) {
    case "mouse:272": return "LMB left mouse";
    case "mouse:273": return "RMB right mouse";
    case "mouse:275": return "MouseBack mouse back";
    case "mouse_up": return "Scroll Down scroll down mouse up";
    case "mouse_down": return "Scroll Up scroll up mouse down";
    default: return "";
    }
}

function keybindHaystack(bind, substitutions, categoryName) {
    const modParts = [];
    for (const mod of modMaskToStringList(bind.modmask)) {
        modParts.push(mod);
        modParts.push(lookupSubstitution(substitutions, mod));
    }
    const rawKey = bind.key || "";
    const displayKey = transformKey(rawKey, substitutions);
    const description = bind.description || "";
    const displayDescription = transformDescription(bind, categoryName);
    const categoryPrefix = categoryName || description.substring(0, description.indexOf(":"));
    const keyTerms = [rawKey, displayKey, mouseKeySearchTerms(rawKey)].join(" ");
    return [modParts.join(" "), keyTerms, description, displayDescription, categoryPrefix].join(" ");
}

function matchesElement(element, query) {
    if (!element || element.type === "empty") return false;
    if (queryTokens(query).length === 0) return true;
    const haystack = [element.name, element.symbol, String(element.weight)].join(" ");
    return matchesQuery(haystack, query);
}
