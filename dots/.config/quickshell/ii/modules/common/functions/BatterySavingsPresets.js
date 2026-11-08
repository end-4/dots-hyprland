.pragma library

function options(value) {
    const percent = Number(value.brightnessPercent);
    return {
        limitBrightness: value.limitBrightness === true,
        brightnessPercent: Number.isFinite(percent) ? Math.max(10, Math.min(100, Math.round(percent))) : 80,
        setProfile: value.setProfile === true,
        profile: ["power-saver", "balanced", "performance"].includes(value.profile) ? value.profile : "power-saver",
        disableBlur: value.disableBlur === true,
        disableAnimations: value.disableAnimations === true
    };
}
function list(presets) {
    return Array.from(presets || []).filter(preset => preset && typeof preset.name === "string" && preset.options).slice(0, 16);
}
function save(presets, name, value) {
    const cleanName = name.trim().slice(0, 64);
    const current = list(presets);
    if (!cleanName) return current;
    const existing = current.findIndex(preset => preset.name === cleanName);
    const preset = { name: cleanName, options: options(value) };
    if (existing >= 0) current[existing] = preset;
    else if (current.length < 16) current.push(preset);
    return current;
}
