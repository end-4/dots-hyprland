pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Service for searching and downloading wallpapers from wallhaven.cc
 */
Singleton {
    id: root

    // State
    property bool fetching: false
    property var currentResults: []
    property var currentMeta: ({})
    property string lastError: ""
    property string currentQuery: ""
    property int currentPage: 1
    property int lastPage: 1

    // Search parameters
    property string categories: "111" // general,anime,people (all enabled)
    property string purity: "100" // sfw
    property string sorting: "relevance"
    property string order: "desc"
    property string topRange: "1y" // wider window so toplist (esp. with a color filter) isn't starved
    property string seed: ""
    property string minResolution: ""
    property string ratios: ""
    property string apiKey: ""
    property string colors: "" // wallhaven palette filter, single hex without '#'

    // Wallhaven's fixed searchable palette (hex without '#')
    readonly property var paletteColors: [
        "660000", "990000", "cc0000", "cc3333", "ea4c88", "993399", "663399", "333399",
        "0066cc", "0099cc", "66cccc", "77cc33", "669900", "336600", "666600", "999900",
        "cccc33", "ffff00", "ffcc33", "ff9900", "ff6600", "cc6633", "996633", "663300",
        "000000", "999999", "cccccc", "ffffff", "424153"
    ]

    // Download directory
    readonly property string downloadDirectory: `${FileUtils.trimFileProtocol(Directories.pictures)}/Wallpapers`

    // Signals
    signal searchCompleted(var results, var meta)
    signal searchFailed(string error)
    signal wallpaperDownloaded(string wallpaperId, string localPath)
    readonly property string apiBaseUrl: "https://wallhaven.cc/api/v1"

    Component.onCompleted: {
        loadFromConfig()
    }

    function loadFromConfig() {
        const cfg = Config.options?.wallpaperSelector
        if (!cfg) return
        apiKey = cfg.wallhavenApiKey || ""
        categories = cfg.wallhavenCategories || "111"
        purity = cfg.wallhavenPurity || "100"
        sorting = cfg.wallhavenSorting || "relevance"
        order = cfg.wallhavenOrder || "desc"
        ratios = cfg.wallhavenRatios || ""
        colors = cfg.wallhavenColors || ""
        currentQuery = cfg.wallhavenQuery || ""
    }

    function saveToConfig() {
        const cfg = Config.options?.wallpaperSelector
        if (!cfg) return
        cfg.wallhavenApiKey = apiKey
        cfg.wallhavenCategories = categories
        cfg.wallhavenPurity = purity
        cfg.wallhavenSorting = sorting
        cfg.wallhavenOrder = order
        cfg.wallhavenRatios = ratios
        cfg.wallhavenColors = colors
        cfg.wallhavenQuery = currentQuery
    }

    function search(query, page) {
        if (fetching) return

        fetching = true
        lastError = ""
        currentQuery = query || ""
        currentPage = page || 1

        var url = apiBaseUrl + "/search"
        var params = []

        if (currentQuery){
            params.push("q=" + encodeURIComponent(currentQuery))
        }

        params.push("categories=" + categories)
        var safePurity = (purity === "000") ? "100" : purity
        params.push("purity=" + safePurity)
        params.push("sorting=" + sorting)
        params.push("order=" + order)

        if (sorting === "toplist"){
            params.push("topRange=" + topRange)
        }

        if (sorting === "random" && seed){
            params.push("seed=" + seed)
        }

        if (minResolution){
            params.push("atleast=" + minResolution)
        }

        if (ratios){
            params.push("ratios=" + ratios)
        }

        if (colors){
            params.push("colors=" + colors)
        }

        if (apiKey){
            params.push("apikey=" + apiKey)
        }

        params.push("page=" + currentPage)

        url += "?" + params.join("&")

        console.log("[WallhavenSearch] Searching:", url.replace(/apikey=[^&]+/, "apikey=***"))

        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                fetching = false
                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText)
                        if (response.data && Array.isArray(response.data)) {
                            currentResults = response.data
                            currentMeta = response.meta || {}
                            lastPage = currentMeta.last_page || 1
                            if (currentMeta.seed){
                                seed = currentMeta.seed
                            }
                            console.log("[WallhavenSearch] Search completed:", currentResults.length, "results, page", currentPage, "of", lastPage)
                            searchCompleted(currentResults, currentMeta)
                        } else {
                            lastError = "Invalid API response"
                            console.warn("[WallhavenSearch]", lastError)
                            searchFailed(lastError)
                        }
                    } catch (e) {
                        lastError = "Failed to parse API response: " + e.toString()
                        console.warn("[WallhavenSearch]", lastError)
                        searchFailed(lastError)
                    }
                } else if (xhr.status === 429) {
                    lastError = Translation.tr("Rate limit exceeded (45 requests/minute)")
                    console.warn("[WallhavenSearch]", lastError)
                    searchFailed(lastError)
                } else if (xhr.status === 401) {
                    lastError = Translation.tr("Invalid API Key")
                    console.warn("[WallhavenSearch]", lastError)
                    searchFailed(lastError)
                } else {
                    lastError = "API error: " + xhr.status
                    console.warn("[WallhavenSearch]", lastError)
                    searchFailed(lastError)
                }
            }
        }

        xhr.open("GET", url)
        xhr.send()
    }

    function getWallpaperUrl(wallpaper) {
        if (wallpaper.path){ return wallpaper.path }
        if (wallpaper.id) {
            var idPrefix = wallpaper.id.substring(0, 2)
            return "https://w.wallhaven.cc/full/" + idPrefix + "/wallhaven-" + wallpaper.id + ".jpg"
        }
        return ""
    }

    function getThumbnailUrl(wallpaper, size) {
        // size: "small", "large", "original"
        if (wallpaper.thumbs && wallpaper.thumbs[size]){
            return wallpaper.thumbs[size]
        }
        if (wallpaper.id) {
            var idPrefix = wallpaper.id.substring(0, 2)
            var sizeMap = { "small": "small", "large": "lg", "original": "orig" }
            var sizePath = sizeMap[size] || "lg"
            return "https://th.wallhaven.cc/" + sizePath + "/" + idPrefix + "/" + wallpaper.id + ".jpg"
        }
        return ""
    }

    // Download process
    Process {
        id: downloadProc
        property string localPath: ""
        property var callback: null
        property string wallpaperId: ""
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                console.log("[WallhavenSearch] Wallpaper downloaded:", downloadProc.localPath)
                root.wallpaperDownloaded(downloadProc.wallpaperId, downloadProc.localPath)
                if (downloadProc.callback){
                    downloadProc.callback(true, downloadProc.localPath)
                }
            } else {
                console.warn("[WallhavenSearch] Failed to download wallpaper, exit code:", exitCode)
                if (downloadProc.callback){
                    downloadProc.callback(false, "")
                }
            }
        }
    }

    function downloadWallpaper(wallpaper, callback) {
        var url = getWallpaperUrl(wallpaper)
        if (!url) {
            console.warn("[WallhavenSearch] No URL available for wallpaper", wallpaper.id)
            if (callback) callback(false, "")
            return
        }

        var wallpaperId = wallpaper.id || "unknown"
        var extension = url.split('.').pop() || "jpg"
        var localPath = downloadDirectory + "/wallhaven_" + wallpaperId + "." + extension

        console.log("[WallhavenSearch] Downloading wallpaper", wallpaperId, "to", localPath)

        downloadProc.localPath = localPath
        downloadProc.callback = callback
        downloadProc.wallpaperId = wallpaperId
        downloadProc.command = [
            "bash", "-c",
            `mkdir -p '${downloadDirectory}' && curl -L -s -o '${localPath}' '${url}'`
        ]
        downloadProc.running = true
    }

    // Predefined browse without typing a query (e.g. toplist / latest / random).
    function browse(sortMode) {
        currentQuery = ""
        sorting = sortMode || "toplist"
        if (sortMode === "random") seed = ""
        saveToConfig()
        search("", 1)
    }

    // Toggle a palette-color filter (pass "" to clear) and re-search.
    function setColor(hex) {
        colors = (colors === hex) ? "" : (hex || "")
        saveToConfig()
        search(currentQuery, 1)
    }

    function reset() {
        currentResults = []
        currentMeta = {}
        currentQuery = ""
        currentPage = 1
        lastPage = 1
        seed = ""
        lastError = ""
    }

    function nextPage() {
        if (currentPage < lastPage && !fetching){
            search(currentQuery, currentPage + 1)
        }
    }

    function previousPage() {
        if (currentPage > 1 && !fetching){
            search(currentQuery, currentPage - 1)
        }
    }
}
