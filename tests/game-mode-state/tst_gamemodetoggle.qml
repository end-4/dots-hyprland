import QtQuick
import QtTest
import qs.services

TestCase {
    id: testCase
    name: "GameModeToggle"
    property url toggleUrl: Qt.resolvedUrl("../../dots/.config/quickshell/ii/modules/common/models/quickToggles/GameModeToggle.qml")

    function createToggle() {
        const component = Qt.createComponent(toggleUrl)
        if (component.status !== Component.Ready)
            fail(component.errorString())
        const toggle = component.createObject(testCase)
        verify(toggle !== null)
        return toggle
    }

    function init() {
        HyprlandConfig.clearCalls()
    }

    function test_undefinedValueIsUnavailableOffAndDoesNotWrite() {
        const toggle = createToggle()
        compare(toggle.available, false)
        compare(toggle.toggled, false)
        toggle.mainAction()
        compare(HyprlandConfig.setManyCalls, 0)
        compare(HyprlandConfig.resetManyCalls, 0)
        toggle.destroy()
    }

    function test_booleanValuesMapToOffAndOnStates() {
        const toggle = createToggle()
        const option = findChild(toggle, "gameModeAnimations")
        verify(option !== null)
        option.value = true
        compare(toggle.available, true)
        compare(toggle.toggled, false)
        option.value = false
        compare(toggle.toggled, true)
        toggle.destroy()
    }

    function test_legacyNumericValuesMapToOffAndOnStates() {
        const toggle = createToggle()
        const option = findChild(toggle, "gameModeAnimations")
        verify(option !== null)
        option.value = 1
        compare(toggle.available, true)
        compare(toggle.toggled, false)
        option.value = 0
        compare(toggle.toggled, true)
        toggle.destroy()
    }

    function test_toggleDoesNotBreakBindingToConfigValue() {
        const toggle = createToggle()
        const option = findChild(toggle, "gameModeAnimations")
        verify(option !== null)
        option.value = true
        toggle.mainAction()
        compare(toggle.toggled, false)
        option.value = false
        compare(toggle.toggled, true)
        toggle.mainAction()
        option.value = true
        compare(toggle.toggled, false)
        toggle.destroy()
    }

    function test_clickWhenUnavailableDoesNothing() {
        const toggle = createToggle()
        toggle.mainAction()
        compare(HyprlandConfig.setManyCalls, 0)
        compare(HyprlandConfig.resetManyCalls, 0)
        toggle.destroy()
    }

    function test_enablingSendsBooleanPayload() {
        const toggle = createToggle()
        const option = findChild(toggle, "gameModeAnimations")
        option.value = true
        toggle.mainAction()
        compare(HyprlandConfig.setManyCalls, 1)
        const payload = HyprlandConfig.lastSetMany
        compare(payload["animations:enabled"], false)
        compare(payload["decoration:shadow:enabled"], false)
        compare(payload["decoration:blur:enabled"], false)
        compare(payload["general:allow_tearing"], true)
        for (const key in payload)
            compare(typeof payload[key], key === "general:allow_tearing" ? "boolean" : (key === "general:gaps_in" || key === "general:gaps_out" || key === "general:border_size" || key === "decoration:rounding" ? "number" : "boolean"))
        compare(HyprlandConfig.resetManyCalls, 0)
        toggle.destroy()
    }

    function test_disablingResetsAllGameModeKeys() {
        const toggle = createToggle()
        const option = findChild(toggle, "gameModeAnimations")
        option.value = false
        compare(toggle.toggled, true)
        toggle.mainAction()
        compare(HyprlandConfig.resetManyCalls, 1)
        compare(HyprlandConfig.lastResetMany, [
            "animations:enabled",
            "decoration:shadow:enabled",
            "decoration:blur:enabled",
            "general:gaps_in",
            "general:gaps_out",
            "general:border_size",
            "decoration:rounding",
            "general:allow_tearing"
        ])
        compare(HyprlandConfig.setManyCalls, 0)
        toggle.destroy()
    }
}
