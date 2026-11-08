import QtQuick
import QtTest
import "../../dots/.config/quickshell/ii/modules/common/functions/BatterySavingsPresets.js" as Presets

TestCase {
    name: "BatterySavingsPresets"

    function test_optionsCopiesOnlySupportedFields() {
        const result = Presets.options({
            active: true,
            enable: true,
            command: "run arbitrary command",
            commands: ["one", "two"],
            limitBrightness: true,
            brightnessPercent: 73,
            setProfile: true,
            profile: "balanced",
            disableBlur: true,
            disableAnimations: true,
            pauseWallpapers: true
        })
        compare(Object.keys(result).sort(), [
            "brightnessPercent", "disableAnimations", "disableBlur",
            "limitBrightness", "profile", "setProfile"
        ])
        verify(!("enable" in result))
        verify(!("command" in result))
        verify(!("commands" in result))
        verify(!("active" in result))
        compare(result.limitBrightness, true)
        compare(result.brightnessPercent, 73)
        compare(result.profile, "balanced")
    }

    function test_brightnessPercentIsClampedAndRounded() {
        compare(Presets.options({ brightnessPercent: 2 }).brightnessPercent, 10)
        compare(Presets.options({ brightnessPercent: 140 }).brightnessPercent, 100)
        compare(Presets.options({ brightnessPercent: 55.6 }).brightnessPercent, 56)
        compare(Presets.options({ brightnessPercent: "invalid" }).brightnessPercent, 80)
    }

    function test_unknownProfileFallsBackToPowerSaver() {
        compare(Presets.options({ profile: "custom" }).profile, "power-saver")
        compare(Presets.options({ profile: "performance" }).profile, "performance")
    }

    function test_saveTrimsNamesAndReplacesMatchingEntry() {
        const initial = [{ name: "quiet", options: { disableBlur: false } }]
        const replaced = Presets.save(initial, " quiet ", { disableBlur: true })
        compare(replaced.length, 1)
        compare(replaced[0].name, "quiet")
        compare(replaced[0].options.disableBlur, true)
        // Saving produces a new list and does not mutate the caller's array.
        compare(initial[0].options.disableBlur, false)
    }

    function test_saveEnforcesSixteenEntryLimit() {
        const initial = []
        for (let index = 0; index < 16; index++)
            initial.push({ name: "preset-" + index, options: {} })
        const result = Presets.save(initial, "extra", { disableBlur: true })
        compare(result.length, 16)
        compare(result[15].name, "preset-15")
        const replaced = Presets.save(initial, "preset-0", { disableBlur: true })
        compare(replaced.length, 16)
        compare(replaced[0].options.disableBlur, true)
    }

    function test_listRejectsMalformedEntries() {
        const result = Presets.list([
            null,
            false,
            { name: 7, options: {} },
            { name: "missing-options" },
            { name: "empty-options", options: null },
            { name: "valid", options: {} }
        ])
        compare(result.length, 1)
        compare(result[0].name, "valid")
    }
}
