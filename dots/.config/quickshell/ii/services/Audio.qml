pragma Singleton
pragma ComponentBehavior: Bound
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

/**
 * A nice wrapper for default Pipewire audio sink and source.
 */
Singleton {
    id: root

    // Misc props
    property bool ready: Pipewire.defaultAudioSink?.ready ?? false
    property PwNode sink: Pipewire.defaultAudioSink
    property PwNode source: Pipewire.defaultAudioSource
    readonly property real hardMaxValue: 2.00 // People keep joking about setting volume to 5172% so...
    readonly property int startupAndNotificationVolumePercent: 65
    property string audioTheme: Config.options.sounds.theme
    property real value: sink?.audio.volume ?? 0
    
    function friendlyDeviceName(node) {
        return (node.nickname || node.description || Translation.tr("Unknown"));
    }
    function appNodeDisplayName(node) {
        return (node.properties["application.name"] || node.description || node.name)
    }

    function normalizeStreamTitlePart(s) {
        return (s ?? "").toString().toLowerCase().replace(/\s+/g, " ").trim();
    }

    function appStreamRowTitle(node) {
        const app = root.appNodeDisplayName(node);
        const media = node?.properties?.["media.name"];
        const showApp = Config.options.audio.volumeMixer?.showAppNameWithMedia ?? true;
        if (media === undefined || media === null || String(media).length === 0)
            return app;
        const mediaStr = String(media);
        if (!showApp)
            return mediaStr;
        const hideDup = Config.options.audio.volumeMixer?.hideAppNameWhenSameAsMedia ?? true;
        if (hideDup && root.normalizeStreamTitlePart(app) === root.normalizeStreamTitlePart(mediaStr))
            return mediaStr;
        return `${app} • ${mediaStr}`;
    }

    property var __streamHideKeyCache: ({})

    function streamHideKeyRank(s) {
        if (!s || s.length === 0)
            return 0;
        if (s.startsWith("app:"))
            return 30;
        if (s.startsWith("node:") || s.startsWith("serial:"))
            return 20;
        return 10;
    }

    /** One-shot key from current PipeWire props (may change as metadata arrives). */
    function streamHideKeyFresh(node) {
        if (!node || !node.isStream)
            return "";
        const props = node.properties ?? {};
        const binPath = (props["application.process.binary"] ?? "").toString().trim();
        const appName = (props["application.name"] ?? "").toString().trim();
        if (binPath.length > 0 || appName.length > 0) {
            const base = binPath.split("/").pop().split("\\").pop().toLowerCase();
            return `app:${base}|${appName.toLowerCase()}`;
        }
        const nn = (props["node.name"] || node.name || "").toString().trim();
        if (nn.length > 0)
            return `node:${nn}`;
        const serial = props["object.serial"];
        if (serial !== undefined && serial !== null && String(serial).length > 0)
            return `serial:${String(serial)}`;
        if (node.id !== undefined && node.id !== null)
            return `id:${String(node.id)}`;
        return "";
    }

    /**
     * Stable key for hide rules: never downgrade from a stronger id (e.g. app:) to a weaker
     * transient one (id:) when PipeWire metadata flickers - stops mixer list fighting itself.
     */
    function streamPersistHideKey(node) {
        if (!node || !node.isStream)
            return "";
        const oid = String(node.id);
        const fresh = root.streamHideKeyFresh(node);
        const prev = root.__streamHideKeyCache[oid];
        if (!fresh || fresh.length === 0)
            return prev ?? "";
        if (!prev || prev.length === 0) {
            root.__streamHideKeyCache[oid] = fresh;
            return fresh;
        }
        if (root.streamHideKeyRank(fresh) > root.streamHideKeyRank(prev)) {
            root.__streamHideKeyCache[oid] = fresh;
            return fresh;
        }
        return prev;
    }

    function streamHideKeyInList(key, isSink) {
        if (!key || key.length === 0)
            return false;
        const list = root.hiddenStreamKeyList(isSink);
        for (let i = 0; i < list.length; ++i) {
            if (String(list[i]).trim() === key)
                return true;
        }
        return false;
    }

    /**
     * True if this hidden-list entry applies to the node (handles id vs app key drift).
     * @param includePersistMatch when false, skip persist equality (unless persistKeyOpt is set).
     * @param persistKeyOpt when set, used for persist equality instead of calling streamPersistHideKey() again (stable per filter pass).
     */
    function streamNodeMatchesHiddenKey(node, hiddenKey, includePersistMatch, persistKeyOpt) {
        if (!node)
            return false;
        const h = String(hiddenKey ?? "").trim();
        if (h.length === 0)
            return false;
        const fresh = root.streamHideKeyFresh(node);
        if (h === fresh)
            return true;
        if (h.startsWith("id:") && node.id !== undefined && node.id !== null && h === `id:${String(node.id)}`)
            return true;
        if (h.startsWith("app:")) {
            const pipe = h.indexOf("|");
            if (pipe > 4) {
                const wantBin = h.slice(4, pipe).toLowerCase();
                const wantApp = h.slice(pipe + 1).toLowerCase();
                const props = node.properties ?? {};
                const binPath = (props["application.process.binary"] ?? "").toString().trim();
                const base = binPath.split("/").pop().split("\\").pop().toLowerCase();
                const appName = (props["application.name"] ?? "").toString().trim().toLowerCase();
                if (wantApp.length > 0 && appName === wantApp && (wantBin.length === 0 || base === wantBin))
                    return true;
            }
        }
        if (h.startsWith("node:")) {
            const wantNn = h.slice(5).trim();
            const nn = (node.properties?.["node.name"] || node.name || "").toString().trim();
            if (wantNn.length > 0 && nn === wantNn)
                return true;
        }
        if (h.startsWith("serial:")) {
            const wantS = h.slice(7).trim();
            const ser = (node.properties?.["object.serial"] ?? "").toString().trim();
            if (wantS.length > 0 && ser === wantS)
                return true;
        }
        if (includePersistMatch !== false) {
            const persist = persistKeyOpt !== undefined && persistKeyOpt !== null
                ? persistKeyOpt
                : root.streamPersistHideKey(node);
            return h === persist;
        }
        return false;
    }

    function streamMixerIsHidden(node, isSink, includePersistMatch, persistKeyOpt) {
        const list = root.hiddenStreamKeyList(isSink);
        for (let i = 0; i < list.length; ++i) {
            if (root.streamNodeMatchesHiddenKey(node, list[i], includePersistMatch, persistKeyOpt))
                return true;
        }
        return false;
    }

    function hiddenStreamKeyList(isSink) {
        const vm = Config.options.audio.volumeMixer;
        const raw = isSink ? vm?.hiddenMixerPlaybackStreamKeys : vm?.hiddenMixerRecordStreamKeys;
        if (!raw)
            return [];
        const out = [];
        for (let i = 0; i < raw.length; ++i) {
            const s = String(raw[i] ?? "").trim();
            if (s.length > 0)
                out.push(s);
        }
        return out;
    }

    function mixerAppNodesFiltered(isSink) {
        const nodes = root.appNodes(isSink);
        const out = [];
        for (let i = 0; i < nodes.length; ++i) {
            const n = nodes[i];
            const pk = root.streamPersistHideKey(n);
            if (!root.streamMixerIsHidden(n, isSink, true, pk))
                out.push(n);
        }
        return out;
    }

    function orphanStreamHideKeys(isSink) {
        const hidden = root.hiddenStreamKeyList(isSink);
        const nodes = root.appNodes(isSink);
        return hidden.filter(h => {
            for (let i = 0; i < nodes.length; ++i) {
                if (root.streamNodeMatchesHiddenKey(nodes[i], h, true))
                    return false;
            }
            return true;
        });
    }

    function setStreamHiddenForMixer(node, isSink, hide) {
        const key = root.streamPersistHideKey(node);
        if (!key)
            return;
        let list = [...root.hiddenStreamKeyList(isSink)];
        if (hide) {
            if (!root.streamMixerIsHidden(node, isSink, true, key))
                list.push(key);
        } else {
            list = list.filter(entry => !root.streamNodeMatchesHiddenKey(node, entry, true));
        }
        if (isSink)
            Config.options.audio.volumeMixer.hiddenMixerPlaybackStreamKeys = list;
        else
            Config.options.audio.volumeMixer.hiddenMixerRecordStreamKeys = list;
    }

    function removeStreamHideKey(key, isSink) {
        let list = [...root.hiddenStreamKeyList(isSink)];
        const i = list.indexOf(key);
        if (i < 0)
            return;
        list.splice(i, 1);
        if (isSink)
            Config.options.audio.volumeMixer.hiddenMixerPlaybackStreamKeys = list;
        else
            Config.options.audio.volumeMixer.hiddenMixerRecordStreamKeys = list;
    }

    function mixerDeviceStableId(node) {
        if (!node || node.isStream)
            return "";
        const props = node.properties ?? {};
        const serial = props["object.serial"];
        if (serial !== undefined && serial !== null && String(serial).trim().length > 0)
            return "pwSerial:" + String(serial).trim();
        const nn = (props["node.name"] || node.name || "").toString().trim();
        if (nn.length > 0)
            return "pwNode:" + nn;
        if (node.id !== undefined && node.id !== null)
            return "pwId:" + String(node.id);
        return "";
    }

    /** All hide keys to store for a device so matching survives pwId / serial / node.name drift. */
    function collectDeviceHideKeys(node) {
        if (!node || node.isStream)
            return [];
        const out = [];
        const add = k => {
            const s = (k ?? "").toString().trim();
            if (s.length > 0 && out.indexOf(s) < 0)
                out.push(s);
        };
        add(root.mixerDeviceStableId(node));
        const props = node.properties ?? {};
        const serial = (props["object.serial"] ?? "").toString().trim();
        if (serial.length > 0)
            add("pwSerial:" + serial);
        const nn = (props["node.name"] || node.name || "").toString().trim();
        if (nn.length > 0)
            add("pwNode:" + nn);
        if (node.id !== undefined && node.id !== null)
            add("pwId:" + String(node.id));
        return out;
    }

    function hiddenDeviceKeyList(isSink) {
        const vm = Config.options.audio.volumeMixer;
        let raw = isSink ? vm?.hiddenMixerOutputDeviceKeys : vm?.hiddenMixerInputDeviceKeys;
        if (raw === undefined || raw === null)
            return [];
        let arr = raw;
        if (typeof arr.length === "undefined") {
            try {
                arr = Array.from(raw);
            } catch (e) {
                return [];
            }
        }
        const out = [];
        const len = arr.length;
        for (let i = 0; i < len; ++i) {
            const s = String(arr[i] ?? "").trim();
            if (s.length > 0)
                out.push(s);
        }
        return out;
    }

    function deviceNodeMatchesHiddenKey(node, hiddenKey) {
        if (!node || node.isStream)
            return false;
        const h = String(hiddenKey ?? "").trim();
        if (h.length === 0)
            return false;
        if (h === root.mixerDeviceStableId(node))
            return true;
        const props = node.properties ?? {};
        const serial = (props["object.serial"] ?? "").toString().trim();
        const nn = (props["node.name"] || node.name || "").toString().trim();
        const nid = node.id !== undefined && node.id !== null ? String(node.id) : "";
        if (h.startsWith("pwSerial:")) {
            const want = h.slice(9).trim();
            return want.length > 0 && serial === want;
        }
        if (h.startsWith("pwNode:")) {
            const want = h.slice(7).trim();
            return want.length > 0 && nn === want;
        }
        if (h.startsWith("pwId:")) {
            const want = h.slice(5).trim();
            return want.length > 0 && nid === want;
        }
        return false;
    }

    function deviceMixerIsHidden(node, isSink) {
        if (!node || node.isStream)
            return false;
        const def = isSink ? Pipewire.defaultAudioSink : Pipewire.defaultAudioSource;
        if (def && node.id !== undefined && def.id !== undefined && String(def.id) === String(node.id))
            return false;
        const list = root.hiddenDeviceKeyList(isSink);
        for (let i = 0; i < list.length; ++i) {
            if (root.deviceNodeMatchesHiddenKey(node, list[i]))
                return true;
        }
        return false;
    }

    function mixerDevicesFiltered(isSink) {
        return root.devices(isSink).filter(n => !root.deviceMixerIsHidden(n, isSink));
    }

    function orphanDeviceHideKeys(isSink) {
        const hidden = root.hiddenDeviceKeyList(isSink);
        const nodes = root.devices(isSink);
        return hidden.filter(h => {
            for (let i = 0; i < nodes.length; ++i) {
                if (root.deviceNodeMatchesHiddenKey(nodes[i], h))
                    return false;
            }
            return true;
        });
    }

    function setDeviceHiddenForMixer(node, isSink, hide) {
        const def = isSink ? Pipewire.defaultAudioSink : Pipewire.defaultAudioSource;
        if (def && node.id !== undefined && def.id !== undefined && String(def.id) === String(node.id))
            return;
        let list = [...root.hiddenDeviceKeyList(isSink)];
        if (hide) {
            const merge = root.collectDeviceHideKeys(node);
            if (merge.length === 0)
                return;
            for (let i = 0; i < merge.length; ++i) {
                if (list.indexOf(merge[i]) < 0)
                    list.push(merge[i]);
            }
        } else {
            list = list.filter(entry => !root.deviceNodeMatchesHiddenKey(node, entry));
        }
        if (isSink)
            Config.options.audio.volumeMixer.hiddenMixerOutputDeviceKeys = list;
        else
            Config.options.audio.volumeMixer.hiddenMixerInputDeviceKeys = list;
    }

    function removeDeviceHideKey(key, isSink) {
        let list = [...root.hiddenDeviceKeyList(isSink)];
        const i = list.indexOf(key);
        if (i < 0)
            return;
        list.splice(i, 1);
        if (isSink)
            Config.options.audio.volumeMixer.hiddenMixerOutputDeviceKeys = list;
        else
            Config.options.audio.volumeMixer.hiddenMixerInputDeviceKeys = list;
    }

    // Lists
    function correctType(node, isSink) {
        return (node.isSink === isSink) && node.audio
    }
    function appNodes(isSink) {
        return Pipewire.nodes.values.filter((node) => { // Should be list<PwNode> but it breaks ScriptModel
            return root.correctType(node, isSink) && node.isStream
        })
    }
    function devices(isSink) {
        return Pipewire.nodes.values.filter(node => {
            return root.correctType(node, isSink) && !node.isStream
        })
    }
    readonly property list<var> outputAppNodes: root.appNodes(true)
    readonly property list<var> inputAppNodes: root.appNodes(false)
    readonly property list<var> outputDevices: root.devices(true)
    readonly property list<var> inputDevices: root.devices(false)
    // Touch hidden-key lists so this re-evaluates when settings change (plain call + filter() is not always tracked).
    readonly property list<var> mixerOutputAppNodes: {
        const vm = Config.options.audio.volumeMixer
        const kp = vm.hiddenMixerPlaybackStreamKeys ?? []
        const kr = vm.hiddenMixerRecordStreamKeys ?? []
        const _dep = JSON.stringify(kp) + "|" + JSON.stringify(kr)
        void _dep
        return root.mixerAppNodesFiltered(true)
    }
    readonly property list<var> mixerInputAppNodes: {
        const vm = Config.options.audio.volumeMixer
        const kp = vm.hiddenMixerPlaybackStreamKeys ?? []
        const kr = vm.hiddenMixerRecordStreamKeys ?? []
        const _dep = JSON.stringify(kp) + "|" + JSON.stringify(kr)
        void _dep
        return root.mixerAppNodesFiltered(false)
    }
    readonly property list<var> mixerOutputDevices: {
        const vm = Config.options.audio.volumeMixer
        const ko = vm.hiddenMixerOutputDeviceKeys ?? []
        const ki = vm.hiddenMixerInputDeviceKeys ?? []
        const _dep = JSON.stringify(ko) + "|" + JSON.stringify(ki)
        void _dep
        const _pw = Pipewire.nodes?.values?.length ?? 0
        void _pw
        void Pipewire.defaultAudioSink
        void Pipewire.defaultAudioSource
        return root.mixerDevicesFiltered(true)
    }
    readonly property list<var> mixerInputDevices: {
        const vm = Config.options.audio.volumeMixer
        const ko = vm.hiddenMixerOutputDeviceKeys ?? []
        const ki = vm.hiddenMixerInputDeviceKeys ?? []
        const _dep = JSON.stringify(ko) + "|" + JSON.stringify(ki)
        void _dep
        const _pw = Pipewire.nodes?.values?.length ?? 0
        void _pw
        void Pipewire.defaultAudioSink
        void Pipewire.defaultAudioSource
        return root.mixerDevicesFiltered(false)
    }

    // Signals
    signal sinkProtectionTriggered(string reason);

    // Controls
    function toggleMute() {
        Audio.sink.audio.muted = !Audio.sink.audio.muted
    }

    function toggleMicMute() {
        Audio.source.audio.muted = !Audio.source.audio.muted
    }

    function incrementVolume() {
        const currentVolume = Audio.value;
        const step = currentVolume < 0.1 ? 0.01 : 0.02 || 0.2;
        Audio.sink.audio.volume = Math.min(1, Audio.sink.audio.volume + step);
    }
    
    function decrementVolume() {
        const currentVolume = Audio.value;
        const step = currentVolume < 0.1 ? 0.01 : 0.02 || 0.2;
        Audio.sink.audio.volume -= step;
    }

    function setDefaultSink(node) {
        Pipewire.preferredDefaultAudioSink = node;
    }

    function setDefaultSource(node) {
        Pipewire.preferredDefaultAudioSource = node;
    }

    // Internals
    PwObjectTracker {
        objects: [sink, source]
    }

    Connections { // Protection against sudden volume changes
        target: sink?.audio ?? null
        property bool lastReady: false
        property real lastVolume: 0
        function onVolumeChanged() {
            if (!Config.options.audio.protection.enable) return;
            const newVolume = sink.audio.volume;
            // when resuming from suspend, we should not write volume to avoid pipewire volume reset issues
            if (isNaN(newVolume) || newVolume === undefined || newVolume === null) {
                lastReady = false;
                lastVolume = 0;
                return;
            }
            if (!lastReady) {
                lastVolume = newVolume;
                lastReady = true;
                return;
            }
            const maxAllowedIncrease = Config.options.audio.protection.maxAllowedIncrease / 100; 
            const maxAllowed = Config.options.audio.protection.maxAllowed / 100;

            if (newVolume - lastVolume > maxAllowedIncrease) {
                sink.audio.volume = lastVolume;
                root.sinkProtectionTriggered(Translation.tr("Illegal increment"));
            } else if (newVolume > maxAllowed || newVolume > root.hardMaxValue) {
                root.sinkProtectionTriggered(Translation.tr("Exceeded max allowed"));
                sink.audio.volume = Math.min(lastVolume, maxAllowed);
            }
            lastVolume = sink.audio.volume;
        }
    }

    function playSystemSound(soundName) {
        const ogaPath = `/usr/share/sounds/${root.audioTheme}/stereo/${soundName}.oga`;
        const oggPath = `/usr/share/sounds/${root.audioTheme}/stereo/${soundName}.ogg`;

        // Try playing .oga first
        let command = [
            "ffplay",
            "-nodisp",
            "-autoexit",
            ogaPath
        ];
        Quickshell.execDetached(command);

        // Also try playing .ogg (ffplay will just fail silently if file doesn't exist)
        command = [
            "ffplay",
            "-nodisp",
            "-autoexit",
            oggPath
        ];
        Quickshell.execDetached(command);
    }

    function expandHomePath(path) {
        if (!path || typeof path !== "string")
            return path;
        const t = path.trim();
        const h = Quickshell.env("HOME");
        if (!h || !t.includes("~/"))
            return t;
        return t.split("~/").join(h + "/");
    }

    /** Normalize config command strings (trim, strip wrapping quotes/backticks, expand ~/). */
    function prepareShellConfigCommand(commandString) {
        let t = String(commandString ?? "").trim();
        if (!t.length)
            return "";
        if (t.length >= 2 && ((t.startsWith("`") && t.endsWith("`")) || (t.startsWith("\"") && t.endsWith("\"")) || (t.startsWith("'") && t.endsWith("'"))))
            t = t.slice(1, -1).trim();
        t = root.expandHomePath(t);
        // Older configs pointed at hypr/hyprland/scripts; this repo’s launcher lives under hypr/ii/scripts.
        t = t.replace(/\/hypr\/hyprland\/scripts\/launch_first_available\.sh/g, "/hypr/ii/scripts/launch_first_available.sh");
        return t;
    }

    /** Launch apps.volumeMixer (pavucontrol helper, etc.), same pattern as other `bash -lc` app launches. */
    function launchConfigurableShellCommand(commandString) {
        const line = root.prepareShellConfigCommand(commandString);
        if (!line.length)
            return;
        Quickshell.execDetached(["bash", "-lc", line]);
    }

    function playFile(path, volumePercent) {
        if (!path || typeof path !== "string" || path.trim().length === 0) return;
        const resolvedPath = root.expandHomePath(path);
        const safeVolume = Math.max(0, Math.min(100, Math.round(
            volumePercent === undefined ? 100 : volumePercent
        )));
        Quickshell.execDetached([
            "ffplay",
            "-nodisp",
            "-autoexit",
            "-loglevel",
            "quiet",
            "-sync",
            "audio",
            "-volume",
            `${safeVolume}`,
            resolvedPath,
        ]);
    }

    function playStartupSound() {
        const enabled = Config.options?.sounds?.startup?.enable ?? true;
        if (!enabled) return;
        const path = Config.options?.sounds?.startup?.path ?? "~/.local/share/sounds/ii/stereo/startup.oga";
        playFile(path, root.startupAndNotificationVolumePercent);
    }

    function playNotificationSound() {
        const enabled = Config.options?.sounds?.notification?.enable ?? true;
        if (!enabled) return;
        const path = Config.options?.sounds?.notification?.path ?? "~/.local/share/sounds/ii/stereo/notify.oga";
        if (notificationSoundProcess.running) return;
        notificationSoundProcess.command = [
            "ffplay",
            "-nodisp",
            "-autoexit",
            "-loglevel",
            "quiet",
            "-sync",
            "audio",
            "-volume",
            `${root.startupAndNotificationVolumePercent}`,
            root.expandHomePath(path),
        ];
        notificationSoundProcess.running = true;
    }

    Process {
        id: notificationSoundProcess
        running: false
        command: []
    }
}
