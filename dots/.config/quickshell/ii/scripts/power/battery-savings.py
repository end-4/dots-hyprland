"""Apply a small set of reversible battery preferences; no polling or daemon."""
import argparse
import fcntl
import json
import os
from pathlib import Path
import subprocess
import tempfile


class Hardware:
    OPTIONS = {'blur': 'decoration:blur:enabled', 'animations': 'animations:enabled'}

    def run(self, *args):
        result = subprocess.run(args, text=True, capture_output=True, timeout=10)
        if result.returncode:
            raise RuntimeError(result.stderr.strip() or result.stdout.strip() or f'{args[0]} failed')
        return result.stdout.strip()

    def backlight(self):
        devices = sorted(Path('/sys/class/backlight').glob('*'))
        if not devices:
            raise RuntimeError('No internal backlight device found')
        return devices[0].name

    def read(self, key):
        if key == 'brightness':
            device = self.backlight()
            return {'device': device, 'value': int(self.run('brightnessctl', '-d', device, 'get')),
                    'maximum': int(self.run('brightnessctl', '-d', device, 'max'))}
        if key == 'profile':
            return self.run('powerprofilesctl', 'get')
        value = json.loads(self.run('hyprctl', '-j', 'getoption', self.OPTIONS[key]))
        for field in ('bool', 'int'):
            if type(value.get(field)) in (bool, int):
                return bool(value[field])
        raise RuntimeError(f'No boolean value for {key}: {value!r}')

    def write(self, key, value):
        if key == 'brightness':
            self.run('brightnessctl', '-d', value['device'], 'set', str(value['value']), '--quiet')
        elif key == 'profile':
            self.run('powerprofilesctl', 'set', value)
        else:
            enabled = 'true' if value else 'false'
            config_home = Path(os.environ.get('XDG_CONFIG_HOME', str(Path.home() / '.config')))
            if (config_home / 'hypr/hyprland.lua').is_file():
                table = '{ animations = { enabled = ' + enabled + ' } }' if key == 'animations' else '{ decoration = { blur = { enabled = ' + enabled + ' } } }'
                self.run('hyprctl', 'eval', 'hl.config(' + table + ')')
            else:
                self.run('hyprctl', 'keyword', self.OPTIONS[key], enabled)

    def profile_held(self):
        return bool(self.run('powerprofilesctl', 'list-holds'))


def desired_options(settings):
    if settings.get('active') is not True:
        return {}
    target = {}
    if settings.get('limitBrightness') is True:
        cap = settings.get('brightnessPercent', 80)
        if type(cap) not in (int, float) or not 10 <= cap <= 100:
            raise ValueError('Brightness must be between 10 and 100 percent')
        target['brightness'] = cap
    if settings.get('disableBlur') is True:
        target['blur'] = False
    if settings.get('disableAnimations') is True:
        target['animations'] = False
    if settings.get('setProfile') is True:
        profile = settings.get('profile', 'power-saver')
        if profile not in ('power-saver', 'balanced', 'performance'):
            raise ValueError('Unsupported power profile')
        target['profile'] = profile
    return target


def reconcile(settings, state, hardware, save=lambda: None):
    """Snapshot before changing; restore only values still owned by this policy."""
    desired = desired_options(settings)
    records = state.setdefault('changes', {})
    errors, warnings = [], []
    for key in ('brightness', 'blur', 'animations', 'profile'):
        if key not in desired and key not in records:
            continue
        try:
            if key == 'profile' and hardware.profile_held():
                warnings.append('Power profile held by another application')
                continue
            current = hardware.read(key)
            previous = records.get(key)
            if key not in desired:
                if current == previous['applied']:
                    hardware.write(key, previous['original'])
                records.pop(key)
                save()
                continue
            target = desired[key]
            if key == 'brightness':
                target = dict(current, value=max(1, int(current['maximum'] * target / 100)))
                if current['value'] <= target['value']:
                    # A manually lowered brightness takes precedence; never raise it to the cap.
                    if previous and current != previous['applied']:
                        records.pop(key)
                        save()
                    continue
            if current == target:
                continue
            original = previous['original'] if previous and current == previous['applied'] else current
            records[key] = {'original': original, 'applied': target}
            save()  # Recovery information must be durable before changing the device.
            hardware.write(key, target)
        except (OSError, ValueError, RuntimeError, subprocess.SubprocessError) as error:
            errors.append(f'{key}: {error}')
    state['errors'], state['warnings'] = errors, warnings
    save()
    return state


def write_state(path, state):
    fd, name = tempfile.mkstemp(prefix='.battery-savings-', dir=path.parent)
    try:
        with os.fdopen(fd, 'w') as stream:
            json.dump(state, stream, indent=2)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(name, path)
    finally:
        if os.path.exists(name):
            os.unlink(name)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--settings', required=True)
    args = parser.parse_args()
    settings = json.loads(args.settings)
    # Validate before reading or changing any device.
    desired_options(settings)
    state_home = Path(os.environ.get('XDG_STATE_HOME', str(Path.home() / '.local/state')))
    path = state_home / 'quickshell/user/battery-savings.json'
    path.parent.mkdir(parents=True, exist_ok=True)
    with (path.parent / 'battery-savings.lock').open('a') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        state = json.loads(path.read_text()) if path.exists() else {}
        session = os.environ.get('HYPRLAND_INSTANCE_SIGNATURE', '')
        if not session:
            raise ValueError('A Hyprland session is required')
        if state.get('session') != session:
            # Compositor options are reset by a new compositor session; physical
            # brightness and the daemon profile may persist across sessions.
            for key in ('blur', 'animations'):
                state.get('changes', {}).pop(key, None)
        state['session'] = session
        result = reconcile(settings, state, Hardware(), lambda: write_state(path, state))
        print(json.dumps({'errors': result['errors'], 'warnings': result['warnings']}))
        return 1 if result['errors'] else 0


if __name__ == '__main__':
    raise SystemExit(main())
