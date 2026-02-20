pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import qs.modules.common

Singleton {
    id: root

    readonly property bool enabled: Config.options.bar.homeAssistant.enable
    readonly property string externalConfigPath: {
        const p = (Config.options.bar.homeAssistant.configPath || "").trim();
        return p.length > 0 ? p : `${Directories.shellConfig}/homeassistant.json`;
    }
    property var externalConfig: ({})

    readonly property string rawBaseUrl: {
        const ext = (externalConfig.url || "").trim();
        if (ext.length > 0) return ext;
        return (Config.options.bar.homeAssistant.url || "").trim();
    }
    readonly property string baseUrl: {
        let url = rawBaseUrl.replace(/\/$/, "");
        if (url.length === 0) return "";
        if (!url.includes("://")) {
            url = `https://${url}`;
        }
        return url;
    }
    readonly property string token: {
        const ext = (externalConfig.token || "").trim();
        if (ext.length > 0) return ext;
        return (Config.options.bar.homeAssistant.token || "").trim();
    }
    readonly property int fetchInterval: {
        const ext = Number(externalConfig.fetchInterval || 0);
        if (ext > 0) return ext * 60 * 1000;
        return Config.options.bar.homeAssistant.fetchInterval * 60 * 1000;
    }

    property bool loading: false
    property string lastError: ""
    property string lastRefresh: ""
    property var statesById: ({})

    readonly property var groupMeta: ({
        "cameras": {"title": Translation.tr("Cameras"), "icon": "videocam"},
        "lights": {"title": Translation.tr("Lights"), "icon": "lightbulb"},
        "locks": {"title": Translation.tr("Locks"), "icon": "lock"},
        "covers": {"title": Translation.tr("Covers"), "icon": "garage"},
        "climate": {"title": Translation.tr("Climate"), "icon": "thermostat"},
        "appliances": {"title": Translation.tr("Appliances"), "icon": "kitchen"},
    })

    readonly property list<string> groupOrder: ["cameras", "lights", "locks", "covers", "climate", "appliances"]

    function listForGroup(groupKey) {
        const ext = externalConfig[groupKey];
        if (Array.isArray(ext) && ext.length > 0) return ext;
        return Config.options.bar.homeAssistant[groupKey] || [];
    }

    function configuredGroups() {
        return {
            cameras: listForGroup("cameras"),
            lights: listForGroup("lights"),
            locks: listForGroup("locks"),
            covers: listForGroup("covers"),
            climate: listForGroup("climate"),
            appliances: listForGroup("appliances"),
        };
    }

    function allEntityIds() {
        const groups = configuredGroups();
        const seen = {};
        const ids = [];
        for (let i = 0; i < groupOrder.length; ++i) {
            const key = groupOrder[i];
            const arr = groups[key] || [];
            for (let j = 0; j < arr.length; ++j) {
                const id = (arr[j] || "").trim();
                if (!id || seen[id]) continue;
                seen[id] = true;
                ids.push(id);
            }
        }
        return ids;
    }

    function entitiesForGroup(groupKey) {
        const groups = configuredGroups();
        const ids = groups[groupKey] || [];
        const out = [];
        for (let i = 0; i < ids.length; ++i) {
            const entity = statesById[ids[i]];
            if (entity) out.push(entity);
        }
        return out;
    }

    function configuredCount() {
        return allEntityIds().length;
    }

    function onlineCount() {
        let count = 0;
        const ids = allEntityIds();
        for (let i = 0; i < ids.length; ++i) {
            const state = statesById[ids[i]]?.state;
            if (state && state !== "unavailable" && state !== "unknown") count += 1;
        }
        return count;
    }

    function hasCredentials() {
        return enabled && baseUrl.length > 0 && token.length > 0;
    }

    function authHeader() {
        return `Authorization: Bearer ${token}`;
    }

    function refresh() {
        if (!hasCredentials()) {
            loading = false;
            if (enabled) {
                lastError = Translation.tr("Set Home Assistant URL/token in Shell Settings or %1.").arg(externalConfigPath);
            } else {
                lastError = "";
            }
            return;
        }

        loading = true;
        lastError = "";
        fetchStates.command = [
            "curl", "-sS", "-L",
            "-H", authHeader(),
            "-H", "Accept: application/json",
            `${baseUrl}/api/states`,
        ];
        fetchStates.running = true;
    }

    function stateLabel(entity) {
        if (!entity) return "—";
        const st = entity.state || "unknown";
        if (st === "on") return Translation.tr("On");
        if (st === "off") return Translation.tr("Off");
        if (st === "locked") return Translation.tr("Locked");
        if (st === "unlocked") return Translation.tr("Unlocked");
        if (st === "open") return Translation.tr("Open");
        if (st === "closed") return Translation.tr("Closed");
        return st;
    }

    function entityName(entity) {
        if (!entity) return "";
        return entity.attributes?.friendly_name || entity.entity_id;
    }

    function cameraImageUrl(entity) {
        const pic = entity?.attributes?.entity_picture || "";
        if (!pic) return "";
        if (pic.startsWith("http")) return pic;
        return `${baseUrl}${pic}`;
    }

    function cameraStreamUrl(entity) {
        const eid = entity?.entity_id || "";
        const camToken = entity?.attributes?.access_token || "";
        const proxy = `${baseUrl}/api/camera_proxy_stream/${eid}`;
        if (camToken && camToken.length > 0) {
            return `${proxy}?token=${camToken}`;
        }
        return proxy;
    }

    function openCamera(entity) {
        const url = cameraImageUrl(entity);
        if (url.length > 0) {
            Quickshell.execDetached(["xdg-open", url]);
        }
    }

    function openCameraPip(entity) {
        if (!entity) return;

        // Browser-based stream wrapper avoids browsers downloading raw multipart streams.
        const streamUrl = cameraStreamUrl(entity);
        const title = entityName(entity);
        const html = `<!doctype html>
<html>
    <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width,initial-scale=1" />
        <title>${title}</title>
        <style>
            html, body { margin: 0; padding: 0; background: #000; width: 100%; height: 100%; }
            .wrap { width: 100%; height: 100%; display: flex; align-items: center; justify-content: center; }
            img { width: 100%; height: 100%; object-fit: contain; background: #000; }
        </style>
    </head>
    <body>
        <div class="wrap">
            <img src="${streamUrl}" alt="${title}" />
        </div>
    </body>
</html>`;

        const fileName = `qs-ha-camera-${Date.now()}.html`;
        const filePath = `/tmp/${fileName}`;
        const quotedHtml = html.replace(/'/g, `'"'"'`);
        const quotedPath = filePath.replace(/'/g, `'"'"'`);
        const quotedUrl = (`file://${filePath}`).replace(/'/g, `'"'"'`);
        const openCmd = `set -e; printf '%s' '${quotedHtml}' > '${quotedPath}'; browser="$(xdg-settings get default-web-browser 2>/dev/null || true)"; if [ -n "$browser" ]; then desktop="\${browser%.desktop}"; gtk-launch "$desktop" '${quotedUrl}' >/dev/null 2>&1 && exit 0; fi; xdg-open '${quotedUrl}' >/dev/null 2>&1`;
        Quickshell.execDetached(["sh", "-lc", openCmd]);
    }

    function hasDimming(entity) {
        if (!entity) return false;
        const attrs = entity.attributes || {};
        if (typeof attrs.brightness === "number") return true;
        if (typeof attrs.brightness_pct === "number") return true;

        const modes = attrs.supported_color_modes;
        if (Array.isArray(modes)) {
            const rich = ["brightness", "color_temp", "xy", "hs", "rgb", "rgbw", "rgbww", "white"];
            for (let i = 0; i < rich.length; ++i) {
                if (modes.indexOf(rich[i]) >= 0) return true;
            }
        }
        return false;
    }

    function brightnessPct(entity) {
        if (!entity) return 0;
        const attrs = entity.attributes || {};
        if (typeof attrs.brightness_pct === "number") {
            return Math.min(100, Math.max(0, attrs.brightness_pct));
        }
        if (typeof attrs.brightness === "number") {
            return Math.round(Math.min(255, Math.max(0, attrs.brightness)) * 100 / 255);
        }
        return entity.state === "on" ? 100 : 0;
    }

    function setBrightnessPct(entity, pct) {
        if (!entity) return;
        const id = entity.entity_id;
        const domain = id.split(".")[0];
        const clamped = Math.round(Math.min(100, Math.max(1, pct)));
        const payload = {"entity_id": id, "brightness_pct": clamped};

        if (domain === "light") {
            callService("light", "turn_on", payload);
            return;
        }

        // Generic fallback for dimmable entities exposed as switches.
        callService("homeassistant", "turn_on", payload);
    }

    function toggleEntity(entity) {
        if (!entity) return;
        const id = entity.entity_id;
        const domain = id.split(".")[0];
        const st = entity.state || "unknown";

        if (domain === "light" || domain === "switch" || domain === "fan") {
            const service = st === "on" ? "turn_off" : "turn_on";
            callService(domain, service, {"entity_id": id});
            return;
        }

        if (domain === "lock") {
            const service = st === "locked" ? "unlock" : "lock";
            callService("lock", service, {"entity_id": id});
            return;
        }

        if (domain === "cover") {
            const service = (st === "open" || st === "opening") ? "close_cover" : "open_cover";
            callService("cover", service, {"entity_id": id});
            return;
        }

        if (domain === "climate") {
            const hvac = entity.attributes?.hvac_mode || st;
            const newMode = hvac === "off" ? "heat" : "off";
            callService("climate", "set_hvac_mode", {"entity_id": id, "hvac_mode": newMode});
            return;
        }

        if (domain === "vacuum") {
            const service = st === "cleaning" ? "return_to_base" : "start";
            callService("vacuum", service, {"entity_id": id});
            return;
        }

        callService("homeassistant", "toggle", {"entity_id": id});
    }

    function callService(domain, service, payload) {
        if (!hasCredentials()) return;

        const body = JSON.stringify(payload || {});
        serviceCall.command = [
            "curl", "-sS", "-L", "-X", "POST",
            "-H", authHeader(),
            "-H", "Content-Type: application/json",
            "-H", "Accept: application/json",
            "-d", body,
            `${baseUrl}/api/services/${domain}/${service}`,
        ];
        serviceCall.running = true;
    }

    Process {
        id: fetchStates
        command: ["curl", "-sS", "http://localhost"]

        stdout: StdioCollector {
            onStreamFinished: {
                root.loading = false;
                if (!text || text.length === 0) {
                    root.lastError = Translation.tr("No response from Home Assistant.");
                    return;
                }

                try {
                    const parsed = JSON.parse(text);
                    if (!Array.isArray(parsed)) {
                        const apiMsg = parsed?.message || parsed?.error || "";
                        if (apiMsg.length > 0) {
                            root.lastError = apiMsg;
                        } else {
                            root.lastError = Translation.tr("Unexpected Home Assistant response.");
                        }
                        return;
                    }
                    const ids = root.allEntityIds();
                    const selected = {};
                    for (let i = 0; i < ids.length; ++i) {
                        selected[ids[i]] = true;
                    }

                    const map = {};
                    for (let i = 0; i < parsed.length; ++i) {
                        const entity = parsed[i];
                        const id = entity.entity_id;
                        if (selected[id]) {
                            map[id] = entity;
                        }
                    }

                    root.statesById = map;
                    root.lastError = "";
                    root.lastRefresh = DateTime.time + " • " + DateTime.date;
                } catch (e) {
                    root.lastError = Translation.tr("Failed parsing output from Home Assistant.");
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text && text.length > 0) {
                    root.loading = false;
                    root.lastError = text.trim();
                }
            }
        }
    }

    FileView {
        id: externalConfigFile
        path: root.externalConfigPath
        watchChanges: true

        onFileChanged: reload()

        onLoaded: {
            try {
                const text = externalConfigFile.text().trim();
                root.externalConfig = text.length > 0 ? JSON.parse(text) : {};
            } catch (e) {
                root.externalConfig = {};
                root.lastError = Translation.tr("Failed parsing external Home Assistant config: %1").arg(root.externalConfigPath);
            }
        }

        onLoadFailed: error => {
            if (error == FileViewError.FileNotFound) {
                root.externalConfig = {};
                return;
            }
            root.externalConfig = {};
        }
    }

    Process {
        id: serviceCall
        command: ["curl", "-sS", "http://localhost"]

        onExited: {
            Qt.callLater(() => root.refresh());
        }
    }

    Timer {
        running: root.enabled
        repeat: true
        interval: root.fetchInterval
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    onEnabledChanged: {
        if (enabled) refresh();
    }

    onBaseUrlChanged: {
        if (enabled) refresh();
    }

    onTokenChanged: {
        if (enabled) refresh();
    }

    onExternalConfigPathChanged: {
        externalConfigFile.reload();
    }
}
