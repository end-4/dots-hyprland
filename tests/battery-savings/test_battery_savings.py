"""Unit tests for the battery-savings policy; all device access is faked."""
import importlib.util
from pathlib import Path
import unittest
from unittest.mock import patch


SCRIPT = (Path(__file__).resolve().parents[2] / "dots/.config/quickshell/ii/scripts/power/battery-savings.py")
SPEC = importlib.util.spec_from_file_location("battery_savings", SCRIPT)
policy = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(policy)


class FakeHardware:
    def __init__(self, values=None, held=False):
        self.values = dict(values or {})
        self.held = held
        self.reads = []
        self.writes = []
        self.fail_write = set()

    def read(self, key):
        self.reads.append(key)
        return self.values[key]

    def write(self, key, value):
        self.writes.append((key, value))
        if key in self.fail_write:
            raise RuntimeError("simulated write failure")
        self.values[key] = value

    def profile_held(self):
        return self.held


def settings(**kwargs):
    return {"active": True, **kwargs}


class BatterySavingsTests(unittest.TestCase):
    def test_hyprland_boolean_option_reads_bool_and_int_json_fields(self):
        hardware = policy.Hardware()
        with patch.object(hardware, "run", return_value='{"bool":true}'):
            self.assertIs(hardware.read("blur"), True)
        with patch.object(hardware, "run", return_value='{"int":0}'):
            self.assertIs(hardware.read("animations"), False)

    def test_hyprland_boolean_option_rejects_json_without_bool_or_int(self):
        hardware = policy.Hardware()
        for payload in ('{"string":"true"}', '{"int":"1"}', '{}'):
            with self.subTest(payload=payload):
                with patch.object(hardware, "run", return_value=payload):
                    with self.assertRaises(RuntimeError):
                        hardware.read("blur")

    def test_inactive_does_no_hardware_io(self):
        hardware = FakeHardware()
        state = policy.reconcile({"active": False}, {}, hardware)
        self.assertEqual(hardware.reads, [])
        self.assertEqual(hardware.writes, [])
        self.assertEqual(state["changes"], {})

    def test_snapshots_and_restores_values_when_turned_off(self):
        hardware = FakeHardware({"blur": True, "profile": "balanced"})
        state = {}
        policy.reconcile(settings(disableBlur=True, setProfile=True), state, hardware)
        self.assertEqual(state["changes"]["blur"], {"original": True, "applied": False})
        self.assertEqual(state["changes"]["profile"], {"original": "balanced", "applied": "power-saver"})
        policy.reconcile({"active": False}, state, hardware)
        self.assertTrue(hardware.values["blur"])
        self.assertEqual(hardware.values["profile"], "balanced")
        self.assertEqual(state["changes"], {})

    def test_already_disabled_blur_has_no_snapshot_to_restore(self):
        hardware = FakeHardware({"blur": False})
        state = {}
        policy.reconcile(settings(disableBlur=True), state, hardware)
        self.assertNotIn("blur", state["changes"])
        policy.reconcile({"active": False}, state, hardware)
        self.assertEqual(hardware.writes, [])
        self.assertFalse(hardware.values["blur"])

    def test_brightness_cap_never_raises_and_preserves_original(self):
        hardware = FakeHardware({"brightness": {"device": "panel", "value": 80, "maximum": 100}})
        state = {}
        policy.reconcile(settings(limitBrightness=True, brightnessPercent=60), state, hardware)
        self.assertEqual(state["changes"]["brightness"]["original"]["value"], 80)
        self.assertEqual(hardware.values["brightness"]["value"], 60)
        # A subsequent policy update may lower the cap, but never replaces the snapshot.
        policy.reconcile(settings(limitBrightness=True, brightnessPercent=50), state, hardware)
        self.assertEqual(state["changes"]["brightness"]["original"]["value"], 80)
        self.assertEqual(hardware.values["brightness"]["value"], 50)

    def test_manual_brightness_lowering_is_preserved_on_disable(self):
        hardware = FakeHardware({"brightness": {"device": "panel", "value": 80, "maximum": 100}})
        state = {}
        policy.reconcile(settings(limitBrightness=True, brightnessPercent=60), state, hardware)
        hardware.values["brightness"] = {"device": "panel", "value": 40, "maximum": 100}
        policy.reconcile({"active": False}, state, hardware)
        self.assertEqual(hardware.values["brightness"]["value"], 40)
        self.assertNotIn("brightness", state["changes"])

    def test_manual_profile_override_is_not_overwritten_on_disable(self):
        hardware = FakeHardware({"profile": "balanced"})
        state = {}
        policy.reconcile(settings(setProfile=True, profile="power-saver"), state, hardware)
        hardware.values["profile"] = "performance"
        policy.reconcile({"active": False}, state, hardware)
        self.assertEqual(hardware.values["profile"], "performance")
        self.assertNotIn("profile", state["changes"])

    def test_held_profile_skips_apply_then_defers_restore_until_released(self):
        hardware = FakeHardware({"profile": "balanced"}, held=True)
        state = {}
        policy.reconcile(settings(setProfile=True), state, hardware)
        self.assertEqual(hardware.reads, [])
        self.assertNotIn("profile", state["changes"])
        self.assertTrue(state["warnings"])
        hardware.held = False
        policy.reconcile(settings(setProfile=True), state, hardware)
        self.assertEqual(hardware.values["profile"], "power-saver")
        hardware.held = True
        policy.reconcile({"active": False}, state, hardware)
        self.assertIn("profile", state["changes"])
        self.assertEqual(hardware.values["profile"], "power-saver")
        hardware.held = False
        policy.reconcile({"active": False}, state, hardware)
        self.assertEqual(hardware.values["profile"], "balanced")
        self.assertNotIn("profile", state["changes"])

    def test_error_is_reported_per_key_and_other_keys_continue(self):
        hardware = FakeHardware({"blur": True, "animations": True})
        hardware.fail_write.add("blur")
        state = policy.reconcile(settings(disableBlur=True, disableAnimations=True), {}, hardware)
        self.assertEqual(state["errors"], ["blur: simulated write failure"])
        self.assertFalse(hardware.values["animations"])
        self.assertEqual([key for key, _ in hardware.writes], ["blur", "animations"])

    def test_invalid_brightness_and_profile_settings_fail_before_hardware_io(self):
        cases = (
            settings(limitBrightness=True, brightnessPercent=101),
            settings(setProfile=True, profile="unknown"),
        )
        for config in cases:
            with self.subTest(config=config):
                hardware = FakeHardware()
                with self.assertRaises(ValueError):
                    policy.reconcile(config, {}, hardware)
                self.assertEqual(hardware.reads, [])
                self.assertEqual(hardware.writes, [])

    def test_journal_is_saved_before_hardware_write(self):
        hardware = FakeHardware({"blur": True})
        state = {}
        observed = []

        def save():
            observed.append((dict(state.get("changes", {})), list(hardware.writes)))

        policy.reconcile(settings(disableBlur=True), state, hardware, save)
        self.assertTrue(any(changes.get("blur") and not writes for changes, writes in observed))

    def test_failed_write_keeps_snapshot_for_recovery(self):
        hardware = FakeHardware({"blur": True})
        hardware.fail_write.add("blur")
        state = policy.reconcile(settings(disableBlur=True), {}, hardware)
        self.assertEqual(state["changes"]["blur"], {"original": True, "applied": False})
        self.assertEqual(state["errors"], ["blur: simulated write failure"])


if __name__ == "__main__":
    unittest.main()
