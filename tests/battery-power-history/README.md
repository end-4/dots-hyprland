# Battery power history tests

From the repository root:

```sh
QT_QPA_PLATFORM=offscreen /usr/lib/qt6/bin/qmltestrunner -input tests/battery-power-history
```

Tests instantiate the real history component. They cover reading validation, averaging, bounded storage, reset, and active/inactive timer behavior.
They do not query hardware, run a power benchmark, or change power profiles.
