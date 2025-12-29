pragma Singleton  
pragma ComponentBehavior: Bound  
  
import qs.modules.common  
import qs.services  
import Quickshell;  
import QtQuick;  
  
/**  
 * A service for interacting with wallpaper APIs (Unsplash and Wallhaven).  
 */  
Singleton {  
    id: root  
    property Component unsplashResponseDataComponent: BooruResponseData {}  
  
    signal tagSuggestion(string query, var suggestions)  
    signal responseFinished()  
  
    property string unsplashApiToken: Config.options.unsplash?.apiKey ?? ""  
    property string wallhavenApiToken: Config.options.wallhaven?.apiKey ?? ""  
    property string failMessage: Translation.tr("That didn't work. Tips:\n- Check your search query\n- Try different keywords\n- Check your API key under settings")  
    property var responses: []  
    property int runningRequests: 0  
    property var providerList: ["unsplash", "wallhaven"]  
    property var currentProvider: Persistent.states.wallpapers?.provider ?? "unsplash"  
      
    property var providers: {  
        "system": { "name": Translation.tr("System") },  
        "unsplash": {  
            "name": "Unsplash",  
            "url": "https://unsplash.com",  
            "api": "https://api.unsplash.com/photos/random",  
            "description": Translation.tr("High quality photos from Unsplash"),  
            "mapFunc": (response) => {  
                const items = Array.isArray(response) ? response : [response];  
                return items.map(item => {  
                    return {  
                        "id": item.id,  
                        "width": item.width,  
                        "height": item.height,  
                        "aspect_ratio": item.width / item.height,  
                        "tags": item.tags ? item.tags.map(tag => tag.title).join(" ") : (item.alt_description || item.description || "wallpaper"),  
                        "rating": "s",  
                        "is_nsfw": false,  
                        "md5": item.id,  
                        "preview_url": item.urls.full,  
                        "sample_url": item.urls.full,  
                        "file_url": item.urls.full,  
                        "file_ext": "jpg",  
                        "source": item.links.html,  
                        "author": item.user.name,  
                        "author_url": item.user.links.html  
                    }  
                })  
            },  
            "tagSearchTemplate": "https://api.unsplash.com/search/collections",  
            "tagMapFunc": (response) => {  
                return response.results.slice(0, 10).map(item => {  
                    return {  
                        "name": item.title.toLowerCase().replace(/\s+/g, '-'),  
                        "displayName": item.title,  
                        "count": item.total_photos,  
                        "description": item.description || ""  
                    }  
                })  
            }  
        },  
        "wallhaven": {  
            "name": "Wallhaven",  
            "url": "https://wallhaven.cc",  
            "api": "https://wallhaven.cc/api/v1/search",  
            "description": Translation.tr("Wallpapers | Advanced search with ratios, resolutions, categories, sorting"),  
            "mapFunc": (response) => {  
                console.log("[Wallpapers] Wallhaven response structure: " + JSON.stringify(Object.keys(response)))  
                if (!response.data) {  
                    console.log("[Wallpapers] Wallhaven response has no data field")  
                    return [];  
                }  
                if (!Array.isArray(response.data)) {  
                    console.log("[Wallpapers] Wallhaven response.data is not an array: " + typeof response.data)  
                    return [];  
                }  
                console.log("[Wallpapers] Wallhaven found " + response.data.length + " items")  
                response = response.data  
                return response.map(item => {  
                    return {  
                        "id": item.id,  
                        "width": item.dimension_x || 1920,  
                        "height": item.dimension_y || 1080,  
                        "aspect_ratio": (item.dimension_x || 1920) / (item.dimension_y || 1080),  
                        "tags": item.tags && Array.isArray(item.tags) ? item.tags.map(tag => tag.name).join(" ") : "",  
                        "rating": item.purity === 'sfw' ? 's' : item.purity === 'sketchy' ? 'q' : 'e',  
                        "is_nsfw": item.purity !== 'sfw',  
                        "md5": item.id,  
                        "preview_url": item.thumbs && item.thumbs.small ? item.thumbs.small : item.path,  
                        "sample_url": item.thumbs && item.thumbs.large ? item.thumbs.large : item.path,  
                        "file_url": item.path,  
                        "file_ext": item.file_type ? item.file_type.split('/')[1] : 'jpg',  
                        "source": item.source || "",  
                    }  
                })  
            },  
            "tagSearchTemplate": "https://wallhaven.cc/api/v1/search",  
            "tagMapFunc": (response) => {  
                if (!response.data) return [];  
                return response.data.slice(0, 10).map(item => {  
                    return {  
                        "name": item.tags && item.tags.length > 0 ? item.tags[0].name : "",  
                        "count": ""  
                    }  
                })  
            }  
        }  
    }  
  
    function setProvider(provider) {  
        provider = provider.toLowerCase()  
        if (providerList.indexOf(provider) !== -1) {  
            Persistent.states.wallpapers = Persistent.states.wallpapers || {}  
            Persistent.states.wallpapers.provider = provider  
            root.addSystemMessage(Translation.tr("Provider set to ") + providers[provider].name)  
        } else {  
            root.addSystemMessage(Translation.tr("Invalid API provider. Supported: \n- ") + providerList.join("\n- "))  
        }  
    }  
  
    function clearResponses() {  
        responses = []  
    }  
  
    function addSystemMessage(message) {  
        responses = [...responses, root.unsplashResponseDataComponent.createObject(null, {  
            "provider": "system",  
            "tags": [],  
            "page": -1,  
            "images": [],  
            "message": message  
        })]  
    }  
  
    function constructRequestUrl(tags, limit=20, page=1) {  
        var provider = providers[currentProvider]  
        var baseUrl = provider.api  
        var url = baseUrl  
        var tagString = tags.join(" ")  
        var params = []  
          
        if (currentProvider === "unsplash") {  
            if (tagString.trim().length > 0) {  
                params.push("query=" + encodeURIComponent(tagString))  
            }  
            params.push("count=" + Math.min(limit, 30))  
            params.push("orientation=landscape")  
        }  
        else if (currentProvider === "wallhaven") {  
            if (tagString.trim().length > 0) {  
                params.push("q=" + encodeURIComponent(tagString))  
            }  
            params.push("categories=111")  // General, Anime, People  
            params.push("purity=100")      // SFW only by default  
            params.push("sorting=relevance")  
            params.push("page=" + page)  
        }  
          
        if (baseUrl.indexOf("?") === -1) {  
            url += "?" + params.join("&")  
        } else {  
            url += "&" + params.join("&")  
        }  
        return url  
    }
  
    function makeRequest(tags, limit=20, page=1) {  
        var url = constructRequestUrl(tags, limit, page)  
        console.log("[Wallpapers] Making request to " + url)  
  
        const newResponse = root.unsplashResponseDataComponent.createObject(null, {  
            "provider": currentProvider,  
            "tags": tags,  
            "page": page,  
            "images": [],  
            "message": ""  
        })  
  
        var xhr = new XMLHttpRequest()  
        xhr.open("GET", url)  
        xhr.onreadystatechange = function() {  
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {  
                try {  
                    const provider = providers[currentProvider]  
                    let response = JSON.parse(xhr.responseText)  
                    response = provider.mapFunc(response)  
                      
                    newResponse.images = response  
                    newResponse.message = response.length > 0 ? "" : root.failMessage  
                      
                } catch (e) {  
                    console.log("[Wallpapers] Failed to parse response: " + e)  
                    newResponse.message = root.failMessage  
                } finally {  
                    root.runningRequests--;  
                    root.responses = [...root.responses, newResponse]  
                }  
            }  
            else if (xhr.readyState === XMLHttpRequest.DONE) {  
                console.log("[Wallpapers] Request failed with status: " + xhr.status)  
                newResponse.message = root.failMessage  
                root.runningRequests--;  
                root.responses = [...root.responses, newResponse]  
            }  
            root.responseFinished()  
        }  
  
        try {  
            if (currentProvider === "unsplash") {  
                xhr.setRequestHeader("Authorization", "Client-ID " + root.unsplashApiToken)  
            } else if (currentProvider === "wallhaven" && root.wallhavenApiToken) {  
                xhr.setRequestHeader("X-API-Key", root.wallhavenApiToken)  
            }  
            root.runningRequests++;  
            xhr.send()  
        } catch (error) {  
            console.log("Could not set headers:", error)  
        }   
    }  
  
    property var currentTagRequest: null  
    function triggerTagSearch(query) {  
        if (currentTagRequest) {  
            currentTagRequest.abort();  
        }  
  
        var provider = providers[currentProvider]  
        if (!provider.tagSearchTemplate) {  
            return  
        }  
          
        var url = provider.tagSearchTemplate  
        if (currentProvider === "unsplash") {  
            url += "?query=" + encodeURIComponent(query) + "&per_page=10"  
        } else if (currentProvider === "wallhaven") {  
            url += "?q=" + encodeURIComponent(query)  
        }  
  
        var xhr = new XMLHttpRequest()  
        currentTagRequest = xhr  
        xhr.open("GET", url)  
        xhr.onreadystatechange = function() {  
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {  
                currentTagRequest = null  
                try {  
                    var response = JSON.parse(xhr.responseText)  
                    response = provider.tagMapFunc(response)  
                    root.tagSuggestion(query, response)  
                } catch (e) {  
                    console.log("[Wallpapers] Failed to parse tag suggestions: " + e)  
                }  
            }  
            else if (xhr.readyState === XMLHttpRequest.DONE) {  
                console.log("[Wallpapers] Tag search failed with status: " + xhr.status)  
            }  
        }  
  
        try {  
            if (currentProvider === "unsplash") {  
                xhr.setRequestHeader("Authorization", "Client-ID " + root.unsplashApiToken)  
            } else if (currentProvider === "wallhaven" && root.wallhavenApiToken) {  
                xhr.setRequestHeader("X-API-Key", root.wallhavenApiToken)  
            }  
            xhr.send()  
        } catch (error) {  
            console.log("Could not set headers:", error)  
        }   
    }  
}