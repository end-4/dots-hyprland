// Original code from https://github.com/koeqaife/hyprland-material-you
// Original code license: GPLv3
// Translated to Js from Cython with an LLM and reviewed

function min3(a, b, c) {
    return a < b && a < c ? a : b < c ? b : c;
}

function max3(a, b, c) {
    return a > b && a > c ? a : b > c ? b : c;
}

function min2(a, b) {
    return a < b ? a : b;
}

function max2(a, b) {
    return a > b ? a : b;
}

function levenshteinDistance(s1, s2) {
    let len1 = s1.length;
    let len2 = s2.length;

    if (len1 === 0) return len2;
    if (len2 === 0) return len1;

    if (len2 > len1) {
        [s1, s2] = [s2, s1];
        [len1, len2] = [len2, len1];
    }

    let prev = new Array(len2 + 1);
    let curr = new Array(len2 + 1);

    for (let j = 0; j <= len2; j++) {
        prev[j] = j;
    }

    for (let i = 1; i <= len1; i++) {
        curr[0] = i;
        for (let j = 1; j <= len2; j++) {
            let cost = s1[i - 1] === s2[j - 1] ? 0 : 1;
            curr[j] = min3(prev[j] + 1, curr[j - 1] + 1, prev[j - 1] + cost);
        }
        [prev, curr] = [curr, prev];
    }

    return prev[len2];
}

function partialRatio(shortS, longS) {
    let lenS = shortS.length;
    let lenL = longS.length;
    let best = 0.0;

    if (lenS === 0) return 1.0;

    for (let i = 0; i <= lenL - lenS; i++) {
        let sub = longS.slice(i, i + lenS);
        let dist = levenshteinDistance(shortS, sub);
        let score = 1.0 - (dist / lenS);
        if (score > best) best = score;
    }

    return best;
}

function computeScore(s1, s2) {
    if (s1 === s2) return 1.0;

    let dist = levenshteinDistance(s1, s2);
    let maxLen = max2(s1.length, s2.length);
    if (maxLen === 0) return 1.0;

    let full = 1.0 - (dist / maxLen);
    let part = s1.length < s2.length ? partialRatio(s1, s2) : partialRatio(s2, s1);

    let score = 0.85 * full + 0.15 * part;

    if (s1 && s2 && s1[0] !== s2[0]) {
        score -= 0.05;
    }

    let lenDiff = Math.abs(s1.length - s2.length);
    if (lenDiff >= 3) {
        score -= 0.05 * lenDiff / maxLen;
    }

    let commonPrefixLen = 0;
    let minLen = min2(s1.length, s2.length);
    for (let i = 0; i < minLen; i++) {
        if (s1[i] === s2[i]) {
            commonPrefixLen++;
        } else {
            break;
        }
    }
    score += 0.02 * commonPrefixLen;

    if (s1.includes(s2) || s2.includes(s1)) {
        score += 0.06;
    }

    return Math.max(0.0, Math.min(1.0, score));
}

function computeTextMatchScore(s1, s2) {
    if (s1 === s2) return 1.0;

    let dist = levenshteinDistance(s1, s2);
    let maxLen = max2(s1.length, s2.length);
    if (maxLen === 0) return 1.0;

    let full = 1.0 - (dist / maxLen);
    let part = s1.length < s2.length ? partialRatio(s1, s2) : partialRatio(s2, s1);

    let score = 0.4 * full + 0.6 * part;

    let lenDiff = Math.abs(s1.length - s2.length);
    if (lenDiff >= 10) {
        score -= 0.02 * lenDiff / maxLen;
    }

    let commonPrefixLen = 0;
    let minLen = min2(s1.length, s2.length);
    for (let i = 0; i < minLen; i++) {
        if (s1[i] === s2[i]) {
            commonPrefixLen++;
        } else {
            break;
        }
    }
    score += 0.01 * commonPrefixLen;

    if (s1.includes(s2) || s2.includes(s1)) {
        score += 0.2;
    }

    return Math.max(0.0, Math.min(1.0, score));
}
