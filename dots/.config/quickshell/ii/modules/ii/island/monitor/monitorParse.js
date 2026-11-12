// Pure parsers for the System Monitor. Top-level declarations only, no pragmas:
// loaded both by QML (as a JS library) and by node:vm in the tests.

// nvidia-smi --query-gpu=name,utilization.gpu,memory.used,memory.total,temperature.gpu
//            --format=csv,noheader,nounits
// Returns null for any failure text or for non-numeric fields.
function parseNvidiaSmi(text) {
    var line = String(text || "").trim();
    if (line.length === 0) return null;
    var parts = line.split(",");
    if (parts.length < 5) return null;
    var n = parts.length;
    var tempC = Number(parts[n - 1].trim());
    var memTotal = Number(parts[n - 2].trim());
    var memUsed = Number(parts[n - 3].trim());
    var util = Number(parts[n - 4].trim());
    var name = parts.slice(0, n - 4).join(",").trim();
    if (name.length === 0) return null;
    if (parts[n - 4].trim() === "" || parts[n - 3].trim() === "" ||
        parts[n - 2].trim() === "" || parts[n - 1].trim() === "") return null;
    if (!isFinite(util) || !isFinite(memUsed) || !isFinite(memTotal) || !isFinite(tempC)) return null;
    return { name: name, util: util, memUsedMiB: memUsed, memTotalMiB: memTotal, tempC: tempC };
}

// ps -eo comm,%cpu --sort=-%cpu --no-headers
// The CPU number is taken from the end of each line so names with spaces survive.
function parsePs(text, n) {
    var out = [];
    var lines = String(text || "").split("\n");
    for (var i = 0; i < lines.length && out.length < n; i++) {
        var line = lines[i].trim();
        if (line.length === 0) continue;
        var idx = line.lastIndexOf(" ");
        if (idx <= 0) continue;
        var cpu = Number(line.slice(idx + 1));
        var name = line.slice(0, idx).trim();
        if (!isFinite(cpu) || name.length === 0) continue;
        out.push({ name: name, cpu: cpu });
    }
    return out;
}

// /proc/cpuinfo: average of every "cpu MHz" line. Tabs before the colon are real.
function parseCpuFreqMHz(text) {
    var re = /^cpu MHz\s*:\s*([0-9.]+)/gm;
    var sum = 0;
    var count = 0;
    var m;
    while ((m = re.exec(String(text || ""))) !== null) {
        var v = Number(m[1]);
        if (isFinite(v)) {
            sum += v;
            count++;
        }
    }
    return count > 0 ? sum / count : null;
}

// sensors -j. Accepts the JSON text or an already-parsed object.
// Prefers coretemp "Package id 0", then k10temp "Tctl". Null if neither exists.
function pickCpuTemp(sensorsJson) {
    var data = sensorsJson;
    if (typeof sensorsJson === "string") {
        try {
            data = JSON.parse(sensorsJson);
        } catch (e) {
            return null;
        }
    }
    if (!data || typeof data !== "object") return null;

    var coretemp = data["coretemp-isa-0000"];
    if (coretemp && typeof coretemp === "object" && coretemp["Package id 0"]) {
        var pkg = coretemp["Package id 0"];
        if (typeof pkg.temp1_input === "number") return pkg.temp1_input;
    }

    var keys = Object.keys(data);
    for (var i = 0; i < keys.length; i++) {
        if (keys[i].indexOf("k10temp") !== 0) continue;
        var k10 = data[keys[i]];
        if (k10 && typeof k10 === "object" && k10["Tctl"] && typeof k10["Tctl"].temp1_input === "number") {
            return k10["Tctl"].temp1_input;
        }
    }
    return null;
}
