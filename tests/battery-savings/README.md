# Battery savings tests

Run the backend tests with the end-4 virtual environment:

```sh
~/.local/state/quickshell/.venv/bin/python -m unittest discover -s tests/battery-savings -p 'test_*.py'
QT_QPA_PLATFORM=offscreen /usr/lib/qt6/bin/qmltestrunner -input tests/battery-savings
```

The backend tests use fake hardware only. They cover snapshots, conditional restoration, brightness limits, manual changes, held profiles, validation and partial failures.
Preset tests cover allowed fields, limits, names and replacement. No commands are saved in presets.

The ASUS session was also used to apply and restore blur and the daemon power profile. Those live checks do not measure battery-life improvements.
