pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.services
import Quickshell;
import QtQuick;

/**
 * A service for interacting with Unsplash API.
 */
Singleton {
    id: root
    property Component booruResponseDataComponent: BooruResponseData {}

    signal tagSuggestion(string query, var suggestions)
    signal responseFinished()

    // TODO: Mover el API token a Config
    property string unsplashApiToken: Config.options.unsplash?.apiKey ?? ""

    
    property string failMessage: Translation.tr("That didn't work. Tips:\n- Check your search query\n- Try different keywords\n- Check your API key under settings")
    property var responses: []
    property int runningRequests: 0
    property var defaultUserAgent: Config.options?.networking?.userAgent || "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36"
    property var providerList: ["unsplash"]
    property var providers: {
        "system": { "name": Translation.tr("System") },
        "unsplash": {
            "name": "Unsplash",
            "url": "https://unsplash.com",
            "api": "https://api.unsplash.com/photos/random",
            "description": Translation.tr("High quality photos from Unsplash"),
            "mapFunc": (response) => {
                // Unsplash devuelve un objeto si es 1 foto, o array si son varias
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
        }
    }
    property var currentProvider: "unsplash" // Siempre Unsplash

    function getWorkingImageSource(url) {
        return url;
    }
    
    function setProvider(provider) {
        // No hace nada, siempre es Unsplash
        root.addSystemMessage(Translation.tr("Using Unsplash API"))
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
        var tagString = tags.join(" ")
        
        var params = []
        
        // Query de búsqueda
        if (tagString.trim().length > 0) {
            params.push("query=" + encodeURIComponent(tagString))
        }
        
        // Número de fotos (Unsplash permite hasta 30 en random)
        params.push("count=" + Math.min(limit, 30))
        
        // Orientación landscape para wallpapers
        params.push("orientation=landscape")
        
        url += "?" + params.join("&")
        return url
    }

    function makeRequest(tags, nsfw=false, limit=20, page=1) {
        var url = constructRequestUrl(tags, nsfw, limit, page)
        console.log("[Booru] Making request to " + url)

        const newResponse = root.booruResponseDataComponent.createObject(null, {
            "provider": "unsplash",
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
                    console.log("[Booru] Failed to parse response: " + e)
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

        try {
            // Header de autorización para Unsplash
            xhr.setRequestHeader("Authorization", "Client-ID " + root.unsplashApiToken)
            root.runningRequests++;
            xhr.send()
        } catch (error) {
            console.log("Could not set Authorization:", error)
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
        
        // Buscar colecciones relacionadas con el query
        var url = provider.tagSearchTemplate + "?query=" + encodeURIComponent(query) + "&per_page=10"

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
                    console.log("[Booru] Failed to parse tag suggestions: " + e)
                }
            }
            else if (xhr.readyState === XMLHttpRequest.DONE) {
                console.log("[Booru] Tag search failed with status: " + xhr.status)
            }
        }

        try {
            xhr.setRequestHeader("Authorization", "Client-ID " + root.unsplashApiToken)
            xhr.send()
        } catch (error) {
            console.log("Could not set Authorization:", error)
        } 
    }
}