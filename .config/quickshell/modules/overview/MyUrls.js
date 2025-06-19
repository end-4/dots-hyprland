var urls = [];

function load(jsonPath) {
    var xhr = new XMLHttpRequest();
    xhr.open("GET", jsonPath, false); // synchronous
    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
            try {
                urls = JSON.parse(xhr.responseText);
            } catch(e) {
                urls = [];
            }
        }
    }
    xhr.send();
}

// Fuzzy matching: allows "gh" to match "GitHub", "yt" for "YouTube", etc.
function fuzzyMatch(str, pattern) {
    str = str.toLowerCase();
    pattern = pattern.toLowerCase();
    let j = 0;
    for (let i = 0; i < str.length && j < pattern.length; i++) {
        if (str[i] === pattern[j]) j++;
    }
    return j === pattern.length;
}

function fuzzyQuery(query) {
    var q = query.trim().toLowerCase();
    if (!q) return [];
    return urls.filter(function(entry) {
        return entry.name && fuzzyMatch(entry.name, q);
    });
}
