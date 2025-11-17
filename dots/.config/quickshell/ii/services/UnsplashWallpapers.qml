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
    property Component unsplashResponseDataComponent: BooruResponseData {}  
  
    signal tagSuggestion(string query, var suggestions)  
    signal responseFinished()  
  
    property string unsplashApiToken: Config.options.unsplash?.apiKey ?? ""  
    property string failMessage: Translation.tr("That didn't work. Tips:\n- Check your search query\n- Try different keywords\n- Check your API key under settings")  
    property var responses: []  
    property int runningRequests: 0  
  
    readonly property string apiUrl: "https://api.unsplash.com/photos/random"  
    readonly property string tagSearchUrl: "https://api.unsplash.com/search/collections"  
    readonly property string providerName: "Unsplash"  
  
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
  
    function mapResponse(response) {  
        const items = Array.isArray(response) ? response : [response];  
        return items.map(item => {  
            return {  
                "id": item.id,  
                "width": item.width,  
                "height": item.height,  
                "aspect_ratio": item.width / item.height,  
                "tags": item.tags ? item.tags.map(tag => tag.title).join(" ") : (item.alt_description || item.description || "wallpaper"),  
                "rating": "s",  
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
    }  
  
    function mapTagSuggestions(response) {  
        return response.results.slice(0, 10).map(item => {  
            return {  
                "name": item.title.toLowerCase().replace(/\s+/g, '-'),  
                "displayName": item.title,  
                "count": item.total_photos,  
                "description": item.description || ""  
            }  
        })  
    }  
  
    function constructRequestUrl(tags, limit=20) {  
        var tagString = tags.join(" ")  
        var params = []  
          
        if (tagString.trim().length > 0) {  
            params.push("query=" + encodeURIComponent(tagString))  
        }  
        params.push("count=" + Math.min(limit, 30))  
        params.push("orientation=landscape")  
          
        return apiUrl + "?" + params.join("&")  
    }  
  
    function makeRequest(tags, limit=20, page=1) {  
        var url = constructRequestUrl(tags, limit)  
        console.log("[Unsplash] Making request to " + url)  
  
        const newResponse = root.unsplashResponseDataComponent.createObject(null, {  
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
                    let response = JSON.parse(xhr.responseText)  
                    response = root.mapResponse(response)  
                      
                    newResponse.images = response  
                    newResponse.message = response.length > 0 ? "" : root.failMessage  
                      
                } catch (e) {  
                    console.log("[Unsplash] Failed to parse response: " + e)  
                    newResponse.message = root.failMessage  
                } finally {  
                    root.runningRequests--;  
                    root.responses = [...root.responses, newResponse]  
                }  
            }  
            else if (xhr.readyState === XMLHttpRequest.DONE) {  
                console.log("[Unsplash] Request failed with status: " + xhr.status)  
                newResponse.message = root.failMessage  
                root.runningRequests--;  
                root.responses = [...root.responses, newResponse]  
            }  
            root.responseFinished()  
        }  
  
        try {  
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
  
        var url = tagSearchUrl + "?query=" + encodeURIComponent(query) + "&per_page=10"  
  
        var xhr = new XMLHttpRequest()  
        currentTagRequest = xhr  
        xhr.open("GET", url)  
        xhr.onreadystatechange = function() {  
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {  
                currentTagRequest = null  
                try {  
                    var response = JSON.parse(xhr.responseText)  
                    response = root.mapTagSuggestions(response)  
                    root.tagSuggestion(query, response)  
                } catch (e) {  
                    console.log("[Unsplash] Failed to parse tag suggestions: " + e)  
                }  
            }  
            else if (xhr.readyState === XMLHttpRequest.DONE) {  
                console.log("[Unsplash] Tag search failed with status: " + xhr.status)  
            }  
        }  
  
        try {  
            xhr.setRequestHeader("Authorization", "Client-ID " + root.unsplashApiToken)  
            xhr.send()  
        } catch (error) {  
            console.log("Could not set Authorization:", error)  
        }   
    }  
  
    // Compatibility property for UnsplashResponse.qml  
    readonly property var providers: {  
        "system": { "name": Translation.tr("System") },  
        "unsplash": { "name": providerName }  
    }  
}