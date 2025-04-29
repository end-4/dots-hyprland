pragma Singleton
pragma ComponentBehavior: Bound

import "root:/modules/common"
import Quickshell;
import Quickshell.Io;
import Qt.labs.platform
import QtQuick;

Singleton {
    id: root

    Connections {
        target: ConfigOptions.sidebar.booru
        function onAllowNsfwChanged() {
            root.addSystemMessage(ConfigOptions.sidebar.booru.allowNsfw ? qsTr("Tiddies enabled") : qsTr("No horny"))
        }
    }

    property string failMessage: qsTr("That didn't work. Tips:\n- Check your tags and NSFW settings\n- If you don't have a tag in mind, type a page number")
    property var responses: []
    property var getWorkingImageSource: (url) => {
        if (url.includes('pximg.net')) {
            return `https://www.pixiv.net/en/artworks/${url.substring(url.lastIndexOf('/') + 1).replace(/_p\d+\.(png|jpg|jpeg|gif)$/, '')}`;
        }
        return url;
    }

    property var defaultUserAgent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36"
    property var providerList: ["yandere", "konachan", "zerochan", "danbooru", "gelbooru", "waifu.im"]
    property var providers: {
        "system": { "name": "System" },
        "yandere": {
            "name": "yande.re",
            "url": "https://yande.re",
            "api": "https://yande.re/post.json",
            "listAccess": [],
            "mapFunc": (response) => {
                return response.map(item => {
                    return {
                        "id": item.id,
                        "width": item.width,
                        "height": item.height,
                        "aspect_ratio": item.width / item.height,
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
            }
        },
        "konachan": {
            "name": "Konachan",
            "url": "https://konachan.com",
            "api": "https://konachan.com/post.json",
            "listAccess": [],
            "mapFunc": (response) => {
                return response.map(item => {
                    return {
                        "id": item.id,
                        "width": item.width,
                        "height": item.height,
                        "aspect_ratio": item.width / item.height,
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
            }
        },
        "zerochan": {
            "name": "Zerochan",
            "url": "https://www.zerochan.net",
            "api": "https://www.zerochan.net/?json",
            "listAccess": ["items"],
            "mapFunc": (response) => {
                return response.map(item => {
                    return {
                        "id": item.id,
                        "width": item.width,
                        "height": item.height,
                        "aspect_ratio": item.width / item.height,
                        "tags": item.tags.join(" "),
                        "rating": "safe", // Zerochan doesn't have nsfw
                        "is_nsfw": false,
                        "md5": item.md5,
                        "preview_url": item.thumbnail,
                        "sample_url": item.thumbnail,
                        "file_url": item.thumbnail,
                        "file_ext": "avif",
                        "source": getWorkingImageSource(item.source) ?? item.thumbnail,
                        "character": item.tag
                    }
                })
            }
        },
        "danbooru": {
            "name": "Danbooru",
            "url": "https://danbooru.donmai.us",
            "api": "https://danbooru.donmai.us/posts.json",
            "listAccess": [],
            "mapFunc": (response) => {
                return response.map(item => {
                    return {
                        "id": item.id,
                        "width": item.image_width,
                        "height": item.image_height,
                        "aspect_ratio": item.image_width / item.image_height,
                        "tags": item.tag_string,
                        "rating": item.rating,
                        "is_nsfw": (item.rating != 's'),
                        "md5": item.md5,
                        "preview_url": item.preview_file_url,
                        "sample_url": item.file_url ?? item.large_file_url,
                        "file_url": item.large_file_url,
                        "file_ext": item.file_ext,
                        "source": getWorkingImageSource(item.source) ?? item.file_url,
                    }
                })
            }
        },
        "gelbooru": {
            "name": "Gelbooru",
            "url": "https://gelbooru.com",
            "api": "https://gelbooru.com/index.php?page=dapi&s=post&q=index&json=1",
            "listAccess": ["post"],
            "mapFunc": (response) => {
                return response.map(item => {
                    return {
                        "id": item.id,
                        "width": item.width,
                        "height": item.height,
                        "aspect_ratio": item.width / item.height,
                        "tags": item.tags,
                        "rating": item.rating.replace('general', 's').charAt(0),
                        "is_nsfw": (item.rating != 's'),
                        "md5": item.md5,
                        "preview_url": item.preview_url,
                        "sample_url": item.sample_url ?? item.file_url,
                        "file_url": item.file_url,
                        "file_ext": item.file_url.split('.').pop(),
                        "source": getWorkingImageSource(item.source) ?? item.file_url,
                    }
                })
            }
        },
        "waifu.im": {
            "name": "waifu.im",
            "url": "https://waifu.im",
            "api": "https://api.waifu.im/search",
            "listAccess": ["images"],
            "mapFunc": (response) => {
                return response.map(item => {
                    return {
                        "id": item.image_id,
                        "width": item.width,
                        "height": item.height,
                        "aspect_ratio": item.width / item.height,
                        "tags": item.tags.map(tag => {return tag.name}).join(" "),
                        "rating": item.is_nsfw ? "e" : "s",
                        "is_nsfw": item.is_nsfw,
                        "md5": item.md5,
                        "preview_url": item.sample_url ?? item.url, // preview_url just says access denied (maybe i fucked up and sent too many requests idk)
                        "sample_url": item.url,
                        "file_url": item.url,
                        "file_ext": item.extension,
                        "source": getWorkingImageSource(item.source) ?? item.url,
                    }
                })
            }
        },
    }
    
    property var currentProvider: ConfigOptions.sidebar.booru.defaultProvider
    
    function setProvider(provider) {
        if (providerList.indexOf(provider) !== -1) {
            currentProvider = provider
            root.addSystemMessage(qsTr("Provider set to ") + providers[provider].name
                + (provider == "zerochan" ? qsTr(". Notes for Zerochan:\n- You must enter a color\n- Set your zerochan username in `sidebar.booru.zerochan.username` config option. You [might be banned for not doing so](https://www.zerochan.net/api#:~:text=The%20request%20may%20still%20be%20completed%20successfully%20without%20this%20custom%20header%2C%20but%20your%20project%20may%20be%20banned%20for%20being%20anonymous.)!") : ""))
        } else {
            console.log("[Booru] Invalid provider: " + provider)
            root.addSystemMessage(qsTr("Invalid provider. Supported providers: \n- ") + providerList.join("\n- "))
        }
    }

    function clearResponses() {
        responses = []
    }

    function addSystemMessage(message) {
        responses = [...responses, {
            "provider": "system",
            "tags": [],
            "page": -1,
            "images": [],
            "message": `${message}`
        }]
    }

    function constructRequestUrl(tags, nsfw=true, limit=20, page=1) {
        var provider = providers[currentProvider]
        var baseUrl = provider.api
        var tagString = tags.join(" ")
        if (!nsfw && !(["zerochan", "waifu.im"].includes(currentProvider))) {
            tagString += " rating:safe"
        }
        var params = []
        // Tags & limit
        if (currentProvider === "zerochan") {
            params.push("c=" + tagString) // zerochan doesn't have search in api, so we use color
            params.push("l=" + limit)
            params.push("s=" + "fav")
            params.push("t=" + 1)
            params.push("p=" + page)
        }
        else if (currentProvider === "waifu.im") {
            var tagsArray = tagString.split(" ");
            tagsArray.forEach(tag => {
                params.push("included_tags=" + encodeURIComponent(tag));
            });
            params.push("limit=" + Math.min(limit, 30)) // Only admin can do > 30
            params.push("is_nsfw=" + (nsfw ? "null" : "false")) // null is random
        }
        else {
            params.push("tags=" + encodeURIComponent(tagString))
            params.push("limit=" + limit)
            if (currentProvider == "gelbooru") {
                params.push("pid=" + page)
            }
            else {
                params.push("page=" + page)
            }
        }
        var url = baseUrl
        if (baseUrl.indexOf("?") === -1) {
            url += "?" + params.join("&")
        } else {
            url += "&" + params.join("&")
        }
        return url
    }

    function makeRequest(tags, nsfw=false, limit=20, page=1) {
        var url = constructRequestUrl(tags, nsfw, limit, page)
        console.log("[Booru] Making request to " + url)

        var xhr = new XMLHttpRequest()
        xhr.open("GET", url)
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                try {
                    // console.log("[Booru] Raw response length: " + xhr.responseText.length)
                    // console.log("[Booru] Raw response: " + xhr.responseText)
                    var response = JSON.parse(xhr.responseText)

                    // Access nested properties based on listAccess
                    var accessList = providers[currentProvider].listAccess
                    for (var i = 0; i < accessList.length; ++i) {
                        // console.log("[Booru] Accessing property: " + accessList[i])
                        // console.log("[Booru] Current response: " + JSON.stringify(response))
                        if (response && response.hasOwnProperty(accessList[i])) {
                            response = response[accessList[i]]
                        } else {
                            break
                        }
                    }
                    response = providers[currentProvider].mapFunc(response)
                    // console.log("[Booru] Scoped & mapped response: " + JSON.stringify(response))
                    root.responses = [...root.responses, {
                        "provider": currentProvider,
                        "tags": tags,
                        "page": page,
                        "images": response,
                        "message": response.length > 0 ? "" : root.failMessage
                    }]
                    
                } catch (e) {
                    console.log("[Booru] Failed to parse response: " + e)
                    root.responses = [...root.responses, {
                        "provider": currentProvider,
                        "tags": tags,
                        "page": page,
                        "images": [],
                        "message": root.failMessage
                    }]
                }
            }
            else if (xhr.readyState === XMLHttpRequest.DONE) {
                console.log("[Booru] Request failed with status: " + xhr.status)
            }
        }

        try {
            // Required for danbooru
            if (currentProvider == "danbooru") {
                xhr.setRequestHeader("User-Agent", defaultUserAgent)
            }
            else if (currentProvider == "zerochan") {
                const userAgent = ConfigOptions.sidebar.booru.zerochan.username ? `Desktop sidebar booru viewer - ${ConfigOptions.sidebar.booru.zerochan.username}` : defaultUserAgent
                console.log("Setting User-Agent for zerochan: " + userAgent)
                xhr.setRequestHeader("User-Agent", userAgent)
            }
            xhr.send()
        } catch (error) {
            console.log("Could not set User-Agent:", error)
        } 
    }
}

