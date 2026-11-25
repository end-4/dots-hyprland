pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.services
import Quickshell;
import QtQuick;

/**
 * A service for interacting with various booru APIs.
 */
Singleton {
    id: root
    property Component booruResponseDataComponent: BooruResponseData {}

    signal tagSuggestion(string query, var suggestions)
    signal responseFinished()

    property string failMessage: Translation.tr("That didn't work. Tips:\n- Check your tags and NSFW settings\n- If you don't have a tag in mind, type a page number")
    property var responses: []
    property int runningRequests: 0
    property var defaultUserAgent: "QuickshellBooru/1.0"
    property var providerList: Object.keys(providers).filter(provider => provider !== "system" && providers[provider].api)
    property var providers: {
        "system": { "name": Translation.tr("System") },
        "yandere": {
            "name": "yande.re",
            "url": "https://yande.re",
            "api": "https://yande.re/post.json",
            "description": Translation.tr("All-rounder | Good quality, decent quantity"),
            "mapFunc": (response) => {
                return (response || []).map(item => {
                    return {
                        "id": item.id,
                        "width": item.width,
                        "height": item.height,
                        "aspect_ratio": item.height ? item.width / item.height : 1,
                        "tags": item.tags,
                        "rating": item.rating,
                        "is_nsfw": (item.rating != 's'),
                        "md5": item.md5,
                        "preview_url": item.preview_url,
                        "sample_url": item.sample_url ?? item.file_url,
                        "file_url": item.file_url,
                        "file_ext": item.file_ext,
                        "source": getWorkingImageSource(item.source) ?? item.file_url,
                    }
                })
            },
            "tagSearchTemplate": "https://yande.re/tag.json?order=count&limit=10&name={{query}}*",
            "tagMapFunc": (response) => {
                return (response || []).map(item => {
                    return {
                        "name": item.name,
                        "count": item.count
                    }
                })
            }
        },
        "konachan": {
            "name": "Konachan",
            "url": "https://konachan.net",
            "api": "https://konachan.net/post.json",
            "description": Translation.tr("For desktop wallpapers | Good quality"),
            "mapFunc": (response) => {
                return (response || []).map(item => {
                    return {
                        "id": item.id,
                        "width": item.width,
                        "height": item.height,
                        "aspect_ratio": item.height ? item.width / item.height : 1,
                        "tags": item.tags,
                        "rating": item.rating,
                        "is_nsfw": (item.rating != 's'),
                        "md5": item.md5,
                        "preview_url": item.preview_url,
                        "sample_url": item.sample_url ?? item.file_url,
                        "file_url": item.file_url,
                        "file_ext": item.file_ext,
                        "source": getWorkingImageSource(item.source) ?? item.file_url,
                    }
                })
            },
            "tagSearchTemplate": "https://konachan.net/tag.json?order=count&limit=10&name={{query}}*",
            "tagMapFunc": (response) => {
                return (response || []).map(item => {
                    return {
                        "name": item.name,
                        "count": item.count
                    }
                })
            }
        },
        "danbooru": {
            "name": "Danbooru",
            "url": "https://danbooru.donmai.us",
            "api": "https://danbooru.donmai.us/posts.json",
            "description": Translation.tr("The popular one | Best quantity, but quality can vary wildly"),
            "mapFunc": (response) => {
                return (response || []).map(item => {
                    return {
                        "id": item.id,
                        "width": item.image_width,
                        "height": item.image_height,
                        "aspect_ratio": item.image_height ? item.image_width / item.image_height : 1,
                        "tags": item.tag_string,
                        "rating": item.rating,
                        "is_nsfw": (item.rating != 's'),
                        "md5": item.md5,
                        "preview_url": item.preview_file_url,
                        "sample_url": item.large_file_url ?? item.file_url,
                        "file_url": item.file_url ?? item.large_file_url,
                        "file_ext": item.file_ext,
                        "source": getWorkingImageSource(item.source) ?? item.file_url,
                    }
                })
            },
            "tagSearchTemplate": "https://danbooru.donmai.us/tags.json?limit=10&search[name_matches]={{query}}*",
            "tagMapFunc": (response) => {
                return (response || []).map(item => {
                    return {
                        "name": item.name,
                        "count": item.post_count
                    }
                })
            }
        },
        "safebooru": {
            "name": "Safebooru",
            "url": "https://safebooru.org",
            "api": "https://safebooru.org/index.php?page=dapi&s=post&q=index&json=1",
            "description": Translation.tr("Safebooru mirror | Great quantity, no API key needed"),
            "mapFunc": (response) => {
                const list = Array.isArray(response) ? response : (response?.post || [])
                return list.map(item => {
                    const ratingChar = (item.rating || "s").replace("general", "s").charAt(0)
                    const fileUrl = item.file_url || (item.directory && item.image ? `https://safebooru.org/images/${item.directory}/${item.image}` : "")
                    const previewUrl = item.preview_url || (item.directory && item.image ? `https://safebooru.org/thumbnails/${item.directory}/thumbnail_${item.image}` : fileUrl)
                    return {
                        "id": item.id,
                        "width": item.width || 1000,
                        "height": item.height || 1000,
                        "aspect_ratio": (item.width && item.height) ? item.width / item.height : 1,
                        "tags": item.tags,
                        "rating": ratingChar,
                        "is_nsfw": (ratingChar != 's'),
                        "md5": item.md5 || item.hash || String(item.id),
                        "preview_url": previewUrl,
                        "sample_url": item.sample_url ?? fileUrl,
                        "file_url": fileUrl,
                        "file_ext": (fileUrl || "jpg").split('.').pop(),
                        "source": getWorkingImageSource(item.source) ?? fileUrl,
                    }
                })
            },
            "tagSearchTemplate": "https://safebooru.org/index.php?page=dapi&s=tag&q=index&json=1&orderby=count&limit=10&name_pattern={{query}}%",
            "tagMapFunc": (response) => {
                const list = Array.isArray(response) ? response : (response?.tag || [])
                return list.map(item => {
                    return {
                        "name": item.name,
                        "count": item.count
                    }
                })
            }
        },
        "waifu.best": {
            "name": "waifu.best",
            "url": "https://waifu.best",
            "api": "https://api.waifu.best/images",
            "description": Translation.tr("Waifus only | Excellent quality, limited quantity"),
            "mapFunc": (response) => {
                const list = response?.items || response?.results || (Array.isArray(response) ? response : [])
                return list.map(item => {
                    const tagList = Array.isArray(item.tags) ? item.tags.map(t => typeof t === "string" ? t : t.name).join(" ") : (item.tags || "")
                    return {
                        "id": item.image_id || item.id,
                        "width": item.width || 1000,
                        "height": item.height || 1000,
                        "aspect_ratio": (item.width && item.height) ? item.width / item.height : 1,
                        "tags": tagList,
                        "rating": (item.is_nsfw ?? item.isNsfw) ? "e" : "s",
                        "is_nsfw": Boolean(item.is_nsfw ?? item.isNsfw),
                        "md5": item.md5 || String(item.image_id || item.id),
                        "preview_url": item.preview_url ?? item.sample_url ?? item.url,
                        "sample_url": item.sample_url ?? item.url,
                        "file_url": item.url,
                        "file_ext": item.extension || (item.url || "jpg").split('.').pop(),
                        "source": getWorkingImageSource(item.source) ?? item.url,
                    }
                })
            },
            "tagSearchTemplate": "https://api.waifu.best/tags?name={{query}}",
            "tagMapFunc": (response) => {
                const list = response?.items || response?.results || (Array.isArray(response) ? response : [])
                return list.map(item => { return { "name": typeof item === "string" ? item : item.name } })
            }
        },
        "zerochan": {
            "name": "Zerochan",
            "url": "https://www.zerochan.net",
            "api": "https://www.zerochan.net/",
            "description": Translation.tr("High-res anime art | Uses p/l pagination & Title Case tags"),
            "mapFunc": (response) => {
                const list = Array.isArray(response) ? response : (response?.items || response?.result || [])
                return list.map(item => {
                    const id = item.id
                    const w = Number(item.width) || 1000
                    const h = Number(item.height) || 1000
                    const tagsVal = Array.isArray(item.tags) ? item.tags.join(" ") : (item.tags || item.tag || "")
                    const previewUrl = item.thumbnail || item.preview_url || item.sample_url || item.sample || item.file_url || item.full || ""
                    const sampleUrl = item.sample_url || item.sample || previewUrl
                    const fileUrl = item.file_url || item.full || previewUrl
                    const cleanPath = (fileUrl || previewUrl).split("?")[0]
                    const ext = item.file_ext || (cleanPath.split(".").pop() || "avif")
                    return {
                        "id": id,
                        "width": w,
                        "height": h,
                        "aspect_ratio": h ? w / h : 1,
                        "tags": tagsVal,
                        "rating": "s",
                        "is_nsfw": false,
                        "md5": item.md5 || String(id),
                        "preview_url": previewUrl,
                        "sample_url": sampleUrl,
                        "file_url": fileUrl,
                        "file_ext": ext,
                        "source": item.source || (id ? `https://www.zerochan.net/${id}` : fileUrl),
                    }
                })
            }
        },
        "t.alcy.cc": {
            "name": "Alcy",
            "url": "https://t.alcy.cc",
            "api": "https://t.alcy.cc/",
            "description": Translation.tr("Large images | God tier quality, no NSFW."),
            "fixedTags": [
                { "name": "ycy", "count": "General" },
                { "name": "moez", "count": "Moe" },
                { "name": "ysz", "count": "Genshin Impact" },
                { "name": "fj", "count": "Landscape" },
                { "name": "bd", "count": "Girl on white background" },
                { "name": "xhl", "count": "Shiggy" },
            ],
            "manualParseFunc": (responseText) => {
                const lines = responseText.trim().split('\n').filter(Boolean);
                return lines.map(line => {
                    return {
                        "id": Qt.md5(line),
                        "width": 1000,
                        "height": 1000,
                        "aspect_ratio": 1,
                        "tags": "[no tags]",
                        "rating": "s",
                        "is_nsfw": false,
                        "md5": Qt.md5(line),
                        "preview_url": line,
                        "sample_url": line,
                        "file_url": line,
                        "file_ext": line.split('.').pop(),
                        "source": "",
                    }
                });
            },
        }
    }
    property var currentProvider: Persistent.states.booru.provider

    function getWorkingImageSource(url) {
        if (url?.includes('pximg.net')) {
            return `https://www.pixiv.net/en/artworks/${url.substring(url.lastIndexOf('/') + 1).replace(/_p\d+\.(png|jpg|jpeg|gif)$/, '')}`;
        }
        return url;
    }

    function toBase64(str) {
        const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
        const bytes = [];
        for (let i = 0; i < str.length; i++) {
            bytes.push(str.charCodeAt(i) & 0xff);
        }
        let out = "";
        for (let i = 0; i < bytes.length; i += 3) {
            const b0 = bytes[i];
            const b1 = i + 1 < bytes.length ? bytes[i + 1] : 0;
            const b2 = i + 2 < bytes.length ? bytes[i + 2] : 0;
            const has1 = i + 1 < bytes.length;
            const has2 = i + 2 < bytes.length;
            out += chars[b0 >> 2];
            out += chars[((b0 & 0x03) << 4) | (b1 >> 4)];
            out += has1 ? chars[((b1 & 0x0f) << 2) | (b2 >> 6)] : "=";
            out += has2 ? chars[b2 & 0x3f] : "=";
        }
        return out;
    }

    function applyHeaders(xhr) {
        try {
            if (currentProvider === "zerochan") {
                xhr.setRequestHeader("User-Agent", "QuickshellBooru/1.0 - <username>")
            } else if (["danbooru", "konachan"].includes(currentProvider)) {
                xhr.setRequestHeader("User-Agent", defaultUserAgent)
            } else if (currentProvider === "waifu.best") {
                xhr.setRequestHeader("Authorization", "Bearer <waifu-best-api-key>")
            }
        } catch (error) {
            console.log("[Booru] Could not set headers:", error)
        }
    }

    function setProvider(provider) {
        provider = provider.toLowerCase()
        if (providerList.indexOf(provider) !== -1) {
            Persistent.states.booru.provider = provider
            root.addSystemMessage(Translation.tr("Provider set to ") + providers[provider].name)
        } else {
            root.addSystemMessage(Translation.tr("Invalid API provider. Supported: \n- ") + providerList.join("\n- "))
        }
    }

    function clearResponses() {
        responses = []
    }

    function addSystemMessage(message) {
        responses = [...responses, root.booruResponseDataComponent.createObject(null, {
            "provider": "system",
            "tags": [],
            "page": -1,
            "images": [],
            "message": `${message}`
        })]
    }

    function constructRequestUrl(tags, nsfw=true, limit=20, page=1) {
        var provider = providers[currentProvider]
        var baseUrl = provider.api
        var url = baseUrl
        var tagString = (tags || []).join(" ").trim()
        if (!nsfw && !(["waifu.best", "t.alcy.cc"].includes(currentProvider))) {
            if (currentProvider == "safebooru")
                tagString = (tagString + " rating:general").trim();
            else
                tagString = (tagString + " rating:safe").trim();
        }
        var params = []
        if (currentProvider === "waifu.best") {
            if (tagString.length > 0) {
                tagString.split(/\s+/).forEach(tag => {
                    params.push("included_tags=" + encodeURIComponent(tag.toLowerCase()));
                });
            }
            params.push("limit=" + Math.min(limit, 30))
            params.push("is_nsfw=" + (nsfw ? "true" : "false"))
        }
        else if (currentProvider === "zerochan") {
            if (tagString.length > 0) {
                const encodedTags = tagString.split(",").map(part =>
                    part.trim().split(/\s+/).filter(Boolean).map(w => encodeURIComponent(w)).join("+")
                ).filter(Boolean).join(",")
                url += encodedTags
            }
            params.push("json")
            params.push("p=" + page)
            params.push("l=" + Math.min(limit, 250))
        }
        else if (currentProvider === "t.alcy.cc") {
            url += tagString
            params.push("json")
            params.push("quantity=" + limit)
        }
        else {
            if (tagString.length > 0) {
                params.push("tags=" + encodeURIComponent(tagString))
            }
            params.push("limit=" + limit)
            if (currentProvider == "safebooru") {
                params.push("pid=" + Math.max(0, page - 1))
            }
            else {
                params.push("page=" + page)
            }
        }
        if (currentProvider === "danbooru") {
        }
        if (url.indexOf("?") === -1) {
            url += "?" + params.join("&")
        } else {
            url += "&" + params.join("&")
        }
        return url
    }

    function safeParseJson(text) {
        let s = (text || "").trim()
        if (!s || s.startsWith("<")) {
            throw new Error("Non-JSON or empty response")
        }
        s = s.replace(/^(?:\{\s*)+/, "{").replace(/^(?:\[\s*)+/, "[")
        const objIdx = s.indexOf("{")
        const arrIdx = s.indexOf("[")
        let start = -1
        if (objIdx !== -1 && arrIdx !== -1) start = Math.min(objIdx, arrIdx)
        else start = Math.max(objIdx, arrIdx)
        if (start === -1) throw new Error("No JSON start delimiter found")
        s = s.slice(start)
        const openChar = s[0]
        const closeChar = openChar === "{" ? "}" : "]"
        let depth = 0
        let inString = false
        let escaped = false
        let endPos = -1
        for (let i = 0; i < s.length; i++) {
            const ch = s[i]
            const code = s.charCodeAt(i)
            if (inString) {
                if (escaped) escaped = false
                else if (code === 92) escaped = true
                else if (code === 34) inString = false
                continue
            }
            if (code === 34) { inString = true; continue }
            if (ch === openChar) depth++
            else if (ch === closeChar) { depth--; if (depth === 0) { endPos = i; break } }
        }
        if (endPos !== -1) s = s.slice(0, endPos + 1)
        s = s.replace(/,\s*([\]}])/g, "$1")
        return JSON.parse(s)
    }
    function makeRequest(tags, nsfw=false, limit=20, page=1) {
        var url = constructRequestUrl(tags, nsfw, limit, page)
        console.log("[Booru] Making request to " + url)

        const newResponse = root.booruResponseDataComponent.createObject(null, {
            "provider": currentProvider,
            "tags": tags,
            "page": page,
            "images": [],
            "message": ""
        })

        var xhr = new XMLHttpRequest()
        xhr.open("GET", url)
        xhr.onreadystatechange = function() {
            const okStatus = (xhr.status === 200) || (currentProvider === "zerochan" && xhr.status === 500)
            if (xhr.readyState === XMLHttpRequest.DONE && okStatus) {
                try {
                    const provider = providers[currentProvider]
                    let response;
                    if (provider.manualParseFunc) {
                        response = provider.manualParseFunc(xhr.responseText)
                    } else {
                        const parsed = safeParseJson(xhr.responseText)
                        response = provider.mapFunc(parsed)
                    }
                    newResponse.images = response
                    newResponse.message = response.length > 0 ? "" : root.failMessage
                } catch (e) {
                    console.log("[Booru] Failed to parse response: " + e + " | snippet: " + JSON.stringify((xhr.responseText || "").slice(0, 200)))
                    newResponse.message = root.failMessage
                } finally {
                    root.runningRequests--;
                    root.responses = [...root.responses, newResponse]
                }
            }
            else if (xhr.readyState === XMLHttpRequest.DONE) {
                console.log("[Booru] Request failed with status: " + xhr.status)
                newResponse.message = root.failMessage
                root.runningRequests--;
                root.responses = [...root.responses, newResponse]
            }
            root.responseFinished()
        }

        applyHeaders(xhr)
        root.runningRequests++;
        xhr.send()
    }

    property var currentTagRequest: null
    function triggerTagSearch(query) {
        if (currentTagRequest) {
            currentTagRequest.abort();
        }

        var provider = providers[currentProvider]
        if (provider.fixedTags) {
            root.tagSuggestion(query, provider.fixedTags)
            return provider.fixedTags;
        } else if (!provider.tagSearchTemplate) {
            return
        }
        var url = provider.tagSearchTemplate.replace("{{query}}", encodeURIComponent(query))

        var xhr = new XMLHttpRequest()
        currentTagRequest = xhr
        xhr.open("GET", url)
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                currentTagRequest = null
                try {
                    const parsed = safeParseJson(xhr.responseText)
                    const mapped = provider.tagMapFunc(parsed)
                    root.tagSuggestion(query, mapped)
                } catch (e) {
                    console.log("[Booru] Failed to parse response: " + e)
                }
            }
            else if (xhr.readyState === XMLHttpRequest.DONE) {
                console.log("[Booru] Request failed with status: " + xhr.status)
            }
        }

        applyHeaders(xhr)
        xhr.send()
    }
}
