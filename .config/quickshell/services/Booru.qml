pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell;
import Quickshell.Io;
import Qt.labs.platform
import QtQuick;

Singleton {
    id: root

    property var getWorkingImageSource: (url) => {
        if (url.includes('pximg.net')) {
            return `https://www.pixiv.net/en/artworks/${url.substring(url.lastIndexOf('/') + 1).replace(/_p\d+\.(png|jpg|jpeg|gif)$/, '')}`;
        }
        return url;
    }

    property var providerList: ["yandere", "konachan", "danbooru", "gelbooru"]
    property var providers: {
        "yandere": {
            "name": "yande.re",
            "url": "https://yande.re",
            "api": "https://yande.re/post.json",
            "listAccess": [],
            "mapFunc": (response) => {
                return response.map(item => {
                    return {
                        "id": item.id,
                        "aspect_ratio": item.width / item.height,
                        "tags": item.tags,
                        "rating": item.rating,
                        "is_nsfw": (item.rating != 's'),
                        "md5": item.md5,
                        "preview_url": item.preview_url,
                        "sample_url": item.sample_url ?? item.file_url,
                        "file_url": item.file_url,
                        "file_ext": item.file_ext,
                        "source": getWorkingImageSource(item.source),
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
                        "aspect_ratio": item.width / item.height,
                        "tags": item.tags,
                        "rating": item.rating,
                        "is_nsfw": (item.rating != 's'),
                        "md5": item.md5,
                        "preview_url": item.preview_url,
                        "sample_url": item.sample_url ?? item.file_url,
                        "file_url": item.file_url,
                        "file_ext": item.file_ext,
                        "source": getWorkingImageSource(item.source),
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
                        "aspect_ratio": item.image_width / item.image_height,
                        "tags": item.tag_string,
                        "rating": item.rating,
                        "is_nsfw": (item.rating != 's'),
                        "md5": item.md5,
                        "preview_url": item.preview_file_url,
                        "sample_url": item.file_url ?? item.large_file_url,
                        "file_url": item.large_file_url,
                        "file_ext": item.file_ext,
                        "source": getWorkingImageSource(item.source),
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
                        "aspect_ratio": item.width / item.height,
                        "tags": item.tags,
                        "rating": item.rating.replace('general', 's').charAt(0),
                        "is_nsfw": (item.rating != 's'),
                        "md5": item.md5,
                        "preview_url": item.preview_url,
                        "sample_url": item.sample_url ?? item.file_url,
                        "file_url": item.file_url,
                        "file_ext": item.file_url.split('.').pop(),
                        "source": getWorkingImageSource(item.source),
                    }
                })
            }
        }
    }
    property var responses: []
    onResponsesChanged: {
        console.log("[Booru] Responses changed: " + JSON.stringify(responses))
    }
    property var currentProvider: "yandere"
    
    function setProvider(provider) {
        if (providerList.indexOf(provider) !== -1) {
            currentProvider = provider
        } else {
            console.log("[Booru] Invalid provider: " + provider)
        }
    }

    function constructRequestUrl(tags, nsfw=true, limit=20) {
        var provider = providers[currentProvider]
        var baseUrl = provider.api
        var tagString = tags.join(" ")
        if (!nsfw) {
            tagString += " rating:safe"
        }
        var params = []
        // Danbooru, Yandere, Konachan: tags & limit
        if (currentProvider === "danbooru" || currentProvider === "yandere" || currentProvider === "konachan") {
            params.push("tags=" + encodeURIComponent(tagString))
            params.push("limit=" + limit)
        }
        var url = baseUrl
        if (baseUrl.indexOf("?") === -1) {
            url += "?" + params.join("&")
        } else {
            url += "&" + params.join("&")
        }
        return url
    }

    function makeRequest(tags, nsfw=true, limit=20) {
        var url = constructRequestUrl(tags, nsfw, limit)
        console.log("[Booru] Making request to " + url)

        var xhr = new XMLHttpRequest()
        xhr.open("GET", url)
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                try {
                    // console.log("[Booru] Raw response length: " + xhr.responseText.length)
                    var response = JSON.parse(xhr.responseText)

                    // Access nested properties based on listAccess
                    var accessList = providers[currentProvider].listAccess
                    for (var i = 0; i < accessList.length; ++i) {
                        if (response && response.hasOwnProperty(accessList[i])) {
                            response = response[accessList[i]]
                        } else {
                            break
                        }
                    }
                    response = providers[currentProvider].mapFunc(response)
                    // console.log("[Booru] Scoped & mapped response: " + JSON.stringify(response))
                    var newResponses = root.responses.slice() // make a shallow copy
                    newResponses.push(response)
                    root.responses = newResponses
                    
                } catch (e) {
                    console.log("[Booru] Failed to parse response: " + e)
                }
            }
            else if (xhr.readyState === XMLHttpRequest.DONE) {
                console.log("[Booru] Request failed with status: " + xhr.status)
            }
        }

        try {
            // Required for danbooru
            xhr.setRequestHeader("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36")
        } catch (e) {
            console.log("Could not set User-Agent:", e)
        }
        xhr.send()    
    }
}

